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
