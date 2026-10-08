///|
const CLASS_COMPARTMENT_MARGIN_X : Int = 6

///|
const CLASS_COMPARTMENT_MARGIN_Y : Int = 4

///|
const CLASS_COMPARTMENT_TITLE_MARGIN : Int = 8

///|
priv enum ClassCompartmentItem {
  MemberRow(@entity.Member, Int)
}

///|
priv struct ClassCompartment {
  separator : Char
  title : String?
  title_height : Int
  items : Array[ClassCompartmentItem]
  width : Int
  height : Int
  content_top : Int
  has_visibility : Bool
}

///|
fn ClassCompartmentItem::height(self : ClassCompartmentItem) -> Int {
  match self {
    MemberRow(_, height) => height
  }
}

///|
fn @entity.Member::rendered_height(
  self : @entity.Member,
  metrics : ClassTextMetrics,
) -> Int {
  let font = if self.is_abstract { metrics.italic } else { metrics.regular }
  font.entity_measure(self.display_without_visibility()).height.max(
    metrics.row_height(),
  )
}

///|
fn build_class_compartment(
  entries : Array[@entity.Member],
  separator : Char,
  title : String?,
  metrics : ClassTextMetrics,
) -> ClassCompartment {
  let items : Array[ClassCompartmentItem] = []
  let has_visibility = entries.any(entry => !(entry.visibility is Unknown))
  let icon_width = if has_visibility { CLASS_SPOT_RADIUS + 3 } else { 0 }
  let mut width = 0
  let mut height = 0
  let mut index = 0
  while index < entries.length() {
    let entry = entries[index]
    let row_height = entry.rendered_height(metrics)
    items.push(MemberRow(entry, row_height))
    let font = if entry.is_abstract { metrics.italic } else { metrics.regular }
    width = width.max(
      font.entity_measure(entry.display_without_visibility()).width + icon_width,
    )
    height += row_height
    index += 1
  }
  let title_size = title.map(value => metrics.regular.entity_measure(value))
  let title_height = title_size.map_or(0, size => size.height)
  let content_top = if title is Some(_) {
    title_height
  } else {
    CLASS_COMPARTMENT_MARGIN_Y
  }
  {
    separator,
    title,
    title_height,
    items,
    has_visibility,
    content_top,
    width: (width + 2 * CLASS_COMPARTMENT_MARGIN_X).max(
      title_size.map_or(0, size => size.width + CLASS_COMPARTMENT_TITLE_MARGIN),
    ),
    height: height + content_top + CLASS_COMPARTMENT_MARGIN_Y,
  }
}

///|
/// BodyEnhanced1 retains source order once a separator appears;
/// ordinary classes continue to use their automatic fields/methods sections.
fn @entity.Entity::custom_compartments(
  self : @entity.Entity,
  metrics : ClassTextMetrics,
) -> Array[ClassCompartment]? {
  guard self.members.any(entry => entry.is_separator) else { return None }
  let result : Array[ClassCompartment] = []
  let mut entries : Array[@entity.Member] = []
  let mut separator = '_'
  let mut title : String? = None
  for entry in self.members {
    guard self.entry_visible(entry) else { continue }
    if entry.is_separator {
      result.push(build_class_compartment(entries, separator, title, metrics))
      separator = entry.raw.to_array()[0]
      title = if entry.raw.length() > 4 {
        Some(entry.raw[2:entry.raw.length() - 2].trim().to_owned())
      } else {
        None
      }
      entries = []
    } else {
      entries.push(entry)
    }
  }
  result.push(build_class_compartment(entries, separator, title, metrics))
  Some(result)
}

///|
fn draw_class_compartments(
  output : @graphics.Graphic,
  sections : Array[ClassCompartment],
  x : Int,
  y : Int,
  width : Int,
  metrics : ClassTextMetrics,
  colors : @style.EntityColors,
  text_color : String,
  line_style : @graphics.DrawingStyle,
) -> Unit {
  let mut top = y
  for section in sections {
    let line_y = top.to_double() + section.title_height.to_double() / 2.0
    let stroke = {
      ..line_style,
      dash: if section.separator == '.' {
        Some([1, 2])
      } else {
        None
      },
      stroke_width: if section.separator == '_' {
        line_style.stroke_width
      } else {
        Some(1)
      },
    }
    let title_width = section.title.map_or(0.0, title => {
      metrics.regular.entity_measure(title).width.to_double()
    })
    let draw_line = (dy : Double) => {
      if section.title is Some(_) {
        let half_gap = title_width / 2.0
        output
        .with_style(stroke)
        .draw(
          Line({ x: x.to_double(), y: line_y + dy, }, {
            x: (x + width / 2).to_double() - half_gap,
            y: line_y + dy,
          }),
        )
        output
        .with_style(stroke)
        .draw(
          Line({ x: (x + width / 2).to_double() + half_gap, y: line_y + dy, }, {
            x: (x + width).to_double(),
            y: line_y + dy,
          }),
        )
      } else {
        output
        .with_style(stroke)
        .draw(
          Line({ x: x.to_double(), y: line_y + dy, }, {
            x: (x + width).to_double(),
            y: line_y + dy,
          }),
        )
      }
    }
    draw_line(0.0)
    if section.separator == '=' {
      draw_line(2.0)
    }
    if section.title is Some(title) {
      draw_entity_text(
        output,
        (x + width / 2).to_double(),
        top.to_double() - 0.5 + metrics.regular.ascent.to_double(),
        title,
        metrics.regular,
        class_name="class-compartment-title",
        anchor=Middle,
        fill=text_color,
      )
    }
    let mut row_top = top + section.content_top
    for item in section.items {
      match item {
        MemberRow(entry, height) => {
          let text_x = x +
            CLASS_COMPARTMENT_MARGIN_X +
            (if section.has_visibility { CLASS_SPOT_RADIUS + 3 } else { 0 })
          let baseline = row_top + metrics.regular.ascent
          entry.draw_visibility_icon(
            output,
            x + CLASS_COMPARTMENT_MARGIN_X,
            baseline,
            colors,
          )
          draw_member_text(
            output, entry, text_x, baseline, "member", metrics, text_color,
          )
          row_top += height
        }
      }
    }
    top += section.height
  }
}
