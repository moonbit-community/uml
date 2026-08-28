///|
pub(all) enum TextAlignment {
  Left
  Center
  Right
} derive(Eq, Debug)

///|
pub extend TextAlignment with Eq::{not_equal, equal}

///|
pub extend TextAlignment with Debug::{to_repr}

///|
/// The tree-diagram family selects default constants and the selector and
/// skinparam prefixes shared by node, root, leaf, and arrow rules.
pub(all) enum TreeDiagramFamily {
  Mindmap
  Wbs
} derive(Eq, Debug)

///|
pub extend TreeDiagramFamily with Eq::{not_equal, equal}

///|
pub extend TreeDiagramFamily with Debug::{to_repr}

///|
/// Node geometry and paint rules shared by tree diagrams. Each family ignores
/// the fields it does not use (mindmaps the WBS-only `width_auto`, WBS the
/// mindmap-only `same_class_width`), so the parsing and precedence logic
/// lives once.
pub(all) struct TreeNodeStyle {
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
  width_auto : Bool?
  alignment : TextAlignment?
} derive(Eq, Debug)

///|
pub extend TreeNodeStyle with Eq::{not_equal, equal}

///|
pub extend TreeNodeStyle with Debug::{to_repr}

///|
pub(all) struct TreeArrowStyle {
  line_color : String?
  line_thickness : Int?
} derive(Eq, Debug)

///|
pub extend TreeArrowStyle with Eq::{not_equal, equal}

///|
pub extend TreeArrowStyle with Debug::{to_repr}

///|
/// The layered node/arrow style container of a tree diagram. The `family`
/// drives default constants and the selector/skinparam prefixes.
pub(all) struct TreeStyle {
  family : TreeDiagramFamily
  mut node : TreeNodeStyle
  mut root_node : TreeNodeStyle
  mut leaf_node : TreeNodeStyle
  stereotypes : Map[String, TreeNodeStyle]
  mut arrow : TreeArrowStyle
} derive(Eq, Debug)

///|
pub extend TreeStyle with Eq::{not_equal, equal}

///|
pub extend TreeStyle with Debug::{to_repr}

///|
pub type MindmapStyle = TreeStyle

///|
pub type MindmapNodeStyle = TreeNodeStyle

///|
pub type MindmapArrowStyle = TreeArrowStyle

///|
pub type WbsStyle = TreeStyle

///|
pub type WbsNodeStyle = TreeNodeStyle

///|
pub type WbsArrowStyle = TreeArrowStyle

///|
pub const MINDMAP_DEFAULT_PADDING_X : Int = 10

///|
pub const MINDMAP_DEFAULT_PADDING_Y : Int = 10

///|
pub const MINDMAP_DEFAULT_MARGIN : Int = 10

///|
pub const WBS_DEFAULT_PADDING_X : Int = 10

///|
pub const WBS_DEFAULT_PADDING_Y : Int = 10

///|
pub const WBS_DEFAULT_MARGIN : Int = 15

///|
pub const WBS_DEFAULT_FONT_SIZE : Int = 12

///|
pub fn TreeNodeStyle::empty() -> TreeNodeStyle {
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
    width_auto: None,
    alignment: None,
  }
}

///|
pub fn TreeNodeStyle::defaults(family : TreeDiagramFamily) -> TreeNodeStyle {
  match family {
    Mindmap =>
      {
        ..TreeNodeStyle::empty(),
        padding_x: Some(MINDMAP_DEFAULT_PADDING_X),
        padding_y: Some(MINDMAP_DEFAULT_PADDING_Y),
        margin_left: Some(MINDMAP_DEFAULT_MARGIN),
        margin_right: Some(MINDMAP_DEFAULT_MARGIN),
        margin_top: Some(MINDMAP_DEFAULT_MARGIN),
        margin_bottom: Some(MINDMAP_DEFAULT_MARGIN),
        alignment: Some(Left),
      }
    Wbs =>
      {
        ..TreeNodeStyle::empty(),
        padding_x: Some(WBS_DEFAULT_PADDING_X),
        padding_y: Some(WBS_DEFAULT_PADDING_Y),
        margin_left: Some(WBS_DEFAULT_MARGIN),
        margin_right: Some(WBS_DEFAULT_MARGIN),
        margin_top: Some(WBS_DEFAULT_MARGIN),
        margin_bottom: Some(WBS_DEFAULT_MARGIN),
        font_size: Some(WBS_DEFAULT_FONT_SIZE),
        round_corner: Some(0),
        alignment: Some(Left),
      }
  }
}

