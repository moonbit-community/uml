///|
priv enum StateRichBlock {
  Table(StateRichTable)
  Rule(Char, StateRichText?)
}

///|
priv struct StateRichTableCell {
  content : StateRichText
  background : String?
  alignment : @graphics.TextAnchor
}

///|
priv struct StateRichTableRow {
  cells : Array[StateRichTableCell]
  background : String?
  height : Double
}

///|
priv struct StateRichTable {
  rows : Array[StateRichTableRow]
  widths : Array[Double]
  border : String?
  width : Double
  height : Double
}

///|
const STATE_TABLE_MARGIN : Double = 2.0

///|
fn state_rich_plain(
  text : String,
  metrics : @metrics.FontMetrics,
  monospaced_family : String,
) -> StateRichText {
  state_rich_text(text, metrics, 0.0, monospaced_family~).unwrap_or_else(() => {
    let display = state_display(text)
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
              url: None,
              media: None,
            },
          ],
          metrics,
        )
      })
      .to_array()
    {
      lines,
      width: lines.fold(init=0.0, (width, line) => width.max(line.width)),
      height: lines.fold(init=0.0, (height, line) => height + line.height),
      alignment: display.alignment,
    }
  })
}

///|
fn state_table_colors(line : String) -> (String, String?, String?) {
  guard line.has_prefix("<#") && line.find(">") is Some(end) else {
    return (line, None, None)
  }
  let colors = line[1:end].split(",").map(StringView::to_owned).to_array()
  (line[end + 1:].to_owned(), colors.get(0), colors.get(1))
}

///|
fn state_is_table_line(line : String) -> Bool {
  let (line, _, _) = state_table_colors(line)
  line.has_prefix("|") && line.has_suffix("|") && line.length() > 1
}

///|
fn state_table_cells(line : String) -> Array[String] {
  let cells = []
  let cursor = @tokenizer.Cursor::new(line)
  let mut cell = StringBuilder()
  while cursor.advance() is Some(char) {
    if char == '\\' && cursor.peek() is Some('|') {
      ignore(cursor.advance())
      cell.write_char('|')
    } else if char == '|' {
      // StripeTable's StringTokenizer excludes empty fields.
      let value = cell.to_string()
      if !value.is_empty() {
        cells.push(value)
      }
      cell = StringBuilder()
    } else {
      cell.write_char(char)
    }
  }
  cells
}

///|
fn state_rich_table(
  source : Array[String],
  start : Int,
  metrics : @metrics.FontMetrics,
  monospaced_family : String,
) -> (StateRichTable, Int) {
  let rows = []
  let widths : Array[Double] = []
  let mut index = start
  let (_, _, border) = state_table_colors(source[start])
  let mut height = STATE_TABLE_MARGIN * 2.0
  while index < source.length() && state_is_table_line(source[index]) {
    let (line, background, _) = state_table_colors(source[index])
    let cells = []
    let mut row_height = 0.0
    for column, value in state_table_cells(line) {
      let header = value.has_prefix("=")
      let value = if header { value[1:].to_owned() } else { value }
      let (value, cell_background, _) = state_table_colors(value)
      let (value, alignment) = if value.has_prefix("<r>") {
        (value[3:].to_owned(), @graphics.TextAnchor::End)
      } else {
        (value, @graphics.TextAnchor::Start)
      }
      let font = if header {
        metrics.with_face(700, metrics.style)
      } else {
        metrics
      }
      let content = state_rich_plain(
        value.replace_all(old="<br>", new="\n"),
        font,
        monospaced_family,
      )
      if column >= widths.length() {
        widths.push(content.width)
      } else {
        widths[column] = widths[column].max(content.width)
      }
      row_height = row_height.max(content.height)
      cells.push({ content, background: cell_background, alignment, })
    }
    rows.push({ cells, background, height: row_height, })
    height += row_height
    index += 1
  }
  (
    {
      rows,
      widths,
      border,
      width: widths.fold(init=0.0, (width, cell) => width + cell),
      height,
    },
    index,
  )
}

