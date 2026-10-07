///|
pub enum PreValue {
  String(String)
  Number(Double)
  Array(Array[PreValue])
  Object(Map[String, PreValue])
  True
  False
  Null
} derive(Eq)

///|
pub extend PreValue with Eq::{not_equal, equal}

///|
fn PreValue::number(value : Double) -> PreValue {
  Number(value)
}

///|
fn PreValue::to_json(self : PreValue) -> Json {
  match self {
    String(text) => Json::string(text)
    Number(number) => Json::number(number)
    True => Json::boolean(true)
    False => Json::boolean(false)
    Null => Json::null()
    Array(values) => Json::array(values.map(value => value.to_json()))
    Object(values) => {
      let object : Map[String, Json] = Map([])
      for key, value in values {
        object[key] = value.to_json()
      }
      Json::object(object)
    }
  }
}

///|
fn pre_text(value : PreValue) -> String {
  match value {
    String(text) => text
    Null => ""
    True => "1"
    False => "0"
    _ => value.to_json().stringify()
  }
}

///|
fn pre_truth(value : PreValue) -> Bool {
  match value {
    False | Null => false
    Number(number) => number != 0
    String(text) => !text.is_empty() && text != "0"
    _ => true
  }
}

///|
priv struct PreExpression {
  cursor : Cursor
  preprocessor : Preprocessor
}

///|
fn pre_identifier(char : Char) -> Bool {
  char == '$' || char == '%' || @identifier.is_identifier_char(char)
}

///|
fn Preprocessor::evaluate(
  self : Preprocessor,
  text : String,
) -> PreValue raise ParseError {
  let expression = { cursor: Cursor::new(text), preprocessor: self, }
  let value = expression.expression(0)
  expression.cursor.skip_inline_spaces()
  guard expression.cursor.is_eof() else {
    raise SyntaxError(self.line, "invalid preprocessor expression: " + text)
  }
  value
}

///|
fn PreExpression::expression(
  self : PreExpression,
  minimum : Int,
) -> PreValue raise ParseError {
  let mut left = self.atom()
  while true {
    self.cursor.skip_inline_spaces()
    let operator = [
        "||", "&&", "==", "!=", ">=", "<=", ">", "<", "+", "-", "*", "/", "%",
      ]
      .iter()
      .find_first(op => self.cursor.starts_with_literal(op))
    guard operator is Some(operator) else { break }
    let priority = match operator {
      "||" => 1
      "&&" => 2
      "==" | "!=" | ">=" | "<=" | ">" | "<" => 3
      "+" | "-" => 4
      _ => 5
    }
    guard priority >= minimum else { break }
    ignore(self.cursor.consume_literal(operator))
    let right = self.expression(priority + 1)
    left = pre_binary(left, operator, right, self.preprocessor.line)
  }
  left
}

