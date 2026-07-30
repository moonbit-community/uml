///|
fn Entity::spot(self : Entity) -> (String, String) {
  match self.kind {
    AbstractClass => ("A", "#A9DCDF")
    Interface => ("I", "#B4A7E5")
    Enum => ("E", "#EB937F")
    Annotation => ("@", "#B4A7E5")
    _ => ("C", "#ADD1B2")
  }
}

///|
fn Member::display_without_visibility(self : Member) -> String {
  match self.visibility {
    Unknown => self.raw
    _ => self.raw[1:].trim_start().to_owned()
  }
}

///|
fn Member::visibility_icon(self : Member, x : Int, baseline_y : Int) -> String {
  if self.visibility is Unknown {
    return ""
  }
  let fill = if self.is_method { "#84BE84" } else { "none" }
  let color = match self.visibility {
    Public => "#038048"
    Private => "#B20000"
    Protected => "#A9A900"
    Package => "#A06000"
    Unknown => "#181818"
  }
  let center_y = baseline_y - 4
  match self.visibility {
    Public =>
      "<circle cx=\"\{x + 5}\" cy=\"\{center_y}\" r=\"3\" fill=\"\{fill}\" stroke=\"\{color}\" stroke-width=\"1\"/>"
    Private =>
      "<rect x=\"\{x + 2}\" y=\"\{center_y - 3}\" width=\"6\" height=\"6\" fill=\"\{fill}\" stroke=\"\{color}\" stroke-width=\"1\"/>"
    Protected =>
      "<path d=\"M \{x + 5} \{center_y - 4} L \{x + 9} \{center_y} L \{x + 5} \{center_y + 4} L \{x + 1} \{center_y} Z\" fill=\"\{fill}\" stroke=\"\{color}\" stroke-width=\"1\"/>"
    Package =>
      "<path d=\"M \{x + 5} \{center_y - 3} L \{x + 9} \{center_y + 3} L \{x + 1} \{center_y + 3} Z\" fill=\"\{fill}\" stroke=\"\{color}\" stroke-width=\"1\"/>"
    Unknown => ""
  }
}

///|
fn ClassTextMetrics::header_height(self : ClassTextMetrics) -> Int {
  (self.regular.line_height + 16).max(32)
}

///|
fn ClassTextMetrics::row_height(self : ClassTextMetrics) -> Int {
  self.regular.line_height.max(17)
}

///|
priv struct ClassHeaderLayout {
  width : Int
  height : Int
}

///|
priv struct ClassBodyLayout {
  fields : Array[Member]
  methods : Array[Member]
  fields_height : Int
  methods_height : Int
}

///|
fn body_section_height(
  entries : Array[Member],
  text_metrics : ClassTextMetrics,
) -> Int {
  if entries.is_empty() {
    8
  } else {
    7 + entries.length() * text_metrics.row_height()
  }
}

///|
fn Entity::header_layout(
  self : Entity,
  text_metrics : ClassTextMetrics,
) -> ClassHeaderLayout {
  // PlantUML places a 22px circled type icon beside every class title.
  let title_metrics = match self.kind {
    AbstractClass | Interface => text_metrics.italic
    _ => text_metrics.regular
  }
  let width = @metrics.measure_text_with(self.display, title_metrics).width + 32
  { width, height: text_metrics.header_height() }
}

///|
fn Entity::body_layout(
  self : Entity,
  text_metrics : ClassTextMetrics,
) -> ClassBodyLayout {
  let fields : Array[Member] = []
  let methods : Array[Member] = []
  for entry in self.members {
    guard self.entry_visible(entry) && !entry.is_separator else { continue }
    if entry.is_method {
      methods.push(entry)
    } else {
      fields.push(entry)
    }
  }
  // MethodsOrFieldsArea always contributes its separator and vertical margins,
  // even when that portion has no visible members.
  {
    fields,
    methods,
    fields_height: body_section_height(fields, text_metrics),
    methods_height: body_section_height(methods, text_metrics),
  }
}

///|
fn Entity::height(self : Entity, text_metrics : ClassTextMetrics) -> Int {
  let header = self.header_layout(text_metrics)
  let body = self.body_layout(text_metrics)
  header.height + body.fields_height + body.methods_height
}

///|
fn Entity::entry_visible(self : Entity, entry : Member) -> Bool {
  !entry.is_hidden &&
  !(entry.is_method && self.methods_hidden) &&
  !(!entry.is_method && !entry.is_separator && self.fields_hidden)
}

///|
priv struct ClassTextMetrics {
  regular : @metrics.FontMetrics
  italic : @metrics.FontMetrics
  usecase_regular : @metrics.FontMetrics
  usecase_italic : @metrics.FontMetrics
  actor_regular : @metrics.FontMetrics
  actor_italic : @metrics.FontMetrics
  usecase_font_family : String
  actor_font_family : String
  note : @metrics.FontMetrics
  actor_style : String
}

///|
priv enum ActorAppearance {
  Stickman
  Awesome
  Hollow
}

///|
priv enum NodeShape {
  Box
  Ellipse
} derive(Eq, Debug)

///|
priv struct NodeGeometry {
  width : Int
  height : Int
  shape : NodeShape
}

///|
const TEXT_BLOCK_ELLIPSE_MARGIN : Double = 6.0

///|
const USECASE_BODY_HORIZONTAL_MARGIN : Int = 12

///|
const ACTOR_FIGURE_WIDTH : Int = 29

///|
const ACTOR_FIGURE_HEIGHT : Int = 62

///|
const ACTOR_AWESOME_WIDTH : Int = 57

///|
const ACTOR_AWESOME_HEIGHT : Int = 62

///|
const ACTOR_HOLLOW_WIDTH : Int = 28

///|
const ACTOR_HOLLOW_HEIGHT : Int = 35

///|
const COMPONENT_HORIZONTAL_PADDING : Int = 40

///|
const COMPONENT_VERTICAL_PADDING : Int = 30

///|
const COMPONENT_TAB_WIDTH : Int = 15

///|
const COMPONENT_TAB_HEIGHT : Int = 10

///|
const COMPONENT_TAB_INSET : Int = 5

///|
const COMPONENT_TAB_MARK_WIDTH : Int = 4

///|
const COMPONENT_TAB_MARK_HEIGHT : Int = 2

///|
const COMPONENT_TAB_MARK_LEFT_OFFSET : Int = 2

///|
const COMPONENT_TAB_MARK_TOP_OFFSET : Int = 2

///|
const COMPONENT_TAB_MARK_GAP : Int = 4

///|
const USECASE_RELATION_LABEL_FONT_SIZE : Int = 13

///|
const NOTE_FONT_SIZE : Int = 13

///|
const NOTE_LEFT_PADDING : Int = 6

///|
const NOTE_RIGHT_PADDING : Int = 15

///|
const NOTE_VERTICAL_PADDING : Int = 5

///|
const SVG_CANVAS_MARGIN : Int = 10

///|
fn ClassTextMetrics::new(style : @core.DocumentStyle) -> ClassTextMetrics {
  let font_size = if style.font_size is None {
    14
  } else {
    @core.font_size_value(style)
  }
  let usecase_font_size = style.usecase_font_size(fallback=font_size)
  let actor_font_size = style.actor_font_size(fallback=font_size)
  let usecase_font_family = style.usecase_font_family()
  let actor_font_family = style.actor_font_family()
  {
    regular: style.font_metrics(font_size~),
    italic: style.font_metrics(font_size~, font_style=Italic),
    usecase_regular: style.font_metrics_for(
      usecase_font_family,
      font_size=usecase_font_size,
    ),
    usecase_italic: style.font_metrics_for(
      usecase_font_family,
      font_size=usecase_font_size,
      font_style=Italic,
    ),
    actor_regular: style.font_metrics_for(
      actor_font_family,
      font_size=actor_font_size,
    ),
    actor_italic: style.font_metrics_for(
      actor_font_family,
      font_size=actor_font_size,
      font_style=Italic,
    ),
    usecase_font_family,
    actor_font_family,
    note: style.font_metrics(font_size=NOTE_FONT_SIZE),
    actor_style: style.actor_style(),
  }
}

///|
fn actor_appearance(style : String) -> ActorAppearance {
  match style {
    "awesome" => Awesome
    "hollow" => Hollow
    _ => Stickman
  }
}

///|
fn actor_figure_geometry(
  appearance : ActorAppearance,
  business~ : Bool,
) -> (Int, Int) {
  if business {
    return (ACTOR_FIGURE_WIDTH, ACTOR_FIGURE_HEIGHT)
  }
  match appearance {
    Awesome => (ACTOR_AWESOME_WIDTH, ACTOR_AWESOME_HEIGHT)
    Hollow => (ACTOR_HOLLOW_WIDTH, ACTOR_HOLLOW_HEIGHT)
    Stickman => (ACTOR_FIGURE_WIDTH, ACTOR_FIGURE_HEIGHT)
  }
}

///|
fn Entity::width(self : Entity, text_metrics : ClassTextMetrics) -> Int {
  let mut width = self.header_layout(text_metrics).width
  let body = self.body_layout(text_metrics)
  for entry in body.fields {
    width = width.max(
      @metrics.measure_text_with(entry.raw, text_metrics.regular).width + 28,
    )
  }
  for entry in body.methods {
    width = width.max(
      @metrics.measure_text_with(entry.raw, text_metrics.regular).width + 28,
    )
  }
  width
}

