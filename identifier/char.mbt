///|
/// Whether `char` is a Unicode letter. Covers the major letter blocks as an
/// approximation of `\p{L}`.
pub fn is_unicode_letter(char : Char) -> Bool {
  char.is_latin() ||
  char.is_greek() ||
  char.is_cyrillic() ||
  char.is_armenian() ||
  char.is_hebrew() ||
  char.is_arabic() ||
  char.is_semitic() ||
  char.is_indic() ||
  char.is_southeast_asian() ||
  char.is_georgian() ||
  char.is_hangul() ||
  char.is_ethiopic() ||
  char.is_native_american() ||
  char.is_philippine() ||
  char.is_khmer_mongolian() ||
  char.is_japanese() ||
  char.is_bopomofo() ||
  char.is_cjk() ||
  char.is_yi_vai_bamum() ||
  char.is_extended_indic() ||
  char.is_slavonic() ||
  char.is_tifinagh() ||
  char.is_presentation_forms()
}

///|
fn Char::is_latin(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x41 && code <= 0x5A) || // A-Z
  (code >= 0x61 && code <= 0x7A) || // a-z
  (code >= 0xAA && code <= 0xAA) ||
  (code >= 0xB5 && code <= 0xB5) ||
  (code >= 0xBA && code <= 0xBA) ||
  (code >= 0xC0 && code <= 0xD6) || // Latin-1 letters
  (code >= 0xD8 && code <= 0xF6) ||
  (code >= 0xF8 && code <= 0x2C1) || // Latin Extended, IPA, Spacing Modifiers
  (code >= 0x2E0 && code <= 0x2E4) ||
  (code >= 0x1E00 && code <= 0x1EFF) || // Latin Extended Additional
  (code >= 0x2090 && code <= 0x209C) || // Superscripts
  (code >= 0x2102 && code <= 0x2102) || // Letterlike Symbols
  (code >= 0x2107 && code <= 0x2107) ||
  (code >= 0x210A && code <= 0x2113) ||
  (code >= 0x2115 && code <= 0x2115) ||
  (code >= 0x2119 && code <= 0x211D) ||
  (code >= 0x2124 && code <= 0x2124) ||
  (code >= 0x2126 && code <= 0x2126) ||
  (code >= 0x2128 && code <= 0x2128) ||
  (code >= 0x212A && code <= 0x212D) ||
  (code >= 0x212F && code <= 0x2139) ||
  (code >= 0x213C && code <= 0x213F) ||
  (code >= 0x2145 && code <= 0x2149) ||
  (code >= 0x2160 && code <= 0x2182) || // Number Forms
  (code >= 0x2C60 && code <= 0x2C7C) || // Latin Extended-C
  (code >= 0xA7A0 && code <= 0xA7A9) || // Latin Extended-D
  (code >= 0xA7AA && code <= 0xA7AD) ||
  (code >= 0xA7B0 && code <= 0xA7B1) ||
  (code >= 0xFF21 && code <= 0xFF3A) || // Fullwidth Latin
  (code >= 0xFF41 && code <= 0xFF5A)
}

///|
fn Char::is_greek(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x370 && code <= 0x3FF) || // Greek
  (code >= 0x1F00 && code <= 0x1F15) || // Greek Extended
  (code >= 0x1F18 && code <= 0x1F1D) ||
  (code >= 0x1F20 && code <= 0x1F45) ||
  (code >= 0x1F48 && code <= 0x1F4D) ||
  (code >= 0x1F50 && code <= 0x1F57) ||
  (code >= 0x1F59 && code <= 0x1F59) ||
  (code >= 0x1F5B && code <= 0x1F5B) ||
  (code >= 0x1F5D && code <= 0x1F5D) ||
  (code >= 0x1F5F && code <= 0x1F7D) ||
  (code >= 0x1F80 && code <= 0x1FB4) ||
  (code >= 0x1FB6 && code <= 0x1FBC) ||
  (code >= 0x1FBE && code <= 0x1FBE) ||
  (code >= 0x1FC2 && code <= 0x1FC4) ||
  (code >= 0x1FC6 && code <= 0x1FCC) ||
  (code >= 0x1FD0 && code <= 0x1FD3) ||
  (code >= 0x1FD6 && code <= 0x1FDB) ||
  (code >= 0x1FE0 && code <= 0x1FEC) ||
  (code >= 0x1FF2 && code <= 0x1FF4) ||
  (code >= 0x1FF6 && code <= 0x1FFC)
}

///|
fn Char::is_cyrillic(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x400 && code <= 0x4FF) || // Cyrillic
  (code >= 0xA640 && code <= 0xA66D) || // Cyrillic Extended-B
  (code >= 0xA67F && code <= 0xA69D)
}

