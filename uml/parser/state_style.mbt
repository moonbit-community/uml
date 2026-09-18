///|
/// FromSkinparamToStyle maps both stateFont* and stateAttributeFont* to the
/// same state style. Preserve the source property and update the shared key
/// in source order, including stereotype suffixes and mixed-case spellings.
fn Parser::apply_state_font_alias(
  self : Parser,
  directive : @style.StyleDirective,
) -> Unit {
  guard directive is Property(key, value) else { return }
  let lower = key.to_lower()
  let prefix = if lower.has_prefix("stateattributefont") {
    "stateattribute"
  } else if lower.has_prefix("statefont") {
    "state"
  } else {
    return
  }
  let suffix = key[prefix.length():].to_owned()
  for property in ["FontName", "FontSize", "FontColor", "FontStyle"] {
    let lower_property = property.to_lower()
    let lower_suffix = suffix.to_lower()
    guard lower_suffix == lower_property ||
      lower_suffix.has_prefix(lower_property + "<<") else {
      continue
    }
    let stereotype = suffix[property.length():].to_owned()
    self.style.apply(Property("State" + property + stereotype, value))
    return
  }
}

///|
/// CommandSkinParamMultilines accepts an optional group before the brace.
fn state_skinparam_prefix(line : String) -> String? {
  guard line.to_lower().has_prefix("skinparam") && line.has_suffix("{") else {
    return None
  }
  let suffix = line["skinparam".length():line.length() - 1].to_owned()
  let cursor = @tokenizer.Cursor::new(suffix)
  guard suffix.is_empty() ||
    cursor.peek().map_or(false, char => char.is_whitespace()) else {
    return None
  }
  Some(suffix.trim().to_owned())
}

///|
/// SkinParam.cleanForKey moves stereotypes to the end and treats property
/// names case-insensitively. Apply each normalized key in source order.
/// Previously verified: flat/nested skinparams, font aliases and defaults
/// follow source order while stereotype-specific properties retain priority.
fn Parser::apply_state_style(
  self : Parser,
  directive : @style.StyleDirective,
) -> Unit {
  guard directive is Property(key, value) else {
    self.style.apply(directive)
    match directive {
      FontSize(value) => self.apply_state_font_default("FontSize", value)
      FontFamily(value) => self.apply_state_font_default("FontName", value)
      _ => ()
    }
    return
  }
  let cursor = @tokenizer.Cursor::new(key.to_lower())
  let base = StringBuilder()
  let stereotypes : Array[String] = []
  while !cursor.is_eof() {
    if cursor.consume_literal("<<") {
      let stereotype = cursor.take_while(char => char != '>')
      if cursor.consume_literal(">>") {
        stereotypes.push("<<" + stereotype + ">>")
      }
    } else if cursor.advance() is Some(char) && char != '_' && char != '.' {
      base.write_char(char)
    }
  }
  let suffixes = if stereotypes.is_empty() { [""] } else { stereotypes }
  for suffix in suffixes {
    let directive = @style.Property(base.to_string() + suffix, value)
    self.style.apply(directive)
    self.apply_state_font_alias(directive)
    // Root shadow changes carry source priority into the note style too.
    if base.to_string() == "shadowing" {
      for prefix in ["Note", "Frame", "Package"] {
        self.style.apply(Property(prefix + "Shadowing" + suffix, value))
      }
    }
    // Style-based note text follows source priority. Keep the original
    // noteTextAlignment too: Rose reads it independently for note margins.
    if base.to_string() == "defaulttextalignment" ||
      base.to_string() == "notetextalignment" {
      self.style.apply(Property("statenotestylealignment" + suffix, value))
    }
    for property in ["FontName", "FontSize", "FontColor"] {
      if base.to_string() == "default" + property.to_lower() {
        self.apply_state_font_default(property, value, stereotype=suffix)
      }
    }
  }
}

///|
/// Default font styles match every element. Java's style values carry source
/// priority, so a later default replaces earlier role values at the same
/// stereotype level. Materialize that result while the order is available.
fn Parser::apply_state_font_default(
  self : Parser,
  property : String,
  value : String,
  stereotype? : String = "",
) -> Unit {
  for
    prefix in [
      "State", "Arrow", "Note", "ActivityDiamond", "Frame", "Package", "StateStereotype",
      "PackageStereotype",
    ] {
    let directive = @style.Property(
      (prefix + property + stereotype).to_lower(),
      value,
    )
    self.style.apply(directive)
    self.apply_state_font_alias(directive)
  }
  // DefaultFontSize maps to element; DefaultFontName/Color map to root and
  // therefore also participate in document text styles, in source order.
  if property != "FontSize" {
    for prefix in ["Title", "Caption", "Header", "Footer", "Legend"] {
      self.style.apply(
        @style.Property((prefix + property + stereotype).to_lower(), value),
      )
    }
  }
}
