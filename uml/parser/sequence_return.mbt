///|
/// CommandReturn reverses the activating call (or the last ordinary message
/// when no activation is pending). Resolve it before numbering and layout so
/// all ordinary message rules also apply to replies.
fn ParseCtx::resolve_return(
  self : ParseCtx,
  value : @seq.Return,
) -> @seq.Event raise @tokenizer.ParseError {
  let activation = self.activating_messages.last()
  let call = activation.map_or(self.last_message, pair => Some(pair.0))
  guard call is Some(call) else {
    raise SyntaxError(
      self.source.diagnostic("").line_number(),
      "nowhere to return to",
    )
  }
  let config = (original : @seq.ArrowConfig) => {
    ..original,
    body: @seq.Dotted,
    line_style: value.color.map_or(original.line_style, color => {
      Some("#" + color)
    }),
  }
  match call {
    @seq.Message(message) =>
      @seq.Message({
        from_code: message.to_code,
        to_code: message.from_code,
        from_display: message.to_display,
        to_display: message.from_display,
        label: value.value,
        arrow_config: config(message.arrow_config),
        anchor: None,
        from_anchor: None,
        to_anchor: None,
        parallel: value.parallel,
        multicast: [],
        activation_spec: if activation is Some(_) {
          Some(@seq.Deactivate)
        } else {
          None
        },
        activation_spec2: None,
        life_color: None,
        stereotype: None,
        url: None,
      })
    @seq.MessageExo(message) if activation is Some(_) => {
      let _ = self.activating_messages.pop()
      @seq.MessageExo({
        ..message,
        exo_type: match message.exo_type {
          @seq.FromLeft => @seq.ToLeft
          @seq.ToLeft => @seq.FromLeft
          @seq.FromRight => @seq.ToRight
          @seq.ToRight => @seq.FromRight
        },
        label: value.value,
        arrow_config: config(message.arrow_config),
        short_arrow: false,
        parallel: value.parallel,
        anchor: None,
        activation_spec: Some(@seq.Deactivate),
        life_color: None,
        url: None,
      })
    }
    _ =>
      raise SyntaxError(
        self.source.diagnostic("").line_number(),
        "nowhere to return to",
      )
  }
}