///|
fn Char::is_armenian(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x531 && code <= 0x556) || // Armenian
  (code >= 0x561 && code <= 0x587)
}

///|
fn Char::is_hebrew(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x5B0 && code <= 0x5F2) || // Hebrew
  (code >= 0xFB1D && code <= 0xFB36) || // Hebrew Presentation Forms
  (code >= 0xFB38 && code <= 0xFB3C) ||
  (code >= 0xFB3E && code <= 0xFB3E) ||
  (code >= 0xFB40 && code <= 0xFB41) ||
  (code >= 0xFB43 && code <= 0xFB44) ||
  (code >= 0xFB46 && code <= 0xFBB1)
}

///|
fn Char::is_arabic(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x620 && code <= 0x64A) || // Arabic
  (code >= 0x671 && code <= 0x6D3) ||
  (code >= 0x6FA && code <= 0x6FC) ||
  (code >= 0xFBD3 && code <= 0xFD3D) || // Arabic Presentation Forms
  (code >= 0xFD50 && code <= 0xFD8F) ||
  (code >= 0xFD92 && code <= 0xFDC7) ||
  (code >= 0xFDF0 && code <= 0xFDFB) ||
  (code >= 0xFE70 && code <= 0xFE74) ||
  (code >= 0xFE76 && code <= 0xFEFC)
}

///|
fn Char::is_semitic(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x710 && code <= 0x72F) || // Syriac
  (code >= 0x7CA && code <= 0x7EA) || // NKo
  (code >= 0x800 && code <= 0x815) || // Samaritan
  (code >= 0x840 && code <= 0x858) // Mandaic
}

///|
fn Char::is_indic(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x904 && code <= 0x93C) || // Devanagari
  (code >= 0x93E && code <= 0x94D) ||
  (code >= 0x950 && code <= 0x950) ||
  (code >= 0x958 && code <= 0x961) ||
  (code >= 0x985 && code <= 0x98C) || // Bengali
  (code >= 0x98F && code <= 0x990) ||
  (code >= 0x993 && code <= 0x9A8) ||
  (code >= 0x9AA && code <= 0x9B0) ||
  (code >= 0x9B2 && code <= 0x9B2) ||
  (code >= 0x9B6 && code <= 0x9B9) ||
  (code >= 0x9DC && code <= 0x9DD) ||
  (code >= 0x9DF && code <= 0x9E1) ||
  (code >= 0x9F0 && code <= 0x9F1) ||
  (code >= 0xA05 && code <= 0xA0A) || // Gurmukhi
  (code >= 0xA0F && code <= 0xA10) ||
  (code >= 0xA13 && code <= 0xA28) ||
  (code >= 0xA2A && code <= 0xA30) ||
  (code >= 0xA32 && code <= 0xA33) ||
  (code >= 0xA35 && code <= 0xA36) ||
  (code >= 0xA38 && code <= 0xA39) ||
  (code >= 0xA59 && code <= 0xA5C) ||
  (code >= 0xA5E && code <= 0xA5E) ||
  (code >= 0xA72 && code <= 0xA74) ||
  (code >= 0xA85 && code <= 0xA8D) || // Gujarati
  (code >= 0xA8F && code <= 0xA91) ||
  (code >= 0xA93 && code <= 0xAA8) ||
  (code >= 0xAAA && code <= 0xAB0) ||
  (code >= 0xAB2 && code <= 0xAB3) ||
  (code >= 0xAB5 && code <= 0xAB9) ||
  (code >= 0xABD && code <= 0xABD) ||
  (code >= 0xAE0 && code <= 0xAE1) ||
  (code >= 0xB05 && code <= 0xB0C) || // Oriya
  (code >= 0xB0F && code <= 0xB10) ||
  (code >= 0xB13 && code <= 0xB28) ||
  (code >= 0xB2A && code <= 0xB30) ||
  (code >= 0xB32 && code <= 0xB33) ||
  (code >= 0xB35 && code <= 0xB39) ||
  (code >= 0xB5C && code <= 0xB5D) ||
  (code >= 0xB5F && code <= 0xB61) ||
  (code >= 0xB85 && code <= 0xB8A) || // Tamil
  (code >= 0xB8E && code <= 0xB90) ||
  (code >= 0xB92 && code <= 0xB95) ||
  (code >= 0xB99 && code <= 0xB9A) ||
  (code >= 0xB9C && code <= 0xB9C) ||
  (code >= 0xB9E && code <= 0xB9F) ||
  (code >= 0xBA3 && code <= 0xBA4) ||
  (code >= 0xBA8 && code <= 0xBAA) ||
  (code >= 0xBAE && code <= 0xBB9) ||
  (code >= 0xC05 && code <= 0xC0C) || // Telugu
  (code >= 0xC0E && code <= 0xC10) ||
  (code >= 0xC12 && code <= 0xC28) ||
  (code >= 0xC2A && code <= 0xC39) ||
  (code >= 0xC58 && code <= 0xC5A) ||
  (code >= 0xC60 && code <= 0xC61) ||
  (code >= 0xC85 && code <= 0xC8C) || // Kannada
  (code >= 0xC8E && code <= 0xC90) ||
  (code >= 0xC92 && code <= 0xCA8) ||
  (code >= 0xCAA && code <= 0xCB3) ||
  (code >= 0xCB5 && code <= 0xCB9) ||
  (code >= 0xCE0 && code <= 0xCE1) ||
  (code >= 0xD05 && code <= 0xD0C) || // Malayalam
  (code >= 0xD0E && code <= 0xD10) ||
  (code >= 0xD12 && code <= 0xD3A) ||
  (code >= 0xD60 && code <= 0xD61) ||
  (code >= 0xD7A && code <= 0xD7F) // Sinhala
}

