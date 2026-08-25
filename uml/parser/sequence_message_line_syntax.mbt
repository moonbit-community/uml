///|
/// Matches one of the message activation specifiers `++`, `**`, `!!`, `--`,
/// `--++`, `++--`, mirroring Java's ACTIVATION group. The first effect
/// targets the second participant, the combined forms add a second effect
/// (see `manageActivations`). Never consumes input when it fails.
fn take_message_activation(
  cursor : @parse.Cursor,
) -> (@seq.ActivationSpec, @seq.ActivationSpec?)? {
  if cursor.consume_literal("++") {
    if cursor.consume_literal("--") {
      Some((@seq.Activate, Some(@seq.Deactivate)))
    } else {
      Some((@seq.Activate, None))
    }
  } else if cursor.consume_literal("**") {
    Some((@seq.Create, None))
  } else if cursor.consume_literal("!!") {
    Some((@seq.Destroy, None))
  } else if cursor.consume_literal("--") {
    if cursor.consume_literal("++") {
      Some((@seq.Deactivate, Some(@seq.Activate)))
    } else {
      Some((@seq.Deactivate, None))
    }
  } else {
    None
  }
}

///|
/// Matches the exo activation run `[+*!-]+`; only its first character has
/// an effect, mirroring `CommandExoArrowAny`. Never consumes input when it
/// fails.
fn take_exo_activation(cursor : @parse.Cursor) -> @seq.ActivationSpec? {
  let start = cursor.offset()
  match cursor.peek() {
    Some('+') => {
      ignore(cursor.skip_while(char => is_exo_activation_char(char)))
      Some(@seq.Activate)
    }
    Some('-') => {
      ignore(cursor.skip_while(char => is_exo_activation_char(char)))
      Some(@seq.Deactivate)
    }
    Some('!') => {
      ignore(cursor.skip_while(char => is_exo_activation_char(char)))
      Some(@seq.Destroy)
    }
    Some('*') => {
      ignore(cursor.skip_while(char => is_exo_activation_char(char)))
      Some(@seq.Create)
    }
    _ => {
      ignore(cursor.restore(start))
      None
    }
  }
}

///|
fn is_exo_activation_char(char : Char) -> Bool {
  char == '+' || char == '*' || char == '!' || char == '-'
}

///|
/// Matches an optional `{anchor}` token followed by exactly one inline
/// space, mirroring Java's `(\{([%pLN_]+)\}[%s]+)?`: the greedy `[%s]+`
/// hands surplus spaces back to the following tokens, so a single space is
/// consumed here and the remainder is skipped by the caller.
fn take_anchor(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('{') else { return None }
  let name = cursor.take_while(is_anchor_char)
  guard name.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.consume('}') else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  Some(name)
}

///|
fn is_anchor_char(char : Char) -> Bool {
  char.is_ascii_alphabetic() || char.is_ascii_digit() || char == '_'
}

///|
/// Matches one or more ` & name` multicast elements, mirroring Java's
/// `(?:\s&\s[%pLN_.@]+)*`. An element needs a space before `&`, a space
/// after it and a name; a partial element discards only that element.
fn take_multicast(cursor : @parse.Cursor) -> Array[String] {
  let result = Array::new()
  while true {
    let saved = cursor.offset()
    if !consume_inline_space1(cursor) {
      break
    }
    if !cursor.consume('&') {
      ignore(cursor.restore(saved))
      break
    }
    if !consume_inline_space1(cursor) {
      ignore(cursor.restore(saved))
      break
    }
    let ident = cursor.take_while(is_ident_char)
    if ident.length() > 0 {
      result.push(ident)
    } else {
      ignore(cursor.restore(saved))
      break
    }
  }
  result
}

///|
/// Consumes exactly one inline whitespace character.
fn consume_inline_space1(cursor : @parse.Cursor) -> Bool {
  if cursor.peek() is Some(char) && is_inline_whitespace(char) {
    ignore(cursor.advance())
    true
  } else {
    false
  }
}

