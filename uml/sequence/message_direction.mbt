///|
fn ArrowConfig::from_dressing(
  left : DressingResult,
  right : DressingResult,
  body : ArrowBody,
  direction : MessageDirection,
) -> ArrowConfig {
  let (start, end) = match direction {
    Reverse => (right, left)
    Forward => (left, right)
  }
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
priv enum MessageDirection {
  Forward
  Reverse
}

///|
fn message_direction(
  left : DressingResult,
  right : DressingResult,
) -> MessageDirection? {
  if right.has_dir {
    Some(Forward)
  } else if left.has_dir {
    Some(Reverse)
  } else if left.cross || right.cross {
    Some(Forward)
  } else {
    None
  }
}

///|
/// Derives the exo message type for the left-border commands, mirroring
/// `CommandExoArrowLeft.getMessageExoType`: a leading `]` selects the
/// right border, otherwise the border is the left one.
fn exo_left_type(
  symbol : Char,
  left : DressingResult,
  right : DressingResult,
) -> MessageExoType? {
  if symbol == ']' {
    if right.has_dir {
      Some(FromRight)
    } else if left.has_dir {
      Some(ToRight)
    } else {
      None
    }
  } else if right.has_dir {
    Some(FromLeft)
  } else if left.has_dir {
    Some(ToLeft)
  } else {
    None
  }
}

///|
/// Derives the exo message type for the right-border commands, mirroring
/// `CommandExoArrowRight.getMessageExoType`: a leading `[` selects the
/// left border, otherwise the border is the right one.
fn exo_right_type(
  symbol : Char,
  left : DressingResult,
  right : DressingResult,
) -> MessageExoType? {
  if symbol == '[' {
    if right.has_dir {
      Some(ToLeft)
    } else if left.has_dir {
      Some(FromLeft)
    } else {
      None
    }
  } else if right.has_dir {
    Some(ToRight)
  } else if left.has_dir {
    Some(FromRight)
  } else {
    None
  }
}
