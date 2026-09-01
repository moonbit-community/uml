///|
/// A `--keep` rule could not be parsed.
suberror KeepRuleError {
  Invalid(message~ : String)
}

///|
enum Axis { In; Out }

///|
enum Cmp { Lt; Le; Eq; Ne; Ge; Gt }

///|
enum Value { IntV(Int); MaxV; MinV }

///|
enum Expr {
  Atom(Axis, Cmp, Value)
  Not(Expr)
  And(Expr, Expr)
  Or(Expr, Expr)
}

///|
/// The node predicate produced by a parsed `--keep` rule.
type KeepPredicate = (@api.InOutDegrees) -> Bool

///|
/// Parse a `--keep` rule into a node predicate over `InOutDegrees`.
///
/// Grammar:
///
/// ```text
/// expr    := or
/// or      := and ('||' and)*
/// and     := unary ('&&' unary)*
/// unary   := '!' unary | primary
/// primary := '(' expr ')' | atom
/// atom    := [in | out] cmp value
/// cmp     := <= | >= | == | != | < | >
/// value   := integer | max | min
/// ```
///
/// An atom without an axis compares both axes and keeps the node when either
/// side matches: `>1` is `in > 1 or out > 1`.
pub fn parse_keep_rule(
  source : String,
) -> KeepPredicate raise KeepRuleError {
  let pos : Ref[Int] = { val: 0 }
  let expr = parse_or(source, pos)
  skip_ws(source, pos)
  if pos.val < source.length() {
    raise KeepRuleError::Invalid(message="unexpected trailing input")
  }
  (degrees) => expr.eval(degrees)
}

///|
fn Expr::eval(self : Expr, degrees : @api.InOutDegrees) -> Bool {
  match self {
    Atom(axis, cmp, value) => compare(axis, cmp, value, degrees)
    Not(inner) => !inner.eval(degrees)
    And(left, right) => left.eval(degrees) && right.eval(degrees)
    Or(left, right) => left.eval(degrees) || right.eval(degrees)
  }
}

///|
fn parse_or(source : String, pos : Ref[Int]) -> Expr raise KeepRuleError {
  let left = parse_and(source, pos)
  skip_ws(source, pos)
  if consume(source, pos, "||") {
    Or(left, parse_or(source, pos))
  } else {
    left
  }
}

///|
fn parse_and(source : String, pos : Ref[Int]) -> Expr raise KeepRuleError {
  let left = parse_unary(source, pos)
  skip_ws(source, pos)
  if consume(source, pos, "&&") {
    And(left, parse_and(source, pos))
  } else {
    left
  }
}

///|
fn parse_unary(source : String, pos : Ref[Int]) -> Expr raise KeepRuleError {
  skip_ws(source, pos)
  if consume(source, pos, "!") {
    Not(parse_unary(source, pos))
  } else {
    parse_primary(source, pos)
  }
}

///|
fn parse_primary(source : String, pos : Ref[Int]) -> Expr raise KeepRuleError {
  skip_ws(source, pos)
  if consume(source, pos, "(") {
    let inner = parse_or(source, pos)
    skip_ws(source, pos)
    if !consume(source, pos, ")") {
      raise KeepRuleError::Invalid(message="expected ')'")
    }
    inner
  } else {
    parse_atom(source, pos)
  }
}

///|
fn parse_atom(source : String, pos : Ref[Int]) -> Expr raise KeepRuleError {
  let axis = try_parse_axis(source, pos)
  let cmp = parse_cmp(source, pos)
  let value = parse_value(source, pos)
  match axis {
    Some(axis) => Atom(axis, cmp, value)
    None => Or(Atom(In, cmp, value), Atom(Out, cmp, value))
  }
}

///|
/// Whether `in` or `out` prefixes the comparison at the cursor.
fn try_parse_axis(source : String, pos : Ref[Int]) -> Option[Axis] {
  skip_ws(source, pos)
  let remaining = source.length() - pos.val
  if remaining >= 2 {
    let two = source.unsafe_substring(start=pos.val, end=pos.val + 2)
    let axis_len = if two == "in" {
      2
    } else if remaining >= 3 &&
      source.unsafe_substring(start=pos.val, end=pos.val + 3) == "out" {
      3
    } else {
      0
    }
    let after = pos.val + axis_len
    if axis_len > 0 && after < source.length() && is_cmp(source[after].to_int()) {
      pos.val = after
      Some(if two == "in" { In } else { Out })
    } else {
      None
    }
  } else {
    None
  }
}

///|
fn is_cmp(code : Int) -> Bool {
  code == '<'.to_int() || code == '>'.to_int() ||
  code == '='.to_int() || code == '!'.to_int()
}

///|
fn parse_cmp(source : String, pos : Ref[Int]) -> Cmp raise KeepRuleError {
  skip_ws(source, pos)
  if consume(source, pos, "<=") {
    Le
  } else if consume(source, pos, ">=") {
    Ge
  } else if consume(source, pos, "==") {
    Eq
  } else if consume(source, pos, "!=") {
    Ne
  } else if consume(source, pos, "<") {
    Lt
  } else if consume(source, pos, ">") {
    Gt
  } else {
    raise KeepRuleError::Invalid(message="expected a comparison operator")
  }
}

///|
fn parse_value(source : String, pos : Ref[Int]) -> Value raise KeepRuleError {
  skip_ws(source, pos)
  if consume(source, pos, "max") {
    return MaxV
  }
  if consume(source, pos, "min") {
    return MinV
  }
  let start = pos.val
  while pos.val < source.length() && is_digit(source[pos.val].to_int()) {
    pos.val = pos.val + 1
  }
  if pos.val == start {
    raise KeepRuleError::Invalid(message="expected a number, max, or min")
  }
  let number = for acc = 0, i = start {
    guard i < pos.val else { break acc }
    let digit = source[i].to_int() - '0'.to_int()
    continue acc * 10 + digit, i + 1
  }
  IntV(number)
}

///|
fn is_digit(code : Int) -> Bool {
  code >= '0'.to_int() && code <= '9'.to_int()
}

///|
fn compare(
  axis : Axis,
  cmp : Cmp,
  value : Value,
  degrees : @api.InOutDegrees,
) -> Bool {
  let degree = match axis {
    In => degrees.in_degree
    Out => degrees.out_degree
  }
  let bound = match value {
    IntV(n) => n
    MaxV =>
      match axis {
        In => degrees.max_in
        Out => degrees.max_out
      }
    MinV =>
      match axis {
        In => degrees.min_in
        Out => degrees.min_out
      }
  }
  match cmp {
    Lt => degree < bound
    Le => degree <= bound
    Eq => degree == bound
    Ne => degree != bound
    Ge => degree >= bound
    Gt => degree > bound
  }
}

///|
fn skip_ws(source : String, pos : Ref[Int]) -> Unit {
  while pos.val < source.length() && source[pos.val] == ' ' {
    pos.val = pos.val + 1
  }
}

///|
fn consume(source : String, pos : Ref[Int], literal : String) -> Bool {
  if pos.val + literal.length() <= source.length() &&
    source.unsafe_substring(start=pos.val, end=pos.val + literal.length()) ==
      literal {
    pos.val = pos.val + literal.length()
    true
  } else {
    false
  }
}