///|
fn Entity::usecase_content_layout(
  self : Entity,
  text_metrics : ClassTextMetrics,
) -> (Int, Int, String?) {
  let title = @metrics.measure_text_with(
    self.display,
    text_metrics.usecase_regular,
  )
  // BodyEnhanced1 uses TextBlockUtils.withMargin(block, 6, 0), which adds
  // 6px to both horizontal sides. Its UEmpty footprint participates in sizing.
  let title_width = title.width + USECASE_BODY_HORIZONTAL_MARGIN
  match self.stereotype {
    Some(stereotype) if !self.stereotype_hidden => {
      let display = @core.display_stereotype(stereotype)
      let stereotype_metrics = @metrics.measure_text_with(
        display,
        text_metrics.usecase_italic,
      )
      (
        title_width.max(stereotype_metrics.width),
        title.height + stereotype_metrics.height,
        Some(display),
      )
    }
    _ => (title_width, title.height, None)
  }
}

///|
/// Matches TextBlockInEllipse: calculate the smallest ellipse containing the
/// text footprint, then expand it by UEllipse.bigger(6).
fn text_block_in_ellipse_geometry(width : Int, height : Int) -> (Int, Int) {
  let width = width.max(1).to_double()
  let height = height.max(1).to_double()
  let alpha = (height / width).max(0.2).min(0.8)
  let radius = (width * width + height / alpha * (height / alpha)).sqrt() / 2.0
  (
    (2.0 * radius + TEXT_BLOCK_ELLIPSE_MARGIN).ceil().to_int(),
    (2.0 * radius * alpha + TEXT_BLOCK_ELLIPSE_MARGIN).ceil().to_int(),
  )
}

///|
const BUSINESS_MARK_ELLIPSE_SCALE : Double = 0.99

///|
const BUSINESS_MARK_USECASE_ANGLE : Double = 20.0 * @math.PI / 180.0

///|
const BUSINESS_MARK_ACTOR_ANGLE : Double = 21.0 * @math.PI / 64.0

///|
fn ellipse_point_at_angle(
  center_x : Int,
  center_y : Int,
  radius_x : Double,
  radius_y : Double,
  angle : Double,
) -> (Double, Double) {
  (
    center_x.to_double() + radius_x * @math.cos(angle),
    center_y.to_double() + radius_y * @math.sin(angle),
  )
}

///|
/// Mirrors EntityImageUseCase.specialBusiness: a short chord along the
/// ellipse's upper-right perimeter, leaving the display text unobscured.
fn usecase_business_mark(
  x : Int,
  y : Int,
  width : Int,
  height : Int,
) -> ((Double, Double), (Double, Double)) {
  let radius_x = width.to_double() / 2.0
  let radius_y = height.to_double() / 2.0
  let rotation = @math.PI / 4.0
  let z = radius_x *
    @math.cos(BUSINESS_MARK_USECASE_ANGLE) *
    @math.cos(rotation) -
    radius_y * @math.sin(BUSINESS_MARK_USECASE_ANGLE) * @math.sin(rotation)
  let a = radius_x * @math.cos(rotation)
  let b = radius_y * @math.sin(rotation)
  let other_cosine = (2.0 * a * z / (a * a + b * b) -
    @math.cos(BUSINESS_MARK_USECASE_ANGLE))
    .max(-1.0)
    .min(1.0)
  let other_angle = -@math.acos(other_cosine)
  let center_x = x + width / 2
  let center_y = y + height / 2
  let mark_radius_x = radius_x * BUSINESS_MARK_ELLIPSE_SCALE
  let mark_radius_y = radius_y * BUSINESS_MARK_ELLIPSE_SCALE
  (
    ellipse_point_at_angle(
      center_x,
      center_y,
      mark_radius_x,
      mark_radius_y,
      -BUSINESS_MARK_USECASE_ANGLE,
    ),
    ellipse_point_at_angle(
      center_x,
      center_y,
      mark_radius_x,
      mark_radius_y,
      -other_angle,
    ),
  )
}

///|
/// Mirrors ActorStickMan.specialBusiness with chord endpoints on the head.
fn actor_business_mark(
  center_x : Int,
  center_y : Int,
  radius : Int,
) -> ((Double, Double), (Double, Double)) {
  let radius = radius.to_double()
  (
    ellipse_point_at_angle(
      center_x,
      center_y,
      radius,
      radius,
      @math.PI / 4.0 + BUSINESS_MARK_ACTOR_ANGLE,
    ),
    ellipse_point_at_angle(
      center_x,
      center_y,
      radius,
      radius,
      @math.PI / 4.0 - BUSINESS_MARK_ACTOR_ANGLE,
    ),
  )
}

///|
fn Entity::actor_content_layout(
  self : Entity,
  text_metrics : ClassTextMetrics,
) -> (Int, Int, String?) {
  let title = @metrics.measure_text_with(
    self.display,
    text_metrics.actor_regular,
  )
  let (figure_width, figure_height) = actor_figure_geometry(
    actor_appearance(text_metrics.actor_style),
    business=self.kind is BusinessActor,
  )
  match self.stereotype {
    Some(stereotype) if !self.stereotype_hidden => {
      let display = @core.display_stereotype(stereotype)
      let stereotype_metrics = @metrics.measure_text_with(
        display,
        text_metrics.actor_italic,
      )
      (
        title.width.max(stereotype_metrics.width).max(figure_width),
        stereotype_metrics.height + figure_height + title.height,
        Some(display),
      )
    }
    _ => (title.width.max(figure_width), figure_height + title.height, None)
  }
}

///|
fn Entity::component_geometry(
  self : Entity,
  text_metrics : ClassTextMetrics,
) -> NodeGeometry {
  let title = @metrics.measure_text_with(self.display, text_metrics.regular)
  {
    width: title.width + COMPONENT_HORIZONTAL_PADDING,
    height: title.height + COMPONENT_VERTICAL_PADDING,
    shape: Box,
  }
}

///|
fn Entity::node_geometry(
  self : Entity,
  text_metrics : ClassTextMetrics,
  usecase~ : Bool,
) -> NodeGeometry {
  guard usecase else {
    return {
      width: self.width(text_metrics),
      height: self.height(text_metrics),
      shape: Box,
    }
  }
  match self.kind {
    Usecase | BusinessUsecase => {
      let (content_width, content_height, _) = self.usecase_content_layout(
        text_metrics,
      )
      let (width, height) = text_block_in_ellipse_geometry(
        content_width, content_height,
      )
      { width, height, shape: Ellipse }
    }
    Actor | BusinessActor => {
      let (width, height, _) = self.actor_content_layout(text_metrics)
      { width, height, shape: Box }
    }
    Component => self.component_geometry(text_metrics)
    _ =>
      {
        width: self.width(text_metrics),
        height: self.height(text_metrics),
        shape: Box,
      }
  }
}

///|
priv struct ClassLayout {
  columns : Int
  cell_width : Int
  cell_height : Int
  width : Int
  height : Int
  graphviz : GraphvizLayout?
}

///|
fn EntityDiagram::layout(
  self : EntityDiagram,
  text_metrics : ClassTextMetrics,
  usecase? : Bool = false,
) -> ClassLayout {
  let columns = self.entities.length().min(3).max(1)
  let rows = (self.entities.length() + columns - 1) / columns
  let mut cell_width = 220
  let mut cell_height = 180
  for entity in self.entities {
    let geometry = entity.node_geometry(text_metrics, usecase~)
    cell_width = cell_width.max(geometry.width + 24)
    cell_height = cell_height.max(geometry.height + 24)
  }
  {
    columns,
    cell_width,
    cell_height,
    width: columns * cell_width + 24,
    height: rows * cell_height + 24,
    graphviz: None,
  }
}

///|
fn ClassLayout::entity_rect(
  self : ClassLayout,
  diagram : EntityDiagram,
  index : Int,
  text_metrics : ClassTextMetrics,
  usecase? : Bool = false,
) -> (Int, Int, Int, Int) {
  match self.graphviz {
    Some(layout) => {
      let code = diagram.entities[index].qualified_code
      for node in layout.nodes {
        if node.code == code {
          return (
            (node.x - node.width / 2.0).floor().to_int(),
            (node.y - node.height / 2.0).floor().to_int(),
            node.width.ceil().to_int().max(1),
            node.height.ceil().to_int().max(1),
          )
        }
      }
    }
    None => ()
  }
  let geometry = diagram.entities[index].node_geometry(text_metrics, usecase~)
  (self.node_x(index), self.node_y(index), geometry.width, geometry.height)
}

///|
fn ClassLayout::output_width(self : ClassLayout) -> Int {
  match self.graphviz {
    Some(layout) => {
      let mut width = layout.width.ceil().to_int().max(1)
      for note in layout.notes {
        width = width.max((note.x + note.width / 2.0).ceil().to_int())
      }
      width
    }
    None => self.width
  }
}

///|
fn ClassLayout::output_height(self : ClassLayout) -> Int {
  match self.graphviz {
    Some(layout) => {
      let mut height = layout.height.ceil().to_int().max(1)
      for note in layout.notes {
        height = height.max((note.y + note.height / 2.0).ceil().to_int())
      }
      height
    }
    None => self.height
  }
}

///|
fn entity_index(diagram : EntityDiagram, code : String) -> Int? {
  for index, entity in diagram.entities {
    if entity.qualified_code == code {
      return Some(index)
    }
  }
  None
}