///|
/// Matches the optional `(digits)` arrow index token, consuming it when
/// present.
fn take_optional_digits(cursor : @parse.Cursor) -> Unit {
  let start = cursor.offset()
  guard cursor.consume('(') else { return }
  ignore(cursor.skip_while(Char::is_ascii_digit))
  guard cursor.consume(')') else {
    ignore(cursor.restore(start))
    return
  }
  ()
}

///|
/// Matches `o` or `x` followed by at least one inline space, returning
/// `(circle, cross)`; on failure consumes nothing.
fn take_o_x_space(cursor : @parse.Cursor) -> (Bool, Bool)? {
  let start = cursor.offset()
  let circle = cursor.consume('o')
  let cross = if circle { false } else { cursor.consume('x') }
  if circle || cross {
    if cursor.skip_inline_space1() {
      Some((circle, cross))
    } else {
      ignore(cursor.restore(start))
      None
    }
  } else {
    None
  }
}

///|
/// Matches `o` or `x` preceded by at least one inline space, returning
/// `(circle, cross)`; on failure consumes nothing. Mirrors the exo
/// participant-side `([%s]+[ox])?` decoration.
fn take_space_o_x(cursor : @parse.Cursor) -> (Bool, Bool)? {
  let start = cursor.offset()
  let spaces = cursor.skip_inline_whitespace()
  if spaces > 0 && (cursor.peek() == Some('o') || cursor.peek() == Some('x')) {
    let circle = cursor.consume('o')
    let cross = if circle { false } else { cursor.consume('x') }
    Some((circle, cross))
  } else {
    ignore(cursor.restore(start))
    None
  }
}

///|
/// Matches the arrow head on the left side, always succeeding with
/// `@seq.NoneHead`/`@seq.Full` when no head is present. The `_` suffix allowed by
/// Java's `<<?_?` is consumed and discarded.
fn take_left_arrow_head(
  cursor : @parse.Cursor,
) -> (@seq.ArrowHead, @seq.ArrowPart) {
  match cursor.peek() {
    Some('<') => {
      ignore(cursor.advance())
      let is_async = cursor.consume('<')
      ignore(cursor.consume('_'))
      (if is_async { @seq.Async } else { @seq.Normal }, @seq.Full)
    }
    Some('/') => {
      ignore(cursor.advance())
      let is_async = cursor.consume('/')
      (if is_async { @seq.Async } else { @seq.Normal }, @seq.TopPart)
    }
    Some('\\') => {
      ignore(cursor.advance())
      let is_async = cursor.consume('\\')
      (if is_async { @seq.Async } else { @seq.Normal }, @seq.BottomPart)
    }
    _ => (@seq.NoneHead, @seq.Full)
  }
}

///|
/// Matches the arrow head on the right side, always succeeding with
/// `@seq.NoneHead`/`@seq.Full` when no head is present.
fn take_right_arrow_head(
  cursor : @parse.Cursor,
) -> (@seq.ArrowHead, @seq.ArrowPart) {
  match cursor.peek() {
    Some('>') => {
      ignore(cursor.advance())
      let is_async = cursor.consume('>')
      (if is_async { @seq.Async } else { @seq.Normal }, @seq.Full)
    }
    Some('/') => {
      ignore(cursor.advance())
      let is_async = cursor.consume('/')
      (if is_async { @seq.Async } else { @seq.Normal }, @seq.BottomPart)
    }
    Some('\\') => {
      ignore(cursor.advance())
      let is_async = cursor.consume('\\')
      (if is_async { @seq.Async } else { @seq.Normal }, @seq.TopPart)
    }
    _ => (@seq.NoneHead, @seq.Full)
  }
}

