///|
fn Source::try_participant_ref(self : Source) -> PartRef? {
  let checkpoint = self.save()
  if self.consume('"') {
    let display = self.take_while(c => c != '"')
    guard self.consume('"') else {
      self.restore(checkpoint)
      return None
    }
    self.skip_whitespace()
    guard !self.try_keyword("as") else {
      self.skip_whitespace()
      let code = self.take_while(is_ident_char)
      guard code.length() > 0 else {
        self.restore(checkpoint)
        return None
      }
      return Some({ code, display })
    }
    return Some({ code: display, display })
  }
  let code = self.take_while(is_ident_char)
  guard code.length() > 0 else {
    self.restore(checkpoint)
    return None
  }
  self.skip_whitespace()
  guard self.try_keyword("as") else { return Some({ code, display: code }) }
  self.skip_whitespace()
  let display = if self.consume('"') {
    let quoted = self.take_while(c => c != '"')
    guard self.consume('"') else {
      self.restore(checkpoint)
      return None
    }
    quoted
  } else {
    self.take_while(is_ident_char)
  }
  Some({ code, display })
}

///|
fn Source::try_participant_decl_ref(self : Source) -> PartRef? {
  let checkpoint = self.save()
  if self.consume('"') {
    let display = self.take_while(c => c != '"')
    guard self.consume('"') else {
      self.restore(checkpoint)
      return None
    }
    self.skip_whitespace()
    guard !self.try_keyword("as") else {
      self.skip_whitespace()
      let code = self.take_while(is_ident_char)
      guard code.length() > 0 else {
        self.restore(checkpoint)
        return None
      }
      return Some({ code, display })
    }
    return Some({ code: display, display })
  }
  let first = self.take_while(is_ident_char)
  guard first.length() > 0 else {
    self.restore(checkpoint)
    return None
  }
  self.skip_whitespace()
  guard self.try_keyword("as") else {
    return Some({ code: first, display: first })
  }
  self.skip_whitespace()
  if self.consume('"') {
    let display = self.take_while(c => c != '"')
    guard self.consume('"') else {
      self.restore(checkpoint)
      return None
    }
    return Some({ code: first, display })
  }
  let code = self.take_while(is_ident_char)
  guard code.length() > 0 else {
    self.restore(checkpoint)
    return None
  }
  Some({ code, display: first })
}

///|
fn Source::try_participant_code(self : Source) -> String? {
  let checkpoint = self.save()
  if self.consume('"') {
    let code = self.take_while(c => c != '"')
    guard self.consume('"') && code.length() > 0 else {
      self.restore(checkpoint)
      return None
    }
    return Some(code)
  }
  let code = self.take_while(is_ident_char)
  guard code.length() > 0 else {
    self.restore(checkpoint)
    return None
  }
  Some(code)
}

///|
fn Source::take_left_dressing(self : Source) -> DressingResult {
  let circle = self.consume('o')
  let cross = self.consume('x')
  let (head, part) = if self.consume('<') {
    (if self.consume('<') { Async } else { Normal }, Full)
  } else if self.consume('/') {
    (if self.consume('/') { Async } else { Normal }, TopPart)
  } else if self.consume('\\') {
    (if self.consume('\\') { Async } else { Normal }, BottomPart)
  } else {
    (NoneHead, Full)
  }
  if self.consume('(') {
    let _ = self.take_while(Char::is_ascii_digit)
    let _ = self.consume(')')
  }
  { head, circle, cross, has_dir: head.has_direction(), part }
}

///|
fn Source::take_right_dressing(self : Source) -> DressingResult {
  let _ = self.consume('_')
  let (head, part) = if self.consume('>') {
    (if self.consume('>') { Async } else { Normal }, Full)
  } else if self.consume('/') {
    (if self.consume('/') { Async } else { Normal }, BottomPart)
  } else if self.consume('\\') {
    (if self.consume('\\') { Async } else { Normal }, TopPart)
  } else {
    (NoneHead, Full)
  }
  let circle = self.consume('o')
  let cross = self.consume('x')
  if self.consume('(') {
    let _ = self.take_while(Char::is_ascii_digit)
    let _ = self.consume(')')
  }
  { head, circle, cross, has_dir: head.has_direction(), part }
}

///|
fn Source::try_arrow_dressing(
  self : Source,
) -> (DressingResult, ArrowBody, DressingResult)? {
  let left = self.take_left_dressing()
  let first_dashes = self.take_while(c => c == '-')
  if self.consume('[') {
    let _ = self.take_while(c => c != ']')
    let _ = self.consume(']')
  }
  let second_dashes = self.take_while(c => c == '-')
  guard first_dashes.length() + second_dashes.length() > 0 else { None }
  let body = if first_dashes.length() + second_dashes.length() > 1 {
    Dotted
  } else {
    Solid
  }
  Some((left, body, self.take_right_dressing()))
}

///|
fn Source::take_activation_spec(self : Source) -> ActivationSpec? {
  if self.try_string("++") {
    Some(Activate)
  } else if self.try_string("--") {
    Some(Deactivate)
  } else if self.try_string("!!") {
    Some(Destroy)
  } else if self.try_string("**") {
    Some(Create)
  } else {
    None
  }
}

///|
fn Source::try_url_link(self : Source) -> String? {
  let checkpoint = self.save()
  guard self.try_string("[[") else { return None }
  self.skip_whitespace()
  let link = if self.consume('"') {
    let quoted = self.take_while(c => c != '"')
    guard self.consume('"') else {
      self.restore(checkpoint)
      return None
    }
    quoted
  } else {
    self.take_while(c => !is_inline_whitespace(c) && c != '{' && c != ']')
  }
  guard link.length() > 0 else {
    self.restore(checkpoint)
    return None
  }
  let _ = self.take_while(c => c != ']')
  guard self.try_string("]]") else {
    self.restore(checkpoint)
    return None
  }
  Some(@core.normalize_url_target(link))
}

