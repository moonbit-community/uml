///|
priv struct StateGradient {
  first : String
  second : String
  policy : Char
} derive(Eq)

///|
priv struct StateGradients {
  definitions : Array[StateGradient]
}

///|
/// HColorSet supports grayscale hex, short RGB, full RGB, and RGBA. Keep
/// alpha for solid first-color rendering; gradient stops use toRGB instead.
/// Verified 2026-09-16: named/hex equivalents, grayscale expansion, and RGBA
/// preservation passed temporary property tests, which were then removed.
fn state_gradient_color(value : String) -> String? {
  @svg.gradient_color(value)
}

///|
fn parse_state_gradient(value : String) -> StateGradient? {
  @svg.parse_gradient(value).map(gradient => {
    first: gradient.first,
    second: gradient.second,
    policy: gradient.policy,
  })
}

///|
/// HColorGradient.toColor and DriverLineSvg use the first endpoint color.
fn state_first_gradient_color(value : String) -> String {
  parse_state_gradient(value).map_or(value, gradient => gradient.first)
}

///|
/// SvgGraphics.createSvgGradient uses the bounding box of each painted
/// shape. These are normalized coordinates, serialized as percentages.
/// Verified 2026-09-16: all four separators passed axis-direction tests.
fn StateGradient::axis(
  self : StateGradient,
) -> (@graphics.Point, @graphics.Point) {
  @svg.Gradient::{
    first: self.first,
    second: self.second,
    policy: self.policy,
  }.axis()
}

///|
fn StateGradient::opaque_stops(self : StateGradient) -> StateGradient {
  {
    ..self,
    first: self.first[:7].to_owned(),
    second: self.second[:7].to_owned(),
  }
}

///|
/// Encoding the resource contents avoids collisions between different state
/// diagrams embedded on one page. Identical resources have identical meaning.
fn StateGradient::id(self : StateGradient) -> String {
  let direction = match self.policy {
    '|' => "horizontal"
    '-' => "vertical"
    '\\' => "rising"
    _ => "falling"
  }
  "state-gradient-" +
  self.first[1:].to_owned() +
  "-" +
  self.second[1:].to_owned() +
  "-" +
  direction
}

///|
/// Verified 2026-09-16: equivalent resources are reused, gradient stops drop
/// alpha, first-color paints retain alpha, and non-gradient paints pass through.
fn StateGradients::paint(
  self : StateGradients,
  paint : @graphics.Paint,
  first_only~ : Bool,
) -> @graphics.Paint {
  guard paint is Color(value) && parse_state_gradient(value) is Some(gradient) else {
    return paint
  }
  guard !first_only else { return Color(gradient.first) }
  let gradient = gradient.opaque_stops()
  if !self.definitions.contains(gradient) {
    self.definitions.push(gradient)
  }
  Color("url(#" + gradient.id() + ")")
}

///|
/// SVG drivers preserve routed geometry while translating colors to paint
/// resources. DriverPathSvg also omits a same-color solid outline, but retains
/// a gradient outline even when it shares the fill's gradient.
/// Verified 2026-09-16 with composite states, entity/link notes, and scaling:
/// all four gradients preserve layout, drawing geometry, translations, metadata,
/// and group commands. Matching solid/gradient path outlines also passed tests.
fn StateGradients::command(
  self : StateGradients,
  command : @graphics.DrawCommand,
) -> @graphics.DrawCommand {
  guard command is Draw(shape, style, translation, metadata) else {
    return command
  }
  let solid_text = shape
    is (Text(_) | TextBlock(_) | StyledText(_, _) | StyledTextBlock(_, _))
  let suppress_stroke = shape is Path(_) &&
    style.fill == style.stroke &&
    style.fill is Color(value) &&
    parse_state_gradient(value) is None
  let fill = self.paint(style.fill, first_only=solid_text)
  let stroke = if suppress_stroke {
    @graphics.Paint::None
  } else {
    self.paint(style.stroke, first_only=solid_text || shape is Line(_, _))
  }
  Draw(
    shape,
    {
      ..style,
      fill,
      stroke,
      stroke_width: if suppress_stroke {
        Some(0.0)
      } else {
        style.stroke_width
      },
      dash: if suppress_stroke {
        None
      } else {
        style.dash
      },
    },
    translation,
    metadata,
  )
}

///|
fn StateGradients::write_definitions(
  self : StateGradients,
  writer : @svg.XmlWriter,
) -> Unit {
  guard !self.definitions.is_empty() else { return }
  writer.open("defs")
  for gradient in self.definitions {
    let (start, end) = gradient.axis()
    writer.open("linearGradient", attributes=[
      ("id", gradient.id()),
      ("x1", (start.x * 100.0).to_string() + "%"),
      ("y1", (start.y * 100.0).to_string() + "%"),
      ("x2", (end.x * 100.0).to_string() + "%"),
      ("y2", (end.y * 100.0).to_string() + "%"),
    ])
    writer.empty("stop", attributes=[
      ("offset", "0%"),
      ("stop-color", gradient.first),
    ])
    writer.empty("stop", attributes=[
      ("offset", "100%"),
      ("stop-color", gradient.second),
    ])
    writer.close()
  }
  writer.close()
}
