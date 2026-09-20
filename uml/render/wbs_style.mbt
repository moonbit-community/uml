///|
/// wbsDiagram.LineThickness in plantuml.skin applies to boxes and tree links.
const WBS_LINE_THICKNESS : Double = 1.5

///|
priv struct WbsArrowPaint {
  line_color : String?
  line_thickness : Double
}

///|
fn wbs_has_children(diagram : @tree.WbsDiagram, index : Int) -> Bool {
  diagram.nodes.any(node => node.parent == Some(index))
}

///|
fn wbs_stereotype(value : String) -> String {
  value.trim().trim_start(chars="<").trim_end(chars=">").to_lower().to_owned()
}

///|
/// Match the WElement node signature or WBSTextBlock arrow signature.
fn wbs_selector_matches(
  selector : String,
  diagram : @tree.WbsDiagram,
  index : Int,
  arrow : Bool,
  stereotype : String?,
) -> Bool {
  let node = diagram.nodes[index]
  for word in selector.to_lower().split(" ") {
    guard !word.is_empty() else { continue }
    let matches = match word {
      "root" | "element" | "wbsdiagram" => true
      "node" => !arrow
      "arrow" => arrow
      "rootnode" => !arrow && node.parent is None
      "leafnode" =>
        !arrow && node.parent is Some(_) && !wbs_has_children(diagram, index)
      "boxless" => !arrow && node.shape is @tree.NodeShape::Boxless
      _ =>
        if word.has_prefix(".") {
          stereotype.map_or(false, value => {
            wbs_stereotype(value) == word[1:].to_owned()
          })
        } else if word.has_prefix("depth(") && word.has_suffix(")") {
          let level = @string.parse_int(word[6:word.length() - 1]) catch {
            _ => -1
          }
          level == node.level
        } else {
          false
        }
    }
    guard matches else { return false }
  }
  true
}

///|
/// Preserve source order among equally specific selectors.
fn wbs_properties(
  diagram : @tree.WbsDiagram,
  index : Int,
  arrow : Bool,
  stereotype : String?,
) -> Array[@tree.WbsStyleProperty] {
  let selected : Array[(Int, Int, @tree.WbsStyleProperty)] = []
  for order, property in diagram.style_properties {
    guard wbs_selector_matches(
      property.selector,
      diagram,
      index,
      arrow,
      stereotype,
    ) else {
      continue
    }
    let specificity = property.selector
      .to_lower()
      .split(" ")
      .fold(init=0, (score, word) => {
        score +
        (if word.has_prefix(".") {
          1000
        } else if word == "rootnode" ||
          word == "leafnode" ||
          word == "boxless" ||
          word.has_prefix("depth(") {
          100
        } else {
          1
        })
      })
    selected.push((specificity, order, property))
  }
  selected.sort_by((a, b) => if a.0 == b.0 { a.1 - b.1 } else { a.0 - b.0 })
  selected.map(value => value.2)
}

///|
fn wbs_node_style(
  diagram : @tree.WbsDiagram,
  index : Int,
) -> @tree.TreeNodeStyle {
  let base = @tree.TreeStyle::default(Wbs)
  for key, value in diagram.style.properties {
    base.apply_skinparam(@style.StyleDirective::Property(key, value))
  }
  let node = diagram.nodes[index]
  wbs_properties(diagram, index, false, node.stereotype).fold(
    init=base.node_style(
      node.parent is None,
      wbs_has_children(diagram, index),
      node.stereotype,
    ),
    (style, property) => style.with_property(property.name, property.value),
  )
}

///|
fn wbs_arrow_style(
  diagram : @tree.WbsDiagram,
  index : Int,
  stereotype : String?,
) -> WbsArrowPaint {
  let base = @tree.TreeStyle::default(Wbs)
  for key, value in diagram.style.properties {
    base.apply_skinparam(@style.StyleDirective::Property(key, value))
  }
  let style = wbs_properties(diagram, index, true, stereotype).fold(
    init=base.arrow,
    (style, property) => style.with_property(property.name, property.value),
  )
  {
    line_color: style.line_color,
    line_thickness: wbs_line_thickness(diagram, index, true, stereotype),
  }
}

///|
fn wbs_line_thickness(
  diagram : @tree.WbsDiagram,
  index : Int,
  arrow : Bool,
  stereotype : String?,
) -> Double {
  let key = if arrow { "wbsarrowlinethickness" } else { "wbsnodelinethickness" }
  let base = diagram.style
    .property(key)
    .map_or(WBS_LINE_THICKNESS, value => {
      @string.parse_double(value) catch {
        _ => WBS_LINE_THICKNESS
      }
    })
  wbs_properties(diagram, index, arrow, stereotype).fold(init=base, (
    width,
    property,
  ) => {
    guard property.name.equal_ignore_ascii_case("LineThickness") else {
      return width
    }
    let value = @string.parse_double(property.value) catch { _ => return width }
    if value >= 0.0 {
      value
    } else {
      width
    }
  })
}