///|
fn usecase_relation_endpoint(
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  target_x : Int,
  target_y : Int,
) -> (Int, Int) {
  let center_x = x + width / 2
  let center_y = y + height / 2
  let horizontal = (target_x - center_x).abs() > (target_y - center_y).abs()
  if horizontal {
    if target_x < center_x {
      (x, center_y)
    } else {
      (x + width, center_y)
    }
  } else if target_y < center_y {
    (center_x, y)
  } else {
    (center_x, y + height)
  }
}

///|
fn usecase_spline_endpoint(
  entity : Entity,
  x : Int,
  y : Int,
  width : Int,
  height : Int,
  current : (Double, Double),
  toward : (Double, Double),
) -> (Double, Double) {
  let center_x = x.to_double() + width.to_double() / 2.0
  let center_y = y.to_double() + height.to_double() / 2.0
  let dx = toward.0 - center_x
  let dy = toward.1 - center_y
  guard dx != 0.0 || dy != 0.0 else { return (center_x, center_y) }
  match entity.kind {
    Usecase | BusinessUsecase => {
      let radius_x = width.to_double() / 2.0
      let radius_y = height.to_double() / 2.0
      let scale = 1.0 /
        (dx * dx / (radius_x * radius_x) + dy * dy / (radius_y * radius_y)).sqrt()
      (center_x + dx * scale, center_y + dy * scale)
    }
    Component => {
      let scale_x = width.to_double() / 2.0 / dx.abs()
      let scale_y = height.to_double() / 2.0 / dy.abs()
      let scale = if dx == 0.0 {
        scale_y
      } else if dy == 0.0 {
        scale_x
      } else {
        scale_x.min(scale_y)
      }
      (center_x + dx * scale, center_y + dy * scale)
    }
    _ => current
  }
}

///|
fn clip_usecase_spline(
  path : Array[(Double, Double)],
  left : Entity,
  left_rect : (Int, Int, Int, Int),
  right : Entity,
  right_rect : (Int, Int, Int, Int),
) -> Array[(Double, Double)] {
  guard path.length() > 1 else { return path }
  let clipped : Array[(Double, Double)] = []
  for point in path {
    clipped.push(point)
  }
  let (left_x, left_y, left_width, left_height) = left_rect
  let (right_x, right_y, right_width, right_height) = right_rect
  let original_start = clipped[0]
  let original_end = clipped[clipped.length() - 1]
  let clipped_start = usecase_spline_endpoint(
    left,
    left_x,
    left_y,
    left_width,
    left_height,
    clipped[0],
    clipped[1],
  )
  clipped[0] = clipped_start
  let last = clipped.length() - 1
  let clipped_end = usecase_spline_endpoint(
    right,
    right_x,
    right_y,
    right_width,
    right_height,
    clipped[last],
    clipped[last - 1],
  )
  clipped[last] = clipped_end
  if (clipped.length() - 1) % 3 == 0 {
    clipped[1] = (
      clipped_start.0 + clipped[1].0 - original_start.0,
      clipped_start.1 + clipped[1].1 - original_start.1,
    )
    clipped[last - 1] = (
      clipped_end.0 - (original_end.0 - clipped[last - 1].0),
      clipped_end.1 - (original_end.1 - clipped[last - 1].1),
    )
  }
  clipped
}

///|
fn relation_marker(end : RelationEnd) -> String? {
  match end {
    Extension | Redefines | DefinedBy => Some("triangle")
    CompositionEnd => Some("diamond")
    AggregationEnd => Some("diamond-open")
    Arrow | TriangleArrow | HalfArrowUp | HalfArrowDown => Some("arrow")
    NotNavigable | DoubleLine => Some("bar")
    CircleEnd | CircleConnect | CircleLine | CircleCrowfoot => Some("circle")
    FilledCircle => Some("circle-filled")
    Square => Some("square")
    Plus => Some("plus")
    Crowfoot | LineCrowfoot => Some("crowfoot")
    _ => None
  }
}

///|
fn relation_label_position(
  layout : ClassLayout,
  relation_index : Int,
  fallback : (Int, Int),
) -> (Double, Double) {
  match layout.graphviz {
    Some(graphviz) =>
      for edge in graphviz.edges {
        if edge.relation_index == relation_index {
          return edge.label.unwrap_or(
            (fallback.0.to_double(), fallback.1.to_double()),
          )
        }
      }
    None => ()
  }
  (fallback.0.to_double(), fallback.1.to_double())
}

///|
/// Graphviz spline points use the SVG-compatible 3n+1 cubic Bezier form.
fn append_spline_path(
  output : StringBuilder,
  points : Array[(Double, Double)],
) -> Unit {
  output <+
    $|M \{points[0].0} \{points[0].1}
  if (points.length() - 1) % 3 == 0 {
    let mut index = 1
    while index < points.length() {
      output <+
        $| C \{points[index].0} \{points[index].1} \{points[index + 1].0} \{points[index + 1].1} \{points[index + 2].0} \{points[index + 2].1}
      index += 3
    }
  } else {
    for index in 1..<points.length() {
      output <+
        $| L \{points[index].0} \{points[index].1}
    }
  }
}

///|
fn append_packages(
  output : StringBuilder,
  diagram : EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  match layout.graphviz {
    Some(graphviz) =>
      for package_layout in graphviz.packages {
        guard package_layout.package_index < diagram.packages.length() else {
          continue
        }
        let group = diagram.packages[package_layout.package_index]
        let fill = @core.svg_color(
          group.color,
          diagram.style.package_background_color(),
        )
        let tab_width = @metrics.measure_text_with(
            group.display,
            text_metrics.regular,
          ).width.to_double() +
          18.0
        let x = package_layout.x
        let y = package_layout.y
        let right = x + package_layout.width
        let bottom = y + package_layout.height
        let border_color = diagram.style.package_border_color()
        output <+
          $|<g class="package">
          $|<path d="M \{x + 2.5} \{y} L \{x + tab_width - 9.0} \{y} Q \{x + tab_width - 6.5} \{y} \{x + tab_width - 5.5} \{y + 2.5} L \{x + tab_width + 1.5} \{y + 22.0} L \{right - 2.5} \{y + 22.0} Q \{right} \{y + 22.0} \{right} \{y + 24.5} L \{right} \{bottom - 2.5} Q \{right} \{bottom} \{right - 2.5} \{bottom} L \{x + 2.5} \{bottom} Q \{x} \{bottom} \{x} \{bottom - 2.5} L \{x} \{y + 2.5} Q \{x} \{y} \{x + 2.5} \{y}" fill="\{fill}" style="stroke:\{border_color}"/>
          $|<line x1="\{x}" y1="\{y + 22.0}" x2="\{x + tab_width + 1.5}" y2="\{y + 22.0}" style="stroke:\{border_color}"/>
          $|<text x="\{x + 4.0}" y="\{y + 16.0}" class="package-title">\{@core.xml_escape(group.display)}</text></g>
      }
    None => ()
  }
}

///|
fn append_notes(
  output : StringBuilder,
  diagram : EntityDiagram,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  match layout.graphviz {
    Some(graphviz) =>
      for note_layout in graphviz.notes {
        guard note_layout.note_index < diagram.notes.length() else { continue }
        let note = diagram.notes[note_layout.note_index]
        let x = note_layout.x - note_layout.width / 2.0
        let y = note_layout.y - note_layout.height / 2.0
        let fill = @core.svg_color(
          note.color,
          diagram.style.note_background_color(),
        )
        let mut linked_to_target = false
        if note.target_kind is EntityNote || note.target_kind is MemberTip {
          for node in graphviz.nodes {
            guard node.code == note.target else { continue }
            let target_left = node.x - node.width / 2.0
            let target_right = node.x + node.width / 2.0
            let target_top = node.y - node.height / 2.0
            let target_bottom = node.y + node.height / 2.0
            let corner = 12.0
            let path = match note.position {
              Right =>
                (
                  $|M \{x} \{y} L \{x} \{node.y - 4.0} L \{target_right} \{node.y} L \{x} \{node.y + 4.0} L \{x} \{y + note_layout.height} L \{x + note_layout.width} \{y + note_layout.height} L \{x + note_layout.width} \{y + corner} L \{x + note_layout.width - corner} \{y} Z
                )
              Left =>
                (
                  $|M \{x} \{y} L \{x + note_layout.width - corner} \{y} L \{x + note_layout.width} \{y + corner} L \{x + note_layout.width} \{node.y - 4.0} L \{target_left} \{node.y} L \{x + note_layout.width} \{node.y + 4.0} L \{x + note_layout.width} \{y + note_layout.height} L \{x} \{y + note_layout.height} Z
                )
              Top =>
                (
                  $|M \{x} \{y} L \{x + note_layout.width - corner} \{y} L \{x + note_layout.width} \{y + corner} L \{x + note_layout.width} \{y + note_layout.height} L \{node.x + 4.0} \{y + note_layout.height} L \{node.x} \{target_top} L \{node.x - 4.0} \{y + note_layout.height} L \{x} \{y + note_layout.height} Z
                )
              Bottom =>
                (
                  $|M \{x} \{y} L \{node.x - 4.0} \{y} L \{node.x} \{target_bottom} L \{node.x + 4.0} \{y} L \{x + note_layout.width - corner} \{y} L \{x + note_layout.width} \{y + corner} L \{x + note_layout.width} \{y + note_layout.height} L \{x} \{y + note_layout.height} Z
                )
            }
            output <+
              $|<g class="class-note" style="stroke:\{diagram.style.note_border_color()}"><path d="\{path}" class="note-opale-link" fill="\{fill}"/><path d="M \{x + note_layout.width - 12.0} \{y} L \{x + note_layout.width} \{y + 12.0} L \{x + note_layout.width - 12.0} \{y + 12.0} Z" fill="\{fill}"/></g>
            linked_to_target = true
          }
        }
        if !linked_to_target {
          output <+
            $|<g class="class-note" style="stroke:\{diagram.style.note_border_color()}"><rect x="\{x}" y="\{y}" width="\{note_layout.width}" height="\{note_layout.height}" fill="\{fill}"/><path d="M \{x + note_layout.width - 12.0} \{y} L \{x + note_layout.width} \{y + 12.0} L \{x + note_layout.width - 12.0} \{y + 12.0} Z"/></g>
        }
        for line_index, line in note.text.split("\n") {
          output <+
            $|<text x="\{x + NOTE_LEFT_PADDING.to_double()}" y="\{y + NOTE_VERTICAL_PADDING.to_double() + text_metrics.note.ascent.to_double() + line_index.to_double() * text_metrics.note.line_height.to_double()}" class="note-text">\{@core.xml_escape(line.to_owned())}</text>
        }
      }
    None => ()
  }
}