///|
fn state_rich_rule(
  line : String,
  metrics : @metrics.FontMetrics,
  monospaced_family : String,
) -> StateRichLine? {
  for (delimiter, style) in [("--", '-'), ("==", '='), ("..", '.')] {
    guard line.length() >= delimiter.length() * 2 &&
      line.has_prefix(delimiter) &&
      line.has_suffix(delimiter) else {
      continue
    }
    let title = line[delimiter.length():line.length() - delimiter.length()].to_owned()
    guard !title.contains(style.to_string()) ||
      (style == '=' && title.to_array().all(char => char == '=')) else {
      continue
    }
    let title = if title.is_empty() ||
      (style == '=' && title.to_array().all(char => char == '=')) {
      None
    } else {
      Some(state_rich_plain(title, metrics, monospaced_family))
    }
    return Some({
      spans: [],
      block: Some(Rule(style, title)),
      width: title.map_or(10.0, title => title.width),
      height: title.map_or(10.0, title => title.height),
    })
  }
  None
}

///|
fn StateRichBlock::draw(
  self : StateRichBlock,
  output : @graphics.Graphic,
  x : Double,
  top : Double,
  width : Double,
  height : Double,
  metrics : @metrics.FontMetrics,
  metadata : @graphics.Metadata,
) -> Unit {
  match self {
    Table(table) => {
      let border = table.border.map_or(output.style.fill, color => {
        Color(@svg.svg_color(Some(color), "black"))
      })
      let grid = output.with_style({
        ..output.style,
        fill: None,
        stroke: border,
        stroke_width: Some(1.0),
        dash: Some([]),
      })
      let mut y = top + STATE_TABLE_MARGIN
      for row in table.rows {
        if row.background is Some(color) {
          output
          .with_style({
            ..Default::default(),
            fill: Color(@svg.svg_color(Some(color), "white")),
            stroke: None,
          })
          .draw(
            Rectangle(
              origin={ x, y, },
              width=table.width,
              height=row.height,
              rx=None,
              ry=None,
            ),
            metadata~,
          )
        }
        let mut left = x
        for column, cell in row.cells {
          let cell_width = table.widths[column]
          if cell.background is Some(color) {
            output
            .with_style({
              ..Default::default(),
              fill: Color(@svg.svg_color(Some(color), "white")),
              stroke: None,
            })
            .draw(
              Rectangle(
                origin={ x: left, y, },
                width=cell_width,
                height=row.height,
                rx=None,
                ry=None,
              ),
              metadata~,
            )
          }
          let offset = state_text_anchor_offset(
            cell.alignment,
            cell_width - cell.content.width,
          )
          cell.content.draw(
            output,
            left + offset,
            y,
            metrics,
            metadata,
            Start,
            Some(cell.alignment),
          )
          left += cell_width
        }
        grid.draw(Line({ x, y, }, { x: x + table.width, y, }), metadata~)
        y += row.height
      }
      grid.draw(Line({ x, y, }, { x: x + table.width, y, }), metadata~)
      let mut left = x
      for cell_width in table.widths {
        grid.draw(
          Line({ x: left, y: top + STATE_TABLE_MARGIN, }, { x: left, y, }),
          metadata~,
        )
        left += cell_width
      }
      grid.draw(
        Line({ x: left, y: top + STATE_TABLE_MARGIN, }, { x: left, y, }),
        metadata~,
      )
    }
    Rule(style, title) => {
      let line = output.with_style({
        ..output.style,
        stroke: output.style.fill,
        stroke_width: Some(1.0),
        dash: Some(if style == '.' { [1.0, 2.0] } else { [] }),
        fill: None,
      })
      let y = top + height / 2.0
      let title_width = title.map_or(0.0, title => title.width)
      let side = (width - title_width) / 2.0
      for offset in (if style == '=' { [0.0, 2.0] } else { [0.0] }) {
        line.draw(
          Line({ x, y: y + offset, }, { x: x + side, y: y + offset, }),
          metadata~,
        )
        line.draw(
          Line({ x: x + side + title_width, y: y + offset, }, {
            x: x + width,
            y: y + offset,
          }),
          metadata~,
        )
      }
      if title is Some(title) {
        title.draw(
          output,
          x + side,
          y - title.height / 2.0 - 0.5,
          metrics,
          metadata,
          Start,
          None,
        )
      }
    }
  }
}
