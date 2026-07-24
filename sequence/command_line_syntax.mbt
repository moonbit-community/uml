///|
fn inline_space1() -> @talc.StringParser[Unit] {
  @talc.satisfy("inline whitespace", is_inline_whitespace).some().map(_ => ())
}

///|
fn keyword_parser(keyword : String) -> @talc.StringParser[Unit] {
  identifier_word_parser().bind(word => {
    if word.equal_ignore_ascii_case(keyword) {
      @talc.pure(())
    } else {
      @talc.fail(keyword)
    }
  })
}

///|
fn signed_integer_parser() -> @talc.StringParser[Int] {
  @talc.char('-')
  .optional()
  .bind(sign => {
    @talc.many_chars1(@talc.ascii_digit()).map(digits => {
      @string.parse_int((if sign is Some(_) { "-" } else { "" }) + digits) catch {
        _ => 0
      }
    })
  })
}

///|
fn url_value_parser() -> @talc.StringParser[String] {
  let terminator = @talc.string("]]")
  let character = terminator
    .not_followed_by("URL terminator")
    .then(@talc.satisfy("URL character", _ => true))
  @talc.string("[[")
  .then(@talc.many_chars(character))
  .skip(terminator)
  .bind(content => {
    match @core.parse_url_target("[[" + content + "]]") {
      Some(target) => @talc.pure(target.target)
      None => @talc.fail("URL")
    }
  })
}

///|
fn participant_declaration_line_parser() -> @talc.StringParser[ParticipantDecl] {
  keyword_parser("create")
  .attempt()
  .optional()
  .bind(created => {
    if created is Some(_) {
      inline_space1()
      .then(
        participant_type_parser().skip(inline_space1()).attempt().optional(),
      )
      .bind(typ => {
        let typ = typ.unwrap_or(Participant)
        participant_decl_ref_parser().bind(reference => {
          participant_declaration_tail_parser(typ, reference, true)
        })
      })
    } else {
      participant_type_parser().bind(typ => {
        inline_space1()
        .then(participant_decl_ref_parser())
        .bind(reference => {
          participant_declaration_tail_parser(typ, reference, false)
        })
      })
    }
  })
  .skip(@talc.eof())
}

///|
fn participant_declaration_tail_parser(
  typ : ParticipantType,
  reference : PartRef,
  created : Bool,
) -> @talc.StringParser[ParticipantDecl] {
  inline_space1()
  .then(keyword_parser("order"))
  .then(inline_space1())
  .then(signed_integer_parser())
  .attempt()
  .optional()
  .bind(order => {
    inline_space1()
    .then(url_value_parser())
    .attempt()
    .optional()
    .bind(url => {
      inline_space1()
      .then(color_parser())
      .attempt()
      .optional()
      .skip(inline_spaces())
      .map(color => { typ, reference, created, color, url, order })
    })
  })
}

///|
fn life_event_line_parser(
  keyword : String,
  event_type : ActivationSpec,
) -> @talc.StringParser[Event] {
  keyword_parser(keyword)
  .then(
    inline_space1()
    .then(participant_code_parser())
    .bind(participant_code => {
      inline_space1()
      .then(color_parser())
      .attempt()
      .optional()
      .skip(inline_spaces())
      .map(color => LifeEvent({ participant_code, event_type, color }))
    }),
  )
  .skip(@talc.eof())
}

///|
fn deactivate_line_parser() -> @talc.StringParser[Event] {
  let latest = keyword_parser("deactivate")
    .skip(inline_spaces())
    .skip(@talc.eof())
    .map(_ => DeactivateLatest)
  latest.attempt().or(life_event_line_parser("deactivate", Deactivate))
}

///|
fn url_command_line_parser() -> @talc.StringParser[Event] {
  keyword_parser("url")
  .then(inline_space1())
  .then(
    keyword_parser("of")
    .attempt()
    .or(keyword_parser("for"))
    .skip(inline_space1())
    .optional(),
  )
  .then(participant_code_parser())
  .bind(code => {
    inline_space1()
    .then(keyword_parser("is").skip(inline_space1()).optional())
    .then(url_value_parser())
    .skip(inline_spaces())
    .map(url => Url(code, url))
  })
  .skip(@talc.eof())
}

///|
fn line_rest_parser(description : String) -> @talc.StringParser[String] {
  @talc.many_chars(@talc.satisfy(description, _ => true))
}

