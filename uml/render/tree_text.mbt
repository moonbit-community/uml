///|
pub(all) struct TreeTextSpan {
  text : String
  strike : Bool
}

///|
/// Split one label line into creole `<s>` strike spans, mirroring PlantUML's
/// text run serialization.
pub fn parse_creole_text_line(line : String) -> Array[TreeTextSpan] {
  let lower = line.to_lower()
  let spans = []
  let mut cursor = 0
  let mut strike = false
  while cursor < line.length() {
    let marker = if strike { "</s>" } else { "<s>" }
    let rest = lower[cursor:].to_owned()
    match rest.find(marker) {
      Some(relative_index) => {
        let index = cursor + relative_index
        if index > cursor {
          spans.push({ text: line[cursor:index].to_owned(), strike, })
        }
        cursor = index + marker.length()
        strike = !strike
      }
      None => {
        spans.push({ text: line[cursor:].to_owned(), strike, })
        cursor = line.length()
      }
    }
  }
  if spans.is_empty() {
    spans.push({ text: "", strike: false, })
  }
  spans
}

///|
/// The visible label with creole markers stripped, keeping the line structure.
pub fn tree_visible_text(label : String) -> String {
  label
  .split("\n")
  .map(line => {
    parse_creole_text_line(line.to_owned()).map(span => span.text).join("")
  })
  .join("\n")
}

///|
/// PlantUML's real-font string bounder counts the space glyph, but the
/// vendored width table stores zero for it (faithful to PlantUML's own
/// table). Tree diagrams add the reference space advance back: 4.43px at
/// font size 14, derived from the reference SVGs.
pub const PLANTUML_SPACE_ADVANCE_PER_14 : Int32 = 443

///|
/// The width table measures a few percent narrower than PlantUML's real
/// font. Tree diagrams scale the measured advance only, leaving the line
/// heights untouched.
pub const PLANTUML_WIDTH_SCALE : Int32 = 110

///|
pub fn plantuml_space_advance(font_size : Int32) -> Int32 {
  font_size * PLANTUML_SPACE_ADVANCE_PER_14 / 14 / 100
}

///|
pub fn plantuml_measure(
  metrics : @metrics.FontMetrics,
  text : String,
) -> @metrics.TextMetrics {
  let measured = metrics.measure(text)
  let spaces = text.split(" ").to_array().length() - 1
  let extra = measured.advance_width * (PLANTUML_WIDTH_SCALE - 100) / 100 +
    spaces * plantuml_space_advance(metrics.font_size)
  if extra > 0 {
    measured.with_extra_advance(extra)
  } else {
    measured
  }
}

///|
pub(all) struct TreeLabelMetrics {
  width : Double
  height : Double
}

///|
/// Measure a tree label with the PlantUML width compensation, after stripping
/// creole markers.
pub fn tree_label_metrics(
  metrics : @metrics.FontMetrics,
  label : String,
  wrap_width~ : Double = 0.0,
) -> TreeLabelMetrics {
  if tree_rich_text(label, metrics, wrap_width) is Some(rich) {
    return { width: rich.width, height: rich.height, }
  }
  let measured = plantuml_measure(metrics, tree_visible_text(label))
  { width: measured.width.to_double(), height: measured.height.to_double(), }
}

///|
/// Width of a tree label. PlantUML's multi-line labels carry a leading space
/// on their first line (visible in the reference SVGs); it widens the box
/// and offsets the first line of text.
pub fn tree_label_width(
  metrics : @metrics.FontMetrics,
  font_size : Int32,
  label : String,
  wrap_width~ : Double = 0.0,
) -> Double {
  if tree_rich_text(label, metrics, wrap_width) is Some(rich) {
    return rich.width
  }
  let visible = tree_visible_text(label)
  let lines = visible.split("\n").to_array()
  if lines.length() > 1 {
    let space = plantuml_space_advance(font_size)
    let first = plantuml_measure(metrics, lines[0].to_owned()).width + space
    let rest = plantuml_measure(metrics, lines[1:].join("\n")).width
    first.max(rest).to_double()
  } else {
    plantuml_measure(metrics, visible).width.to_double()
  }
}

///|
fn split_whitespace(value : String) -> (String, String, String) {
  let length = value.length()
  let mut start = 0
  while start < length && value[start] == ' ' {
    start = start + 1
  }
  let mut end = length
  while end > start && value[end - 1] == ' ' {
    end = end - 1
  }
  (
    value[start:end].to_owned(),
    value[:start].to_owned(),
    value[end:].to_owned(),
  )
}

