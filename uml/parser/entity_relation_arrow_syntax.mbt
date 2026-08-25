///|
priv struct RelationStroke {
  first_length : Int
  has_direction : Bool
  text : String
}

///|
priv struct RelationArrowCandidate {
  first_length : Int
  has_direction : Bool
  has_left_decor : Bool
  has_right_decor : Bool
  text : String
}

///|
fn take_relation_decor(
  cursor : @parse.Cursor,
  decorations : Array[(String, @entity.RelationEnd)],
) -> String? {
  for entry in decorations {
    if cursor.consume_literal(entry.0) {
      return Some(entry.0)
    }
  }
  None
}

///|
fn take_style(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('[') else { return None }
  let value = cursor.take_while(char => char != ']')
  guard cursor.consume(']') else {
    ignore(cursor.restore(start))
    return None
  }
  Some(value)
}

///|
fn take_direction(cursor : @parse.Cursor) -> String? {
  let symbols = [
    "right", "down", "left", "up", "ri", "do", "le", "r", "d", "l", "u",
  ]
  for symbol in symbols {
    if cursor.consume_literal(symbol) {
      return Some(symbol)
    }
  }
  None
}

///|
fn relation_stroke(cursor : @parse.Cursor) -> RelationStroke? {
  let first = cursor.take_while(char => "-=.".contains_char(char))
  guard first.length() > 0 else { return None }
  let first_style = take_style(cursor)
  let direction = take_direction(cursor)
  let second_style = take_style(cursor)
  let second = cursor.take_while(char => "-=.".contains_char(char))
  let text = first +
    first_style.map_or("", value => "[" + value + "]") +
    direction.unwrap_or("") +
    second_style.map_or("", value => "[" + value + "]") +
    second
  Some({
    first_length: first.length(),
    has_direction: direction is Some(_),
    text,
  })
}

///|
fn take_inside(cursor : @parse.Cursor) -> String? {
  let symbols = ["(0)", "(0", "0)", "0"]
  for symbol in symbols {
    let sym_start = cursor.offset()
    if cursor.consume_literal(symbol) {
      let stroke = cursor.take_while(char => "-=.".contains_char(char))
      if stroke.length() > 0 {
        return Some(symbol + stroke)
      }
      ignore(cursor.restore(sym_start))
    }
  }
  None
}

///|
fn relation_arrow_candidate(cursor : @parse.Cursor) -> RelationArrowCandidate? {
  let start = cursor.offset()
  let left = take_relation_decor(cursor, left_relation_decorations)
  guard relation_stroke(cursor) is Some(stroke) else {
    ignore(cursor.restore(start))
    return None
  }
  let inside = take_inside(cursor)
  let right = take_relation_decor(cursor, right_relation_decorations)
  Some({
    first_length: stroke.first_length,
    has_direction: stroke.has_direction,
    has_left_decor: left is Some(_),
    has_right_decor: right is Some(_),
    text: left.unwrap_or("") +
    stroke.text +
    inside.unwrap_or("") +
    right.unwrap_or(""),
  })
}

///|
fn relation_non_single_arrow(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard relation_arrow_candidate(cursor) is Some(candidate) else { return None }
  if candidate.first_length >= 2 ||
    candidate.has_direction ||
    candidate.has_left_decor ||
    candidate.has_right_decor {
    Some(candidate.text)
  } else {
    ignore(cursor.restore(start))
    None
  }
}
