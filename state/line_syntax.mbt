///|
priv struct StateDeclarationSyntax {
  code : String
  display : String
  kind : StateKind
  description : String?
  stereotype : String?
  url : String?
  color : String?
  opens_group : Bool
}

///|
priv struct StateTransitionSyntax {
  source : String
  target : String
  direction : TransitionDirection
  line_style : String?
  has_cross_start : Bool
  label : String?
}

///|
priv struct TransitionArrowSyntax {
  direction : TransitionDirection
  line_style : String?
  has_cross_start : Bool
  reversed : Bool
}

///|
priv struct TransitionArrowParts {
  direction : TransitionDirection?
  first_style : String?
  second_style : String?
  has_cross_start : Bool
  reversed : Bool
}

///|
priv enum StateLineSyntax {
  Declaration(StateDeclarationSyntax)
  Frame(StateDeclarationSyntax)
  Transition(StateTransitionSyntax)
  EntityNote(String)
  LinkNote(String)
}

///|
priv struct StateIdentifier {
  value : String
  quoted : Bool
}

///|
priv enum StateMetadata {
  Stereotype(String)
  Url(String)
  Color(String)
}

///|
priv struct StateMetadataValues {
  stereotype : String?
  url : String?
  color : String?
}

///|
fn state_identifier_parser() -> @talc.StringParser[StateIdentifier] {
  let quoted = @core.quoted_value_parser().map(value => { value, quoted: true })
  let unquoted = @talc.take_while("state name", char => {
    !char.is_whitespace() &&
    char != ':' &&
    char != '{' &&
    char != '#' &&
    char != '['
  }).map(value => { value, quoted: false })
  quoted.attempt().or(unquoted)
}

///|
fn state_metadata_parser() -> @talc.StringParser[StateMetadata] {
  @core.stereotype_value_parser()
  .lexeme()
  .map(value => Stereotype(value))
  .attempt()
  .or(@core.url_value_parser().lexeme().map(value => Url(value)).attempt())
  .or(
    @core.color_value_parser("state color").lexeme().map(value => Color(value)),
  )
}

///|
fn metadata_values(metadata : Array[StateMetadata]) -> StateMetadataValues {
  let mut stereotype = None
  let mut url = None
  let mut color = None
  for entry in metadata {
    match entry {
      Stereotype(value) => stereotype = Some(value)
      Url(value) => url = Some(value)
      Color(value) => color = Some(value)
    }
  }
  { stereotype, url, color }
}

///|
fn state_group_opener_parser() -> @talc.StringParser[Bool] {
  @talc.symbol("{")
  .map(_ => true)
  .attempt()
  .or(@talc.symbol("begin").map(_ => true))
  .optional()
  .map(open => open.unwrap_or(false))
}

///|
fn state_description_parser() -> @talc.StringParser[String?] {
  @talc.symbol(":")
  .then(@talc.line_content)
  .map(value => Some(value.trim().to_owned()))
  .optional()
  .map(value => value.unwrap_or(None))
}

///|
fn declaration_syntax(
  first : StateIdentifier,
  alias_value : StateIdentifier?,
  metadata : Array[StateMetadata],
  description : String?,
  opens_group : Bool,
) -> StateDeclarationSyntax {
  let values = metadata_values(metadata)
  let (code, display) = match alias_value {
    Some(second) =>
      if first.quoted {
        (second.value, first.value)
      } else {
        (first.value, second.value)
      }
    None => (first.value, first.value)
  }
  let kind = match values.stereotype {
    Some(value) if value.equal_ignore_ascii_case("<<choice>>") => Choice
    _ => Normal
  }
  {
    code,
    display,
    kind,
    description,
    stereotype: values.stereotype,
    url: values.url,
    color: values.color,
    opens_group,
  }
}

///|
fn state_declaration_parser(
  keyword : String,
) -> @talc.StringParser[StateDeclarationSyntax] {
  @talc.symbol(keyword)
  .then(state_identifier_parser().lexeme())
  .bind(first => {
    @talc.symbol("as")
    .then(state_identifier_parser().lexeme())
    .optional()
    .bind(alias_value => {
      state_metadata_parser()
      .many()
      .bind(metadata => {
        state_group_opener_parser().bind(opens_group => {
          state_description_parser()
          .skip(@talc.eof())
          .map(description => {
            declaration_syntax(
              first, alias_value, metadata, description, opens_group,
            )
          })
        })
      })
    })
  })
}

///|
fn state_endpoint_parser() -> @talc.StringParser[String] {
  @talc.choice([
    @talc.symbol("[*]").map(_ => "[*]"),
    @talc.symbol("[H*]").map(_ => "[H*]"),
    @talc.symbol("[H]").map(_ => "[H]"),
    @talc.string("==")
    .then(
      @talc.many_chars1(
        @talc.satisfy("synchronization name character", char => char != '='),
      ),
    )
    .skip(@talc.symbol("=="))
    .map(value => "==" + value + "=="),
    state_identifier_parser().lexeme().map(identifier => identifier.value),
  ])
}

