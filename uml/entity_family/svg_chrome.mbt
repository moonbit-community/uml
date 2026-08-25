///|
/// Vertical padding above and below each document chrome text block.
const CHROME_BLOCK_PADDING : Int = 4

///|
/// Gap between stacked chrome blocks (title above header, etc.).
const CHROME_BLOCK_GAP : Int = 6

///|
priv struct ChromeBlock {
  text : String
  block_class : String
  metrics : @metrics.FontMetrics
  bold : Bool
}

///|
/// Document-level text drawn outside the entity content: title and header
/// above the diagram, caption, legend and footer below it.
fn @entity.EntityDiagram::chrome_blocks(
  self : @entity.EntityDiagram,
  top : Bool,
) -> Array[ChromeBlock] {
  let blocks : Array[ChromeBlock] = []
  if top {
    if self.style.title is Some(text) {
      blocks.push({
        text,
        block_class: "title",
        metrics: self.style.font_metrics(font_weight=700),
        bold: true,
      })
    }
    if self.style.header is Some(text) {
      blocks.push({
        text,
        block_class: "header",
        metrics: self.style.font_metrics(),
        bold: false,
      })
    }
  } else {
    if self.style.caption is Some(text) {
      blocks.push({
        text,
        block_class: "caption",
        metrics: self.style.font_metrics(),
        bold: false,
      })
    }
    if self.style.legend is Some(text) {
      blocks.push({
        text,
        block_class: "legend",
        metrics: self.style.font_metrics(),
        bold: false,
      })
    }
    if self.style.footer is Some(text) {
      blocks.push({
        text,
        block_class: "footer",
        metrics: self.style.font_metrics(),
        bold: false,
      })
    }
  }
  blocks
}

///|
fn ChromeBlock::height(self : ChromeBlock) -> Int {
  self.metrics.measure(self.text).height + CHROME_BLOCK_PADDING * 2
}

///|
fn chrome_stack_height(blocks : Array[ChromeBlock]) -> Int {
  let mut height = 0
  for index, block in blocks {
    if index > 0 {
      height += CHROME_BLOCK_GAP
    }
    height += block.height()
  }
  height
}

///|
fn chrome_stack_width(blocks : Array[ChromeBlock]) -> Int {
  let mut width = 0
  for block in blocks {
    width = width.max(block.metrics.measure(block.text).width)
  }
  width
}

///|
/// Resolve the `scale` directive to a positive factor; `scale 2`, `scale
/// 1.5` and `scale 200/100` forms are all accepted.
fn diagram_scale(style : @style.DocumentStyle) -> Double {
  match style.scale {
    Some(value) => {
      let trimmed = value.trim().to_owned()
      let direct : Double? = Some(@string.parse_double(trimmed)) catch {
        _ => None
      }
      match direct {
        Some(value) => value.max(0.0)
        None =>
          match @parse.find_literal(trimmed, "/") {
            Some(index) => {
              let numerator = @string.parse_double(trimmed[0:index].to_owned()) catch {
                _ => 1.0
              }
              let denominator = @string.parse_double(
                trimmed[index + 1:].to_owned(),
              ) catch {
                _ => 1.0
              }
              if denominator == 0.0 {
                1.0
              } else {
                (numerator / denominator).max(0.0)
              }
            }
            None => 1.0
          }
      }
    }
    None => 1.0
  }
}

///|
fn append_chrome_stack(
  output : StringBuilder,
  blocks : Array[ChromeBlock],
  canvas_width : Double,
  start_y : Double,
  color : String,
) -> Unit {
  let mut y = start_y
  for block in blocks {
    let metrics = block.metrics.measure(block.text)
    let x = ((canvas_width - metrics.width.to_double()) / 2.0).max(0.0)
    output <+
      $|<g class="\{block.block_class}">
    let attributes = [
      ("class", "chrome-text"),
      ("fill", color),
      ..if block.bold {
        [("font-weight", "700")]
      } else {
        []
      },
    ]
    output.write_string(
      @svg.text_markup(
        x,
        y + CHROME_BLOCK_PADDING.to_double() + metrics.ascent.to_double(),
        block.text,
        attributes,
        block.metrics,
      ),
    )
    output.write_char('\n')
    output.write_string("</g>\n")
    y += (block.height() + CHROME_BLOCK_GAP).to_double()
  }
}