///|
fn ClassLayout::node_x(self : ClassLayout, index : Int) -> Int {
  24 + index % self.columns * self.cell_width
}

///|
fn ClassLayout::node_y(self : ClassLayout, index : Int) -> Int {
  24 + index / self.columns * self.cell_height
}

///|
fn append_relation(
  output : StringBuilder,
  diagram : EntityDiagram,
  relation_index : Int,
  relation : Relation,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
  usecase~ : Bool,
) -> Unit {
  guard entity_index(diagram, relation.left) is Some(left_index) else { return }
  guard entity_index(diagram, relation.right) is Some(right_index) else {
    return
  }
  let left = diagram.entities[left_index]
  let right = diagram.entities[right_index]
  guard !left.is_removed && !right.is_removed else { return }
  let (left_x, left_y, left_width, left_height) = layout.entity_rect(
    diagram,
    left_index,
    text_metrics,
    usecase~,
  )
  let (right_x, right_y, right_width, right_height) = layout.entity_rect(
    diagram,
    right_index,
    text_metrics,
    usecase~,
  )
  let left_center = (left_x + left_width / 2, left_y + left_height / 2)
  let right_center = (right_x + right_width / 2, right_y + right_height / 2)
  let (x1, y1) = if usecase {
    usecase_relation_endpoint(
      left_x,
      left_y,
      left_width,
      left_height,
      right_center.0,
      right_center.1,
    )
  } else {
    left_center
  }
  let (x2, y2) = if usecase {
    usecase_relation_endpoint(
      right_x,
      right_y,
      right_width,
      right_height,
      left_center.0,
      left_center.1,
    )
  } else {
    right_center
  }
  let dash = if relation.dotted { " stroke-dasharray=\"6 4\"" } else { "" }
  let relation_style = match relation.line_style {
    Some("dashed") => "stroke-dasharray:6 4"
    Some("dotted") => "stroke-dasharray:2 3"
    Some("bold") => "stroke-width:2.5"
    _ => ""
  }
  let relation_color = @core.svg_color(
    relation.color,
    diagram.style.diagram_line_color(),
  )
  let label_font_size = if usecase {
    diagram.style.arrow_font_size(fallback=USECASE_RELATION_LABEL_FONT_SIZE)
  } else {
    12
  }
  let label_font_family = if usecase {
    diagram.style.arrow_font_family()
  } else {
    @core.font_family(diagram.style)
  }
  let label_color = if usecase {
    diagram.style.arrow_font_color()
  } else {
    diagram.style.diagram_text_color()
  }
  let style =
    $| style="stroke:\{relation_color};\{relation_style}"
  let marker_start = match relation_marker(relation.left_end) {
    Some(marker) => " marker-start=\"url(#\{marker})\""
    None => ""
  }
  let marker_end = match relation_marker(relation.right_end) {
    Some(marker) => " marker-end=\"url(#\{marker})\""
    None => ""
  }
  let mut drew_spline = false
  match layout.graphviz {
    Some(graphviz) if !(usecase &&
      relation.dotted &&
      relation.direction is Automatic) =>
      for edge in graphviz.edges {
        if edge.relation_index == relation_index {
          for path in edge.paths {
            guard path.length() > 1 else { continue }
            drew_spline = true
            let clipped = if usecase {
              clip_usecase_spline(
                path,
                left,
                (left_x, left_y, left_width, left_height),
                right,
                (right_x, right_y, right_width, right_height),
              )
            } else {
              path
            }
            output <+
              $|<path d="
            append_spline_path(output, clipped)
            output <+
              $|" class="relation"\{style}\{dash}\{marker_start}\{marker_end}/>
          }
        }
      }
    _ => ()
  }
  if drew_spline {
    match relation.label {
      Some(label) =>
        output <+
          $|<text x="\{relation_label_position(layout, relation_index, ((x1 + x2) / 2, (y1 + y2) / 2)).0}" y="\{relation_label_position(layout, relation_index, ((x1 + x2) / 2, (y1 + y2) / 2)).1 - 5.0}" class="relation-label" fill="\{label_color}" font-family="\{@core.xml_escape(label_font_family)}" font-size="\{label_font_size}">\{@core.xml_escape(if usecase { @core.display_stereotype(label) } else { label })}</text>
      None => ()
    }
  } else {
    output <+
      $|<line x1="\{x1}" y1="\{y1}" x2="\{x2}" y2="\{y2}" class="relation"\{style}\{dash}\{marker_start}\{marker_end}/>
    match relation.label {
      Some(label) =>
        output <+
          $|<text x="\{(x1 + x2) / 2}" y="\{(y1 + y2) / 2 - 5}" class="relation-label" fill="\{label_color}" font-family="\{@core.xml_escape(label_font_family)}" font-size="\{label_font_size}">\{@core.xml_escape(if usecase { @core.display_stereotype(label) } else { label })}</text>
      None => ()
    }
  }
  match relation.left_cardinality {
    Some(text) =>
      output <+
        $|<text x="\{x1 - 8}" y="\{y1 - 6}" class="relation-end-label">\{@core.xml_escape(text)}</text>
    None => ()
  }
  match relation.right_cardinality {
    Some(text) =>
      output <+
        $|<text x="\{x2 + 8}" y="\{y2 - 6}" class="relation-end-label">\{@core.xml_escape(text)}</text>
    None => ()
  }
  match relation.left_role {
    Some(text) =>
      output <+
        $|<text x="\{x1 - 8}" y="\{y1 + 13}" class="relation-end-label">\{@core.xml_escape(text)}</text>
    None => ()
  }
  match relation.right_role {
    Some(text) =>
      output <+
        $|<text x="\{x2 + 8}" y="\{y2 + 13}" class="relation-end-label">\{@core.xml_escape(text)}</text>
    None => ()
  }
}

///|
fn append_entity(
  output : StringBuilder,
  diagram : EntityDiagram,
  entity : Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
  usecase~ : Bool,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(
    diagram,
    index,
    text_metrics,
    usecase~,
  )
  let header = entity.header_layout(text_metrics)
  let body = entity.body_layout(text_metrics)
  let row_height = text_metrics.row_height()
  let fill = @core.svg_color(
    entity.color,
    diagram.style.class_background_color(),
  )
  let stroke = @core.svg_color(
    entity.line_color,
    diagram.style.class_border_color(),
  )
  let stroke_style = match entity.line_style {
    Some("dashed") => "stroke-dasharray:6 4"
    Some("dotted") => "stroke-dasharray:2 3"
    Some("bold") => "stroke-width:2.5"
    _ => "stroke-width:1.2"
  }
  let line_attributes =
    $| style="stroke:\{stroke};\{stroke_style}"
  let title_style = match entity.kind {
    AbstractClass | Interface => " font-style=\"italic\""
    _ => ""
  }
  let (spot_text, spot_fill) = entity.spot()
  output <+
    $|<g class="class-node" data-code="\{@core.xml_escape(entity.qualified_code)}"><rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" fill="\{fill}"\{line_attributes}/><circle cx="\{x + 15}" cy="\{y + 16}" r="11" fill="\{spot_fill}" stroke="#181818" stroke-width="1"/><text x="\{x + 15}" y="\{y + 20}" class="class-spot">\{spot_text}</text><text x="\{x + 29}" y="\{y + header.height - 11}" class="class-title"\{title_style}>\{@core.xml_escape(entity.display)}</text>
  let mut section_y = y + header.height
  for section_index, section in [body.fields, body.methods] {
    let section_height = if section_index == 0 {
      body.fields_height
    } else {
      body.methods_height
    }
    output <+
      $|<line x1="\{x}" y1="\{section_y}" x2="\{x + width}" y2="\{section_y}"\{line_attributes}/>
    for member_index, entry in section {
      let member_y = section_y + (member_index + 1) * row_height + 1
      output <+
        $|<g class="member-icon">\{entry.visibility_icon(x + 5, member_y)}</g><text x="\{x + 20}" y="\{member_y}" class="member">\{@core.xml_escape(entry.display_without_visibility())}</text>
    }
    section_y += section_height
  }
  output.write_string("</g>\n")
}

