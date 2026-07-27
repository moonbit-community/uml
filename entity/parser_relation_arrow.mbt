///|
fn find_substring(haystack : String, needle : String) -> Int? {
  @core.find_literal(haystack, needle)
}

///|
fn left_relation_end(arrow : String) -> RelationEnd {
  if arrow.has_prefix("<|:") {
    DefinedBy
  } else if arrow.has_prefix("<||") {
    Redefines
  } else if arrow.has_prefix("<|") || arrow.has_prefix("^") {
    Extension
  } else if arrow.has_prefix("}o") {
    CircleCrowfoot
  } else if arrow.has_prefix("|o") {
    CircleLine
  } else if arrow.has_prefix("}|") {
    LineCrowfoot
  } else if arrow.has_prefix("||") {
    DoubleLine
  } else if arrow.has_prefix("*") {
    CompositionEnd
  } else if arrow.has_prefix("o") {
    AggregationEnd
  } else if arrow.has_prefix("x") {
    NotNavigable
  } else if arrow.has_prefix("}") {
    Crowfoot
  } else if arrow.has_prefix("<<") {
    TriangleArrow
  } else if arrow.has_prefix("<") {
    Arrow
  } else if arrow.has_prefix("0)") {
    CircleConnect
  } else if arrow.has_prefix("0") {
    CircleEnd
  } else if arrow.has_prefix("@") {
    FilledCircle
  } else if arrow.has_prefix("()") ||
    arrow.has_prefix("))") ||
    arrow.has_prefix(")") {
    Parenthesis
  } else if arrow.has_prefix("#") {
    Square
  } else if arrow.has_prefix("+") {
    Plus
  } else {
    Plain
  }
}

///|
fn right_relation_end(arrow : String) -> RelationEnd {
  if arrow.has_suffix(":|>") {
    DefinedBy
  } else if arrow.has_suffix("||>") {
    Redefines
  } else if arrow.has_suffix("|>") || arrow.has_suffix("^") {
    Extension
  } else if arrow.has_suffix("o{") {
    CircleCrowfoot
  } else if arrow.has_suffix("o|") {
    CircleLine
  } else if arrow.has_suffix("|{") {
    LineCrowfoot
  } else if arrow.has_suffix("||") {
    DoubleLine
  } else if arrow.has_suffix("*") {
    CompositionEnd
  } else if arrow.has_suffix("o") {
    AggregationEnd
  } else if arrow.has_suffix("x") {
    NotNavigable
  } else if arrow.has_suffix("{") {
    Crowfoot
  } else if arrow.has_suffix(">>") {
    TriangleArrow
  } else if arrow.has_suffix(">") {
    Arrow
  } else if arrow.has_suffix("(0") {
    CircleConnect
  } else if arrow.has_suffix("0") {
    CircleEnd
  } else if arrow.has_suffix("@") {
    FilledCircle
  } else if arrow.has_suffix("()") ||
    arrow.has_suffix("((") ||
    arrow.has_suffix("(") {
    Parenthesis
  } else if arrow.has_suffix("#") {
    Square
  } else if arrow.has_suffix("+") {
    Plus
  } else if arrow.has_suffix("\\") {
    HalfArrowUp
  } else if arrow.has_suffix("//") {
    HalfArrowDown
  } else {
    Plain
  }
}

///|
fn relation_kind(
  left : RelationEnd,
  right : RelationEnd,
  arrow : String,
) -> RelationKind {
  if left is Extension ||
    right is Extension ||
    left is Redefines ||
    right is Redefines ||
    left is DefinedBy ||
    right is DefinedBy {
    if arrow.contains(".") {
      Realization
    } else {
      Extension
    }
  } else if left is CompositionEnd || right is CompositionEnd {
    Composition
  } else if left is AggregationEnd || right is AggregationEnd {
    Aggregation
  } else if arrow.contains(".") {
    Dependency
  } else {
    Association
  }
}

///|
fn relation_direction(arrow : String) -> RelationDirection {
  if arrow.contains("left") || arrow.contains("-le") || arrow.contains("-l") {
    Leftward
  } else if arrow.contains("right") ||
    arrow.contains("-ri") ||
    arrow.contains("-r") {
    Rightward
  } else if arrow.contains("up") || arrow.contains("-u") {
    Upward
  } else if arrow.contains("down") ||
    arrow.contains("-do") ||
    arrow.contains("-d") {
    Downward
  } else {
    Automatic
  }
}

///|
fn relation_style(arrow : String) -> String? {
  guard find_substring(arrow, "[") is Some(start) else { return None }
  guard find_substring(arrow[start + 1:].to_owned(), "]") is Some(length) else {
    return None
  }
  Some(arrow[start + 1:start + 1 + length].to_owned())
}

///|
fn relation_inside(arrow : String) -> String? {
  for inside in ["(0)", "(0", "0)"] {
    if arrow.contains(inside) {
      return Some(inside)
    }
  }
  None
}

///|
