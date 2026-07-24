///|
fn message_tail_parser() -> @talc.StringParser[
  (ActivationSpec?, String?, String?),
] {
  inline_spaces()
  .then(activation_spec_parser().attempt().optional())
  .bind(activation => {
    inline_spaces()
    .then(color_parser().attempt().optional())
    .bind(color => {
      inline_spaces()
      .then(
        @talc.char(':')
        .then(@talc.many_chars(@talc.satisfy("message label", _ => true)))
        .map(@core.normalize_label)
        .optional(),
      )
      .map(label => (activation, color, label.bind(value => value)))
    })
  })
}

///|
fn message_line_parser() -> @talc.StringParser[Event] {
  @talc.char('&')
  .optional()
  .bind(parallel => {
    inline_spaces()
    .then(anchor_parser().attempt().optional())
    .bind(anchor => {
      inline_spaces()
      .then(participant_ref_parser())
      .bind(first => {
        inline_spaces()
        .then(anchor_parser().attempt().optional())
        .skip(inline_spaces())
        .then(arrow_dressing_parser())
        .bind(dressing => {
          let (left, body, right) = dressing
          inline_spaces()
          .then(participant_ref_parser())
          .bind(second => {
            inline_spaces()
            .then(multicast_parser().attempt().optional())
            .bind(_ => {
              inline_spaces()
              .then(anchor_parser().attempt().optional())
              .then(message_tail_parser())
              .bind(tail => {
                guard message_direction(left, right) is Some(reverse) else {
                  return @talc.fail("message direction")
                }
                let (activation_spec, life_color, label) = tail
                let (from, to) = if reverse {
                  (second.code, first.code)
                } else {
                  (first.code, second.code)
                }
                @talc.pure(
                  Message({
                    from_code: from,
                    to_code: to,
                    label,
                    arrow_config: ArrowConfig::from_dressing(
                      left, right, body, reverse,
                    ),
                    parallel: parallel is Some(_),
                    anchor,
                    // PlantUML accepts trailing `& participant` here without
                    // creating an additional message branch.
                    multicast: [],
                    activation_spec,
                    life_color,
                  }),
                )
              })
            })
          })
        })
      })
    })
  })
  .skip(@talc.eof())
}

///|
fn left_exo_message_parser() -> @talc.StringParser[Event] {
  @talc.char('&')
  .optional()
  .then(inline_spaces())
  .then(@talc.char('['))
  .then(@talc.char('?').optional())
  .bind(short_arrow => {
    arrow_dressing_parser().bind(dressing => {
      let (left, body, right) = dressing
      inline_spaces()
      .then(participant_ref_parser())
      .bind(participant => {
        guard from_left_exo_type(left, right) is Some(exo_type) else {
          return @talc.fail("external message direction")
        }
        message_tail_parser().map(tail => {
          let (activation_spec, life_color, label) = tail
          MessageExo({
            participant_code: participant.code,
            exo_type,
            label,
            arrow_config: ArrowConfig::from_dressing(
              left,
              right,
              body,
              left.has_dir,
            ),
            short_arrow: short_arrow is Some(_),
            activation_spec,
            life_color,
          })
        })
      })
    })
  })
  .skip(@talc.eof())
}

///|
fn right_exo_message_parser() -> @talc.StringParser[Event] {
  @talc.char('&')
  .optional()
  .then(inline_spaces())
  .then(participant_ref_parser())
  .bind(participant => {
    inline_spaces()
    .then(arrow_dressing_parser())
    .bind(dressing => {
      let (left, body, right) = dressing
      @talc.char('?')
      .optional()
      .skip(@talc.char(']'))
      .bind(short_arrow => {
        guard to_right_exo_type(left, right) is Some(exo_type) else {
          return @talc.fail("external message direction")
        }
        message_tail_parser().map(tail => {
          let (activation_spec, life_color, label) = tail
          MessageExo({
            participant_code: participant.code,
            exo_type,
            label,
            arrow_config: ArrowConfig::from_dressing(
              left,
              right,
              body,
              left.has_dir,
            ),
            short_arrow: short_arrow is Some(_),
            activation_spec,
            life_color,
          })
        })
      })
    })
  })
  .skip(@talc.eof())
}

///|
fn complete_message_line_parser() -> @talc.StringParser[Event] {
  @talc.choice([
    left_exo_message_parser().attempt(),
    right_exo_message_parser().attempt(),
    message_line_parser(),
  ])
}