///|
/// Matches the left dressing, mirroring Java's ARROW_DRESSING1: an `o`/`x`
/// (requiring a preceding space) or `(digits)` before the head, an
/// optional `_` after `<`/`<<`, and no `o`/`x` together with `(digits)`.
/// Consumes its own leading spaces so the `o`/`x` can demand the extra
/// space Java's `[%s][ox]` needs. Always succeeds.
fn take_left_dressing(cursor : @parse.Cursor) -> @seq.DressingResult {
  let spaces = cursor.skip_inline_whitespace()
  if spaces > 0 && (cursor.peek() == Some('o') || cursor.peek() == Some('x')) {
    let circle = cursor.consume('o')
    let cross = if circle { false } else { cursor.consume('x') }
    let (head, part) = take_left_arrow_head(cursor)
    return { head, circle, cross, has_dir: head.has_direction(), part, }
  }
  let digits = cursor.offset()
  if cursor.consume('(') {
    ignore(cursor.skip_while(Char::is_ascii_digit))
    if !cursor.consume(')') {
      ignore(cursor.restore(digits))
    } else if cursor.peek() == Some('<') {
      let (head, part) = take_left_arrow_head(cursor)
      return {
        head,
        circle: false,
        cross: false,
        has_dir: head.has_direction(),
        part,
      }
    } else {
      ignore(cursor.restore(digits))
    }
  }
  let (head, part) = take_left_arrow_head(cursor)
  { head, circle: false, cross: false, has_dir: head.has_direction(), part, }
}

///|
/// Matches the right dressing, mirroring Java's ARROW_DRESSING2: `_?>>?`
/// (the `_` only when no `>` starts the dressing), `/`/`\` heads, then
/// either `o`/`x` with a following space or `(digits)` (never both), or a
/// standalone `o`/`x` with a following space. Always succeeds.
fn take_right_dressing(cursor : @parse.Cursor) -> @seq.DressingResult {
  let start = cursor.offset()
  let mut head : @seq.ArrowHead = @seq.NoneHead
  let mut part : @seq.ArrowPart = @seq.Full
  let mut circle = false
  let mut cross = false
  match cursor.peek() {
    Some('>') => {
      ignore(cursor.advance())
      head = @seq.Normal
      if cursor.consume('>') {
        head = @seq.Async
      }
      match take_o_x_space(cursor) {
        Some((o, x)) => {
          circle = o
          cross = x
        }
        None => take_optional_digits(cursor)
      }
    }
    Some('_') => {
      ignore(cursor.advance())
      if cursor.consume('>') {
        head = @seq.Normal
        if cursor.consume('>') {
          head = @seq.Async
        }
        match take_o_x_space(cursor) {
          Some((o, x)) => {
            circle = o
            cross = x
          }
          None => take_optional_digits(cursor)
        }
      } else {
        ignore(cursor.restore(start))
      }
    }
    Some('/') => {
      ignore(cursor.advance())
      head = @seq.Normal
      if cursor.consume('/') {
        head = @seq.Async
      }
      part = @seq.BottomPart
      match take_o_x_space(cursor) {
        Some((o, x)) => {
          circle = o
          cross = x
        }
        None => ()
      }
    }
    Some('\\') => {
      ignore(cursor.advance())
      head = @seq.Normal
      if cursor.consume('\\') {
        head = @seq.Async
      }
      part = @seq.TopPart
      match take_o_x_space(cursor) {
        Some((o, x)) => {
          circle = o
          cross = x
        }
        None => ()
      }
    }
    _ =>
      match take_o_x_space(cursor) {
        Some((o, x)) => {
          circle = o
          cross = x
        }
        None => ()
      }
  }
  { head, circle, cross, has_dir: head.has_direction(), part, }
}

