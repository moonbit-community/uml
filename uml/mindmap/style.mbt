///|
pub(all) enum TextAlignment {
  Left
  Center
  Right
} derive(Eq, Debug)

///|
pub struct MindmapNodeStyle {
  minimum_width : Int?
  padding_x : Int?
  padding_y : Int?
  margin_left : Int?
  margin_right : Int?
  margin_top : Int?
  margin_bottom : Int?
  font_size : Int?
  background_color : String?
  line_color : String?
  font_color : String?
  line_thickness : Int?
  round_corner : Int?
  same_class_width : Bool?
  alignment : TextAlignment?
} derive(Eq, Debug)

///|
pub struct MindmapArrowStyle {
  line_color : String?
  line_thickness : Int?
} derive(Eq, Debug)

///|
pub struct MindmapStyle {
  mut node : MindmapNodeStyle
  mut root_node : MindmapNodeStyle
  mut leaf_node : MindmapNodeStyle
  stereotypes : Map[String, MindmapNodeStyle]
  mut arrow : MindmapArrowStyle
} derive(Eq, Debug)

///|
fn MindmapNodeStyle::empty() -> MindmapNodeStyle {
  {
    minimum_width: None,
    padding_x: None,
    padding_y: None,
    margin_left: None,
    margin_right: None,
    margin_top: None,
    margin_bottom: None,
    font_size: None,
    background_color: None,
    line_color: None,
    font_color: None,
    line_thickness: None,
    round_corner: None,
    same_class_width: None,
    alignment: None,
  }
}

///|
fn MindmapNodeStyle::defaults() -> MindmapNodeStyle {
  {
    ..MindmapNodeStyle::empty(),
    padding_x: Some(12),
    padding_y: Some(10),
    margin_left: Some(10),
    margin_right: Some(10),
    margin_top: Some(10),
    margin_bottom: Some(10),
    font_size: None,
    line_thickness: None,
    round_corner: None,
    alignment: Some(Center),
  }
}

///|
fn MindmapArrowStyle::defaults() -> MindmapArrowStyle {
  { line_color: None, line_thickness: Some(1) }
}

///|
pub fn MindmapStyle::default() -> MindmapStyle {
  {
    node: MindmapNodeStyle::empty(),
    root_node: MindmapNodeStyle::empty(),
    leaf_node: MindmapNodeStyle::empty(),
    stereotypes: {},
    arrow: MindmapArrowStyle::defaults(),
  }
}

///|
fn[T] Option::fallback(self : T?, fallback : T?) -> T? {
  self.map_or(fallback, value => Some(value))
}

///|
fn MindmapNodeStyle::merge(
  self : MindmapNodeStyle,
  overlay : MindmapNodeStyle,
) -> MindmapNodeStyle {
  {
    minimum_width: overlay.minimum_width.fallback(self.minimum_width),
    padding_x: overlay.padding_x.fallback(self.padding_x),
    padding_y: overlay.padding_y.fallback(self.padding_y),
    margin_left: overlay.margin_left.fallback(self.margin_left),
    margin_right: overlay.margin_right.fallback(self.margin_right),
    margin_top: overlay.margin_top.fallback(self.margin_top),
    margin_bottom: overlay.margin_bottom.fallback(self.margin_bottom),
    font_size: overlay.font_size.fallback(self.font_size),
    background_color: overlay.background_color.fallback(self.background_color),
    line_color: overlay.line_color.fallback(self.line_color),
    font_color: overlay.font_color.fallback(self.font_color),
    line_thickness: overlay.line_thickness.fallback(self.line_thickness),
    round_corner: overlay.round_corner.fallback(self.round_corner),
    same_class_width: overlay.same_class_width.fallback(self.same_class_width),
    alignment: overlay.alignment.fallback(self.alignment),
  }
}

///|
fn parse_nonnegative_int(value : String) -> Int? {
  let parsed = @string.parse_int(value.trim()) catch { _ => return None }
  if parsed >= 0 {
    Some(parsed)
  } else {
    None
  }
}

///|
fn parse_bool(value : String) -> Bool? {
  match value.trim().to_lower() {
    "true" | "yes" => Some(true)
    "false" | "no" => Some(false)
    _ => None
  }
}

///|
fn parse_box_lengths(value : String) -> (Int, Int, Int, Int)? {
  let values = []
  for word in value.split(" ") {
    let word = word.trim().to_owned()
    guard word.length() > 0 else { continue }
    guard parse_nonnegative_int(word) is Some(length) else { return None }
    values.push(length)
  }
  match values {
    [all] => Some((all, all, all, all))
    [vertical, horizontal] => Some((vertical, horizontal, vertical, horizontal))
    [top, horizontal, bottom] => Some((top, horizontal, bottom, horizontal))
    [top, right, bottom, left] => Some((top, right, bottom, left))
    _ => None
  }
}