///|
/// Render one label as a run of `<text>` elements, each pinned to its
/// measured advance. PlantUML emits one `<text>` per markup span; the
/// whitespace between spans is measured but not drawn. The first line of a
/// multi-line label carries an extra leading space (visible in the reference
/// SVGs).
pub fn append_tree_text(
  output : @svg.XmlWriter,
  x : Int32,
  y : Int32,
  label : String,
  line_height : Int32,
  anchor : String,
  fill : String,
  font_size : Int32,
  text_metrics : @metrics.FontMetrics,
  class_name : String,
) -> Unit {
  for
    run in layout_tree_text(
      x,
      y,
      label,
      line_height,
      font_size,
      text_metrics,
      Start,
    ) {
    output.text_run(run, anchor~, attributes=[
      ("fill", fill),
      ("class", class_name),
    ])
  }
}

///|
/// Position creole runs using exactly the metrics and whitespace rules used
/// for tree layout. Both drawing interfaces consume this one layout result.
fn layout_tree_text(
  x : Int32,
  y : Int32,
  label : String,
  line_height : Int32,
  font_size : Int32,
  text_metrics : @metrics.FontMetrics,
  anchor : @graphics.TextAnchor,
) -> Array[@graphics.TextRun] {
  let runs : Array[@graphics.TextRun] = []
  let lines = label.split("\n").to_array()
  let space = plantuml_space_advance(font_size)
  let first_line_extra = if lines.length() > 1 { space } else { 0 }
  lines.eachi((line_index, line) => {
    let spans = parse_creole_text_line(line.to_owned())
    let mut cursor_x = x + (if line_index == 0 { first_line_extra } else { 0 })
    let mut pending_ws = 0
    for span_index, span in spans {
      let (text, leading, trailing) = split_whitespace(span.text)
      if span_index > 0 {
        cursor_x += pending_ws +
          plantuml_measure(text_metrics, leading).advance_width
      }
      if !text.is_empty() {
        let measured = plantuml_measure(text_metrics, text)
        runs.push({
          text,
          position: {
            x: cursor_x.to_double(),
            y: (y + line_index * line_height).to_double(),
          },
          advance: if measured.advance_width > 0 {
            Some(measured.advance_width.to_double())
          } else {
            None
          },
          strike: span.strike,
          anchor,
          font_size: font_size.to_double(),
          font_family: None,
        })
        cursor_x += measured.advance_width
      }
      pending_ws = plantuml_measure(text_metrics, trailing).advance_width
    }
  })
  runs
}

///|
fn draw_tree_text_at(
  output : @graphics.Graphic,
  x : Double,
  y : Double,
  label : String,
  line_height : Int32,
  anchor : @graphics.TextAnchor,
  fill : String,
  font_size : Int32,
  text_metrics : @metrics.FontMetrics,
  class_name : String,
  wrap_width~ : Double = 0.0,
  font_family~ : String? = None,
) -> Unit {
  let output = output.with_style({
    ..@graphics.DrawingStyle::default(),
    fill: Color(fill),
  })
  if tree_rich_text(label, text_metrics, wrap_width) is Some(rich) {
    draw_tree_rich_text(
      output,
      rich,
      x,
      y - font_size.to_double(),
      anchor,
      text_metrics,
      fill,
      font_family,
      class_name,
    )
    return
  }
  let output = output.translated(x, y)
  for
    run in layout_tree_text(
      0, 0, label, line_height, font_size, text_metrics, anchor,
    ) {
    output.draw(
      StyledText({ ..run, font_family, }, {
        ..Default::default(),
        weight: Some(text_metrics.font_weight),
        italic: Some(text_metrics.style == @metrics.FontStyle::Italic),
      }),
      metadata={
        ..@graphics.Metadata::default(),
        class_name: Some(class_name),
      },
    )
  }
}