///|
pub fn TreeArrowStyle::defaults() -> TreeArrowStyle {
  { line_color: None, line_thickness: Some(1) }
}

///|
pub fn TreeStyle::default(family : TreeDiagramFamily) -> TreeStyle {
  {
    family,
    node: TreeNodeStyle::empty(),
    root_node: TreeNodeStyle::empty(),
    leaf_node: TreeNodeStyle::empty(),
    stereotypes: {},
    arrow: TreeArrowStyle::defaults(),
  }
}

///|
fn[T] Option::fallback(self : T?, fallback : T?) -> T? {
  self.map_or(fallback, value => Some(value))
}

///|
pub fn TreeNodeStyle::merge(
  self : TreeNodeStyle,
  overlay : TreeNodeStyle,
) -> TreeNodeStyle {
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
    width_auto: overlay.width_auto.fallback(self.width_auto),
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
pub fn TreeNodeStyle::with_property(
  self : TreeNodeStyle,
  key : String,
  value : String,
) -> TreeNodeStyle {
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
    "width" =>
      match value.equal_ignore_ascii_case("auto") {
        true => { ..self, width_auto: Some(true) }
        false => self
      }
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
pub fn TreeArrowStyle::with_property(
  self : TreeArrowStyle,
  key : String,
  value : String,
) -> TreeArrowStyle {
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
fn family_diagram_prefix(family : TreeDiagramFamily) -> String {
  match family {
    Mindmap => "mindmapdiagram "
    Wbs => "wbsdiagram "
  }
}

///|
fn family_node_skinparam_prefix(family : TreeDiagramFamily) -> String {
  match family {
    Mindmap => "mindmapnode"
    Wbs => "wbsnode"
  }
}

///|
fn family_arrow_skinparam_prefix(family : TreeDiagramFamily) -> String {
  match family {
    Mindmap => "mindmaparrow"
    Wbs => "wbsarrow"
  }
}

///|
pub fn TreeStyle::apply_node_property(
  self : TreeStyle,
  selector : String,
  key : String,
  value : String,
) -> Unit {
  let mut selector = selector.trim().to_lower()
  let prefix = family_diagram_prefix(self.family)
  if selector.has_prefix(prefix) {
    selector = selector[prefix.length():]
  }
  if selector == "node" {
    self.node = self.node.with_property(key, value)
  } else if selector == "rootnode" {
    self.root_node = self.root_node.with_property(key, value)
  } else if selector == "leafnode" {
    self.leaf_node = self.leaf_node.with_property(key, value)
  } else if selector.has_prefix(".") {
    let name = normalized_stereotype(selector[1:].to_owned())
    let current = self.stereotypes
      .get(name)
      .unwrap_or(TreeNodeStyle::empty())
    self.stereotypes[name] = current.with_property(key, value)
  }
}

///|
pub fn TreeStyle::apply_arrow_property(
  self : TreeStyle,
  key : String,
  value : String,
) -> Unit {
  self.arrow = self.arrow.with_property(key, value)
}

///|
pub fn TreeStyle::apply_skinparam(
  self : TreeStyle,
  directive : @style.StyleDirective,
) -> Unit {
  match directive {
    Property(key, value) => {
      let normalized = key.to_lower().replace(old="-", new="")
      let node_prefix = family_node_skinparam_prefix(self.family)
      let arrow_prefix = family_arrow_skinparam_prefix(self.family)
      if normalized.has_prefix(node_prefix) {
        self.apply_node_property(
          "Node",
          normalized[node_prefix.length():].to_owned(),
          value,
        )
      } else if normalized.has_prefix(arrow_prefix) {
        self.apply_arrow_property(
          normalized[arrow_prefix.length():].to_owned(),
          value,
        )
      }
    }
    _ => ()
  }
}

///|
pub fn TreeStyle::node_style(
  self : TreeStyle,
  is_root : Bool,
  has_children : Bool,
  stereotype : String?,
) -> TreeNodeStyle {
  let mut result = TreeNodeStyle::defaults(self.family).merge(self.node)
  if is_root {
    result = result.merge(self.root_node)
  } else if !has_children {
    result = result.merge(self.leaf_node)
  }
  guard stereotype is Some(value) else { return result }
  result.merge(
    self.stereotypes
    .get(normalized_stereotype(value))
    .unwrap_or(TreeNodeStyle::empty()),
  )
}