///|
fn MindmapNodeStyle::with_property(
  self : MindmapNodeStyle,
  key : String,
  value : String,
) -> MindmapNodeStyle {
  let normalized = key
    .to_lower()
    .replace(old="-", new="")
    .replace(old=":", new="")
  let value = value.trim().to_owned()
  match normalized {
    "minimumwidth" =>
      parse_nonnegative_int(value).map_or(self, width => {
        ..self,
        minimum_width: Some(width),
      })
    "padding" =>
      parse_box_lengths(value).map_or(self, lengths => {
        let (top, right, bottom, left) = lengths
        {
          ..self,
          padding_x: Some(left.max(right)),
          padding_y: Some(top.max(bottom)),
        }
      })
    "margin" =>
      parse_box_lengths(value).map_or(self, lengths => {
        let (top, right, bottom, left) = lengths
        {
          ..self,
          margin_left: Some(left),
          margin_right: Some(right),
          margin_top: Some(top),
          margin_bottom: Some(bottom),
        }
      })
    "fontsize" =>
      parse_nonnegative_int(value).map_or(self, size => {
        ..self,
        font_size: Some(size.max(1)),
      })
    "backgroundcolor" => { ..self, background_color: Some(value) }
    "linecolor" | "bordercolor" => { ..self, line_color: Some(value) }
    "fontcolor" => { ..self, font_color: Some(value) }
    "linethickness" =>
      parse_nonnegative_int(value).map_or(self, thickness => {
        ..self,
        line_thickness: Some(thickness.max(1)),
      })
    "roundcorner" =>
      parse_nonnegative_int(value).map_or(self, corner => {
        ..self,
        round_corner: Some(corner),
      })
    "sameclasswidth" =>
      parse_bool(value).map_or(self, same_width => {
        ..self,
        same_class_width: Some(same_width),
      })
    "horizontalalignment" =>
      match value.to_lower() {
        "left" => { ..self, alignment: Some(Left) }
        "right" => { ..self, alignment: Some(Right) }
        "center" | "centre" => { ..self, alignment: Some(Center) }
        _ => self
      }
    _ => self
  }
}

///|
fn MindmapArrowStyle::with_property(
  self : MindmapArrowStyle,
  key : String,
  value : String,
) -> MindmapArrowStyle {
  match key.to_lower().replace(old=":", new="") {
    "linecolor" | "color" =>
      { ..self, line_color: Some(value.trim().to_owned()) }
    "linethickness" =>
      parse_nonnegative_int(value).map_or(self, thickness => {
        ..self,
        line_thickness: Some(thickness.max(1)),
      })
    _ => self
  }
}

///|
fn normalized_stereotype(value : String) -> String {
  value.trim().trim_start(chars="<").trim_end(chars=">").to_lower().to_owned()
}

///|
pub fn MindmapStyle::apply_node_property(
  self : MindmapStyle,
  selector : String,
  key : String,
  value : String,
) -> Unit {
  let selector = selector.trim().to_lower()
  if selector == "node" || selector == "mindmapdiagram node" {
    self.node = self.node.with_property(key, value)
  } else if selector == "rootnode" {
    self.root_node = self.root_node.with_property(key, value)
  } else if selector == "leafnode" {
    self.leaf_node = self.leaf_node.with_property(key, value)
  } else if selector.has_prefix(".") {
    let name = normalized_stereotype(selector[1:].to_owned())
    let current = self.stereotypes
      .get(name)
      .unwrap_or(MindmapNodeStyle::empty())
    self.stereotypes[name] = current.with_property(key, value)
  }
}

///|
pub fn MindmapStyle::apply_arrow_property(
  self : MindmapStyle,
  key : String,
  value : String,
) -> Unit {
  self.arrow = self.arrow.with_property(key, value)
}

///|
pub fn MindmapStyle::apply_skinparam(
  self : MindmapStyle,
  directive : @core.StyleDirective,
) -> Unit {
  match directive {
    Property(key, value) => {
      let normalized = key.to_lower().replace(old="-", new="")
      if normalized.has_prefix("mindmapnode") {
        self.apply_node_property("Node", key[11:].to_owned(), value)
      } else if normalized.has_prefix("mindmaparrow") {
        self.apply_arrow_property(key[12:].to_owned(), value)
      }
    }
    _ => ()
  }
}

///|
pub fn MindmapStyle::node_style(
  self : MindmapStyle,
  idea : Idea,
  has_children : Bool,
) -> MindmapNodeStyle {
  let mut result = MindmapNodeStyle::defaults().merge(self.node)
  if idea.parent is None {
    result = result.merge(self.root_node)
  } else if !has_children {
    result = result.merge(self.leaf_node)
  }
  match idea.stereotype {
    Some(stereotype) =>
      result.merge(
        self.stereotypes
        .get(normalized_stereotype(stereotype))
        .unwrap_or(MindmapNodeStyle::empty()),
      )
    None => result
  }
}