///|
fn Char::is_southeast_asian(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0xE01 && code <= 0xE3A) || // Thai
  (code >= 0xE40 && code <= 0xE4E) ||
  (code >= 0xE81 && code <= 0xE82) || // Lao
  (code >= 0xE84 && code <= 0xE84) ||
  (code >= 0xE87 && code <= 0xE88) ||
  (code >= 0xE8A && code <= 0xE8A) ||
  (code >= 0xE8D && code <= 0xE8D) ||
  (code >= 0xE94 && code <= 0xE97) ||
  (code >= 0xE99 && code <= 0xE9F) ||
  (code >= 0xEA1 && code <= 0xEA3) ||
  (code >= 0xEA5 && code <= 0xEA5) ||
  (code >= 0xEA7 && code <= 0xEA7) ||
  (code >= 0xEAA && code <= 0xEAB) ||
  (code >= 0xEAD && code <= 0xEB9) ||
  (code >= 0xEC0 && code <= 0xEC4) ||
  (code >= 0xF00 && code <= 0xF47) || // Tibetan
  (code >= 0xF49 && code <= 0xF6C) ||
  (code >= 0xF88 && code <= 0xF8C) ||
  (code >= 0x1000 && code <= 0x102A) // Myanmar
}

///|
fn Char::is_georgian(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x10A0 && code <= 0x10C5) || // Georgian
  (code >= 0x10D0 && code <= 0x10FA) ||
  (code >= 0x2D00 && code <= 0x2D25) // Georgian Supplement
}

///|
fn Char::is_hangul(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x1100 && code <= 0x11FF) || // Hangul Jamo
  (code >= 0x3131 && code <= 0x318E) || // Hangul Compatibility Jamo
  (code >= 0xAC00 && code <= 0xD7A3) // Hangul Syllables
}

///|
fn Char::is_ethiopic(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x1200 && code <= 0x1248) || // Ethiopic
  (code >= 0x124A && code <= 0x124D) ||
  (code >= 0x1250 && code <= 0x1256) ||
  (code >= 0x1258 && code <= 0x1258) ||
  (code >= 0x125A && code <= 0x125D) ||
  (code >= 0x1260 && code <= 0x1288) ||
  (code >= 0x128A && code <= 0x128D) ||
  (code >= 0x1290 && code <= 0x12B0) ||
  (code >= 0x12B2 && code <= 0x12B5) ||
  (code >= 0x12B8 && code <= 0x12BE) ||
  (code >= 0x12C0 && code <= 0x12C0) ||
  (code >= 0x12C2 && code <= 0x12C5) ||
  (code >= 0x12C8 && code <= 0x12D6) ||
  (code >= 0x12D8 && code <= 0x1310) ||
  (code >= 0x1312 && code <= 0x1315) ||
  (code >= 0x1318 && code <= 0x135A) ||
  (code >= 0x1380 && code <= 0x138F) ||
  (code >= 0x2D80 && code <= 0x2D96) || // Ethiopic Extended
  (code >= 0x2DA0 && code <= 0x2DA6) ||
  (code >= 0x2DA8 && code <= 0x2DAE) ||
  (code >= 0x2DB0 && code <= 0x2DB6) ||
  (code >= 0x2DB8 && code <= 0x2DBE) ||
  (code >= 0x2DC0 && code <= 0x2DC6) ||
  (code >= 0x2DC8 && code <= 0x2DCE) ||
  (code >= 0x2DD0 && code <= 0x2DD6) ||
  (code >= 0x2DD8 && code <= 0x2DDE)
}