///|
fn append_usecase_entity(
  output : StringBuilder,
  diagram : EntityDiagram,
  entity : Entity,
  index : Int,
  text_metrics : ClassTextMetrics,
  layout : ClassLayout,
) -> Unit {
  guard !entity.is_hidden && !entity.is_removed else { return }
  let (x, y, width, height) = layout.entity_rect(
    diagram,
    index,
    text_metrics,
    usecase=true,
  )
  let (background, border) = match entity.kind {
    Usecase | BusinessUsecase =>
      (
        diagram.style.usecase_background_color(),
        diagram.style.usecase_border_color(),
      )
    Actor | BusinessActor =>
      (
        diagram.style.actor_background_color(),
        diagram.style.actor_border_color(),
      )
    _ =>
      (
        diagram.style.class_background_color(),
        diagram.style.class_border_color(),
      )
  }
  let fill = @core.svg_color(entity.color, background)
  let stroke = @core.svg_color(entity.line_color, border)
  let text_color = match entity.kind {
    Usecase | BusinessUsecase => diagram.style.usecase_font_color()
    Actor | BusinessActor => diagram.style.actor_font_color()
    _ => diagram.style.diagram_text_color()
  }
  let line_attributes = match entity.line_style {
    Some("dashed") => "stroke-dasharray:6 4"
    Some("dotted") => "stroke-dasharray:2 3"
    Some("bold") => "stroke-width:2.5"
    _ => "stroke-width:1.2"
  }
  match entity.kind {
    Usecase | BusinessUsecase | Actor | BusinessActor | Component => ()
    _ => {
      append_entity(
        output,
        diagram,
        entity,
        index,
        text_metrics,
        layout,
        usecase=true,
      )
      return
    }
  }
  let node_class = match entity.kind {
    Usecase | BusinessUsecase => "usecase-node"
    Actor | BusinessActor => "actor-node"
    Component => "component-node"
    _ => ""
  }
  output <+
    $|<g class="\{node_class}" data-code="\{@core.xml_escape(entity.qualified_code)}">
  match entity.url {
    Some(url) =>
      output <+
        $|<a href="\{@core.xml_escape(url)}">
    None => ()
  }
  match entity.kind {
    Usecase | BusinessUsecase => {
      let (_, content_height, stereotype) = entity.usecase_content_layout(
        text_metrics,
      )
      // TextBlockInEllipse centers the text block, then applies dy - 2.
      // The ellipse itself has grown by 6px, so SVG text needs a +2px
      // top offset before converting its font ascent to a baseline.
      let content_top = y + height / 2 - content_height / 2 + 2
      let title_metrics = @metrics.measure_text_with(
        entity.display,
        text_metrics.usecase_regular,
      )
      output <+
        $|<ellipse cx="\{x + width / 2}" cy="\{y + height / 2}" rx="\{width / 2}" ry="\{height / 2}" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
      match stereotype {
        Some(value) => {
          let metrics = @metrics.measure_text_with(
            value,
            text_metrics.usecase_italic,
          )
          output <+
            $|<text x="\{x + width / 2}" y="\{content_top + metrics.baseline}" class="usecase-stereotype" fill="\{text_color}" font-family="\{@core.xml_escape(text_metrics.usecase_font_family)}" font-size="\{text_metrics.usecase_italic.font_size}">\{@core.xml_escape(value)}</text>
        }
        None => ()
      }
      let title_y = match stereotype {
        Some(value) =>
          content_top +
          @metrics.measure_text_with(value, text_metrics.usecase_italic).height +
          title_metrics.baseline
        None => content_top + title_metrics.baseline
      }
      output <+
        $|<text x="\{x + width / 2}" y="\{title_y}" class="usecase-title" fill="\{text_color}" font-family="\{@core.xml_escape(text_metrics.usecase_font_family)}" font-size="\{text_metrics.usecase_regular.font_size}">\{@core.xml_escape(entity.display)}</text>
      if entity.kind is BusinessUsecase {
        let (mark_start, mark_end) = usecase_business_mark(x, y, width, height)
        output <+
          $|<path d="M \{mark_start.0} \{mark_start.1} L \{mark_end.0} \{mark_end.1}" class="usecase-business-mark" stroke="\{stroke}" style="\{line_attributes}"/>
      }
    }
    Actor | BusinessActor => {
      let center_x = x + width / 2
      let title = @metrics.measure_text_with(
        entity.display,
        text_metrics.actor_regular,
      )
      let (_, _, stereotype) = entity.actor_content_layout(text_metrics)
      let appearance = actor_appearance(text_metrics.actor_style)
      let (figure_width, figure_height) = actor_figure_geometry(
        appearance,
        business=entity.kind is BusinessActor,
      )
      let stereotype_height = match stereotype {
        Some(value) =>
          @metrics.measure_text_with(value, text_metrics.actor_italic).height
        None => 0
      }
      let figure_top = y + stereotype_height
      let label_y = figure_top + figure_height + title.baseline
      match stereotype {
        Some(value) => {
          let metrics = @metrics.measure_text_with(
            value,
            text_metrics.actor_italic,
          )
          output <+
            $|<text x="\{center_x}" y="\{y + metrics.baseline}" class="usecase-stereotype" fill="\{text_color}" font-family="\{@core.xml_escape(text_metrics.actor_font_family)}" font-size="\{text_metrics.actor_italic.font_size}">\{@core.xml_escape(value)}</text>
        }
        None => ()
      }
      if entity.kind is Actor {
        match appearance {
          Awesome =>
            output <+
              $|<circle cx="\{center_x}" cy="\{figure_top + 17}" r="16" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><path d="M \{center_x - 27} \{figure_top + 50} Q \{center_x} \{figure_top + 38} \{center_x + 27} \{figure_top + 50} V \{figure_top + 62} Q \{center_x + 27} \{figure_top + 62} \{center_x + 19} \{figure_top + 62} H \{center_x - 19} Q \{center_x - 27} \{figure_top + 62} \{center_x - 27} \{figure_top + 54} Z" class="actor-awesome-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
          Hollow =>
            output <+
              $|<circle cx="\{center_x}" cy="\{figure_top + 5}" r="4" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><path d="M \{center_x - 13} \{figure_top + 12} H \{center_x + 13} V \{figure_top + 17} H \{center_x + 3} V \{figure_top + 27} L \{center_x + 9} \{figure_top + 35} H \{center_x + 3} L \{center_x} \{figure_top + 30} L \{center_x - 3} \{figure_top + 35} H \{center_x - 9} L \{center_x - 3} \{figure_top + 27} V \{figure_top + 17} H \{center_x - 13} Z" class="actor-hollow-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/>
          Stickman => ()
        }
      }
      if entity.kind is BusinessActor || appearance is Stickman {
        output <+
          $|<circle cx="\{center_x}" cy="\{figure_top + 9}" r="8" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><path d="M \{center_x} \{figure_top + 17} L \{center_x} \{figure_top + 43} M \{center_x - 13} \{figure_top + 27} L \{center_x + 13} \{figure_top + 27} M \{center_x} \{figure_top + 43} L \{center_x - 13} \{figure_top + figure_height} M \{center_x} \{figure_top + 43} L \{center_x + 13} \{figure_top + figure_height}" fill="none" stroke="\{stroke}" style="\{line_attributes}"/>
      }
      output <+
        $|<text x="\{center_x}" y="\{label_y}" class="usecase-title" fill="\{text_color}" font-family="\{@core.xml_escape(text_metrics.actor_font_family)}" font-size="\{text_metrics.actor_regular.font_size}">\{@core.xml_escape(entity.display)}</text>
      if entity.kind is BusinessActor && figure_width == ACTOR_FIGURE_WIDTH {
        let (mark_start, mark_end) = actor_business_mark(
          center_x,
          figure_top + 9,
          8,
        )
        output <+
          $|<path d="M \{mark_start.0} \{mark_start.1} L \{mark_end.0} \{mark_end.1}" class="actor-business-mark" stroke="\{stroke}" style="\{line_attributes}"/>
      }
    }
    Component => {
      let title = @metrics.measure_text_with(
        entity.display,
        text_metrics.regular,
      )
      let tab_x = x + width - COMPONENT_TAB_WIDTH - COMPONENT_TAB_INSET
      let tab_y = y + COMPONENT_TAB_INSET
      let mark_x = tab_x - COMPONENT_TAB_MARK_LEFT_OFFSET
      let first_mark_y = tab_y + COMPONENT_TAB_MARK_TOP_OFFSET
      let second_mark_y = first_mark_y + COMPONENT_TAB_MARK_GAP
      output <+
        $|<rect x="\{x}" y="\{y}" width="\{width}" height="\{height}" rx="2" ry="2" class="component-body" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{tab_x}" y="\{tab_y}" width="\{COMPONENT_TAB_WIDTH}" height="\{COMPONENT_TAB_HEIGHT}" class="component-tab" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{mark_x}" y="\{first_mark_y}" width="\{COMPONENT_TAB_MARK_WIDTH}" height="\{COMPONENT_TAB_MARK_HEIGHT}" class="component-tab-mark" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><rect x="\{mark_x}" y="\{second_mark_y}" width="\{COMPONENT_TAB_MARK_WIDTH}" height="\{COMPONENT_TAB_MARK_HEIGHT}" class="component-tab-mark" fill="\{fill}" stroke="\{stroke}" style="\{line_attributes}"/><text x="\{x + width / 2}" y="\{y + (height + title.height) / 2 - 2}" class="usecase-title" fill="\{text_color}">\{@core.xml_escape(entity.display)}</text>
    }
    _ => ()
  }
  match entity.url {
    Some(_) => output.write_string("</a>")
    None => ()
  }
  output.write_string("</g>\n")
}

