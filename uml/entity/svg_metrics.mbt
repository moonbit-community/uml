///|
fn Entity::spot(
  self : Entity,
  defaults : @style.EntityColors,
) -> (String, String) {
  match self.kind {
    AbstractClass => ("A", defaults.spot_abstract)
    Interface => ("I", defaults.spot_interface)
    Enum => ("E", defaults.spot_enum)
    Annotation => ("@", defaults.spot_annotation)
    _ => ("C", defaults.spot_class)
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
  if self.visibility is Unknown {
    5
  } else {
    20
  }
}

///|
fn Member::visibility_icon(
  self : Member,
  x : Int,
  baseline_y : Int,
  defaults : @style.EntityColors,
) -> String {
  if self.visibility is Unknown {
    return ""
  }
  let (color, method_fill) = match self.visibility {
    Public =>
      (defaults.visibility_public_stroke, defaults.visibility_public_fill)
    Private =>
      (defaults.visibility_private_stroke, defaults.visibility_private_fill)
    Protected =>
      (defaults.visibility_protected_stroke, defaults.visibility_protected_fill)
    Package =>
      (defaults.visibility_package_stroke, defaults.visibility_package_fill)
    Unknown => (defaults.text, defaults.visibility_public_fill)
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
fn ClassTextMetrics::row_height(self : ClassTextMetrics) -> Int {
  self.regular.line_height.max(17)
}

///|
priv struct ClassHeaderLayout {
  width : Int
  height : Int
  circle_width : Int
  circle_height : Int
  title_width : Int
  title_height : Int
  stereotype_width : Int
  stereotype_height : Int
  stereotype : String?
}

///|
priv struct ClassHeaderPlacement {
  circle_center : (Int, Int)?
  title_x : Int
  title_baseline : Int
  stereotype_position : (Int, Int)?
}

///|
priv struct ClassBodyLayout {
  fields : Array[Member]
  methods : Array[Member]
  fields_height : Int
  methods_height : Int
}

///|
/// Object headers have no class spot and keep the stereotype/name as one
/// centered stack.  Keeping this layout separate prevents class-only header
/// geometry from leaking into object diagrams.
priv struct ObjectHeaderLayout {
  width : Int
  height : Int
  title_width : Int
  title_height : Int
  stereotype_width : Int
  stereotype_height : Int
  stereotype : String?
}

///|
/// Object bodies are a single ordered list.  Separators remain in that list
/// so their position is preserved, while their height is accounted for
/// independently from member rows.
priv struct ObjectBodyLayout {
  entries : Array[Member]
  height : Int
  has_visibility : Bool
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
  let title_metrics = self.title_metrics(text_metrics)
  let title = title_metrics.measure(self.display)
  let title_width = title.width + 2 * CLASS_NAME_HORIZONTAL_MARGIN
  let circle_width = if self.circle_hidden {
    0
  } else {
    2 * CLASS_SPOT_RADIUS + CLASS_SPOT_LEFT_MARGIN + CLASS_SPOT_RIGHT_MARGIN
  }
  let circle_height = if self.circle_hidden {
    0
  } else {
    2 * CLASS_SPOT_RADIUS + 2 * CLASS_SPOT_VERTICAL_MARGIN
  }
  let (stereotype, stereotype_width, stereotype_height) = match
    self.stereotype {
    Some(value) if !self.stereotype_hidden => {
      let display = @parse.display_stereotype(value)
      let metrics = text_metrics.class_stereotype.measure(display)
      (
        Some(display),
        metrics.width + 2 * CLASS_STEREOTYPE_HORIZONTAL_MARGIN,
        metrics.height,
      )
    }
    _ => (None, 0, 0)
  }
  {
    width: circle_width + title_width.max(stereotype_width),
    height: circle_height.max(
      stereotype_height + title.height + CLASS_HEADER_VERTICAL_PADDING,
    ),
    circle_width,
    circle_height,
    title_width,
    title_height: title.height,
    stereotype_width,
    stereotype_height,
    stereotype,
  }
}

///|
fn Entity::object_header_layout(
  self : Entity,
  text_metrics : ClassTextMetrics,
) -> ObjectHeaderLayout {
  let title = text_metrics.regular.measure(self.display)
  let title_width = title.width + OBJECT_TEXT_HORIZONTAL_PADDING * 2
  let (stereotype, stereotype_width, stereotype_height) = match
    self.stereotype {
    Some(value) if !self.stereotype_hidden => {
      let display = @parse.display_stereotype(value)
      let metrics = text_metrics.class_stereotype.measure(display)
      (
        Some(display),
        metrics.width + OBJECT_TEXT_HORIZONTAL_PADDING * 2,
        metrics.height,
      )
    }
    _ => (None, 0, 0)
  }
  {
    width: title_width.max(stereotype_width),
    height: title.height + stereotype_height + OBJECT_HEADER_VERTICAL_PADDING,
    title_width,
    title_height: title.height,
    stereotype_width,
    stereotype_height,
    stereotype,
  }
}

///|
fn Entity::object_body_layout(
  self : Entity,
  text_metrics : ClassTextMetrics,
) -> ObjectBodyLayout {
  let entries : Array[Member] = []
  let mut member_count = 0
  let mut separator_count = 0
  let mut has_visibility = false
  let mut previous_separator = false
  for entry in self.members {
    guard self.entry_visible(entry) else { continue }
    if entry.is_separator {
      // PlantUML does not render leading, trailing, or repeated separators as
      // empty rows.  Filtering them here keeps the SVG and node size aligned.
      guard member_count > 0 && !previous_separator else { continue }
      entries.push(entry)
      separator_count += 1
      previous_separator = true
    } else {
      entries.push(entry)
      member_count += 1
      let explicit_visibility = match entry.visibility {
        Unknown => false
        _ => true
      }
      has_visibility = has_visibility || explicit_visibility
      previous_separator = false
    }
  }
  let height = if member_count == 0 {
    OBJECT_EMPTY_BODY_HEIGHT
  } else {
    OBJECT_BODY_BOTTOM_PADDING +
    member_count * text_metrics.row_height() +
    separator_count * OBJECT_SEPARATOR_HEIGHT
  }
  { entries, height, has_visibility }
}

///|
fn ObjectHeaderLayout::placement(
  self : ObjectHeaderLayout,
  rect_width : Int,
) -> (Int, Int, (Int, Int)?) {
  let content_width = self.title_width.max(self.stereotype_width)
  let content_x = ((rect_width - content_width).to_double() / 2.0)
    .max(0.0)
    .round()
    .to_int()
  let title_x = content_x +
    ((content_width - self.title_width).to_double() / 2.0).round().to_int() +
    OBJECT_TEXT_HORIZONTAL_PADDING
  let title_baseline = self.stereotype_height +
    self.title_height -
    OBJECT_TEXT_BASELINE_BOTTOM_GAP
  let stereotype_position = match self.stereotype {
    Some(_) =>
      Some(
        (
          content_x +
          ((content_width - self.stereotype_width).to_double() / 2.0)
          .round()
          .to_int() +
          OBJECT_TEXT_HORIZONTAL_PADDING,
          self.stereotype_height - OBJECT_TEXT_BASELINE_BOTTOM_GAP,
        ),
      )
    None => None
  }
  (title_x, title_baseline, stereotype_position)
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
/// Positions the circled character, stereotype, and name within the final
/// class width using PlantUML HeaderLayout's surplus-width split.
fn ClassHeaderLayout::placement(
  self : ClassHeaderLayout,
  rect_width : Int,
) -> ClassHeaderPlacement {
  let content_width = self.title_width.max(self.stereotype_width)
  let circle_width = self.circle_width.to_double()
  let surplus = (rect_width.to_double() -
  circle_width -
  content_width.to_double()).max(0.0)
  let h2 = (circle_width / 4.0).min(surplus * 0.1)
  let h1 = (surplus - h2) / 2.0
  let circle_center = if self.circle_width == 0 {
    None
  } else {
    Some(
      (
        (h1 + CLASS_SPOT_LEFT_MARGIN.to_double() + CLASS_SPOT_RADIUS.to_double())
        .round()
        .to_int(),
        ((self.height - self.circle_height).to_double() / 2.0 +
        CLASS_SPOT_VERTICAL_MARGIN.to_double() +
        CLASS_SPOT_RADIUS.to_double())
        .round()
        .to_int(),
      ),
    )
  }
  let content_x = circle_width + h1 + h2
  let vertical_surplus = (self.height -
    self.stereotype_height -
    self.title_height).to_double() /
    2.0
  let title_x = (content_x +
    (content_width - self.title_width).to_double() / 2.0 +
    CLASS_NAME_HORIZONTAL_MARGIN.to_double())
    .round()
    .to_int()
  let title_baseline = (vertical_surplus +
    self.stereotype_height.to_double() +
    self.title_height.to_double() -
    CLASS_TEXT_BASELINE_BOTTOM_GAP.to_double())
    .round()
    .to_int()
  let stereotype_position = match self.stereotype {
    Some(_) =>
      Some(
        (
          (content_x +
          (content_width - self.stereotype_width).to_double() / 2.0 +
          CLASS_STEREOTYPE_HORIZONTAL_MARGIN.to_double())
          .round()
          .to_int(),
          (vertical_surplus +
          self.stereotype_height.to_double() -
          CLASS_TEXT_BASELINE_BOTTOM_GAP.to_double())
          .round()
          .to_int(),
        ),
      )
    None => None
  }
  { circle_center, title_x, title_baseline, stereotype_position }
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
fn Entity::object_height(self : Entity, text_metrics : ClassTextMetrics) -> Int {
  self.object_header_layout(text_metrics).height +
  self.object_body_layout(text_metrics).height
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
  class_stereotype : @metrics.FontMetrics
  class_stereotype_font_family : String
  usecase_regular : @metrics.FontMetrics
  usecase_italic : @metrics.FontMetrics
  actor_regular : @metrics.FontMetrics
  actor_italic : @metrics.FontMetrics
  usecase_font_family : String
  actor_font_family : String
  relation_label_regular : @metrics.FontMetrics
  relation_end_regular : @metrics.FontMetrics
  relation_end_font_family : String
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
priv enum NodeShape {
  Box
  Ellipse
}

///|
priv struct NodeGeometry {
  width : Int
  height : Int
  shape : NodeShape
}

///|
const TEXT_BLOCK_ELLIPSE_MARGIN : Double = 6.0

///|
const CLASS_NAME_HORIZONTAL_MARGIN : Int = 3

///|
const CLASS_STEREOTYPE_HORIZONTAL_MARGIN : Int = 1

///|
const CLASS_STEREOTYPE_FONT_SIZE : Int = 12

///|
const CLASS_HEADER_VERTICAL_PADDING : Int = 10

///|
const CLASS_SPOT_RADIUS : Int = 11

///|
const CLASS_SPOT_LEFT_MARGIN : Int = 4

///|
const CLASS_SPOT_RIGHT_MARGIN : Int = 0

///|
const CLASS_SPOT_VERTICAL_MARGIN : Int = 5

///|
const CLASS_TEXT_BASELINE_BOTTOM_GAP : Int = 3

///|
/// Object image tokens mirror PlantUML's object style padding and body rows.
const OBJECT_TEXT_HORIZONTAL_PADDING : Int = 5

///|
const OBJECT_HEADER_VERTICAL_PADDING : Int = 2

///|
const OBJECT_TEXT_BASELINE_BOTTOM_GAP : Int = 3

///|
const OBJECT_BODY_BOTTOM_PADDING : Int = 7

///|
const OBJECT_EMPTY_BODY_HEIGHT : Int = 16

///|
const OBJECT_SEPARATOR_HEIGHT : Int = 7

///|
const OBJECT_ROUND_CORNER : Double = 2.5

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

///|
const SVG_MARGIN_TOP : Int = 6

///|
const SVG_MARGIN_RIGHT : Int = 15

///|
const SVG_MARGIN_BOTTOM : Int = 15

///|
const RELATION_LABEL_FONT_SIZE : Int = 12

///|
/// Class relation endpoint labels use PlantUML's cardinality font role.
const RELATION_END_FONT_SIZE : Int = PLANTUML_RELATION_LABEL_FONT_SIZE

///|
fn ClassTextMetrics::new(style : @style.DocumentStyle) -> ClassTextMetrics {
  let font_size = if style.font_size is None {
    14
  } else {
    style.font_size_value()
  }
  let usecase_font_size = usecase_font_size(style, fallback=font_size)
  let actor_font_size = actor_font_size(style, fallback=font_size)
  let usecase_font_family = usecase_font_family(style)
  let actor_font_family = actor_font_family(style)
  let class_stereotype_font_family = class_stereotype_font_family(style)
  let class_stereotype_font_size = class_stereotype_font_size(
    style,
    fallback=CLASS_STEREOTYPE_FONT_SIZE,
  )
  {
    regular: style.font_metrics(font_size~),
    italic: style.font_metrics(font_size~, font_style=Italic),
    class_stereotype: style.font_metrics_for(
      class_stereotype_font_family,
      font_size=class_stereotype_font_size,
      font_style=Italic,
    ),
    class_stereotype_font_family,
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
    relation_end_regular: style.font_metrics(font_size=RELATION_END_FONT_SIZE),
    relation_end_font_family: style.font_family(),
    arrow_regular: style.font_metrics_for(
      arrow_font_family(style),
      font_size=arrow_font_size(
        style,
        fallback=USECASE_RELATION_LABEL_FONT_SIZE,
      ),
    ),
    note: style.font_metrics(font_size=NOTE_FONT_SIZE),
    actor_style: actor_style(style),
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
    width = width.max(text_metrics.regular.measure(entry.raw).width + 28)
  }
  for entry in body.methods {
    width = width.max(text_metrics.regular.measure(entry.raw).width + 28)
  }
  width
}

///|
fn Entity::object_width(self : Entity, text_metrics : ClassTextMetrics) -> Int {
  let header = self.object_header_layout(text_metrics)
  let body = self.object_body_layout(text_metrics)
  let text_x = if body.has_visibility { 20 } else { 5 }
  let mut width = header.width
  for entry in body.entries {
    guard !entry.is_separator else { continue }
    let text_width = text_metrics.regular.measure(
        entry.display_without_visibility(),
      ).width
    width = width.max(text_width + text_x + OBJECT_TEXT_HORIZONTAL_PADDING)
  }
  width
}

///|
fn Entity::usecase_content_layout(
  self : Entity,
  text_metrics : ClassTextMetrics,
) -> (Int, Int, String?) {
  let title = text_metrics.usecase_regular.measure(self.display)
  // BodyEnhanced1 uses TextBlockUtils.withMargin(block, 6, 0), which adds
  // 6px to both horizontal sides. Its UEmpty footprint participates in sizing.
  let title_width = title.width + USECASE_BODY_HORIZONTAL_MARGIN
  match self.stereotype {
    Some(stereotype) if !self.stereotype_hidden => {
      let display = @parse.display_stereotype(stereotype)
      let stereotype_metrics = text_metrics.usecase_italic.measure(display)
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
  let title = text_metrics.actor_regular.measure(self.display)
  let (figure_width, figure_height) = actor_figure_geometry(
    actor_appearance(text_metrics.actor_style),
    business=self.kind is BusinessActor,
  )
  match self.stereotype {
    Some(stereotype) if !self.stereotype_hidden => {
      let display = @parse.display_stereotype(stereotype)
      let stereotype_metrics = text_metrics.actor_italic.measure(display)
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
  let title = text_metrics.regular.measure(self.display)
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
  if family is ObjectDiagram && self.kind is Object {
    return {
      width: self.object_width(text_metrics),
      height: self.object_height(text_metrics),
      shape: Box,
    }
  }
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