///|
/// Matches an optional `[LINE_STYLE]` token: a comma-separated list of
/// colors (`#\w+`) and style keywords, mirroring `CommandLinkElement.
/// LINE_STYLE`. Consumes nothing when absent or malformed.
fn take_arrow_style(cursor : @parse.Cursor) -> Unit {
  let start = cursor.offset()
  guard cursor.consume('[') else { return }
  if !take_style_token(cursor) {
    ignore(cursor.restore(start))
    return
  }
  while cursor.consume(',') {
    if !take_style_token(cursor) {
      ignore(cursor.restore(start))
      return
    }
  }
  guard cursor.consume(']') else {
    ignore(cursor.restore(start))
    return
  }
  ()
}

///|
fn take_style_token(cursor : @parse.Cursor) -> Bool {
  let start = cursor.offset()
  if cursor.consume('#') {
    let word = cursor.take_while(sequence_is_word_char)
    if word.length() > 0 {
      return true
    }
    ignore(cursor.restore(start))
    return false
  }
  let word = cursor.take_while(sequence_is_word_char)
  if is_style_keyword(word.to_lower()) {
    true
  } else {
    ignore(cursor.restore(start))
    false
  }
}

///|
fn sequence_is_word_char(char : Char) -> Bool {
  char.is_ascii_alphabetic() || char.is_ascii_digit() || char == '_'
}

///|
fn is_style_keyword(word : String) -> Bool {
  word == "dotted" ||
  word == "dashed" ||
  word == "plain" ||
  word == "bold" ||
  word == "hidden" ||
  word == "norank" ||
  word == "single" ||
  word == "node" ||
  (
    word.has_prefix("thickness=") &&
    word.length() > "thickness=".length() &&
    word["thickness=".length():].all(char => char.is_ascii_digit())
  )
}

///|
/// Matches the arrow body: left dressing, dashes, an optional `[style]`
/// token and more dashes, then the right dressing. Requires at least one
/// dash, mirroring the talc "arrow body" failure.
fn take_arrow_dressing(
  cursor : @parse.Cursor,
) -> (@seq.DressingResult, @seq.ArrowBody, @seq.DressingResult)? {
  let left = take_left_dressing(cursor)
  let first = cursor.take_while(char => char == '-')
  take_arrow_style(cursor)
  let second = cursor.take_while(char => char == '-')
  let dashes = first.length() + second.length()
  guard dashes > 0 else { return None }
  let right = take_right_dressing(cursor)
  let body = if dashes > 1 { @seq.Dotted } else { @seq.Solid }
  Some((left, body, right))
}

///|
/// Matches the exo arrow body: an optional left head (`<<?|//?|\\\\?`),
/// dashes, an optional `[style]`, more dashes and an optional right head
/// (`>>?|//?|\\\\?`). Requires at least one dash and one head, mirroring
/// `CommandExoArrowLeft`/`@seq.Right` alternatives.
fn take_exo_arrow_dressing(
  cursor : @parse.Cursor,
) -> (@seq.DressingResult, @seq.ArrowBody, @seq.DressingResult)? {
  let start = cursor.offset()
  let (left_head, left_part) = take_left_arrow_head(cursor)
  let first = cursor.take_while(char => char == '-')
  take_arrow_style(cursor)
  let second = cursor.take_while(char => char == '-')
  let dashes = first.length() + second.length()
  guard dashes > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  let (right_head, right_part) = take_right_arrow_head(cursor)
  guard !(left_head is @seq.NoneHead) || !(right_head is @seq.NoneHead) else {
    ignore(cursor.restore(start))
    return None
  }
  let body = if dashes > 1 { @seq.Dotted } else { @seq.Solid }
  Some(
    (
      {
        head: left_head,
        circle: false,
        cross: false,
        has_dir: left_head.has_direction(),
        part: left_part,
      },
      body,
      {
        head: right_head,
        circle: false,
        cross: false,
        has_dir: right_head.has_direction(),
        part: right_part,
      },
    ),
  )
}