///|
fn transition_direction_parser() -> @talc.StringParser[TransitionDirection] {
  @talc.choice([
    @talc.string("left").map(_ => Leftward),
    @talc.string("right").map(_ => Rightward),
    @talc.string("down").map(_ => Downward),
    @talc.string("up").map(_ => Upward),
    @talc.string("le").map(_ => Leftward),
    @talc.string("ri").map(_ => Rightward),
    @talc.string("do").map(_ => Downward),
    @talc.string("l").map(_ => Leftward),
    @talc.string("r").map(_ => Rightward),
    @talc.string("u").map(_ => Upward),
    @talc.string("d").map(_ => Downward),
  ])
}

///|
fn transition_style_parser() -> @talc.StringParser[String] {
  @talc.many_chars(
    @talc.char(']')
    .not_followed_by("transition style terminator")
    .then(@talc.satisfy("transition style character", _ => true)),
  ).between(@talc.char('['), @talc.char(']'))
}

///|
fn transition_hyphens_parser() -> @talc.StringParser[Unit] {
  @talc.char('-').some().map(_ => ())
}

///|
fn transition_arrow_from(parts : TransitionArrowParts) -> TransitionArrowSyntax {
  let line_style = match parts.second_style {
    Some(value) => Some(value)
    None => parts.first_style
  }
  {
    direction: parts.direction.unwrap_or(Automatic),
    line_style,
    has_cross_start: parts.has_cross_start,
    reversed: parts.reversed,
  }
}

///|
fn forward_transition_arrow_parser() -> @talc.StringParser[TransitionArrowParts] {
  let style = transition_style_parser()
  let direction = transition_direction_parser().optional()
  @talc.char('x')
  .optional()
  .bind(cross => {
    transition_hyphens_parser()
    .then(style.optional())
    .bind(first_style => {
      direction.bind(direction => {
        style
        .optional()
        .bind(second_style => {
          @talc.char('-')
          .many()
          .skip(@talc.char('>'))
          .map(_ => {
            direction,
            first_style,
            second_style,
            has_cross_start: cross is Some(_),
            reversed: false,
          })
        })
      })
    })
  })
}

///|
fn reverse_transition_arrow_parser() -> @talc.StringParser[TransitionArrowParts] {
  let style = transition_style_parser()
  let direction = transition_direction_parser().optional()
  @talc.char('o')
  .optional()
  .then(@talc.char('<'))
  .then(transition_hyphens_parser())
  .then(style.optional())
  .bind(first_style => {
    direction.bind(direction => {
      style
      .optional()
      .bind(second_style => {
        @talc.char('-')
        .many()
        .skip(@talc.char('x').optional())
        .map(_ => {
          direction,
          first_style,
          second_style,
          has_cross_start: false,
          reversed: true,
        })
      })
    })
  })
}

///|
fn transition_arrow_parser() -> @talc.StringParser[TransitionArrowSyntax] {
  @talc.choice([
    forward_transition_arrow_parser().attempt(),
    reverse_transition_arrow_parser(),
  ])
  .map(transition_arrow_from)
  .lexeme()
}

///|
fn transition_label_parser() -> @talc.StringParser[String?] {
  @talc.symbol(":")
  .then(@talc.line_content)
  .map(value => Some(value.trim().to_owned()))
  .optional()
  .map(value => value.unwrap_or(None))
}

///|
fn state_transition_parser() -> @talc.StringParser[StateTransitionSyntax] {
  @talc.spaces()
  .then(state_endpoint_parser())
  .bind(first => {
    transition_arrow_parser().bind(arrow => {
      state_endpoint_parser().bind(second => {
        transition_label_parser()
        .skip(@talc.eof())
        .map(label => {
          let (source, target) = if arrow.reversed {
            (second, first)
          } else {
            (first, second)
          }
          {
            source,
            target,
            direction: arrow.direction,
            line_style: arrow.line_style,
            has_cross_start: arrow.has_cross_start,
            label,
          }
        })
      })
    })
  })
}

///|
fn entity_note_parser() -> @talc.StringParser[String] {
  @talc.symbol("note")
  .then(
    @talc.choice([
      @talc.symbol("left"),
      @talc.symbol("right"),
      @talc.symbol("top"),
      @talc.symbol("bottom"),
    ]),
  )
  .then(@talc.symbol("of"))
  .then(state_endpoint_parser())
  .skip(@talc.line_content.optional())
  .skip(@talc.eof())
}

///|
fn link_note_parser() -> @talc.StringParser[String] {
  @talc.symbol("note")
  .then(@talc.symbol("on"))
  .then(@talc.symbol("link"))
  .skip(@core.color_value_parser("note color").lexeme().optional())
  .then(@talc.symbol(":"))
  .then(@talc.line_content)
  .skip(@talc.eof())
  .map(value => value.trim().to_owned())
}

///|
fn state_line_parser() -> @talc.StringParser[StateLineSyntax] {
  @talc.choice([
    state_declaration_parser("state").map(value => Declaration(value)).attempt(),
    state_declaration_parser("frame").map(value => Frame(value)).attempt(),
    state_transition_parser().map(value => Transition(value)).attempt(),
    entity_note_parser().map(value => EntityNote(value)).attempt(),
    link_note_parser().map(value => LinkNote(value)),
  ])
}

///|
fn parse_line_syntax(line : String) -> StateLineSyntax? {
  match state_line_parser().parse(@talc.Input::new(line)) {
    Ok(syntax) => Some(syntax)
    Err(_) => None
  }
}
