///|
suberror ParseError {
  UnexpectedEof(Int)
  UnexpectedChar(Int, Char, Char)
  ExpectedString(Int, String)
  NoMatchingCommand(String)
  ExpectedIdentifier(Int)
  UnclosedString(Int)
}