///|
/// Matches a participant reference: a quoted name or bare identifier,
/// optionally aliased with `as` followed by a quoted display name,
/// mirroring Java's PART1/PART2 alternatives. On failure restores the
/// cursor.
fn take_part_ref(cursor : @parse.Cursor) -> PartRef? {
  let start = cursor.offset()
  if cursor.peek() == Some('"') {
    if cursor.take_quoted_value() is Some(display) {
      return match take_alias_code(cursor) {
        Some(code) => Some({ code, display, })
        None => Some({ code: display, display, })
      }
    }
  }
  let code = cursor.take_while(is_ident_char)
  guard code.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  let display = take_alias_display(cursor).unwrap_or(code)
  Some({ code, display, })
}

///|
/// Matches `as "display"`, mirroring Java's CODELONG alternative: after
/// `as` only a quoted name is valid. Restores the cursor when the alias
/// is absent or incomplete.
fn take_alias_display(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  cursor.skip_inline_spaces()
  guard take_as_keyword(cursor) else {
    ignore(cursor.restore(start))
    return None
  }
  cursor.skip_inline_spaces()
  match cursor.take_quoted_value() {
    Some(value) => Some(value)
    None => {
      ignore(cursor.restore(start))
      None
    }
  }
}

///|
/// Matches the exo participant: a quoted name or bare identifier with no
/// `as` alias, mirroring Java's PARTICIPANT alternative. On failure
/// restores the cursor.
fn take_exo_participant(cursor : @parse.Cursor) -> PartRef? {
  let start = cursor.offset()
  if cursor.peek() == Some('"') {
    match cursor.take_quoted_value() {
      Some(display) => Some({ code: display, display, })
      None => {
        ignore(cursor.restore(start))
        None
      }
    }
  } else {
    let code = cursor.take_while(is_ident_char)
    if code.length() > 0 {
      Some({ code, display: code, })
    } else {
      ignore(cursor.restore(start))
      None
    }
  }
}

///|
/// Matches a `#`-prefixed life-line color, taking only Java's `\w` run
/// (`[A-Za-z0-9_]`), mirroring the `#\w+` LIFECOLOR group of the arrow and
/// exo commands. Restores the original position when no word follows the
/// marker.
fn take_life_color_value(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('#') else { return None }
  let word = cursor.take_while(sequence_is_word_char)
  guard word.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  Some(word)
}

///|
/// Matches the message tail: optional activation specifier, optional
/// `#color`, optional `<<stereotype>>`, optional `[[url]]`, optional `:`
/// label, mirroring Java's `ACTIVATION LIFECOLOR StereotypePattern.optional
/// UrlBuilder.OPTIONAL : MESSAGE?`. Always succeeds.
fn take_message_tail(
  cursor : @parse.Cursor,
) -> (
  @seq.ActivationSpec?,
  @seq.ActivationSpec?,
  String?,
  String?,
  String?,
  String?,
) {
  cursor.skip_inline_spaces()
  let activation = take_message_activation(cursor)
  cursor.skip_inline_spaces()
  let life_color = take_life_color_value(cursor)
  let stereotype = take_optional_stereotype(cursor, url_then_colon_or_eof)
  let url = take_optional_url(cursor)
  cursor.skip_inline_spaces()
  let label = if cursor.consume(':') {
    @parse.normalize_label(cursor.take_while(_ => true))
  } else {
    None
  }
  activation.map_or((None, None, life_color, stereotype, url, label), pair => {
    let (spec, second) = pair
    (Some(spec), second, life_color, stereotype, url, label)
  })
}

///|
/// Matches the exo tail: optional activation run, optional `#color`,
/// optional `[[url]]`, optional `:` label. Exo arrows accept no stereotype,
/// mirroring `CommandExoArrowLeft`/`@seq.Right`. Always succeeds.
fn take_exo_tail(
  cursor : @parse.Cursor,
) -> (@seq.ActivationSpec?, String?, String?, String?) {
  cursor.skip_inline_spaces()
  let activation_spec = take_exo_activation(cursor)
  cursor.skip_inline_spaces()
  let life_color = take_life_color_value(cursor)
  let url = take_optional_url(cursor)
  cursor.skip_inline_spaces()
  let label = if cursor.consume(':') {
    @parse.normalize_label(cursor.take_while(_ => true))
  } else {
    None
  }
  (activation_spec, life_color, url, label)
}

