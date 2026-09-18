///|
/// CommandCreoleColorChange strips a syntactically valid tag even for an
/// unknown color, retaining the surrounding color in that case.
/// Verified 2026-09-16: delimiters/case, invalid syntax, unknown names, EOL
/// scope, outer-color restoration, nested faces/sizes, and escaped tags passed.
fn state_rich_color_open(text : String) -> (Int, String)? {
  let cursor = @tokenizer.Cursor::new(text.to_lower())
  guard cursor.consume_literal("<color") else { return None }
  guard !cursor
    .take_while(char => {
      char == ':' || char == ' ' || char is ('\u0009'..='\u000d')
    })
    .is_empty() else {
    return None
  }
  let start = cursor.offset()
  ignore(cursor.consume_literal("#"))
  guard !cursor
    .take_while(char => {
      char.is_ascii_alphabetic() || char.is_ascii_digit() || char == '_'
    })
    .is_empty() else {
    return None
  }
  let value = cursor.slice(start, cursor.offset())
  ignore(
    cursor.take_while(char => {
      char == ' ' || char == '\u00a0' || char is ('\u0009'..='\u000d')
    }),
  )
  guard cursor.consume_literal(">") else { return None }
  Some((cursor.offset(), value))
}

///|
fn state_rich_color(value : String) -> String? {
  let value = (if value.has_prefix("#") { value[1:].to_owned() } else { value }).to_lower()
  match value {
    "transparent" | "background" => Some("none")
    "automatic" => Some("automatic")
    _ => state_gradient_color(value)
  }
}

///|
fn state_rich_context(metadata : @graphics.Metadata, key : String) -> String? {
  metadata.data
  .search_by(entry => entry.0 == key)
  .map(index => metadata.data[index].1)
}

///|
/// HColorSimple.opposite selects black/white from ColorUtils' integer YIQ gray.
/// A gradient background delegates to its first endpoint.
/// Verified 2026-09-16: black/white and red/green polarity, gradient delegation,
/// and transparent-background fallback passed temporary property tests.
fn state_automatic_contrast(background : String) -> String {
  let color = state_gradient_color(state_first_gradient_color(background)).unwrap_or(
    "#000000",
  )
  let channel = (start : Int) => {
    @string.parse_int(color[start:start + 2], base=16) catch {
      _ => 0
    }
  }
  let gray = (channel(1) * 299 + channel(3) * 587 + channel(5) * 114) / 1000
  if gray < 128 {
    "#ffffff"
  } else {
    "#000000"
  }
}

///|
fn state_rich_transparent(background : String) -> Bool {
  background == "none" ||
  background == "transparent" ||
  state_gradient_color(background).map_or(false, color => {
    color.length() == 9 && color.has_suffix("00")
  })
}

///|
/// AtomText uses the current drawing background, falling back to the canvas
/// for transparent paint. InnerStateAutonom and document frames draw their
/// text on the original context; ordinary states and notes apply their fill.
/// Verified 2026-09-16: opaque/transparent leaves, composites, per-note fills,
/// and transition text resolve automatic colors with their actual contexts.
fn state_rich_background(
  diagram : @flow.StateDiagram,
  metadata : @graphics.Metadata,
) -> String {
  let canvas = state_decoration_background_color(diagram.style)
  if state_rich_context(metadata, "note-index") is Some(index) {
    let index = @string.parse_int(index) catch { _ => -1 }
    if index >= 0 && index < diagram.notes.length() {
      let color = note_background_color(diagram.notes[index], diagram.style)
      return if state_rich_transparent(color) { canvas } else { color }
    }
  }
  if state_rich_context(metadata, "state-code").bind(code => diagram.state(code))
    is Some(state) &&
    !diagram.has_children(state.code) {
    let color = state_background_color(state, diagram.style)
    return if state_rich_transparent(color) { canvas } else { color }
  }
  canvas
}

///|
/// Verified 2026-09-16: resolution changes only paint, preserving all drawing
/// geometry and metadata. Temporary property tests removed after passing.
fn resolve_state_rich_paint(
  diagram : @flow.StateDiagram,
  command : @graphics.DrawCommand,
) -> @graphics.DrawCommand {
  guard command is Draw(StyledText(_, _) as shape, paint, translation, metadata) &&
    paint.fill == Color("automatic") else {
    return command
  }
  Draw(
    shape,
    {
      ..paint,
      fill: Color(
        state_automatic_contrast(state_rich_background(diagram, metadata)),
      ),
    },
    translation,
    metadata,
  )
}

///|
fn state_text_background_id(color : String) -> String {
  "state-text-background-" + color[1:].to_owned()
}

///|
/// SvgGraphics.getFilterBackColor composites the glyphs over an opaque color
/// in their object bounds. Gradient backgrounds use DriverTextSvg's rectangle.
fn write_state_rich_command(
  writer : @svg.XmlWriter,
  command : @graphics.DrawCommand,
  backgrounds : Array[String],
) -> Unit {
  guard command is Draw(StyledText(_, _), _, _, metadata) &&
    state_rich_context(metadata, "rich-background").bind(state_gradient_color)
    is Some(color) else {
    writer.draw_command(command)
    return
  }
  let color = color[:7].to_owned()
  if !backgrounds.contains(color) {
    backgrounds.push(color)
  }
  writer.open("g", attributes=[
    ("filter", "url(#" + state_text_background_id(color) + ")"),
  ])
  writer.draw_command(command)
  writer.close()
}

///|
fn write_state_text_backgrounds(
  writer : @svg.XmlWriter,
  backgrounds : Array[String],
) -> Unit {
  guard !backgrounds.is_empty() else { return }
  writer.open("defs")
  for color in backgrounds {
    writer.open("filter", attributes=[
      ("id", state_text_background_id(color)),
      ("x", "0"),
      ("y", "0"),
      ("width", "1"),
      ("height", "1"),
    ])
    writer.empty("feFlood", attributes=[
      ("flood-color", color),
      ("result", "flood"),
    ])
    writer.empty("feComposite", attributes=[
      ("in", "SourceGraphic"),
      ("in2", "flood"),
      ("operator", "over"),
    ])
    writer.close()
  }
  writer.close()
}
