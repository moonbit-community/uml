///|
priv enum SequenceTextSyntax {
  Inline(String)
  Multiline
}

///|
priv struct NoteLineSyntax {
  participant_codes : Array[String]
  position : @seq.NotePosition
  note_style : @seq.NoteStyle
  on_arrow : Bool
  color : String?
  text : SequenceTextSyntax
  stereotype : String?
  url : String?
  merge : Bool
  misspelled_across : Bool
}

///|
priv struct ReferenceLineSyntax {
  participant_codes : Array[String]
  text : SequenceTextSyntax
}

///|
fn parsed_note_position(
  position : @seq.NotePosition,
  participants : Array[String],
) -> @seq.NotePosition {
  if position is @seq.Over && participants.length() > 1 {
    @seq.OverSeveral
  } else {
    position
  }
}

///|
/// Matches a note style keyword.
fn note_style(cursor : @parse.Cursor) -> @seq.NoteStyle? {
  let start = cursor.offset()
  let word = take_ident(cursor)
  let result = match word.to_lower() {
    "note" => Some(@seq.NodeNormal)
    "hnote" => Some(@seq.Hexagonal)
    "rnote" => Some(@seq.Box)
    _ => None
  }
  guard result is Some(_) else {
    ignore(cursor.restore(start))
    return None
  }
  result
}

///|
/// Matches a note position keyword, returning the position and the matched
/// word. `accross` is accepted and reported like Java's regex, then rejected
/// at execution time with an explicit error.
fn note_position(cursor : @parse.Cursor) -> (@seq.NotePosition, String)? {
  let start = cursor.offset()
  let word = take_ident(cursor)
  let result = match word.to_lower() {
    "left" => Some((@seq.Left, word))
    "right" => Some((@seq.Right, word))
    "bottom" => Some((@seq.Bottom, word))
    "top" => Some((@seq.Top, word))
    "over" => Some((@seq.Over, word))
    "across" => Some((@seq.Across, word))
    "accross" => Some((@seq.Across, word))
    _ => None
  }
  guard result is Some(_) else {
    ignore(cursor.restore(start))
    return None
  }
  result
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
/// Matches a `<<...>>` stereotype token, mirroring Java's non-greedy
/// `<<.+?>>` under regex backtracking: the shortest token whose
/// continuation satisfies `continues` wins; otherwise the scan extends to
/// the next `>>` and retries. Consumes the trailing spaces when the token
/// is committed, and restores the original position when it is absent.
fn take_stereotype_with_continuation(
  cursor : @parse.Cursor,
  continues : (@parse.Cursor) -> Bool,
) -> String? {
  let start = cursor.offset()
  guard cursor.consume_literal("<<") else { return None }
  while !cursor.is_eof() {
    if cursor.starts_with_literal(">>") {
      ignore(cursor.consume_literal(">>"))
      let end = cursor.offset()
      let saved = cursor.offset()
      cursor.skip_inline_spaces()
      if end - start > 4 && continues(cursor) {
        return Some(cursor.slice(start, end))
      }
      ignore(cursor.restore(saved))
    }
    ignore(cursor.advance())
  }
  ignore(cursor.restore(start))
  None
}

///|
/// Matches an optional `<<...>>` stereotype token with the surrounding
/// spaces, mirroring Java's `StereotypePattern.optional`. The leading
/// spaces are consumed even when the token is absent, because Java's
/// `spaceZeroOrMore` hands them to the following tokens (color, URL, `:`);
/// the trailing spaces belong to the token itself.
fn take_optional_stereotype(
  cursor : @parse.Cursor,
  continues : (@parse.Cursor) -> Bool,
) -> String? {
  cursor.skip_inline_spaces()
  guard take_stereotype_with_continuation(cursor, continues) is Some(value) else {
    return None
  }
  cursor.skip_inline_spaces()
  Some(value)
}

///|
/// Matches an optional `[[...]]` URL token preceded by spaces, restoring
/// the spaces when the token is absent.
fn take_optional_url(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  cursor.skip_inline_spaces()
  guard cursor.take_url_value() is Some(value) else {
    ignore(cursor.restore(start))
    return None
  }
  Some(value)
}

///|
/// Matches the note tail after the position word or participant list:
/// optional stereotype, optional `#color`, optional `[[url]]`, then the
/// text, mirroring the `STEREO2 color()? spaceZeroOrMore UrlBuilder.OPTIONAL
/// spaceZeroOrMore (: spaceZeroOrMore NOTE)?` tail shared by the note
/// factories. `stereo1` wins over STEREO2, like Java's `getLazzy` lookup.
fn note_tail(
  cursor : @parse.Cursor,
  stereo1 : String?,
) -> (String?, String?, String?, SequenceTextSyntax) {
  let stereo2 = take_optional_stereotype(cursor, across_tail_continues)
  let stereotype = stereo1.map_or(stereo2, value => Some(value))
  let color = take_note_color_value(cursor)
  cursor.skip_inline_spaces()
  let url = take_optional_url(cursor)
  cursor.skip_inline_spaces()
  let text = sequence_text(cursor)
  (stereotype, color, url, text)
}

///|
fn note_on_arrow_tail(
  cursor : @parse.Cursor,
  position : @seq.NotePosition,
  note_style : @seq.NoteStyle,
  stereotype : String?,
) -> NoteLineSyntax? {
  let (stereotype, color, url, text) = note_tail(cursor, stereotype)
  Some({
    participant_codes: [],
    position,
    note_style,
    on_arrow: true,
    color,
    text,
    stereotype,
    url,
    merge: false,
    misspelled_across: false,
  })
}

///|
fn participant_note_tail(
  cursor : @parse.Cursor,
  position : @seq.NotePosition,
  note_style : @seq.NoteStyle,
  require_of : Bool,
  stereotype : String?,
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
        @seq.Left | @seq.Right => participant_codes.length() == 1
        @seq.Over =>
          participant_codes.length() >= 1 && participant_codes.length() <= 2
        _ => false
      }
      guard valid else {
        ignore(cursor.restore(start))
        return None
      }
      let (stereotype, color, url, text) = note_tail(cursor, stereotype)
      Some({
        participant_codes,
        position: parsed_note_position(position, participant_codes),
        note_style,
        on_arrow: false,
        color,
        text,
        stereotype,
        url,
        merge: false,
        misspelled_across: false,
      })
    }
  }
}

