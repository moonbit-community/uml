///|
/// Whether `char` is a Unicode letter (`\p{L}`), resolved from the Unicode
/// character database in `moonbit-community/unicode`. ASCII is answered from
/// a pair of range checks, which keeps identifier-heavy parsing cheap.
pub fn is_unicode_letter(char : Char) -> Bool {
  if char.is_ascii() {
    (char >= 'A' && char <= 'Z') || (char >= 'a' && char <= 'z')
  } else {
    @unicode.general_category(char).group() == @unicode.GeneralCategoryGroup::L
  }
}

///|
/// Whether `char` is allowed in an identifier: a Unicode letter, digit, or
/// underscore.
pub fn is_identifier_char(char : Char) -> Bool {
  if char.is_ascii() {
    (char >= 'A' && char <= 'Z') ||
    (char >= 'a' && char <= 'z') ||
    (char >= '0' && char <= '9') ||
    char == '_'
  } else {
    is_unicode_letter(char) || char.is_numeric()
  }
}
