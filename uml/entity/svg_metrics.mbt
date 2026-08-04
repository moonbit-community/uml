///|
fn Entity::spot(self : Entity) -> (String, String) {
  match self.kind {
    AbstractClass => ("A", "#A9DCDF")
    Interface => ("I", "#B4A7E5")
    Enum => ("E", "#EB937F")
    Annotation => ("@", "#E3664A")
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
/// Horizontal offset of the member text from the class rect's left edge.
/// PlantUML starts unadorned members (e.g. enum values) at x+5 with no
/// placeholder, while visibility-prefixed members reserve x+20 for the icon.
fn Member::member_text_x(self : Member) -> Int {
  if self.visibility is Unknown { 5 } else { 20 }
}

///|
fn Member::visibility_icon(self : Member, x : Int, baseline_y : Int) -> String {
  if self.visibility is Unknown {
    return ""
  }
  let (color, method_fill) = match self.visibility {
    Public => ("#038048", "#84BE84")
    Private => ("#C82930", "#F24D5C")
    Protected => ("#B38D22", "#FFFF44")
    Package => ("#1963A0", "#4177AF")
    Unknown => (@style.render_defaults().diagram_text, "#84BE84")
  }
  let fill = if self.is_method { method_fill } else { "none" }
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
  let title_metrics = self.title_metrics(text_metrics)
  let width = @metrics.measure_text_with(self.display, title_metrics).width + 32
  { width, height: text_metrics.header_height() }
}

///|
fn Entity::title_metrics(
  self : Entity,
  text_metrics : ClassTextMetrics,
) -> @metrics.FontMetrics {
  match self.kind {
    AbstractClass | Interface => text_metrics.italic
    _ => text_metrics.regular
  }
}

///|
/// Horizontal offsets (relative to the class rect) that center the group
/// [spot circle 22px + gap + title] within `rect_width`, following the
/// PlantUML HeaderLayout split of the surplus space.
fn class_title_offsets(
  display : String,
  title_metrics : @metrics.FontMetrics,
  rect_width : Int,
) -> (Int, Int) {
  let circle_dim = 26.0
  let title_width = @metrics.measure_text_with(display, title_metrics).width
  let surplus = (rect_width.to_double() - circle_dim - title_width.to_double()).max(0.0)
  let h2 = (circle_dim / 4.0).min(surplus * 0.1)
  let h1 = (surplus - h2) / 2.0
  let circle_cx = h1 + 11.0
  let title_x = h1 + circle_dim + h2
  (circle_cx.round().to_int(), title_x.round().to_int())
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
  relation_label_regular : @metrics.FontMetrics
  arrow_regular : @metrics.FontMetrics
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
#warnings("-unused_value")
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
/// PlantUML SvekResult canvas margins: the drawn content is shifted so its
/// top-left corner sits at (6, 6) and the canvas extends 15px beyond the
/// content's bottom-right corner.
const SVG_MARGIN_LEFT : Int = 6
const SVG_MARGIN_TOP : Int = 6
const SVG_MARGIN_RIGHT : Int = 15
const SVG_MARGIN_BOTTOM : Int = 15

///|
const RELATION_LABEL_FONT_SIZE : Int = 12

///|
/// Distance used to push cardinality/role labels just outside the entity
/// border so they are never covered by the entity body.
const CARDINALITY_LABEL_MARGIN : Double = 16.0

///|
/// Horizontal offset of cardinality/role labels from the edge endpoint,
/// giving the label text a small gap from the edge line.
const RELATION_END_LABEL_X_OFFSET : Int = 13

///|
/// Vertical offset of cardinality/role labels from the edge endpoint.
const RELATION_END_LABEL_Y_OFFSET : Int = 4

///|
fn ClassTextMetrics::new(style : @style.DocumentStyle) -> ClassTextMetrics {
  let font_size = if style.font_size is None {
    14
  } else {
    @style.font_size_value(style)
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
    relation_label_regular: style.font_metrics(
      font_size=RELATION_LABEL_FONT_SIZE,
    ),
    arrow_regular: style.font_metrics_for(
      style.arrow_font_family(),
      font_size=style.arrow_font_size(fallback=USECASE_RELATION_LABEL_FONT_SIZE),
    ),
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
      let display = @parse.display_stereotype(stereotype)
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
      let display = @parse.display_stereotype(stereotype)
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
  family : EntityFamily,
) -> NodeGeometry {
  guard !family.is_usecase() else {
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
  {
    width: self.width(text_metrics),
    height: self.height(text_metrics),
    shape: Box,
  }
}