///|
fn grouping_line_parser() -> @talc.StringParser[Event] {
  let leaf = keyword_parser("else")
    .attempt()
    .or(keyword_parser("also"))
    .then(inline_space1().then(color_parser()).attempt().optional())
    .bind(back_color => {
      inline_spaces()
      .then(line_rest_parser("group label"))
      .map(label => {
        GroupingLeaf({ is_end: false, label: label.optional_text(), back_color })
      })
    })
  let end = keyword_parser("end")
    .then(line_rest_parser("group end"))
    .map(_ => GroupingLeaf({ is_end: true, label: None, back_color: None }))
  let start = @talc.char('&')
    .optional()
    .bind(parallel => {
      inline_spaces()
      .then(group_keyword_parser())
      .bind(keyword => {
        inline_space1()
        .then(color_parser())
        .attempt()
        .optional()
        .bind(back_color_header => {
          inline_space1()
          .then(color_parser())
          .attempt()
          .optional()
          .bind(back_color_body => {
            inline_spaces()
            .then(line_rest_parser("group header"))
            .map(header => {
              GroupingStart({
                keyword,
                header: header.trim().to_owned(),
                back_color_header,
                back_color_body,
                parallel: parallel is Some(_),
              })
            })
          })
        })
      })
    })
  start.attempt().or(leaf.attempt()).or(end).skip(@talc.eof())
}

///|
fn box_line_parser() -> @talc.StringParser[Event] {
  let end = keyword_parser("end")
    .then(inline_space1())
    .then(keyword_parser("box"))
    .skip(inline_spaces())
    .map(_ => BoxEnd)
  let label_character = @talc.char('#')
    .not_followed_by("box color")
    .then(@talc.satisfy("box label", _ => true))
  let start = keyword_parser("box")
    .then(inline_spaces())
    .then(@talc.many_chars(label_character))
    .bind(label => {
      color_parser()
      .attempt()
      .optional()
      .skip(inline_spaces())
      .map(color => BoxStart({ label: label.optional_text(), color }))
    })
  end.attempt().or(start).skip(@talc.eof())
}

///|
fn divider_line_parser() -> @talc.StringParser[Event] {
  @talc.string("==")
  .then(
    @talc.string("==")
    .not_followed_by("divider close")
    .then(@talc.satisfy("divider title", _ => true))
    .string_map(char => char.to_string())
    .many()
    .map(parts => parts.join("")),
  )
  .skip(@talc.string("=="))
  .skip(inline_spaces())
  .map(title => Divider({ title: title.trim().to_owned() }))
  .skip(@talc.eof())
}

///|
fn delay_line_parser() -> @talc.StringParser[Event] {
  let bare = @talc.string("...")
    .attempt()
    .or(@talc.char('…').string_map(char => char.to_string()))
    .skip(inline_spaces())
    .skip(@talc.eof())
    .map(_ => "")
  let ascii = @talc.string("...")
    .then(
      @talc.string("...")
      .not_followed_by("delay close")
      .then(@talc.satisfy("delay label", _ => true))
      .string_map(char => char.to_string())
      .many()
      .map(parts => parts.join("")),
    )
    .skip(@talc.string("..."))
  let unicode = @talc.char('…')
    .then(
      @talc.char('…')
      .not_followed_by("delay close")
      .then(@talc.satisfy("delay label", _ => true))
      .string_map(char => char.to_string())
      .many()
      .map(parts => parts.join("")),
    )
    .skip(@talc.char('…'))
  bare
  .attempt()
  .or(ascii.attempt())
  .or(unicode)
  .skip(inline_spaces())
  .map(label => Delay({ label: label.optional_text() }))
  .skip(@talc.eof())
}

///|
fn hspace_line_parser() -> @talc.StringParser[Event] {
  @talc.string("||")
  .then(@talc.many_chars(@talc.ascii_digit()))
  .bind(raw_pixels => {
    @talc.char('|')
    .then(@talc.char('|').many())
    .map(_ => HSpace({ pixels: raw_pixels.optional_integer() }))
  })
  .skip(inline_spaces())
  .skip(@talc.eof())
}

///|
fn newpage_line_parser() -> @talc.StringParser[Event] {
  @talc.char('@')
  .optional()
  .then(keyword_parser("newpage"))
  .then(line_rest_parser("newpage title"))
  .map(title => Newpage({ title: title.optional_text() }))
  .skip(@talc.eof())
}