///|
fn Source::take_message_tail(
  self : Source,
) -> (ActivationSpec?, String?, String?) {
  self.skip_whitespace()
  let activation = self.take_activation_spec()
  self.skip_whitespace()
  let color = self.try_color()
  self.skip_whitespace()
  let label = if self.consume(':') {
    @core.normalize_label(self.collect_line())
  } else {
    None
  }
  (activation, color, label)
}

///|
fn ArrowConfig::from_dressing(
  left : DressingResult,
  right : DressingResult,
  body : ArrowBody,
  reverse : Bool,
) -> ArrowConfig {
  let (start, end) = if reverse { (right, left) } else { (left, right) }
  let head1 = if start.cross { CrossX } else { start.head }
  let head2 = if end.cross { CrossX } else { end.head }
  let part = match (start.part, end.part) {
    (TopPart, _) | (_, TopPart) => TopPart
    (BottomPart, _) | (_, BottomPart) => BottomPart
    (Full, Full) => Full
  }
  {
    body,
    head1,
    head2,
    part,
    circle_start: start.circle,
    circle_end: end.circle,
  }
}

///|
fn message_direction(left : DressingResult, right : DressingResult) -> Bool? {
  if right.has_dir || left.cross || right.cross {
    Some(false)
  } else if left.has_dir {
    Some(true)
  } else {
    None
  }
}

///|
fn Source::take_multicast(self : Source) -> Array[String]? {
  let targets = []
  while self.consume('&') {
    self.skip_whitespace()
    let target = self.take_while(is_ident_char)
    guard target.length() > 0 else { return None }
    targets.push(target)
    self.skip_whitespace()
  }
  Some(targets)
}

///|
fn arrow(src : Source) -> Event? {
  let checkpoint = src.save()
  let parallel = src.consume('&')
  if parallel {
    src.skip_whitespace()
  }
  let anchor = src.try_anchor()
  if anchor is Some(_) {
    src.skip_whitespace()
  }
  guard src.try_participant_ref() is Some(first) else {
    src.restore(checkpoint)
    return None
  }
  src.skip_whitespace()
  let _ = src.try_anchor()
  src.skip_whitespace()
  guard src.peek().map_or(false, is_arrow_char) else {
    src.restore(checkpoint)
    return None
  }
  guard src.try_arrow_dressing() is Some((left, body, right)) else {
    src.restore(checkpoint)
    return None
  }
  src.skip_whitespace()
  guard src.try_participant_ref() is Some(second) else {
    src.restore(checkpoint)
    return None
  }
  src.skip_whitespace()
  guard src.take_multicast() is Some(multicast) else {
    src.restore(checkpoint)
    return None
  }
  let _ = src.try_anchor()
  guard message_direction(left, right) is Some(reverse) else {
    src.restore(checkpoint)
    return None
  }
  let (from, to) = if reverse {
    (second.code, first.code)
  } else {
    (first.code, second.code)
  }
  let (activation_spec, life_color, label) = src.take_message_tail()
  Some(
    Message({
      from_code: from,
      to_code: to,
      label,
      arrow_config: ArrowConfig::from_dressing(left, right, body, reverse),
      parallel,
      anchor,
      multicast,
      activation_spec,
      life_color,
    }),
  )
}

///|
fn from_left_exo_type(
  left : DressingResult,
  right : DressingResult,
) -> MessageExoType? {
  if right.has_dir {
    Some(FromLeft)
  } else if left.has_dir {
    Some(ToLeft)
  } else {
    None
  }
}

///|
fn to_right_exo_type(
  left : DressingResult,
  right : DressingResult,
) -> MessageExoType? {
  if right.has_dir {
    Some(ToRight)
  } else if left.has_dir {
    Some(FromRight)
  } else {
    None
  }
}

///|
fn try_exo_arrow(src : Source) -> Event? {
  let checkpoint = src.save()
  let _ = src.consume('&')
  src.skip_whitespace()
  if src.consume('[') {
    let short_arrow = src.consume('?')
    guard src.try_arrow_dressing() is Some((left, body, right)) else {
      src.restore(checkpoint)
      return None
    }
    src.skip_whitespace()
    guard src.try_participant_ref() is Some(participant) else {
      src.restore(checkpoint)
      return None
    }
    guard from_left_exo_type(left, right) is Some(exo_type) else {
      src.restore(checkpoint)
      return None
    }
    let (activation_spec, life_color, label) = src.take_message_tail()
    return Some(
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
        short_arrow,
        activation_spec,
        life_color,
      }),
    )
  }
  guard src.try_participant_ref() is Some(participant) else {
    src.restore(checkpoint)
    return None
  }
  src.skip_whitespace()
  guard src.try_arrow_dressing() is Some((left, body, right)) else {
    src.restore(checkpoint)
    return None
  }
  let short_arrow = src.consume('?')
  guard src.consume(']') else {
    src.restore(checkpoint)
    return None
  }
  guard to_right_exo_type(left, right) is Some(exo_type) else {
    src.restore(checkpoint)
    return None
  }
  let (activation_spec, life_color, label) = src.take_message_tail()
  Some(
    MessageExo({
      participant_code: participant.code,
      exo_type,
      label,
      arrow_config: ArrowConfig::from_dressing(left, right, body, left.has_dir),
      short_arrow,
      activation_spec,
      life_color,
    }),
  )
}
