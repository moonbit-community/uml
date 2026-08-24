///|
/// Ordered JSON tree mirroring the `JsonValue` model PlantUML keeps in
/// `BodierJSon`. Object members keep their source order so the rendered
/// body rows match the input text.
pub(all) enum JsonNode {
  JsonObject(Array[JsonMember])
  JsonArray(Array[JsonNode])
  JsonString(String)
  JsonNumber(String)
  JsonBoolean(Bool)
  JsonNull
} derive(Eq, Debug)

///|
pub extend JsonNode with Eq::{not_equal, equal}

///|
pub extend JsonNode with Debug::{to_repr}

///|
pub(all) struct JsonMember {
  key : String
  value : JsonNode
} derive(Eq, Debug)

///|
pub extend JsonMember with Eq::{not_equal, equal}

///|
pub extend JsonMember with Debug::{to_repr}

///|
/// Inline text shown for a scalar value; compounds have no inline display.
fn JsonNode::display(self : JsonNode) -> String {
  match self {
    JsonString(text) => text
    JsonNumber(repr) => repr
    JsonBoolean(value) => if value { "true" } else { "false" }
    JsonNull => "null"
    JsonObject(_) | JsonArray(_) => ""
  }
}

///|
priv struct JsonTreeCursor {
  chars : Array[Char]
  mut index : Int
}

///|
/// Parse a JSON value into an ordered tree.
///
/// PlantUML's bundled parser accepts a plain value (scalar, array, object),
/// rejects trailing commas and malformed input, and reports a stable error.
fn parse_json_tree(source : String) -> JsonNode raise @parse.ParseError {
  let cursor = { chars: source.to_array(), index: 0 }
  cursor.skip_whitespace()
  guard cursor.index < cursor.chars.length() else {
    json_tree_error("empty JSON data")
  }
  let node = cursor.parse_value()
  cursor.skip_whitespace()
  guard cursor.index == cursor.chars.length() else {
    json_tree_error("trailing characters after JSON value")
  }
  node
}

///|
fn[A] json_tree_error(message : String) -> A raise @parse.ParseError {
  raise @parse.SyntaxError(1, message)
}

///|
fn JsonTreeCursor::skip_whitespace(self : JsonTreeCursor) -> Unit {
  while self.index < self.chars.length() {
    match self.chars[self.index] {
      ' ' | '\t' | '\n' | '\r' => self.index += 1
      _ => return
    }
  }
}

///|
fn JsonTreeCursor::consume(self : JsonTreeCursor, char : Char) -> Bool {
  guard self.index < self.chars.length() && self.chars[self.index] == char else {
    return false
  }
  self.index += 1
  true
}

///|
fn JsonTreeCursor::parse_value(
  self : JsonTreeCursor,
) -> JsonNode raise @parse.ParseError {
  self.skip_whitespace()
  guard self.index < self.chars.length() else {
    json_tree_error("unexpected end of JSON")
  }
  match self.chars[self.index] {
    '{' => self.parse_object()
    '[' => self.parse_array()
    '"' => JsonString(self.parse_string())
    't' => {
      self.expect_literal("true")
      JsonBoolean(true)
    }
    'f' => {
      self.expect_literal("false")
      JsonBoolean(false)
    }
    'n' => {
      self.expect_literal("null")
      JsonNull
    }
    '-' | '0'..='9' => JsonNumber(self.parse_number())
    _ => json_tree_error("invalid JSON value")
  }
}

///|
fn JsonTreeCursor::expect_literal(
  self : JsonTreeCursor,
  literal : String,
) -> Unit raise @parse.ParseError {
  let chars = literal.to_array()
  for offset, char in chars {
    guard self.index + offset < self.chars.length() &&
      self.chars[self.index + offset] == char else {
      json_tree_error("invalid JSON literal")
    }
  }
  self.index += chars.length()
}

///|
fn JsonTreeCursor::parse_object(
  self : JsonTreeCursor,
) -> JsonNode raise @parse.ParseError {
  ignore(self.consume('{'))
  self.skip_whitespace()
  let members : Array[JsonMember] = []
  if self.consume('}') {
    return JsonObject(members)
  }
  while true {
    self.skip_whitespace()
    let key = self.parse_string()
    self.skip_whitespace()
    guard self.consume(':') else {
      json_tree_error("expected ':' after object key")
    }
    let value = self.parse_value()
    members.push({ key, value })
    self.skip_whitespace()
    if self.consume('}') {
      return JsonObject(members)
    }
    guard self.consume(',') else {
      json_tree_error("expected ',' or '}' in JSON object")
    }
  } nobreak {
    json_tree_error("unreachable")
  }
}

///|
fn JsonTreeCursor::parse_array(
  self : JsonTreeCursor,
) -> JsonNode raise @parse.ParseError {
  ignore(self.consume('['))
  self.skip_whitespace()
  let elements : Array[JsonNode] = []
  if self.consume(']') {
    return JsonArray(elements)
  }
  while true {
    let value = self.parse_value()
    elements.push(value)
    self.skip_whitespace()
    if self.consume(']') {
      return JsonArray(elements)
    }
    guard self.consume(',') else {
      json_tree_error("expected ',' or ']' in JSON array")
    }
  } nobreak {
    json_tree_error("unreachable")
  }
}