///|
fn autonumber_line_parser() -> @talc.StringParser[Event] {
  let stop = keyword_parser("autonumber")
    .then(inline_space1())
    .then(keyword_parser("stop"))
    .skip(inline_spaces())
    .map(_ => AutonumberStop)
  let resume_event = keyword_parser("autonumber")
    .then(inline_space1())
    .then(keyword_parser("resume"))
    .then(
      inline_space1()
      .then(@talc.many_chars1(@talc.ascii_digit()))
      .map(value => value.optional_integer().unwrap())
      .attempt()
      .optional(),
    )
    .bind(increment => {
      inline_space1()
      .then(quoted_string_parser())
      .attempt()
      .optional()
      .skip(inline_spaces())
      .map(format => AutonumberResume({ increment, format }))
    })
  let increment = keyword_parser("autonumber")
    .then(inline_space1())
    .then(keyword_parser("inc"))
    .then(
      inline_space1()
      .then(
        @talc.many_chars1(
          @talc.satisfy("autonumber increment", Char::is_ascii_alphabetic),
        ),
      )
      .attempt()
      .optional(),
    )
    .skip(inline_spaces())
    .map(value => AutonumberIncrement(value))
  let start_value = @talc.many_chars1(
      @talc.satisfy("autonumber start", char => !is_inline_whitespace(char)),
    )
    .attempt()
    .optional()
  let start = keyword_parser("autonumber")
    .then(inline_spaces())
    .then(start_value)
    .bind(start => {
      inline_space1()
      .then(@talc.many_chars1(@talc.ascii_digit()))
      .map(value => value.optional_integer().unwrap())
      .attempt()
      .optional()
      .bind(increment => {
        inline_space1()
        .then(quoted_string_parser())
        .attempt()
        .optional()
        .skip(inline_spaces())
        .map(format => Autonumber({ start, increment, format }))
      })
    })
  @talc.choice([
    stop.attempt(),
    resume_event.attempt(),
    increment.attempt(),
    start,
  ]).skip(@talc.eof())
}

///|
fn toggle_line_parser() -> @talc.StringParser[Event] {
  let state = keyword_parser("on")
    .map(_ => true)
    .attempt()
    .or(keyword_parser("off").map(_ => false))
  let autoactivate = keyword_parser("autoactivate")
    .then(inline_space1())
    .then(state)
    .map(value => Autoactivate(value))
  let footbox = keyword_parser("footbox")
    .then(inline_space1())
    .then(state)
    .map(value => Footbox(value))
  let hide_footbox = keyword_parser("hide")
    .then(inline_space1())
    .then(keyword_parser("footbox"))
    .map(_ => Footbox(false))
  let unlinked = keyword_parser("hide")
    .map(_ => true)
    .attempt()
    .or(keyword_parser("show").map(_ => false))
    .bind(hidden => {
      inline_space1()
      .then(@talc.char('@').optional())
      .then(keyword_parser("unlinked"))
      .map(_ => HideUnlinked(hidden))
    })
  @talc.choice([
    autoactivate.attempt(),
    hide_footbox.attempt(),
    footbox.attempt(),
    unlinked,
  ])
  .skip(inline_spaces())
  .skip(@talc.eof())
}

///|
fn miscellaneous_event_line_parser() -> @talc.StringParser[Event] {
  let ignore_newpage = keyword_parser("ignore")
    .then(inline_space1())
    .then(keyword_parser("newpage"))
    .map(_ => IgnoreNewpage)
  let auto_newpage = keyword_parser("autonewpage")
    .then(inline_space1())
    .then(@talc.many_chars1(@talc.ascii_digit()))
    .map(value => AutoNewpage(value.optional_integer()))
  let return_event = @talc.char('&')
    .optional()
    .then(inline_spaces())
    .then(keyword_parser("return"))
    .then(line_rest_parser("return value"))
    .map(value => Return({ value: value.optional_text() }))
  let link_anchor = anchor_parser().bind(_ => {
    inline_spaces()
    .then(@talc.string("<->"))
    .then(inline_spaces())
    .then(anchor_parser())
    .bind(_ => {
      inline_spaces()
      .then(
        @talc.char(':')
        .then(line_rest_parser("anchor label"))
        .map(value => value.optional_text())
        .optional(),
      )
      .map(_ => LinkAnchor)
    })
  })
  @talc.choice([
    ignore_newpage.attempt(),
    auto_newpage.attempt(),
    return_event.attempt(),
    link_anchor,
  ])
  .skip(inline_spaces())
  .skip(@talc.eof())
}

///|
fn simple_event_line_parser() -> @talc.StringParser[Event] {
  @talc.choice([
    box_line_parser().attempt(),
    grouping_line_parser().attempt(),
    life_event_line_parser("activate", Activate).attempt(),
    deactivate_line_parser().attempt(),
    life_event_line_parser("destroy", Destroy).attempt(),
    divider_line_parser().attempt(),
    delay_line_parser().attempt(),
    hspace_line_parser().attempt(),
    autonumber_line_parser().attempt(),
    toggle_line_parser().attempt(),
    url_command_line_parser().attempt(),
    miscellaneous_event_line_parser().attempt(),
    newpage_line_parser(),
  ])
}