///|
fn EntityDiagram::render_svg_with_mode(
  self : EntityDiagram,
  usecase~ : Bool,
) -> String {
  let background = self.style.canvas_color()
  let font_family = @core.font_family(self.style)
  let font_size = if self.style.font_size is None {
    "14px"
  } else {
    @core.font_size(self.style)
  }
  let line_color = self.style.diagram_line_color()
  let text_metrics = ClassTextMetrics::new(self.style)
  let fallback_layout = self.layout(text_metrics, usecase~)
  let graphviz = Some(self.graphviz_layout(text_metrics, usecase~)) catch {
    _ => None
  }
  let layout = match graphviz {
    Some(graphviz) =>
      {
        columns: fallback_layout.columns,
        cell_width: fallback_layout.cell_width,
        cell_height: fallback_layout.cell_height,
        width: graphviz.width.ceil().to_int().max(1),
        height: graphviz.height.ceil().to_int().max(1),
        graphviz: Some(graphviz),
      }
    None => fallback_layout
  }
  let content_width = layout.output_width()
  let content_height = layout.output_height()
  let output_width = content_width + 2 * SVG_CANVAS_MARGIN
  let output_height = content_height + 2 * SVG_CANVAS_MARGIN
  let output = StringBuilder()
  let diagram_label = if usecase { "Use case diagram" } else { "Class diagram" }
  output <+
    $|<svg xmlns="http://www.w3.org/2000/svg" width="\{output_width}" height="\{output_height}" viewBox="\{-SVG_CANVAS_MARGIN} \{-SVG_CANVAS_MARGIN} \{output_width} \{output_height}" role="img" aria-label="\{diagram_label}">
  let defs_relations =
    #|<defs>
    #|<marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z"/></marker>
    #|<marker id="triangle" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="9" markerHeight="9" orient="auto-start-reverse"><path d="M 0 0 L 10 5 L 0 10 z" fill="white"/></marker>
    #|<marker id="diamond" viewBox="0 0 12 10" refX="1" refY="5" markerWidth="10" markerHeight="8" orient="auto-start-reverse"><path d="M 0 5 L 6 0 L 12 5 L 6 10 z"/></marker>
    #|<marker id="diamond-open" viewBox="0 0 12 10" refX="1" refY="5" markerWidth="10" markerHeight="8" orient="auto-start-reverse"><path d="M 0 5 L 6 0 L 12 5 L 6 10 z" fill="white"/></marker>
    #|</defs>
  output.write_string(defs_relations)
  let relations_style =
    $|<style>
    $|svg{font-family:\{font_family};font-size:\{font_size};background:\{background}}
    $|.class-node rect,.class-node line{stroke:#181818;stroke-width:1.2}
    $|.relation{stroke:\{line_color};stroke-width:1.2}
    $|.class-node line,.relation{fill:none}
    $|.class-title{fill:#181818}
    $|.class-spot{text-anchor:middle;font-size:12px;font-weight:bold;fill:#181818}
    $|.usecase-title{fill:#181818;text-anchor:middle}
    $|.usecase-stereotype{fill:#181818;text-anchor:middle;font-style:italic}
    $|.member,.relation-label{fill:#181818}
    $|.relation-label{text-anchor:middle;font-size:\{if usecase { USECASE_RELATION_LABEL_FONT_SIZE } else { 12 }}px}
    $|</style>
  output.write_string(relations_style)
  let style_markers =
    #|<style>marker path,marker circle,marker rect{stroke:#181818;stroke-width:1}</style>
  output.write_string(style_markers)
  let style_note =
    $|<style>.package path,.package line{stroke:#181818;stroke-width:1.2}.package-title{fill:#181818;font-weight:bold}.class-note rect,.class-note path{stroke:#181818;stroke-width:1.2}.note-text{fill:#181818;font-size:\{NOTE_FONT_SIZE}px}</style>
  output.write_string(style_note)
  let defs_marks =
    #|<defs>
    #|<marker id="bar" viewBox="0 0 8 10" refX="4" refY="5" markerWidth="6" markerHeight="8" orient="auto-start-reverse"><path d="M 4 0 L 4 10"/></marker>
    #|<marker id="circle" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><circle cx="5" cy="5" r="4" fill="white"/></marker>
    #|<marker id="circle-filled" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><circle cx="5" cy="5" r="4"/></marker>
    #|<marker id="square" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><rect x="1" y="1" width="8" height="8" fill="white"/></marker>
    #|<marker id="plus" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M 5 1 L 5 9 M 1 5 L 9 5"/></marker>
    #|<marker id="crowfoot" viewBox="0 0 12 12" refX="2" refY="6" markerWidth="9" markerHeight="9" orient="auto-start-reverse"><path d="M 2 6 L 11 1 M 2 6 L 11 6 M 2 6 L 11 11"/></marker>
    #|</defs>
  output.write_string(defs_marks)
  append_packages(output, self, text_metrics, layout)
  if usecase {
    for index, entity in self.entities {
      append_usecase_entity(output, self, entity, index, text_metrics, layout)
    }
    for relation_index, relation in self.relations {
      append_relation(
        output,
        self,
        relation_index,
        relation,
        text_metrics,
        layout,
        usecase=true,
      )
    }
  } else {
    for relation_index, relation in self.relations {
      append_relation(
        output,
        self,
        relation_index,
        relation,
        text_metrics,
        layout,
        usecase=false,
      )
    }
    for index, entity in self.entities {
      append_entity(
        output,
        self,
        entity,
        index,
        text_metrics,
        layout,
        usecase=false,
      )
    }
  }
  append_notes(output, self, text_metrics, layout)
  output.write_string("</svg>\n")
  output.to_string()
}

///|
/// Render the parsed class graph to a standalone SVG.
///
/// Node placement is deterministic so parsing and rendering can be used without
/// an external process. The graph-layout adapter will replace these coordinates
/// with Graphviz positions while retaining this entity and relation painter.
pub fn EntityDiagram::render_svg(self : EntityDiagram) -> String {
  self.render_svg_with_mode(usecase=false)
}

///|
/// Render the parsed use-case graph with use-case and actor symbols.
pub fn EntityDiagram::render_usecase_svg(self : EntityDiagram) -> String {
  self.render_svg_with_mode(usecase=true)
}

///|
test "use-case layout uses ellipse and actor geometry before Graphviz" {
  let diagram = parse("@startuml\n:Customer: --> (Place order)\n@enduml")
  let metrics = ClassTextMetrics::new(diagram.style)
  let actor = diagram.entity("Customer").unwrap()
  let usecase = diagram.entity("Place order").unwrap()
  let actor_geometry = actor.node_geometry(metrics, usecase=true)
  let usecase_geometry = usecase.node_geometry(metrics, usecase=true)
  @test.assert_eq(actor_geometry.shape, Box)
  @test.assert_eq(usecase_geometry.shape, Ellipse)
  @test.assert_eq(actor_geometry.height > usecase_geometry.height, true)
  @test.assert_eq(usecase_geometry.width > usecase_geometry.height, true)
}

///|
test "use-case ellipse geometry grows with its text footprint" {
  let compact = text_block_in_ellipse_geometry(20, 10)
  let wide = text_block_in_ellipse_geometry(80, 10)
  let tall = text_block_in_ellipse_geometry(20, 40)
  @test.assert_eq(wide.0 > compact.0, true)
  @test.assert_eq(tall.1 > compact.1, true)
}

///|
test "use-case SVG keeps actor labels below their figure" {
  let svg = parse("@startuml\n:Customer: --> (Place order)\n@enduml").render_usecase_svg()
  @test.assert_eq(svg.contains("class=\"actor-node\""), true)
  @test.assert_eq(svg.contains("class=\"usecase-node\""), true)
  @test.assert_eq(svg.contains("aria-label=\"Use case diagram\""), true)
}

///|
test "dependency links preserve their dot length for Graphviz ranks" {
  let diagram = parse("@startuml\n(Place order) .> (Approve order)\n@enduml")
  let relation = diagram.relations[0]
  @test.assert_eq(relation.dotted, true)
  @test.assert_eq(relation.graphviz_minlen(), 0)
}

///|
test "use-case SVG preserves dotted dependencies and business markers" {
  let svg = parse(
    "@startuml\nactor/ Partner\nusecase/ \"Approve order\" as Approve <<business>>\nPartner --> Approve\nApprove .> (Confirm)\n@enduml",
  ).render_usecase_svg()
  @test.assert_eq(svg.contains("stroke-dasharray=\"6 4\""), true)
  @test.assert_eq(svg.contains("class=\"actor-business-mark\""), true)
  @test.assert_eq(svg.contains("class=\"usecase-business-mark\""), true)
  @test.assert_eq(svg.contains("class=\"usecase-stereotype\""), true)
}

///|
test "actor stereotypes participate in use-case node geometry" {
  let plain = parse("@startuml\nactor Customer\n@enduml")
  let stereotyped = parse("@startuml\nactor Customer <<external>>\n@enduml")
  let plain_metrics = ClassTextMetrics::new(plain.style)
  let stereotyped_metrics = ClassTextMetrics::new(stereotyped.style)
  let plain_geometry = plain.entities[0].node_geometry(
    plain_metrics,
    usecase=true,
  )
  let stereotyped_geometry = stereotyped.entities[0].node_geometry(
    stereotyped_metrics,
    usecase=true,
  )
  let svg = stereotyped.render_usecase_svg()
  @test.assert_eq(stereotyped_geometry.height > plain_geometry.height, true)
  @test.assert_eq(
    svg.contains(">\{@core.xml_escape("«external»")}</text>"),
    true,
  )
}

///|
test "use-case labels render stereotypes with PlantUML guillemets" {
  let svg = parse(
    "@startuml\nusecase Review <<business>>\nReview .> (Approve) : <<include>>\n@enduml",
  ).render_usecase_svg()
  @test.assert_eq(svg.contains("«business»"), true)
  @test.assert_eq(svg.contains("«include»"), true)
}

///|
test "actor styles select matching geometry and SVG symbols" {
  let stickman = parse("@startuml\nactor A\n@enduml")
  let awesome = parse(
    "@startuml\nskinparam actorStyle awesome\nactor A\n@enduml",
  )
  let hollow = parse("@startuml\nskinparam actorStyle hollow\nactor A\n@enduml")
  let stickman_geometry = stickman.entities[0].node_geometry(
    ClassTextMetrics::new(stickman.style),
    usecase=true,
  )
  let awesome_geometry = awesome.entities[0].node_geometry(
    ClassTextMetrics::new(awesome.style),
    usecase=true,
  )
  let hollow_geometry = hollow.entities[0].node_geometry(
    ClassTextMetrics::new(hollow.style),
    usecase=true,
  )
  @test.assert_eq(awesome.style.actor_style(), "awesome")
  @test.assert_eq(awesome_geometry.width > stickman_geometry.width, true)
  @test.assert_eq(hollow_geometry.height < stickman_geometry.height, true)
  @test.assert_eq(
    awesome.render_usecase_svg().contains("class=\"actor-awesome-body\""),
    true,
  )
  @test.assert_eq(
    hollow.render_usecase_svg().contains("class=\"actor-hollow-body\""),
    true,
  )
}

///|
test "mixed use-case components use component geometry and symbols" {
  let diagram = parse(
    "@startuml\nallowmixing\nusecase Pay\ncomponent Provider\nPay --> Provider\n@enduml",
  )
  let metrics = ClassTextMetrics::new(diagram.style)
  let component = diagram.entity("Provider").unwrap()
  let geometry = component.node_geometry(metrics, usecase=true)
  let svg = diagram.render_usecase_svg()
  @test.assert_eq(component.kind, Component)
  @test.assert_eq(geometry.width > component.width(metrics), true)
  @test.assert_eq(svg.contains("class=\"component-node\""), true)
  @test.assert_eq(svg.contains("class=\"component-tab\""), true)
}

///|
test "use-case packages render PlantUML-style bold titles" {
  let svg = parse(
    "@startuml\npackage System {\n  actor User\n  usecase Run\n  User --> Run\n}\n@enduml",
  ).render_usecase_svg()
  @test.assert_eq(
    svg.contains(".package-title{fill:#181818;font-weight:bold}"),
    true,
  )
}

///|
test "use-case package layout preserves PlantUML sibling ordering" {
  let diagram = parse(
    (
      #|@startuml
      #|left to right direction
      #|package Fulfillment {
      #|  :Customer:
      #|  (Place order)
      #|  (Track delivery)
      #|  :Customer: --> (Place order)
      #|  :Customer: --> (Track delivery)
      #|}
      #|@enduml
    ),
  )
  let layout = diagram.graphviz_layout(
    ClassTextMetrics::new(diagram.style),
    usecase=true,
  )
  let mut place_y : Double? = None
  let mut track_y : Double? = None
  for node in layout.nodes {
    if node.code == "Fulfillment.Place order" {
      place_y = Some(node.y)
    } else if node.code == "Fulfillment.Track delivery" {
      track_y = Some(node.y)
    }
  }
  @test.assert_eq(track_y.unwrap() < place_y.unwrap(), true)
}

///|
test "use-case relation labels use PlantUML label typography" {
  let svg = parse(
    "@startuml\nusecase Start\nusecase Finish\nStart .> Finish : <<include>>\n@enduml",
  ).render_usecase_svg()
  @test.assert_eq(
    svg.contains(".relation-label{text-anchor:middle;font-size:13px}"),
    true,
  )
}

///|
test "use-case relation labels use ArrowFont skinparams" {
  let svg = parse(
    "@startuml\nskinparam ArrowFontColor #456789\nskinparam ArrowFontSize 16\nskinparam ArrowFontName Courier\nusecase Start\nStart .> (Finish) : <<include>>\n@enduml",
  ).render_usecase_svg()
  @test.assert_eq(svg.contains("fill=\"#456789\""), true)
  @test.assert_eq(svg.contains("font-family=\"Courier\""), true)
  @test.assert_eq(svg.contains("font-size=\"16\""), true)
}

///|
test "use-case notes use their measured PlantUML font size" {
  let svg = parse(
    "@startuml\nusecase Review\nnote right of Review\n  Review details\nend note\n@enduml",
  ).render_usecase_svg()
  @test.assert_eq(svg.contains(".note-text{fill:#181818;font-size:13px}"), true)
}

///|
test "entity notes use an Opale pointer toward their target" {
  let svg = parse(
    "@startuml\nusecase Review\nnote right of Review\n  Review details\nend note\n@enduml",
  ).render_usecase_svg()
  @test.assert_eq(svg.contains("class=\"note-opale-link\""), true)
}

///|
test "use-case canvas includes notes positioned outside the Graphviz box" {
  let diagram = parse(
    "@startuml\nusecase Review\nnote right of Review\n  Review details\nend note\n@enduml",
  )
  let metrics = ClassTextMetrics::new(diagram.style)
  let graphviz = diagram.graphviz_layout(metrics, usecase=true)
  let layout = {
    columns: 1,
    cell_width: 1,
    cell_height: 1,
    width: graphviz.width.ceil().to_int(),
    height: graphviz.height.ceil().to_int(),
    graphviz: Some(graphviz),
  }
  let note = graphviz.notes[0]
  @test.assert_eq(
    layout.output_width().to_double() >= note.x + note.width / 2.0,
    true,
  )
}

///|
test "use-case SVG preserves entity URLs" {
  let svg = parse(
    "@startuml\nusecase \"Submit request\" as Submit [[https://example.com/submit]]\n@enduml",
  ).render_usecase_svg()
  @test.assert_eq(svg.contains("href=\"https://example.com/submit\""), true)
}

///|
test "use-case SVG uses actor and usecase skinparam colors" {
  let svg = parse(
    "@startuml\nskinparam UsecaseBackgroundColor #456789\nskinparam ActorBorderColor #987654\nactor Customer\nusecase PlaceOrder\nCustomer --> PlaceOrder\n@enduml",
  ).render_usecase_svg()
  @test.assert_eq(svg.contains("fill=\"#456789\""), true)
  @test.assert_eq(svg.contains("stroke=\"#987654\""), true)
}

///|
test "use-case SVG uses actor and usecase font skinparams" {
  let svg = parse(
    "@startuml\nskinparam UsecaseFontColor #456789\nskinparam ActorFontColor #987654\nactor Customer\nusecase PlaceOrder\nCustomer --> PlaceOrder\n@enduml",
  ).render_usecase_svg()
  @test.assert_eq(svg.contains("fill=\"#456789\""), true)
  @test.assert_eq(svg.contains("fill=\"#987654\""), true)
}

///|
test "use-case font sizes affect matching node geometry and SVG text" {
  let regular = parse("@startuml\nactor Customer\nusecase Review\n@enduml")
  let styled = parse(
    "@startuml\nskinparam ActorFontSize 18\nskinparam UsecaseFontSize 18\nactor Customer\nusecase Review\n@enduml",
  )
  let regular_metrics = ClassTextMetrics::new(regular.style)
  let styled_metrics = ClassTextMetrics::new(styled.style)
  let regular_actor = regular.entities[0].node_geometry(
    regular_metrics,
    usecase=true,
  )
  let styled_actor = styled.entities[0].node_geometry(
    styled_metrics,
    usecase=true,
  )
  let regular_usecase = regular.entities[1].node_geometry(
    regular_metrics,
    usecase=true,
  )
  let styled_usecase = styled.entities[1].node_geometry(
    styled_metrics,
    usecase=true,
  )
  let svg = styled.render_usecase_svg()
  @test.assert_eq(styled_actor.width > regular_actor.width, true)
  @test.assert_eq(styled_usecase.height > regular_usecase.height, true)
  @test.assert_eq(svg.contains("font-size=\"18\""), true)
}

///|
test "use-case font families use matching metrics profiles and SVG text" {
  let diagram = parse(
    "@startuml\nskinparam ActorFontName Courier\nskinparam UsecaseFontName Times New Roman\nactor Customer\nusecase Review\n@enduml",
  )
  let metrics = ClassTextMetrics::new(diagram.style)
  let svg = diagram.render_usecase_svg()
  @test.assert_eq(metrics.actor_regular.profile, Monospace)
  @test.assert_eq(metrics.usecase_regular.profile, Serif)
  @test.assert_eq(svg.contains("font-family=\"Courier\""), true)
  @test.assert_eq(svg.contains("font-family=\"Times New Roman\""), true)
}

///|
test "class layout receives document font profile size and title style" {
  let source = "@startuml\nclass VeryLongClassDisplayName\n@enduml"
  let regular = parse(source)
  let styled = parse(
    "@startuml\nskinparam DefaultFontName Courier\nskinparam DefaultFontSize 16\nclass VeryLongClassDisplayName\n@enduml",
  )
  let regular_metrics = ClassTextMetrics::new(regular.style)
  let styled_metrics = ClassTextMetrics::new(styled.style)
  @test.assert_eq(styled_metrics.regular.profile, Monospace)
  @test.assert_eq(styled_metrics.regular.font_size, 16)
  @test.assert_eq(styled_metrics.italic.style, Italic)
  @test.assert_eq(
    styled.entities[0].width(styled_metrics) >
    regular.entities[0].width(regular_metrics),
    true,
  )
  let layout = styled.layout(styled_metrics)
  @test.assert_eq(
    layout.width >=
    layout.node_x(0) + styled.entities[0].width(styled_metrics) + 24,
    true,
  )
}

///|
test "class body keeps empty field and method sections" {
  let empty = parse("@startuml\ninterface Empty\n@enduml")
  let with_field = parse("@startuml\ninterface Empty {\n+ id : Int\n}\n@enduml")
  let with_method = parse("@startuml\ninterface Empty {\n+ run()\n}\n@enduml")
  let metrics = ClassTextMetrics::new(empty.style)
  let empty_entity = empty.entities[0]
  let empty_body = empty_entity.body_layout(metrics)
  @test.assert_eq(empty_body.fields.length(), 0)
  @test.assert_eq(empty_body.methods.length(), 0)
  @test.assert_eq(empty_body.fields_height > 0, true)
  @test.assert_eq(empty_body.methods_height > 0, true)
  @test.assert_eq(
    with_field.entities[0].height(metrics) > empty_entity.height(metrics),
    true,
  )
  @test.assert_eq(
    with_method.entities[0].height(metrics) > empty_entity.height(metrics),
    true,
  )
}

///|
test "class SVG draws field and method partitions from the layout model" {
  let diagram = parse(
    "@startuml\nclass User {\n+ id : Int\n+ login()\n}\n@enduml",
  )
  let entity = diagram.entities[0]
  let metrics = ClassTextMetrics::new(diagram.style)
  let body = entity.body_layout(metrics)
  let svg = diagram.render_svg()
  @test.assert_eq(body.fields.length(), 1)
  @test.assert_eq(body.methods.length(), 1)
  @test.assert_eq(svg.split("<line ").count() >= 2, true)
  @test.assert_eq(svg.contains("class=\"member-icon\""), true)
  @test.assert_eq(svg.contains(">id : Int</text>"), true)
  @test.assert_eq(svg.contains(">login()</text>"), true)
  @test.assert_eq(svg.contains(">+ id : Int</text>"), false)
}

///|
test "class SVG uses PlantUML spots, visibility icons, and package tabs" {
  let diagram = parse(
    "@startuml\npackage domain {\nabstract class Abstract\nclass Concrete {\n+ visible\n- hidden\n+ run()\n}\ninterface Contract\n}\n@enduml",
  )
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("class=\"class-spot\">A</text>"), true)
  @test.assert_eq(svg.contains("class=\"class-spot\">C</text>"), true)
  @test.assert_eq(svg.contains("class=\"class-spot\">I</text>"), true)
  @test.assert_eq(svg.contains("class=\"member-icon\""), true)
  @test.assert_eq(svg.contains("fill=\"#84BE84\""), true)
  @test.assert_eq(svg.contains("<g class=\"package\""), true)
  @test.assert_eq(svg.contains("<g class=\"package\" style="), false)
  @test.assert_eq(svg.contains("class=\"package-title\">domain</text>"), true)
  @test.assert_eq(svg.contains("<path d=\"M "), true)
  @test.assert_eq(svg.contains("style=\"stroke:#181818\""), true)
  @test.assert_eq(svg.contains("<g class=\"package\"><rect"), false)
}

///|
test "class SVG consumes colors resolved by document style" {
  let default_svg = parse("@startuml\nclass User\n@enduml").render_svg()
  let styled_svg = parse(
    "@startuml\nskinparam ClassBackgroundColor #123456\nskinparam ClassBorderColor #654321\nclass User\n@enduml",
  ).render_svg()
  @test.assert_eq(default_svg.contains("fill=\"#F1F1F1\""), true)
  @test.assert_eq(styled_svg.contains("fill=\"#123456\""), true)
  @test.assert_eq(styled_svg.contains("stroke:#654321"), true)
}

///|
test "graphviz receives dimensions from each class header and body" {
  let diagram = parse(
    "@startuml\nclass Short\nclass VeryLongClassDisplayName {\n+ attribute : Int\n+ operation()\n}\nShort --> VeryLongClassDisplayName\n@enduml",
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  let nodes : Map[String, GraphvizNodeLayout] = Map([])
  for node in layout.nodes {
    nodes[node.code] = node
  }
  let short = nodes.get("Short").unwrap()
  let long = nodes.get("VeryLongClassDisplayName").unwrap()
  @test.assert_eq(long.width > short.width, true)
  @test.assert_eq(long.height > short.height, true)
}

///|
test "graphviz layout emits semantic node and spline geometry" {
  let diagram = parse(
    "@startuml\nclass Parent\nclass Child\nParent <|-- Child : inherits\n@enduml",
  )
  let metrics = ClassTextMetrics::new(diagram.style)
  let layout = diagram.graphviz_layout(metrics)
  @test.assert_eq(layout.nodes.length(), 2)
  @test.assert_eq(layout.edges.length(), 1)
  @test.assert_eq(layout.edges[0].paths.length() > 0, true)
  @test.assert_eq(layout.edges[0].label is Some(_), true)
  @test.assert_eq(layout.width > 0.0 && layout.height > 0.0, true)
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("<path d=\"M "), true)
  @test.assert_eq(svg.contains(" C "), true)
}

///|
test "graphviz layout includes package clusters and notes" {
  let diagram = parse(
    "@startuml\npackage Domain {\nclass User\nclass Account\nUser --> Account\nnote right of User : owner\nnote on link : association\n}\n@enduml",
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  @test.assert_eq(layout.packages.length(), 1)
  @test.assert_eq(layout.notes.length(), 2)
  @test.assert_eq(layout.packages[0].width > 0.0, true)
  @test.assert_eq(layout.notes[0].width > 0.0, true)
  @test.assert_eq(layout.notes[1].y > layout.edges[0].label.unwrap().1, true)
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("class=\"package\""), true)
  @test.assert_eq(svg.contains("class=\"class-note\""), true)
  @test.assert_eq(svg.contains(">owner</text>"), true)
}

///|
test "graphviz layout anchors an entity note beside its target" {
  let diagram = parse(
    "@startuml\nclass Identity\nclass Store\nIdentity --> Store\nnote right of Identity : validates\n@enduml",
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  let mut identity_x = None
  for node in layout.nodes {
    if node.code == "Identity" {
      identity_x = Some(node.x)
    }
  }
  @test.assert_eq(layout.notes[0].x > identity_x.unwrap(), true)
}

///|
test "graphviz layout follows PlantUML inheritance ordering without fake labels" {
  let diagram = parse(
    (
      #|@startuml
      #|package domain {
      #|  abstract class "Account Holder" as Account
      #|  interface Auditable
      #|  class Customer extends Account
      #|  Customer ..|> Auditable
      #|}
      #|@enduml
    ),
  )
  let layout = diagram.graphviz_layout(ClassTextMetrics::new(diagram.style))
  let nodes : Map[String, GraphvizNodeLayout] = Map([])
  for node in layout.nodes {
    nodes[node.code] = node
  }
  let account = nodes.get("domain.Account").unwrap()
  let customer = nodes.get("domain.Customer").unwrap()
  let auditable = nodes.get("domain.Auditable").unwrap()
  @test.assert_eq(
    account.y + account.height / 2.0 < customer.y - customer.height / 2.0 &&
    customer.y + customer.height / 2.0 < auditable.y - auditable.height / 2.0,
    true,
  )
  @test.assert_eq(layout.edges.length(), diagram.relations.length())
  for edge in layout.edges {
    @test.assert_eq(edge.label, None)
  }
}

///|
test "routed relations preserve endpoint decorations and cardinalities" {
  let diagram = parse(
    "@startuml\nOrder \"1\" *-- \"many\" Item : contains\nClient --[dashed]--> Service\n@enduml",
  )
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("url(#diamond)"), true)
  @test.assert_eq(svg.contains("marker path,marker circle,marker rect"), true)
  @test.assert_eq(svg.contains("marker-start=\"url(#triangle)\""), false)
  @test.assert_eq(svg.contains(">1</text>"), true)
  @test.assert_eq(svg.contains(">many</text>"), true)
  @test.assert_eq(svg.contains("stroke-dasharray:6 4"), true)
}

///|
test "hollow inheritance arrows retain a visible outline" {
  let svg = parse("@startuml\nParent <|-- Child\n@enduml").render_svg()
  @test.assert_eq(svg.contains("marker-start=\"url(#triangle)\""), true)
  @test.assert_eq(svg.contains("fill=\"white\""), true)
  @test.assert_eq(svg.contains("marker path,marker circle,marker rect"), true)
}