///|
/// Matches a complete message between two participants, requiring the
/// full line to be consumed.
fn message_line_syntax(cursor : @parse.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  ignore(cursor.consume('&'))
  cursor.skip_inline_spaces()
  let anchor = match take_anchor(cursor) {
    Some(anchor) => {
      cursor.skip_inline_spaces()
      Some(anchor)
    }
    None => None
  }
  let first = match take_part_ref(cursor) {
    Some(part) => part
    None => {
      ignore(cursor.restore(start))
      return None
    }
  }
  ignore(take_anchor(cursor))
  let dressing = match take_arrow_dressing(cursor) {
    Some(dressing) => dressing
    None => {
      ignore(cursor.restore(start))
      return None
    }
  }
  let (left, body, right) = dressing
  cursor.skip_inline_spaces()
  let second = match take_part_ref(cursor) {
    Some(part) => part
    None => {
      ignore(cursor.restore(start))
      return None
    }
  }
  ignore(take_multicast(cursor))
  ignore(take_anchor(cursor))
  let (activation_spec, activation_spec2, life_color, stereotype, url, label) = take_message_tail(
    cursor,
  )
  let direction = match @seq.message_direction(left, right) {
    Some(direction) => direction
    None => {
      ignore(cursor.restore(start))
      return None
    }
  }
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  let (from, to) = match direction {
    @seq.Reverse => (second.code, first.code)
    @seq.Forward => (first.code, second.code)
  }
  Some(
    @seq.Message({
      from_code: from,
      to_code: to,
      label,
      arrow_config: @seq.ArrowConfig::from_dressing(
        left, right, body, direction,
      ),
      anchor,
      activation_spec,
      activation_spec2,
      life_color,
      stereotype,
      url,
    }),
  )
}

///|
/// Matches an exogenous message arriving from or leaving to the left
/// border, requiring the full line to be consumed.
fn left_exo_message_syntax(cursor : @parse.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  ignore(cursor.consume('&'))
  cursor.skip_inline_spaces()
  ignore(take_anchor(cursor))
  cursor.skip_inline_spaces()
  let symbol = take_exo_left_symbol(cursor)
  guard symbol is Some((_, _, _, _)) else {
    ignore(cursor.restore(start))
    return None
  }
  let (symbol_char, short_arrow, border_circle, border_cross) = symbol.unwrap()
  let dressing = match take_exo_arrow_dressing(cursor) {
    Some(dressing) => dressing
    None => {
      ignore(cursor.restore(start))
      return None
    }
  }
  let (left, body, right) = dressing
  let (participant_circle, participant_cross) = take_o_x_space(cursor).unwrap_or(
    (false, false),
  )
  cursor.skip_inline_spaces()
  let participant = match take_exo_participant(cursor) {
    Some(part) => part
    None => {
      ignore(cursor.restore(start))
      return None
    }
  }
  let exo_type = match @seq.exo_left_type(symbol_char, left, right) {
    Some(exo_type) => exo_type
    None => {
      ignore(cursor.restore(start))
      return None
    }
  }
  let (activation_spec, life_color, url, label) = take_exo_tail(cursor)
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  let border = { ..left, circle: border_circle, cross: border_cross, }
  let participant_side = {
    ..right,
    circle: participant_circle,
    cross: participant_cross,
  }
  Some(
    @seq.MessageExo({
      participant_code: participant.code,
      exo_type,
      label,
      arrow_config: @seq.ArrowConfig::from_dressing(
        border,
        participant_side,
        body,
        if border.has_dir {
          @seq.Reverse
        } else {
          @seq.Forward
        },
      ),
      short_arrow,
      activation_spec,
      life_color,
      url,
    }),
  )
}

