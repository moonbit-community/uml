///|
priv enum SequenceTextSyntax {
  Inline(String)
  Multiline
}

///|
priv struct NoteLineSyntax {
  participant_codes : Array[String]
  position : NotePosition
  note_style : NoteStyle
  on_arrow : Bool
  color : String?
  text : SequenceTextSyntax
}

///|
priv struct ReferenceLineSyntax {
  participant_codes : Array[String]
  text : SequenceTextSyntax
}

///|
fn parsed_note_position(
  position : NotePosition,
  participants : Array[String],
) -> NotePosition {
  if position is Over && participants.length() > 1 {
    OverSeveral
  } else {
    position
  }
}

///|
/// Matches a note style keyword.
fn note_style(cursor : @parse.Cursor) -> NoteStyle? {
  let start = cursor.offset()
  let word = take_ident(cursor)
  let result = match word.to_lower() {
    "note" => Some(NodeNormal)
    "hnote" => Some(Hexagonal)
    "rnote" => Some(Box)
    _ => None
  }
  match result {
    Some(_) => result
    None => {
      ignore(cursor.restore(start))
      None
    }
  }
}

///|
/// Matches a note position keyword.
fn note_position(cursor : @parse.Cursor) -> NotePosition? {
  let start = cursor.offset()
  let word = take_ident(cursor)
  let result = match word.to_lower() {
    "left" => Some(Left)
    "right" => Some(Right)
    "bottom" => Some(Bottom)
    "top" => Some(Top)
    "over" => Some(Over)
    "across" => Some(Across)
    _ => None
  }
  match result {
    Some(_) => result
    None => {
      ignore(cursor.restore(start))
      None
    }
  }
}

///|
/// Matches one or more participant codes separated by commas, tolerating a
/// trailing comma exactly like the talc `sep_by1` separator.
fn participant_list(cursor : @parse.Cursor) -> Array[String]? {
  let start = cursor.offset()
  cursor.skip_inline_spaces()
  match take_quoted_or_ident(cursor) {
    None => {
      ignore(cursor.restore(start))
      None
    }
    Some(first) => {
      let list = [first]
      while true {
        let saved = cursor.offset()
        cursor.skip_inline_spaces()
        if !cursor.consume(',') {
          ignore(cursor.restore(saved))
          break
        }
        cursor.skip_inline_spaces()
        match take_quoted_or_ident(cursor) {
          None => {
            ignore(cursor.restore(saved))
            break
          }
          Some(code) => list.push(code)
        }
      }
      Some(list)
    }
  }
}

///|
fn sequence_text(cursor : @parse.Cursor) -> SequenceTextSyntax {
  if cursor.consume(':') {
    Inline(cursor.take_while(_ => true).trim().to_owned())
  } else {
    Multiline
  }
}

///|
fn note_on_arrow_tail(
  cursor : @parse.Cursor,
  position : NotePosition,
  note_style : NoteStyle,
) -> NoteLineSyntax? {
  let text = sequence_text(cursor)
  Some({
    participant_codes: [],
    position,
    note_style,
    on_arrow: true,
    color: None,
    text,
  })
}

///|
fn participant_note_tail(
  cursor : @parse.Cursor,
  position : NotePosition,
  note_style : NoteStyle,
  require_of : Bool,
) -> NoteLineSyntax? {
  let start = cursor.offset()
  if require_of {
    guard take_keyword(cursor, "of") && cursor.skip_inline_space1() else {
      ignore(cursor.restore(start))
      return None
    }
  } else {
    let saved = cursor.offset()
    if take_keyword(cursor, "of") {
      if !cursor.skip_inline_space1() {
        ignore(cursor.restore(saved))
      }
    }
  }
  match participant_list(cursor) {
    None => {
      ignore(cursor.restore(start))
      None
    }
    Some(participant_codes) => {
      let valid = match position {
        Left | Right => participant_codes.length() == 1
        Over =>
          participant_codes.length() >= 1 && participant_codes.length() <= 2
        _ => false
      }
      guard valid else {
        ignore(cursor.restore(start))
        return None
      }
      let color = optional_color(cursor)
      cursor.skip_inline_spaces()
      let text = sequence_text(cursor)
      Some({
        participant_codes,
        position: parsed_note_position(position, participant_codes),
        note_style,
        on_arrow: false,
        color,
        text,
      })
    }
  }
}

///|
fn across_note_tail(
  cursor : @parse.Cursor,
  note_style : NoteStyle,
) -> NoteLineSyntax? {
  let color = optional_color(cursor)
  cursor.skip_inline_spaces()
  let text = sequence_text(cursor)
  Some({
    participant_codes: [],
    position: Across,
    note_style,
    on_arrow: false,
    color,
    text,
  })
}

///|
fn note_line_syntax(cursor : @parse.Cursor) -> NoteLineSyntax? {
  let start = cursor.offset()
  ignore(cursor.consume('&'))
  ignore(cursor.consume('/'))
  cursor.skip_inline_spaces()
  match note_style(cursor) {
    None => {
      ignore(cursor.restore(start))
      None
    }
    Some(note_style) => {
      guard cursor.skip_inline_space1() else {
        ignore(cursor.restore(start))
        return None
      }
      match note_position(cursor) {
        None => {
          ignore(cursor.restore(start))
          None
        }
        Some(position) => {
          cursor.skip_inline_spaces()
          let syntax = match position {
            Top | Bottom => note_on_arrow_tail(cursor, position, note_style)
            Left | Right => {
              let saved = cursor.offset()
              match participant_note_tail(cursor, position, note_style, true) {
                Some(value) => Some(value)
                None => {
                  ignore(cursor.restore(saved))
                  note_on_arrow_tail(cursor, position, note_style)
                }
              }
            }
            Over => participant_note_tail(cursor, position, note_style, false)
            Across => across_note_tail(cursor, note_style)
            OverSeveral => None
          }
          match syntax {
            Some(value) => {
              guard cursor.is_eof() else {
                ignore(cursor.restore(start))
                return None
              }
              Some(value)
            }
            None => {
              ignore(cursor.restore(start))
              None
            }
          }
        }
      }
    }
  }
}

///|
fn reference_line_syntax(cursor : @parse.Cursor) -> ReferenceLineSyntax? {
  let start = cursor.offset()
  guard take_keyword(cursor, "ref") else { return None }
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  guard take_keyword(cursor, "over") else {
    ignore(cursor.restore(start))
    return None
  }
  guard cursor.skip_inline_space1() else {
    ignore(cursor.restore(start))
    return None
  }
  match participant_list(cursor) {
    None => {
      ignore(cursor.restore(start))
      None
    }
    Some(participant_codes) => {
      cursor.skip_inline_spaces()
      let text = sequence_text(cursor)
      guard cursor.is_eof() else {
        ignore(cursor.restore(start))
        return None
      }
      Some({ participant_codes, text })
    }
  }
}