///|
/// Reuse the full Creole scanner and wrapping pipeline already used by state
/// labels, then measure each styled run with the tree font calibration.
fn tree_rich_text(
  label : String,
  metrics : @metrics.FontMetrics,
  wrap_width : Double,
) -> StateRichText? {
  let rich = state_rich_text(label, metrics, wrap_width, literal_newlines=true)
  let rich = match rich {
    Some(rich) => rich
    None if wrap_width > 0.0 => {
      let display = state_display(label, literal_newlines=true).wrap(
        metrics, wrap_width,
      )
      let face : StateFontFace = {
        weight: metrics.font_weight,
        style: metrics.style,
      }
      let lines = display.text
        .split("\n")
        .map(line => {
          state_rich_line(
            [
              {
                text: line.to_owned(),
                face,
                size: None,
                color: None,
                family: None,
                decoration: Default::default(),
              },
            ],
            metrics,
          )
        })
        .to_array()
      {
        lines,
        width: 0.0,
        height: lines.fold(init=0.0, (height, line) => height + line.height),
        alignment: display.alignment,
      }
    }
    None => return None
  }
  let lines = rich.lines.mapi((index, line) => {
    let extra = if index == 0 && rich.lines.length() > 1 {
      plantuml_space_advance(metrics.font_size).to_double()
    } else {
      0.0
    }
    {
      ..line,
      width: line.spans.fold(init=extra, (width, span) => {
        width +
        plantuml_measure(span.metrics(metrics), span.text).advance_width.to_double()
      }),
    }
  })
  Some({
    ..rich,
    lines,
    width: lines.fold(init=0.0, (width, line) => width.max(line.width)),
  })
}

///|
fn draw_tree_rich_text(
  output : @graphics.Graphic,
  rich : StateRichText,
  x : Double,
  top : Double,
  anchor : @graphics.TextAnchor,
  metrics : @metrics.FontMetrics,
  fill : String,
  family : String?,
  class_name : String,
) -> Unit {
  let mut top = top
  for index, line in rich.lines {
    let alignment = rich.alignment.unwrap_or(anchor)
    let mut x = x -
      state_text_anchor_offset(anchor, rich.width) +
      state_text_anchor_offset(alignment, rich.width - line.width)
    if index == 0 && rich.lines.length() > 1 {
      x += plantuml_space_advance(metrics.font_size).to_double()
    }
    for span in line.spans {
      let font = span.metrics(metrics)
      let full_width = plantuml_measure(font, span.text).advance_width
      let (text, leading, _) = split_whitespace(span.text)
      let measured = plantuml_measure(font, text)
      let run_x = x + plantuml_measure(font, leading).advance_width.to_double()
      let baseline = top +
        line.height -
        font.line_height.to_double() +
        font.font_size.to_double()
      let color = @svg.svg_color(span.color, fill)
      let graphic = output.with_style({ ..output.style, fill: Color(color), })
      if span.decoration.background && span.decoration.color is Some(background) {
        graphic
        .with_style({
          ..Default::default(),
          fill: Color(@svg.svg_color(Some(background), fill)),
          stroke: None,
        })
        .draw(
          Rectangle(
            origin={ x, y: top, },
            width=measured.width.to_double(),
            height=line.height,
            rx=None,
            ry=None,
          ),
        )
      }
      graphic.draw(
        StyledText(
          {
            text,
            position: { x: run_x, y: baseline, },
            advance: Some(measured.advance_width.to_double()),
            anchor: Start,
            font_size: font.font_size.to_double(),
            font_family: span.family.map_or(family, name => Some(name)),
            strike: span.decoration.strike,
          },
          {
            ..Default::default(),
            weight: Some(span.face.weight),
            italic: Some(span.face.style == @metrics.FontStyle::Italic),
          },
        ),
        metadata={ ..Default::default(), class_name: Some(class_name), },
      )
      if span.decoration.underline {
        graphic
        .with_style({
          ..Default::default(),
          stroke: Color(@svg.svg_color(span.decoration.color, color)),
          stroke_width: Some(1.0),
        })
        .draw(
          Line(
            {
              x,
              y: baseline +
              font.font_size.to_double() / STATE_RICH_UNDERLINE_DIVISOR,
            },
            {
              x: x + measured.advance_width.to_double(),
              y: baseline +
              font.font_size.to_double() / STATE_RICH_UNDERLINE_DIVISOR,
            },
          ),
        )
      }
      x += full_width.to_double()
    }
    top += line.height
  }
}

///|
fn draw_tree_text(
  output : @graphics.Graphic,
  x : Int32,
  y : Int32,
  label : String,
  line_height : Int32,
  anchor : @graphics.TextAnchor,
  fill : String,
  font_size : Int32,
  text_metrics : @metrics.FontMetrics,
  class_name : String,
) -> Unit {
  draw_tree_text_at(
    output,
    x.to_double(),
    y.to_double(),
    label,
    line_height,
    anchor,
    fill,
    font_size,
    text_metrics,
    class_name,
  )
}
