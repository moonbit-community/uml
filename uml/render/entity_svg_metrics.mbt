///|
/// The bold kind word the mbti family draws next to a node title instead of
/// the class circled letter.
fn mbti_spot_word(kind : @entity.EntityKind) -> String {
  match kind {
    @entity.EntityKind::Struct => "struct"
    @entity.EntityKind::Interface => "trait"
    @entity.EntityKind::Enum => "enum"
    @entity.EntityKind::AbstractClass => "abstract"
    @entity.EntityKind::Exception => "suberror"
    _ => "type"
  }
}

///|
fn @entity.Entity::spot(
  self : @entity.Entity,
  family : @entity.EntityFamily,
  defaults : @style.EntityColors,
) -> (String, String) {
  match (family, self.kind) {
    (Mbti, kind) =>
      (
        mbti_spot_word(kind),
        match kind {
          @entity.EntityKind::Interface => defaults.spot_interface
          @entity.EntityKind::Enum => defaults.spot_enum
          @entity.EntityKind::AbstractClass => defaults.spot_abstract
          @entity.EntityKind::Exception => defaults.spot_annotation
          _ => defaults.spot_class
        },
      )
    _ =>
      match self.kind {
        @entity.EntityKind::AbstractClass => ("A", defaults.spot_abstract)
        @entity.EntityKind::Interface => ("I", defaults.spot_interface)
        @entity.EntityKind::Enum => ("E", defaults.spot_enum)
        @entity.EntityKind::Annotation => ("@", defaults.spot_annotation)
        _ => ("C", defaults.spot_class)
      }
  }
}

///|
fn @entity.Member::display_without_visibility(self : @entity.Member) -> String {
  match self.visibility {
    Unknown => self.raw
    _ => self.raw[1:].trim_start().to_owned()
  }
}

///|
/// Horizontal offset of the member text from the class rect's left edge.
/// PlantUML starts unadorned members (e.g. enum values) at x+5 with no
/// placeholder, while visibility-prefixed members reserve x+20 for the icon.
fn @entity.Member::member_text_x(self : @entity.Member) -> Int {
  if self.visibility is Unknown {
    5
  } else {
    20
  }
}

///|
fn @entity.Member::visibility_icon(
  self : @entity.Member,
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
    @entity.Package =>
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
    @entity.Package =>
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
  /// Half width of the spot glyph: the circle radius for class diagrams, or
  /// half the measured kind word for the mbti family.
  spot_half_width : Int
  title_width : Int
  title_height : Int
  stereotype_width : Int
  stereotype_height : Int
  stereotype : String?
  annotation_width : Int
  annotation_height : Int
  annotation : String?
}

///|
priv struct ClassHeaderPlacement {
  circle_center : (Int, Int)?
  title_x : Int
  title_baseline : Int
  stereotype_position : (Int, Int)?
  annotation_position : (Int, Int)?
}

///|
priv struct ClassBodyLayout {
  fields : Array[@entity.Member]
  methods : Array[@entity.Member]
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
  entries : Array[@entity.Member]
  height : Int
  has_visibility : Bool
}

///|
/// One ordered map row. `top` is relative to the map body, so SVG painting,
/// Graphviz ports, and fallback relation endpoints share the same geometry.
priv struct MapRowLayout {
  entry : @entity.MapEntry
  key : String
  top : Int
  height : Int
  port_id : String
}

///|
/// PlantUML's `TextBlockMap` sizes the two columns independently, then lets
/// linked rows span the resulting total width.
priv struct MapBodyLayout {
  rows : Array[MapRowLayout]
  key_column_width : Int
  value_column_width : Int
  width : Int
  height : Int
}

///|
fn body_section_height(
  entries : Array[@entity.Member],
  text_metrics : ClassTextMetrics,
) -> Int {
  if entries.is_empty() {
    8
  } else {
    7 + entries.length() * text_metrics.row_height()
  }
}

