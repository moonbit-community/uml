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

///|
/// Collect every whitespace-separated item the parser accepts at the cursor.
/// The repeated "skip a space, parse, or restore and stop" loop shared by the
/// suffix, modifier, and metadata grammars.
fn[T] collect_repeated(
  cursor : @parse.Cursor,
  parse : (@parse.Cursor) -> T?,
) -> Array[T] {
  let items : Array[T] = []
  while true {
    let item_start = cursor.offset()
    guard cursor.skip_inline_space1() && parse(cursor) is Some(item) else {
      ignore(cursor.restore(item_start))
      break
    }
    items.push(item)
  }
  items
}
