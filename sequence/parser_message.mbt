///|
fn Source::try_participant_ref(self : Source) -> PartRef? {
  self.try_parsec(participant_ref_parser())
}

///|
fn Source::try_participant_decl_ref(self : Source) -> PartRef? {
  self.try_parsec(participant_decl_ref_parser())
}

///|
fn Source::try_participant_code(self : Source) -> String? {
  self.try_parsec(participant_code_parser())
}

///|
fn Source::try_arrow_dressing(
  self : Source,
) -> (DressingResult, ArrowBody, DressingResult)? {
  self.try_parsec(arrow_dressing_parser())
}

///|
fn Source::take_activation_spec(self : Source) -> ActivationSpec? {
  self.try_parsec(activation_spec_parser())
}

///|
fn Source::try_url_link(self : Source) -> String? {
  self.try_url_target().map(target => target.target)
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
  match self.try_parsec(multicast_parser()) {
    Some(targets) => Some(targets)
    None => Some([])
  }
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