///|
/// Measure a single header label (a stereotype or annotation) and return it
/// with its padded width and height.
///
/// Shared by the class and object header layouts; do not re-implement the
/// `(Some(display), width + padding, height)` triple locally.
fn measure_header_label(
  display : String,
  metrics : @metrics.FontMetrics,
  horizontal_padding : Int,
) -> (String?, Int, Int) {
  let measured = metrics.measure(display)
  (Some(display), measured.width + horizontal_padding, measured.height)
}

///|
fn @entity.Entity::header_layout(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
  family : @entity.EntityFamily,
) -> ClassHeaderLayout {
  let title_metrics = self.title_metrics(text_metrics)
  let title = title_metrics.measure(self.display)
  let title_width = title.width + 2 * CLASS_NAME_HORIZONTAL_MARGIN
  // The mbti family replaces the circled letter with the kind word (struct,
  // trait, ...) drawn in bold, so its spot slot spans the measured word.
  let spot_word = if family is Mbti {
    Some(mbti_spot_word(self.kind))
  } else {
    None
  }
  let spot_half_width = spot_word.map_or(CLASS_SPOT_RADIUS, word => {
    (text_metrics.class_spot.measure(word).width + 1) / 2
  })
  let circle_width = if self.circle_hidden {
    0
  } else {
    2 * spot_half_width + CLASS_SPOT_LEFT_MARGIN + CLASS_SPOT_RIGHT_MARGIN
  }
  let circle_height = if self.circle_hidden {
    0
  } else {
    2 * CLASS_SPOT_RADIUS + 2 * CLASS_SPOT_VERTICAL_MARGIN
  }
  let (stereotype, stereotype_width, stereotype_height) = match
    self.stereotype {
    Some(value) if !self.stereotype_hidden =>
      measure_header_label(
        @tokenizer.display_stereotype(value),
        text_metrics.class_stereotype,
        2 * CLASS_STEREOTYPE_HORIZONTAL_MARGIN,
      )
    _ => (None, 0, 0)
  }
  let (annotation, annotation_width, annotation_height) = match
    self.annotation {
    Some(value) =>
      measure_header_label(
        value,
        text_metrics.class_stereotype,
        2 * CLASS_STEREOTYPE_HORIZONTAL_MARGIN,
      )
    None => (None, 0, 0)
  }
  {
    width: circle_width +
    title_width.max(stereotype_width).max(annotation_width),
    height: circle_height.max(
      stereotype_height +
      title.height +
      annotation_height +
      CLASS_HEADER_VERTICAL_PADDING,
    ),
    circle_width,
    circle_height,
    spot_half_width,
    title_width,
    title_height: title.height,
    stereotype_width,
    stereotype_height,
    stereotype,
    annotation_width,
    annotation_height,
    annotation,
  }
}