///|
/// Matches an exogenous message arriving from or leaving to the right
/// border, requiring the full line to be consumed.
fn right_exo_message_syntax(cursor : @parse.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  ignore(cursor.consume('&'))
  cursor.skip_inline_spaces()
  ignore(take_anchor(cursor))
  cursor.skip_inline_spaces()
  let participant = match take_exo_participant(cursor) {
    Some(part) => part
    None => {
      ignore(cursor.restore(start))
      return None
    }
  }
  let (participant_circle, participant_cross) = take_space_o_x(cursor).unwrap_or(
    (false, false),
  )
  cursor.skip_inline_spaces()
  let dressing = match take_exo_arrow_dressing(cursor) {
    Some(dressing) => dressing
    None => {
      ignore(cursor.restore(start))
      return None
    }
  }
  let (left, body, right) = dressing
  let symbol = take_exo_right_symbol(cursor)
  guard symbol is Some((_, _, _, _)) else {
    ignore(cursor.restore(start))
    return None
  }
  let (symbol_char, short_arrow, border_circle, border_cross) = symbol.unwrap()
  let exo_type = match @seq.exo_right_type(symbol_char, left, right) {
    Some(exo_type) => exo_type
    None => {
      ignore(cursor.restore(start))
      return None
    }
  }
  let (activation_spec, life_color, url, label) = take_exo_tail(cursor)
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  let border = { ..right, circle: border_circle, cross: border_cross, }
  let participant_side = {
    ..left,
    circle: participant_circle,
    cross: participant_cross,
  }
  Some(
    @seq.MessageExo({
      participant_code: participant.code,
      exo_type,
      label,
      arrow_config: @seq.ArrowConfig::from_dressing(
        participant_side,
        border,
        body,
        if participant_side.has_dir {
          @seq.Reverse
        } else {
          @seq.Forward
        },
      ),
      short_arrow,
      activation_spec,
      life_color,
      url,
    }),
  )
}

///|
/// Matches the exo border symbol `[?\[\]][ox]?` on the left side,
/// returning the symbol character, the short-arrow flag and the border
/// circle/cross decorations.
fn take_exo_left_symbol(cursor : @parse.Cursor) -> (Char, Bool, Bool, Bool)? {
  let start = cursor.offset()
  let symbol = match cursor.peek() {
    Some(char) if char == '?' || char == '[' || char == ']' => {
      ignore(cursor.advance())
      char
    }
    _ => {
      ignore(cursor.restore(start))
      return None
    }
  }
  let circle = cursor.consume('o')
  let cross = if circle { false } else { cursor.consume('x') }
  Some((symbol, symbol == '?', circle, cross))
}

///|
/// Matches the exo border symbol `[ox]?[?\]\[]` on the right side,
/// returning the symbol character and the border circle/cross
/// decorations. A `?` or `[` here can never complete a line (the closing
/// `]` is required), so only `]` with an optional `o`/`x` is reachable.
fn take_exo_right_symbol(cursor : @parse.Cursor) -> (Char, Bool, Bool, Bool)? {
  let start = cursor.offset()
  let circle = cursor.consume('o')
  let cross = if circle { false } else { cursor.consume('x') }
  if cursor.consume(']') {
    Some((']', false, circle, cross))
  } else {
    ignore(cursor.restore(start))
    None
  }
}

///|
/// Tries the left exo, right exo and plain message forms in order,
/// mirroring the talc `choice` with the two exo forms wrapped in
/// `attempt`.
fn complete_message_line_syntax(cursor : @parse.Cursor) -> @seq.Event? {
  let start = cursor.offset()
  if left_exo_message_syntax(cursor) is Some(event) {
    return Some(event)
  }
  ignore(cursor.restore(start))
  if right_exo_message_syntax(cursor) is Some(event) {
    return Some(event)
  }
  ignore(cursor.restore(start))
  message_line_syntax(cursor)
}