///|
fn Char::is_native_american(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x13A0 && code <= 0x13F4) || // Cherokee
  (code >= 0x1401 && code <= 0x166C) || // Canadian Aboriginal
  (code >= 0x1681 && code <= 0x169A) || // Ogham
  (code >= 0x16A0 && code <= 0x16EA) // Runic
}

///|
fn Char::is_philippine(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x1700 && code <= 0x170C) || // Tagalog
  (code >= 0x170E && code <= 0x1711) ||
  (code >= 0x1720 && code <= 0x1731) || // Hanunoo
  (code >= 0x1740 && code <= 0x1751) || // Buhid
  (code >= 0x1760 && code <= 0x176C) || // Tagbanwa
  (code >= 0x176E && code <= 0x1770)
}

///|
fn Char::is_khmer_mongolian(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x1780 && code <= 0x17B3) || // Khmer
  (code >= 0x17D7 && code <= 0x17D7) ||
  (code >= 0x17DC && code <= 0x17DC) ||
  (code >= 0x1820 && code <= 0x1842) || // Mongolian
  (code >= 0x1844 && code <= 0x1877) ||
  (code >= 0x1880 && code <= 0x18A8)
}

///|
fn Char::is_japanese(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x3041 && code <= 0x3096) || // Hiragana
  (code >= 0x309D && code <= 0x309F) ||
  (code >= 0x30A1 && code <= 0x30FA) || // Katakana
  (code >= 0x30FC && code <= 0x30FF) ||
  (code >= 0x31F0 && code <= 0x31FF) || // Katakana Phonetic Extensions
  (code >= 0xFF66 && code <= 0xFFBE) || // Halfwidth Katakana
  (code >= 0xFFC2 && code <= 0xFFC7) ||
  (code >= 0xFFCA && code <= 0xFFCF) ||
  (code >= 0xFFD2 && code <= 0xFFD7) ||
  (code >= 0xFFDA && code <= 0xFFDC)
}

///|
fn Char::is_bopomofo(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x3105 && code <= 0x312D) || // Bopomofo
  (code >= 0x31A0 && code <= 0x31BA) // Bopomofo Extended
}

///|
fn Char::is_cjk(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x3400 && code <= 0x4DB5) || // CJK Extension A
  (code >= 0x4E00 && code <= 0x9FD5) || // CJK Unified
  (code >= 0xF900 && code <= 0xFA2D) || // CJK Compatibility
  (code >= 0xFA70 && code <= 0xFAD9)
}

///|
fn Char::is_yi_vai_bamum(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0xA000 && code <= 0xA48C) || // Yi
  (code >= 0xA500 && code <= 0xA60C) || // Vai
  (code >= 0xA610 && code <= 0xA61F) ||
  (code >= 0xA62A && code <= 0xA62B) ||
  (code >= 0xA6A0 && code <= 0xA6E5) // Bamum
}

///|
fn Char::is_extended_indic(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0xA800 && code <= 0xA819) || // Syloti Nagri
  (code >= 0xA840 && code <= 0xA873) || // Phags-pa
  (code >= 0xA882 && code <= 0xA8B3) || // Saurashtra
  (code >= 0xA8F2 && code <= 0xA8F7) || // Devanagari Extended
  (code >= 0xA90A && code <= 0xA925) || // Kayah Li
  (code >= 0xA930 && code <= 0xA946) || // Rejang
  (code >= 0xAA00 && code <= 0xAA28) || // Cham
  (code >= 0xAA40 && code <= 0xAA42) ||
  (code >= 0xAA44 && code <= 0xAA4B)
}

///|
fn Char::is_slavonic(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x2C00 && code <= 0x2C2E) || // Glagolitic
  (code >= 0x2C30 && code <= 0x2C5E) ||
  (code >= 0x2C80 && code <= 0x2CE4) // Coptic
}

///|
fn Char::is_tifinagh(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0x2D30 && code <= 0x2D65) || // Tifinagh
  (code >= 0x2D6F && code <= 0x2D6F)
}

///|
fn Char::is_presentation_forms(self : Char) -> Bool {
  let code = self.to_int()
  (code >= 0xFB00 && code <= 0xFB06) || // Alphabetic Presentation Forms
  (code >= 0xFB13 && code <= 0xFB17)
}

///|
/// Whether `char` is allowed in an identifier: a Unicode letter, digit, or underscore.
pub fn is_identifier_char(char : Char) -> Bool {
  char == '_' || is_unicode_letter(char) || char.is_numeric()
}