///|
fn @entity.Entity::object_header_layout(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> ObjectHeaderLayout {
  let title = text_metrics.regular.measure(self.display)
  let title_width = title.width + OBJECT_TEXT_HORIZONTAL_PADDING * 2
  let (stereotype, stereotype_width, stereotype_height) = match
    self.stereotype {
    Some(value) if !self.stereotype_hidden =>
      measure_header_label(
        @tokenizer.display_stereotype(value),
        text_metrics.class_stereotype,
        2 * OBJECT_TEXT_HORIZONTAL_PADDING,
      )
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
fn @entity.Entity::object_body_layout(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> ObjectBodyLayout {
  let entries : Array[@entity.Member] = []
  let mut member_count = 0
  let mut separator_count = 0
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
      previous_separator = false
    }
  }
  let has_visibility = self.members.any(entry => {
    self.entry_visible(entry) &&
    !entry.is_separator &&
    !(entry.visibility is Unknown)
  })
  let height = if member_count == 0 {
    OBJECT_EMPTY_BODY_HEIGHT
  } else {
    OBJECT_BODY_BOTTOM_PADDING +
    member_count * text_metrics.row_height() +
    separator_count * OBJECT_SEPARATOR_HEIGHT
  }
  { entries, height, has_visibility, }
}

///|
fn stable_port_identifier(value : String) -> String {
  let output = StringBuilder()
  output.write_string("p")
  for char in value {
    output.write_char('_')
    output.write_string(char.to_int().to_string(radix=16))
  }
  output.to_string()
}

///|
fn @entity.MapEntry::display_key(self : @entity.MapEntry) -> String {
  let chars = self.key.to_array()
  guard chars.length() > 0 else { return self.key }
  match chars[0] {
    '+' | '-' | '#' | '~' => self.key[1:].trim_start().to_owned()
    _ => self.key
  }
}

///|
fn @entity.MapEntry::port_id(self : @entity.MapEntry) -> String {
  stable_port_identifier(self.key)
}

///|
fn @entity.Entity::map_body_layout(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> MapBodyLayout {
  let rows : Array[MapRowLayout] = []
  let mut key_column_width = 0
  let mut value_column_width = 0
  let mut top = 0
  for entry in self.map_entries {
    let key = entry.display_key()
    let key_metrics = text_metrics.regular.measure(key)
    let key_block_width = key_metrics.width + MAP_CELL_HORIZONTAL_PADDING * 2
    let (value_block_width, value_height) = match entry.value {
      Some(value) => {
        let metrics = text_metrics.regular.measure(value)
        (
          metrics.width + MAP_CELL_HORIZONTAL_PADDING * 2,
          metrics.height + MAP_CELL_VERTICAL_PADDING * 2,
        )
      }
      None => (MAP_LINK_VALUE_DIAMETER, MAP_LINK_VALUE_DIAMETER)
    }
    let height = (key_metrics.height + MAP_CELL_VERTICAL_PADDING * 2).max(
      value_height,
    )
    rows.push({ entry, key, top, height, port_id: entry.port_id(), })
    key_column_width = key_column_width.max(key_block_width)
    value_column_width = value_column_width.max(value_block_width)
    top += height
  }
  {
    rows,
    key_column_width,
    value_column_width,
    width: key_column_width + value_column_width,
    height: top,
  }
}

///|
fn MapBodyLayout::row(self : MapBodyLayout, key : String) -> MapRowLayout? {
  for row in self.rows {
    if row.entry.key == key {
      return Some(row)
    }
  }
  None
}

///|
fn @entity.Entity::graphviz_port(
  self : @entity.Entity,
  port : String?,
) -> @cgraph.Port? {
  guard self.kind is Map else { return None }
  guard port is Some(key) else { return None }
  guard self.map_entries.any(entry => entry.key == key) else { return None }
  Some({ name: Some(stable_port_identifier(key)), compass: None, })
}

///|
/// Graphviz only consumes this invisible HTML table to route named ports. The
/// custom SVG painter draws the visible table from the same `MapBodyLayout`.
fn @entity.Entity::map_graphviz_port_label(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
  width : Int,
) -> String {
  let body = self.map_body_layout(text_metrics)
  let output = StringBuilder()
  output <+
    $|<<TABLE BORDER="0" CELLBORDER="0" CELLSPACING="0" CELLPADDING="0"><TR><TD WIDTH="\{width}" HEIGHT="\{self.object_header_layout(text_metrics).height}"></TD></TR>
  for row in body.rows {
    output <+
      $|<TR><TD PORT="\{row.port_id}" WIDTH="\{width}" HEIGHT="\{row.height}"></TD></TR>
  }
  output.write_string("</TABLE>>")
  output.to_string()
}

///|
/// Resolve a map entry port in local node coordinates for the non-Graphviz
/// fallback. Like PlantUML's dynamic record port, a row may attach on either
/// horizontal side depending on the other endpoint.
fn @entity.Entity::map_port_endpoint(
  self : @entity.Entity,
  port : String?,
  text_metrics : ClassTextMetrics,
  x : Int,
  y : Int,
  width : Int,
  target_x : Int,
) -> (Int, Int)? {
  guard self.kind is Map else { return None }
  guard port is Some(key) else { return None }
  guard self.map_body_layout(text_metrics).row(key) is Some(row) else {
    return None
  }
  let center_x = x + width / 2
  let port_x = if target_x < center_x { x } else { x + width }
  let port_y = y +
    self.object_header_layout(text_metrics).height +
    row.top +
    row.height / 2
  Some((port_x, port_y))
}

///|
/// One ordered JSON row inside the body. `top` is relative to the body so the
/// SVG painter, Graphviz node size, and fallback endpoints share one geometry.
priv struct JsonRowLayout {
  key : String?
  value : String?
  top : Int
  hline : Bool
  hline_from : Int
  hline_width : Int
  value_x : Int
}

///|
/// Vertical divider of one JSON object body, spanning the object's rows.
priv struct JsonDividerLayout {
  x : Int
  top : Int
  height : Int
}

///|
priv struct JsonBodyLayout {
  rows : Array[JsonRowLayout]
  dividers : Array[JsonDividerLayout]
  width : Int
  height : Int
}

///|
priv struct JsonNodeSize {
  key_column_width : Int
  width : Int
  height : Int
}

///|
/// `TextBlockCucaJSon` measures each object's key and value columns
/// independently; nested compounds participate with their own full width.
fn measure_json_node(
  node : @bodierjson.JsonNode,
  text_metrics : ClassTextMetrics,
) -> JsonNodeSize {
  match node {
    JsonObject(members) => {
      let mut key_column_width = 0
      let mut value_column_width = 0
      let mut height = 0
      for entry in members {
        let key = text_metrics.regular.measure(entry.key)
        let value_size = measure_json_node(entry.value, text_metrics)
        key_column_width = key_column_width.max(
          key.width + MAP_CELL_HORIZONTAL_PADDING * 2,
        )
        value_column_width = value_column_width.max(value_size.width)
        height += (key.height + MAP_CELL_VERTICAL_PADDING * 2).max(
          value_size.height,
        )
      }
      {
        key_column_width,
        width: key_column_width + value_column_width,
        height,
      }
    }
    JsonArray(elements) => {
      let mut width = 0
      let mut height = 0
      for element in elements {
        let size = measure_json_node(element, text_metrics)
        width = width.max(size.width)
        height += size.height
      }
      { key_column_width: 0, width, height, }
    }
    _ => {
      let scalar = text_metrics.regular.measure(node.display())
      {
        key_column_width: 0,
        width: scalar.width + MAP_CELL_HORIZONTAL_PADDING * 2,
        height: scalar.height + MAP_CELL_VERTICAL_PADDING * 2,
      }
    }
  }
}

///|
/// Flatten a JSON node into ordered body rows. Rows carry their absolute body
/// offsets; nested compounds append their own rows below the member row and
/// emit their own divider. Object hlines precede every row, array hlines
/// precede all but the first element, and both span the enclosing value
/// column (`hline_width`) like `TextBlockJson.drawU`.
fn build_json_rows(
  node : @bodierjson.JsonNode,
  text_metrics : ClassTextMetrics,
  rows : Array[JsonRowLayout],
  dividers : Array[JsonDividerLayout],
  origin_x : Int,
  hline_width : Int,
  top : Int,
) -> Unit {
  match node {
    JsonObject(members) => {
      let size = measure_json_node(node, text_metrics)
      dividers.push({
        x: origin_x + size.key_column_width,
        top,
        height: size.height,
      })
      let mut current_top = top
      for entry in members {
        let key = text_metrics.regular.measure(entry.key)
        let value_size = measure_json_node(entry.value, text_metrics)
        let row_height = (key.height + MAP_CELL_VERTICAL_PADDING * 2).max(
          value_size.height,
        )
        rows.push({
          key: Some(entry.key),
          value: match entry.value {
            JsonObject(_) | JsonArray(_) => None
            _ => Some(entry.value.display())
          },
          top: current_top,
          hline: true,
          hline_from: origin_x,
          hline_width,
          value_x: origin_x + size.key_column_width,
        })
        match entry.value {
          JsonObject(_) | JsonArray(_) =>
            build_json_rows(
              entry.value,
              text_metrics,
              rows,
              dividers,
              origin_x + size.key_column_width,
              hline_width - size.key_column_width,
              current_top,
            )
          _ => ()
        }
        current_top += row_height
      }
    }
    JsonArray(elements) => {
      let mut current_top = top
      for index, element in elements {
        let element_size = measure_json_node(element, text_metrics)
        rows.push({
          key: None,
          value: match element {
            JsonObject(_) | JsonArray(_) => None
            _ => Some(element.display())
          },
          top: current_top,
          hline: index > 0,
          hline_from: origin_x,
          hline_width,
          value_x: origin_x,
        })
        match element {
          JsonObject(_) | JsonArray(_) =>
            build_json_rows(
              element, text_metrics, rows, dividers, origin_x, hline_width, current_top,
            )
          _ => ()
        }
        current_top += element_size.height
      }
    }
    _ =>
      rows.push({
        key: None,
        value: Some(node.display()),
        top,
        hline: false,
        hline_from: origin_x,
        hline_width,
        value_x: origin_x,
      })
  }
}

///|
fn @entity.Entity::json_body_layout(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> JsonBodyLayout {
  match self.json_tree {
    Some(tree) => {
      let rows : Array[JsonRowLayout] = []
      let dividers : Array[JsonDividerLayout] = []
      let size = measure_json_node(tree, text_metrics)
      build_json_rows(tree, text_metrics, rows, dividers, 0, size.width, 0)
      { rows, dividers, width: size.width, height: size.height, }
    }
    None => { rows: [], dividers: [], width: 0, height: 0, }
  }
}

///|
/// `EntityImageJson` stacks the stereotype without margins and wraps the
/// title with a 2px vertical margin on both sides. The width and centering
/// come from the object header contract.
fn @entity.Entity::json_header_layout(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> ObjectHeaderLayout {
  let header = self.object_header_layout(text_metrics)
  { ..header, height: header.height + 2, }
}

///|
fn ObjectHeaderLayout::json_placement(
  self : ObjectHeaderLayout,
  rect_width : Int,
) -> (Int, Int, (Int, Int)?) {
  let (title_x, title_baseline, stereotype_position) = self.placement(
    rect_width,
  )
  (title_x, title_baseline + 2, stereotype_position)
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
  let stereotype_position = self.stereotype.map(_ => {
    (
      content_x +
      ((content_width - self.stereotype_width).to_double() / 2.0)
      .round()
      .to_int() +
      OBJECT_TEXT_HORIZONTAL_PADDING,
      self.stereotype_height - OBJECT_TEXT_BASELINE_BOTTOM_GAP,
    )
  })
  (title_x, title_baseline, stereotype_position)
}

///|
fn @entity.Entity::title_metrics(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> @metrics.FontMetrics {
  match self.kind {
    @entity.EntityKind::AbstractClass | @entity.EntityKind::Interface =>
      text_metrics.italic
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
  let content_width = self.title_width
    .max(self.stereotype_width)
    .max(self.annotation_width)
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
        (h1 +
        CLASS_SPOT_LEFT_MARGIN.to_double() +
        self.spot_half_width.to_double())
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
    self.title_height -
    self.annotation_height).to_double() /
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
  let stereotype_position = self.stereotype.map(_ => {
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
    )
  })
  let annotation_position = self.annotation.map(_ => {
    (
      (content_x +
      (content_width - self.annotation_width).to_double() / 2.0 +
      CLASS_STEREOTYPE_HORIZONTAL_MARGIN.to_double())
      .round()
      .to_int(),
      (vertical_surplus +
      self.stereotype_height.to_double() +
      self.title_height.to_double() +
      self.annotation_height.to_double() -
      CLASS_TEXT_BASELINE_BOTTOM_GAP.to_double())
      .round()
      .to_int(),
    )
  })
  {
    circle_center,
    title_x,
    title_baseline,
    stereotype_position,
    annotation_position,
  }
}

///|
/// The fields and methods portions of the class body. MethodsOrFieldsArea
/// always contributes its separator and vertical margins for the class
/// family, even when that portion has no visible members; the mbti family
/// collapses an empty portion so its type skeletons keep no spare strip.
fn @entity.Entity::body_layout(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
  family : @entity.EntityFamily,
) -> ClassBodyLayout {
  let visible = self.members.filter(entry => {
    self.entry_visible(entry) && !entry.is_separator
  })
  let fields = visible.filter(entry => !entry.is_method)
  let methods = visible.filter(entry => entry.is_method)
  let skeleton = family is Mbti
  {
    fields,
    methods,
    fields_height: if skeleton && fields.is_empty() {
      0
    } else {
      body_section_height(fields, text_metrics)
    },
    methods_height: if skeleton && methods.is_empty() {
      0
    } else {
      body_section_height(methods, text_metrics)
    },
  }
}

///|
fn @entity.Entity::entry_visible(
  self : @entity.Entity,
  entry : @entity.Member,
) -> Bool {
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
  /// Bold 12px font of the class spot; the mbti family measures its kind word
  /// (struct, trait, ...) with it.
  class_spot : @metrics.FontMetrics
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
priv struct NodeGeometry {
  width : Int
  height : Int
  shape : @entity.NodeShape
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
/// Font size of the class spot, matching the `.class-spot` CSS rule.
const CLASS_SPOT_FONT_SIZE : Int = 12

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
/// `TextBlockMap` wraps cell text with a 5px horizontal and 2px vertical
/// margin. Linked entries use its 7px point block for the second column.
const MAP_CELL_HORIZONTAL_PADDING : Int = 5

///|
const MAP_CELL_VERTICAL_PADDING : Int = 2

///|
const MAP_LINK_VALUE_DIAMETER : Int = 7

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
/// `EntityImageLollipopInterface` is a fixed 10x10 circle image with the
/// interface name centered below the circle.
const LOLLIPOP_SIZE : Int = 10

///|
/// `EntityImageAssociationPoint` is a fixed 4x4 filled circle.
const ASSOCIATION_POINT_SIZE : Int = 4

///|
/// `EntityImagePort`: a fixed 12x12 square with the name above or below.
const PORT_SIZE : Int = 12

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
  let usecase_font_size = @entity.usecase_font_size(style, fallback=font_size)
  let actor_font_size = @entity.actor_font_size(style, fallback=font_size)
  let usecase_font_family = @entity.usecase_font_family(style)
  let actor_font_family = @entity.actor_font_family(style)
  let class_stereotype_font_family = @entity.class_stereotype_font_family(style)
  let class_stereotype_font_size = @entity.class_stereotype_font_size(
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
    class_spot: style.font_metrics(
      font_size=CLASS_SPOT_FONT_SIZE,
      font_weight=700,
    ),
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
      @entity.arrow_font_family(style),
      font_size=@entity.arrow_font_size(
        style,
        fallback=USECASE_RELATION_LABEL_FONT_SIZE,
      ),
    ),
    note: style.font_metrics(font_size=NOTE_FONT_SIZE),
    actor_style: @entity.actor_style(style),
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
fn @entity.Entity::class_node_size(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
  family : @entity.EntityFamily,
) -> (Int, Int) {
  let header = self.header_layout(text_metrics, family)
  let body = self.body_layout(text_metrics, family)
  let mut width = header.width
  for entry in body.fields + body.methods {
    width = width.max(text_metrics.regular.measure(entry.raw).width + 28)
  }
  (width, header.height + body.fields_height + body.methods_height)
}

///|
fn @entity.Entity::object_node_size(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> (Int, Int) {
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
  (width, header.height + body.height)
}

///|
fn @entity.Entity::map_node_size(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> (Int, Int) {
  let header = self.object_header_layout(text_metrics)
  let body = self.map_body_layout(text_metrics)
  (header.width.max(body.width), header.height + body.height)
}

///|
fn @entity.Entity::json_node_size(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> (Int, Int) {
  let header = self.json_header_layout(text_metrics)
  let body = self.json_body_layout(text_metrics)
  (header.width.max(body.width), header.height + body.height)
}

///|
fn @entity.Entity::usecase_content_layout(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> (Int, Int, String?) {
  let title = text_metrics.usecase_regular.measure(self.display)
  // BodyEnhanced1 uses TextBlockUtils.withMargin(block, 6, 0), which adds
  // 6px to both horizontal sides. Its UEmpty footprint participates in sizing.
  let title_width = title.width + USECASE_BODY_HORIZONTAL_MARGIN
  match self.stereotype {
    Some(stereotype) if !self.stereotype_hidden => {
      let display = @tokenizer.display_stereotype(stereotype)
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
fn @entity.Entity::actor_content_layout(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
) -> (Int, Int, String?) {
  let title = text_metrics.actor_regular.measure(self.display)
  let (figure_width, figure_height) = actor_figure_geometry(
    actor_appearance(text_metrics.actor_style),
    business=self.kind is @entity.EntityKind::BusinessActor,
  )
  match self.stereotype {
    Some(stereotype) if !self.stereotype_hidden => {
      let display = @tokenizer.display_stereotype(stereotype)
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
fn @entity.Entity::component_geometry(
  self : @entity.Entity,
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
fn @entity.Entity::node_geometry(
  self : @entity.Entity,
  text_metrics : ClassTextMetrics,
  family : @entity.EntityFamily,
) -> NodeGeometry {
  let capability = self.render_capability(family)
  match (capability.header, capability.body, capability.renderer) {
    (ObjectHeader, OrderedMembers, ObjectRenderer) => {
      let (width, height) = self.object_node_size(text_metrics)
      { width, height, shape: capability.shape, }
    }
    (ObjectHeader, JsonData, JsonRenderer) => {
      let (width, height) = self.json_node_size(text_metrics)
      { width, height, shape: capability.shape, }
    }
    (ObjectHeader, MapEntries, MapRenderer) => {
      let (width, height) = self.map_node_size(text_metrics)
      { width, height, shape: capability.shape, }
    }
    (DescriptionHeader, NoBody, UsecaseRenderer) => {
      let (content_width, content_height, _) = self.usecase_content_layout(
        text_metrics,
      )
      let (width, height) = text_block_in_ellipse_geometry(
        content_width, content_height,
      )
      { width, height, shape: capability.shape, }
    }
    (DescriptionHeader, NoBody, ActorRenderer) => {
      let (width, height, _) = self.actor_content_layout(text_metrics)
      { width, height, shape: capability.shape, }
    }
    (DescriptionHeader, NoBody, ComponentRenderer) =>
      self.component_geometry(text_metrics)
    (DescriptionHeader, NoBody, DescriptionRenderer) => {
      let (width, height) = self.description_geometry(text_metrics)
      {
        width,
        height,
        shape: if self.description_symbol() is CircleSymbol {
          InterfaceCircle
        } else {
          capability.shape
        },
      }
    }
    (DescriptionHeader, NoBody, PortRenderer) =>
      { width: PORT_SIZE, height: PORT_SIZE, shape: Box, }
    (DescriptionHeader, NoBody, LollipopRenderer) =>
      { width: LOLLIPOP_SIZE, height: LOLLIPOP_SIZE, shape: Circle, }
    (DescriptionHeader, NoBody, PointRenderer) =>
      {
        width: ASSOCIATION_POINT_SIZE,
        height: ASSOCIATION_POINT_SIZE,
        shape: Circle,
      }
    (ClassHeader, ClassCompartments, ClassRenderer) => {
      let (width, height) = self.class_node_size(text_metrics, family)
      { width, height, shape: capability.shape, }
    }
    _ => panic()
  }
}