///|
/// Matches a `#`-prefixed note color, taking Java's
/// `#\w+[-\\|/]?\w+` run (`ColorParser.COLOR_REGEXP`): word characters,
/// then one optional `-`/`\`/`|`/`/` separator and more word characters.
/// A lone separator keeps only the first word, leaving the separator for
/// the caller, like the regex engine backtracking out of the separator
/// group. Restores the original position when no word follows the marker.
fn take_note_color_value(cursor : @parse.Cursor) -> String? {
  let start = cursor.offset()
  guard cursor.consume('#') else { return None }
  let first = cursor.take_while(sequence_is_word_char)
  guard first.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  let separator = cursor.offset()
  match cursor.peek() {
    Some(char) if char == '-' || char == '\\' || char == '|' || char == '/' => {
      ignore(cursor.advance())
      let second = cursor.take_while(sequence_is_word_char)
      if second.length() > 0 {
        Some(first + char.to_string() + second)
      } else {
        ignore(cursor.restore(separator))
        Some(first)
      }
    }
    _ => Some(first)
  }
}

///|
/// The tail-continuation check shared by the message and across tails: the
/// input after a candidate `>>` must be an optional `[[url]]` followed by
/// `: label` or eof, mirroring `UrlBuilder.OPTIONAL spaceZeroOrMore
/// MESSAGE? end()`. A URL that is itself followed by another token belongs
/// to the stereotype, so the token keeps extending (Java backtracks `.+?`
/// past it). Never moves the cursor.
fn url_then_colon_or_eof(cursor : @parse.Cursor) -> Bool {
  let saved = cursor.offset()
  cursor.skip_inline_spaces()
  let result = match cursor.peek() {
    Some(':') | None => true
    Some('[') =>
      cursor.take_url_value() is Some(_) &&
      ({
        cursor.skip_inline_spaces()
        cursor.peek() == Some(':') || cursor.is_eof()
      })
    _ => false
  }
  ignore(cursor.restore(saved))
  result
}

