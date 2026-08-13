///|
fn take_inline_word(cursor : @parse.Cursor) -> String? {
  let word = cursor.take_while(char => {
    char.is_ascii_alphabetic() || char == '_' || char == '/'
  })
  if word.length() == 0 {
    None
  } else {
    Some(word)
  }
}

///|
fn consume_inline_keyword(cursor : @parse.Cursor, keyword : String) -> Bool {
  let start = cursor.offset()
  guard take_inline_word(cursor) is Some(word) else { return false }
  if word.equal_ignore_ascii_case(keyword) {
    true
  } else {
    ignore(cursor.restore(start))
    false
  }
}
