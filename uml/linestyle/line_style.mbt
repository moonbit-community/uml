///|
#derive(Eq, Debug)
pub(all) enum LineStyleToken {
  Dashed
  Dotted
  Plain
  Bold
  Hidden
  NoRank
  Single
  Node
  Thickness(Double?)
  Color(String)
}

///|
pub extend LineStyleToken with Eq::{not_equal, equal}

///|
pub extend LineStyleToken with Debug::{to_repr}

///|
pub fn line_style_keyword(word : String) -> LineStyleToken? {
  match word.to_lower() {
    "dashed" => Some(Dashed)
    "dotted" => Some(Dotted)
    "plain" => Some(Plain)
    "bold" => Some(Bold)
    "hidden" => Some(Hidden)
    "norank" => Some(NoRank)
    "single" => Some(Single)
    "node" => Some(Node)
    _ => None
  }
}

///|
/// Dynamic skinparam values and permissive diagram grammars retain unknown
/// tokens as colors. Thickness(None) preserves their ignored invalid numbers.
pub fn parse_line_style(source : String) -> Array[LineStyleToken] {
  source
  .split(",")
  .map(part => {
    let word = part.trim().to_owned()
    if line_style_keyword(word) is Some(token) {
      token
    } else if word.to_lower().strip_prefix("thickness=") is Some(number) {
      Thickness(Some(@string.parse_double(number)) catch { _ => None })
    } else {
      Color(word)
    }
  })
  .to_array()
}