///|
fn PreExpression::atom(self : PreExpression) -> PreValue raise ParseError {
  let cursor = self.cursor
  cursor.skip_inline_spaces()
  let mut value : PreValue = if cursor.consume('!') {
    if pre_truth(self.atom()) {
      False
    } else {
      True
    }
  } else if cursor.consume('-') {
    let value = self.atom()
    match value {
      Number(n) => PreValue::number(-n)
      _ => raise SyntaxError(self.preprocessor.line, "expected a number")
    }
  } else if cursor.consume('(') {
    let value = self.expression(0)
    cursor.skip_inline_spaces()
    guard cursor.consume(')') else {
      raise SyntaxError(self.preprocessor.line, "unclosed expression")
    }
    value
  } else if cursor.peek() is Some('"' | '\'') {
    let quote = cursor.advance().unwrap()
    let output = StringBuilder()
    while cursor.advance() is Some(char) {
      if char == quote {
        break
      }
      if char == '\\' {
        if cursor.advance() is Some(escaped) {
          output.write_char(
            match escaped {
              'n' => '\n'
              't' => '\t'
              _ => escaped
            },
          )
        }
      } else {
        output.write_char(char)
      }
    }
    String(output.to_string())
  } else if cursor.consume('[') {
    let values : Array[PreValue] = []
    cursor.skip_inline_spaces()
    if !cursor.consume(']') {
      while true {
        values.push(self.expression(0))
        cursor.skip_inline_spaces()
        if cursor.consume(']') {
          break
        }
        guard cursor.consume(',') else {
          raise SyntaxError(self.preprocessor.line, "expected comma in array")
        }
      }
    }
    Array(values)
  } else if cursor.consume('{') {
    let values : Map[String, PreValue] = Map([])
    cursor.skip_inline_spaces()
    if !cursor.consume('}') {
      while true {
        let key = pre_text(self.atom())
        cursor.skip_inline_spaces()
        guard cursor.consume(':') else {
          raise SyntaxError(self.preprocessor.line, "expected colon in object")
        }
        values[key] = self.expression(0)
        cursor.skip_inline_spaces()
        if cursor.consume('}') {
          break
        }
        guard cursor.consume(',') else {
          raise SyntaxError(self.preprocessor.line, "expected comma in object")
        }
      }
    }
    Object(values)
  } else if cursor.peek().map_or(false, char => char.is_ascii_digit()) {
    let token = cursor.take_while(char => char.is_ascii_digit() || char == '.')
    PreValue::number(
      @string.parse_double(token) catch {
        _ =>
          raise SyntaxError(self.preprocessor.line, "invalid number: " + token)
      },
    )
  } else {
    let name = cursor.take_while(pre_identifier)
    guard !name.is_empty() else {
      raise SyntaxError(self.preprocessor.line, "expected preprocessor value")
    }
    let after_name = cursor.offset()
    cursor.skip_inline_spaces()
    if cursor.consume('(') {
      let arguments = self.arguments()
      self.preprocessor.call_value(name, arguments)
    } else {
      ignore(cursor.restore(after_name))
      match name {
        "true" => True
        "false" => False
        "null" => Null
        _ => self.preprocessor.variables.get(name).unwrap_or(String(name))
      }
    }
  }
  while true {
    let after_value = cursor.offset()
    cursor.skip_inline_spaces()
    let key = if cursor.consume('.') {
      let name = cursor.take_while(pre_identifier)
      guard !name.is_empty() else {
        raise SyntaxError(self.preprocessor.line, "missing member name")
      }
      Some(String(name))
    } else if cursor.consume('[') {
      let key = self.expression(0)
      cursor.skip_inline_spaces()
      guard cursor.consume(']') else {
        raise SyntaxError(self.preprocessor.line, "unclosed index")
      }
      Some(key)
    } else {
      None
    }
    guard key is Some(key) else {
      ignore(cursor.restore(after_value))
      break
    }
    value = match (value, key) {
      (Object(object), key) => object.get(pre_text(key)).unwrap_or(Null)
      (Array(values), Number(index)) =>
        values.get(index.to_int()).unwrap_or(Null)
      _ => Null
    }
  }
  value
}

///|
fn PreExpression::arguments(
  self : PreExpression,
) -> Array[PreValue] raise ParseError {
  let result : Array[PreValue] = []
  self.cursor.skip_inline_spaces()
  if self.cursor.consume(')') {
    return result
  }
  while true {
    result.push(self.expression(0))
    self.cursor.skip_inline_spaces()
    if self.cursor.consume(')') {
      break
    }
    guard self.cursor.consume(',') else {
      raise SyntaxError(self.preprocessor.line, "expected comma in arguments")
    }
  }
  result
}

///|
fn pre_binary(
  left : PreValue,
  operator : String,
  right : PreValue,
  line : Int,
) -> PreValue raise ParseError {
  let boolean = (value : Bool) => {
    if value {
      PreValue::True
    } else {
      PreValue::False
    }
  }
  match operator {
    "||" => boolean(pre_truth(left) || pre_truth(right))
    "&&" => boolean(pre_truth(left) && pre_truth(right))
    "==" => boolean(left == right)
    "!=" => boolean(left != right)
    "+" if !(left is Number(_) && right is Number(_)) =>
      String(pre_text(left) + pre_text(right))
    _ => {
      let comparison = match (left, right) {
        (Number(a), Number(b)) => a.compare(b)
        _ => pre_text(left).compare(pre_text(right))
      }
      match operator {
        ">" => boolean(comparison > 0)
        "<" => boolean(comparison < 0)
        ">=" => boolean(comparison >= 0)
        "<=" => boolean(comparison <= 0)
        _ => {
          guard left is Number(a) && right is Number(b) else {
            raise SyntaxError(line, "arithmetic needs numbers")
          }
          match operator {
            "+" => PreValue::number(a + b)
            "-" => PreValue::number(a - b)
            "*" => PreValue::number(a * b)
            "/" if b != 0 => PreValue::number((a / b).trunc())
            "%" if b != 0 => PreValue::number(a % b)
            _ => raise SyntaxError(line, "division by zero")
          }
        }
      }
    }
  }
}