///|
/// The across-tail continuation: `#color?` then the URL/colon/eof
/// remainder, mirroring Java's `color()? spaceZeroOrMore UrlBuilder.OPTIONAL
/// spaceZeroOrMore (: ...)?`. Never moves the cursor.
fn across_tail_continues(cursor : @parse.Cursor) -> Bool {
  let saved = cursor.offset()
  cursor.skip_inline_spaces()
  let result = match cursor.peek() {
    Some('#') =>
      take_note_color_value(cursor) is Some(_) && url_then_colon_or_eof(cursor)
    _ => url_then_colon_or_eof(cursor)
  }
  ignore(cursor.restore(saved))
  result
}

///|
/// Matches the across tail: optional stereotype, optional color, optional
/// URL, then the text, mirroring Java's across factory tail. Each token
/// consumes its own spaces.
fn across_note_tail(
  cursor : @parse.Cursor,
  note_style : @seq.NoteStyle,
  stereotype : String?,
  misspelled_across : Bool,
) -> NoteLineSyntax? {
  let (stereotype, color, url, text) = note_tail(cursor, stereotype)
  Some({
    participant_codes: [],
    position: @seq.Across,
    note_style,
    on_arrow: false,
    color,
    text,
    stereotype,
    url,
    merge: false,
    misspelled_across,
  })
}

///|
fn note_line_syntax(cursor : @parse.Cursor) -> NoteLineSyntax? {
  let start = cursor.offset()
  let parallel = cursor.consume('&')
  let merge = cursor.consume('/')
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
      let stereotype = take_optional_stereotype(cursor, cursor => {
        cursor.peek() is Some(char) && is_ident_char(char)
      })
      match note_position(cursor) {
        None => {
          ignore(cursor.restore(start))
          None
        }
        Some((position, word)) => {
          let misspelled_across = position is @seq.Across &&
            word.to_lower() == "accross"
          let syntax = match position {
            @seq.Top | @seq.Bottom => {
              guard !parallel else {
                ignore(cursor.restore(start))
                return None
              }
              cursor.skip_inline_spaces()
              note_on_arrow_tail(cursor, position, note_style, stereotype)
            }
            @seq.Left | @seq.Right => {
              cursor.skip_inline_spaces()
              let saved = cursor.offset()
              match
                participant_note_tail(
                  cursor, position, note_style, true, stereotype,
                ) {
                Some(value) => Some(value)
                None => {
                  // The `&` prefix is only accepted by the participant note
                  // factories; the on-arrow fallback rejects it.
                  guard !parallel else {
                    ignore(cursor.restore(start))
                    return None
                  }
                  ignore(cursor.restore(saved))
                  note_on_arrow_tail(cursor, position, note_style, stereotype)
                }
              }
            }
            @seq.Over => {
              cursor.skip_inline_spaces()
              participant_note_tail(
                cursor, position, note_style, false, stereotype,
              )
            }
            @seq.Across => {
              guard !parallel else {
                ignore(cursor.restore(start))
                return None
              }
              across_note_tail(
                cursor, note_style, stereotype, misspelled_across,
              )
            }
            @seq.OverSeveral => None
          }
          match syntax {
            Some(value) => {
              guard cursor.is_eof() else {
                ignore(cursor.restore(start))
                return None
              }
              Some({ ..value, merge, })
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
      Some({ participant_codes, text, })
    }
  }
}
