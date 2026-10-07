///|
/// Consume PlantUML's nested style selectors using the same property boundary
/// as skinparam. Diagram parsers supply their own line source and diagnostics.
pub fn consume_style_body(
  next_line : () -> String?,
  apply : (StyleDirective) -> Unit,
) -> Bool {
  let selectors : Array[Array[String]] = []
  let mut pending = ""
  while next_line() is Some(raw) {
    let line = raw.trim().to_owned()
    if line.equal_ignore_ascii_case("</style>") {
      return selectors.is_empty()
    }
    guard !line.is_empty() && !line.has_prefix("'") && !line.has_prefix("//") else {
      continue
    }
    let mut segment = StringBuilder()
    let mut quoted : Char? = None
    for char in line {
      if quoted is Some(quote) {
        segment.write_char(char)
        if char == quote {
          quoted = None
        }
      } else if char == '"' || char == '\'' {
        quoted = Some(char)
        segment.write_char(char)
      } else if char == '{' {
        let selector = (pending + " " + segment.to_string()).trim().to_owned()
        selectors.push(
          selector.split(",").map(value => value.trim().to_owned()).to_array(),
        )
        pending = ""
        segment = StringBuilder()
      } else if char == '}' {
        apply_style_entry(selectors, segment.to_string(), apply)
        guard !selectors.is_empty() else { return false }
        ignore(selectors.pop())
        segment = StringBuilder()
      } else if char == ';' {
        apply_style_entry(selectors, segment.to_string(), apply)
        segment = StringBuilder()
      } else {
        segment.write_char(char)
      }
    }
    let rest = segment.to_string().trim().to_owned()
    if !rest.is_empty() {
      if rest.contains(" ") || rest.contains("\t") {
        apply_style_entry(selectors, rest, apply)
      } else {
        pending = rest
      }
    }
  }
  false
}

///|
fn apply_style_entry(
  selectors : Array[Array[String]],
  line : String,
  apply : (StyleDirective) -> Unit,
) -> Unit {
  let cursor = @tokenizer.Cursor::new(line.trim().to_owned())
  let property = cursor.take_while(char => !char.is_whitespace() && char != ':')
  ignore(cursor.consume(':'))
  let value = cursor.take_rest_trimmed()
  guard !property.is_empty() && !value.is_empty() else { return }
  let mut paths : Array[String] = [""]
  for alternatives in selectors {
    let nested : Array[String] = []
    for path in paths {
      for selector in alternatives {
        nested.push((path + " " + selector).trim().to_owned())
      }
    }
    paths = nested
  }
  for path in paths {
    // Retain the original selector for renderers with a domain-specific cascade.
    apply(Property("style " + path + " " + property, value))
    apply_style_selector(path, property, value, apply)
  }
}

///|
fn apply_style_selector(
  path : String,
  property : String,
  value : String,
  apply : (StyleDirective) -> Unit,
) -> Unit {
  let words = @tokenizer.syntax_words(path.to_lower())
  let mut prefix = ""
  let mut stereotype = false
  let mut sequence = false
  for word in words {
    match word {
      "root" | "element" | "document" => ()
      "sequencediagram" => sequence = true
      "classdiagram"
      | "objectdiagram"
      | "activitydiagram"
      | "statediagram"
      | "componentdiagram"
      | "deploymentdiagram"
      | "usecasediagram"
      | "mindmapdiagram"
      | "wbsdiagram"
      | "jsondiagram"
      | "yamldiagram" => ()
      "stereotype" => stereotype = true
      "arrow" => prefix = if sequence { "SequenceArrow" } else { "Arrow" }
      "participant" => prefix = "Participant"
      "lifeline" => prefix = "SequenceLifeLine"
      "activation" => prefix = "SequenceLifeLine"
      "group" => prefix = "SequenceGroup"
      "reference" => prefix = "SequenceReference"
      "separator" => prefix = "SequenceDivider"
      "diamond" => prefix = "ActivityDiamond"
      "circle" => prefix = "Circle"
      "class" => prefix = "Class"
      "object" => prefix = "Object"
      "component" => prefix = "Component"
      "actor" => prefix = "Actor"
      "usecase" => prefix = "Usecase"
      "state" => prefix = "State"
      "activity" => prefix = "Activity"
      "note" => prefix = "Note"
      "package" => prefix = "Package"
      "node" => prefix = "Node"
      "title" => prefix = "Title"
      "caption" => prefix = "Caption"
      "header" => prefix = "Header"
      "footer" => prefix = "Footer"
      "legend" => prefix = "Legend"
      _ => return
    }
  }
  if stereotype {
    prefix += "Stereotype"
  }
  if prefix.is_empty() {
    match property.to_lower() {
      "backgroundcolor" => apply(BackgroundColor(value))
      "fontname" => apply(FontFamily(value))
      "fontsize" => apply(FontSize(value))
      "fontcolor" => apply(Property("DefaultFontColor", value))
      "linecolor" => {
        apply(LineColor(value))
        for
          role in [
            "Class", "Object", "Component", "Actor", "Usecase", "Node", "Package",
            "Note", "State", "Activity", "Participant",
          ] {
          apply(Property(role + "BorderColor", value))
        }
      }
      _ => apply(Property(property, value))
    }
  } else {
    let key = match property.to_lower() {
      "linecolor" =>
        if prefix.has_suffix("Arrow") {
          "Color"
        } else {
          "BorderColor"
        }
      "linethickness" | "thickness" =>
        if prefix.has_suffix("Arrow") {
          "Thickness"
        } else {
          "BorderThickness"
        }
      "fontname" => "FontName"
      "fontcolor" => "FontColor"
      "fontsize" => "FontSize"
      "fontstyle" => "FontStyle"
      "backgroundcolor" => "BackgroundColor"
      "roundcorner" => "RoundCorner"
      "minimumwidth" => "MinimumWidth"
      "maximumwidth" => "MaximumWidth"
      _ => property
    }
    apply(
      Property(
        if prefix == "Class" && key == "MinimumWidth" {
          "MinClassWidth"
        } else {
          prefix + key
        },
        value,
      ),
    )
  }
}