///|
fn JsonTreeCursor::parse_string(
  self : JsonTreeCursor,
) -> String raise @parse.ParseError {
  guard self.consume('"') else { json_tree_error("expected string") }
  let output = StringBuilder()
  while self.index < self.chars.length() {
    match self.chars[self.index] {
      '"' => {
        self.index += 1
        return output.to_string()
      }
      '\\' => {
        self.index += 1
        guard self.index < self.chars.length() else {
          json_tree_error("unterminated string escape")
        }
        match self.chars[self.index] {
          '"' => output.write_char('"')
          '\\' => output.write_char('\\')
          '/' => output.write_char('/')
          'b' => output.write_char('\b')
          'f' => output.write_char('\f')
          'n' => output.write_char('\n')
          'r' => output.write_char('\r')
          't' => output.write_char('\t')
          'u' => {
            let hex = self.chars[self.index + 1:self.index + 5]
            guard hex.length() == 4 && hex.all(char => char.is_digit(16)) else {
              json_tree_error("invalid \\u escape")
            }
            let code_point = hex.fold(init=0, (value, digit) => {
              value * 16 + digit.to_int()
            })
            guard code_point.to_char() is Some(char) else {
              json_tree_error("invalid \\u escape")
            }
            output.write_char(char)
            self.index += 4
          }
          _ => json_tree_error("invalid string escape")
        }
        self.index += 1
      }
      char => {
        output.write_char(char)
        self.index += 1
      }
    }
  }
  json_tree_error("unterminated string")
}

///|
fn JsonTreeCursor::parse_number(
  self : JsonTreeCursor,
) -> String raise @parse.ParseError {
  let output = StringBuilder()
  if self.consume('-') {
    output.write_char('-')
    guard self.index < self.chars.length() else {
      json_tree_error("invalid number")
    }
  }
  if self.consume('0') {
    output.write_char('0')
    guard !(self.index < self.chars.length() &&
      self.chars[self.index].is_digit(10)) else {
      json_tree_error("leading zeros in JSON number")
    }
  } else {
    ignore(self.take_digits(output))
  }
  if self.consume('.') {
    output.write_char('.')
    guard self.take_digits(output) > 0 else {
      json_tree_error("missing fractional digits")
    }
  }
  if self.index < self.chars.length() &&
    (self.chars[self.index] == 'e' || self.chars[self.index] == 'E') {
    output.write_char(self.chars[self.index])
    self.index += 1
    if self.index < self.chars.length() &&
      (self.chars[self.index] == '+' || self.chars[self.index] == '-') {
      output.write_char(self.chars[self.index])
      self.index += 1
    }
    guard self.take_digits(output) > 0 else {
      json_tree_error("missing exponent digits")
    }
  }
  output.to_string()
}

///|
fn JsonTreeCursor::take_digits(
  self : JsonTreeCursor,
  output : StringBuilder,
) -> Int {
  let start = self.index
  while self.index < self.chars.length() && self.chars[self.index].is_digit(10) {
    output.write_char(self.chars[self.index])
    self.index += 1
  }
  self.index - start
}

///|
test "parse scalar json values" {
  @test.assert_eq(parse_json_tree("3"), JsonNumber("3"))
  @test.assert_eq(parse_json_tree("true"), JsonBoolean(true))
  @test.assert_eq(parse_json_tree("null"), JsonNull)
  @test.assert_eq(parse_json_tree("\"Ada\""), JsonString("Ada"))
}

///|
test "parse ordered json objects" {
  let tree = parse_json_tree("{\"name\": \"Ada\", \"active\": true}")
  match tree {
    JsonObject(members) => {
      @test.assert_eq(members.length(), 2)
      @test.assert_eq(members[0].key, "name")
      @test.assert_eq(members[0].value, JsonString("Ada"))
      @test.assert_eq(members[1].key, "active")
      @test.assert_eq(members[1].value, JsonBoolean(true))
    }
    _ => fail("expected object")
  }
}

///|
test "parse nested json arrays and objects" {
  let tree = parse_json_tree(
    "{\"tags\": [\"priority\", \"export\"], \"nested\": {\"locale\": \"en-GB\"}}",
  )
  match tree {
    JsonObject(members) => {
      match members[0].value {
        JsonArray(elements) => {
          @test.assert_eq(elements.length(), 2)
          @test.assert_eq(elements[1], JsonString("export"))
        }
        _ => fail("expected array")
      }
      match members[1].value {
        JsonObject(nested) => @test.assert_eq(nested[0].key, "locale")
        _ => fail("expected nested object")
      }
    }
    _ => fail("expected object")
  }
}

///|
test "parse braces and escapes inside strings" {
  let tree = parse_json_tree("{\"template\": \"{customer}/{order}\"}")
  match tree {
    JsonObject(members) =>
      @test.assert_eq(members[0].value, JsonString("{customer}/{order}"))
    _ => fail("expected object")
  }
  @test.assert_eq(
    parse_json_tree("\"a\\\"b\\\\c\\n\""),
    JsonString("a\"b\\c\n"),
  )
}

///|
test "parse numbers preserving their raw representation" {
  @test.assert_eq(parse_json_tree("-12.5e3"), JsonNumber("-12.5e3"))
  @test.assert_eq(parse_json_tree("0.25"), JsonNumber("0.25"))
}

///|
test "reject malformed json input" {
  for
    bad in [
      "{\"missing\":}", "{\"a\": 1,}", "{\"a\" 1}", "nul", "\"unterminated", "01",
      "1.2.3",
    ] {
    let failed = try {
      ignore(parse_json_tree(bad))
      false
    } catch {
      _ => true
    }
    @test.assert_eq(failed, true, msg=bad)
  }
}

///|
test "accept whitespace around json values" {
  let tree = parse_json_tree("  { \"a\" : [ 1 , 2 ] }  ")
  match tree {
    JsonObject(members) =>
      match members[0].value {
        JsonArray(elements) => @test.assert_eq(elements.length(), 2)
        _ => fail("expected array")
      }
    _ => fail("expected object")
  }
}
