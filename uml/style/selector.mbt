///|
#derive(Eq, Debug)
pub(all) enum SelectorTerm {
  Name(String)
  Stereotype(String)
  Depth(Int)
}

///|
pub extend SelectorTerm with Eq::{not_equal, equal}

///|
pub extend SelectorTerm with Debug::{to_repr}

///|
pub fn parse_selector_term(source : String) -> SelectorTerm {
  let word = source.to_lower()
  if word.has_prefix(".") {
    Stereotype(word[1:].to_owned())
  } else if word.has_prefix("depth(") && word.has_suffix(")") {
    Depth(@string.parse_int(word[6:word.length() - 1]) catch { _ => -1 })
  } else {
    Name(word)
  }
}
