///|
/// Strip leading zeroes from a digit string, keeping a single zero.
fn normalize_digits(value : String) -> String {
  let mut index = 0
  while index < value.length() - 1 && value[index] == '0' {
    index += 1
  }
  value[index:].to_owned()
}

///|
/// The ASCII character for a single decimal digit.
fn digit_char(digit : Int) -> Char {
  (digit + 48).to_char().unwrap()
}

///|
fn rev_string(value : String) -> String {
  let chars = value.to_array()
  let output = StringBuilder()
  let mut index = chars.length() - 1
  while index >= 0 {
    output.write_char(chars[index])
    index -= 1
  }
  output.to_string()
}

///|
fn digits_longer(a : String, b : String) -> Bool {
  a.length() > b.length() || (a.length() == b.length() && a > b)
}

///|
/// Unsigned digit-string addition.
fn add_digits(a : String, b : String) -> String {
  let output = StringBuilder()
  let mut carry = 0
  let mut index = 0
  while index < a.length() || index < b.length() {
    let digit_a = if index < a.length() {
      a[a.length() - 1 - index].to_int() - 48
    } else {
      0
    }
    let digit_b = if index < b.length() {
      b[b.length() - 1 - index].to_int() - 48
    } else {
      0
    }
    let total = digit_a + digit_b + carry
    output.write_char(digit_char(total % 10))
    carry = total / 10
    index += 1
  }
  if carry > 0 {
    output.write_char(digit_char(carry))
  }
  rev_string(output.to_string())
}

///|
/// Unsigned digit-string subtraction, requiring `a >= b`.
fn sub_digits(a : String, b : String) -> String {
  let chars_a = a.to_array()
  let chars_b = b.to_array()
  let output = StringBuilder()
  let mut borrow = 0
  let mut index = 0
  while index < chars_a.length() {
    let digit_a = chars_a[chars_a.length() - 1 - index].to_int() - 48 - borrow
    let digit_b = if index < chars_b.length() {
      chars_b[chars_b.length() - 1 - index].to_int() - 48
    } else {
      0
    }
    let mut digit = digit_a - digit_b
    if digit < 0 {
      digit += 10
      borrow = 1
    } else {
      borrow = 0
    }
    output.write_char(digit_char(digit))
    index += 1
  }
  normalize_digits(rev_string(output.to_string()))
}

///|
/// Unsigned digit-string multiplication by a small positive integer.
fn mul_digits_int(a : String, factor : Int) -> String {
  if factor == 0 {
    return "0"
  }
  let chars = a.to_array()
  let output = StringBuilder()
  let mut carry = 0
  let mut index = chars.length() - 1
  while index >= 0 {
    let total = (chars[index].to_int() - 48) * factor + carry
    output.write_char(digit_char(total % 10))
    carry = total / 10
    index -= 1
  }
  while carry > 0 {
    output.write_char(digit_char(carry % 10))
    carry = carry / 10
  }
  rev_string(output.to_string())
}

///|
/// Shift a digit string by `zeros` decimal positions.
fn shift_digits(a : String, zeros : Int) -> String {
  if a == "0" {
    return a
  }
  let output = StringBuilder()
  output.write_string(a)
  for _ in 0..<zeros {
    output.write_char('0')
  }
  output.to_string()
}

///|
fn parse_digits(cursor : @parse.Cursor) -> String? {
  let digits = cursor.take_while(char => char >= '0' && char <= '9')
  if digits.length() == 0 {
    None
  } else {
    Some(normalize_digits(digits))
  }
}

///|
/// Parse a decimal literal the way `BigDecimal(String)` does for the numeric
/// forms produced by the timing grammars: optional sign, digits, one dot.
///
/// `10.`, `.5`, `+12` and `-0.25` are all accepted; scientific notation is
/// rejected because the grammars never produce it.
fn @flow.Decimal::parse(raw : String) -> @flow.Decimal? {
  let cursor = @parse.Cursor::new(raw)
  let sign = if cursor.consume('-') {
    -1
  } else {
    ignore(cursor.consume('+'))
    1
  }
  let mut whole = ""
  let mut fraction = ""
  let mut trailing_dot = false
  if cursor.consume('.') {
    guard parse_digits(cursor) is Some(digits) else { return None }
    fraction = digits
  } else {
    guard parse_digits(cursor) is Some(digits) else { return None }
    whole = digits
    if cursor.consume('.') {
      if parse_digits(cursor) is Some(digits) {
        fraction = digits
      } else {
        // A trailing dot keeps one fractional position, like BigDecimal("5.").
        trailing_dot = true
      }
    }
  }
  guard cursor.is_eof() else { return None }
  Some(decimal(sign, whole, fraction, trailing_dot))
}

///|
fn decimal(
  sign : Int,
  whole : String,
  fraction : String,
  trailing_dot : Bool,
) -> @flow.Decimal {
  let scale = if trailing_dot { 1 } else { fraction.length() }
  let tail = if trailing_dot { "0" } else { "" }
  let coeff = normalize_digits(whole + fraction + tail)
  { sign, coeff: if coeff == "0" { "0" } else { coeff }, scale, }
}

///|
fn @flow.Decimal::is_zero(self : @flow.Decimal) -> Bool {
  self.coeff == "0"
}

///|
fn @flow.Decimal::negate(self : @flow.Decimal) -> @flow.Decimal {
  { ..self, sign: if self.sign < 0 { 1 } else { -1 }, }
}

///|
fn @flow.Decimal::scaled(self : @flow.Decimal, target : Int) -> String {
  shift_digits(self.coeff, target - self.scale)
}

///|
/// Exact decimal addition, mirroring `BigDecimal.add`.
fn @flow.Decimal::add(
  self : @flow.Decimal,
  other : @flow.Decimal,
) -> @flow.Decimal {
  let scale = self.scale.max(other.scale)
  let a = self.scaled(scale)
  let b = other.scaled(scale)
  let (sign, coeff) = if self.sign == other.sign {
    (self.sign, add_digits(a, b))
  } else if digits_longer(a, b) {
    (self.sign, sub_digits(a, b))
  } else {
    (other.sign, sub_digits(b, a))
  }
  { sign, coeff: normalize_digits(coeff), scale, }
}

///|
/// Exact multiplication by a positive integer, mirroring
/// `BigDecimal.multiply(BigDecimal.valueOf(nb))`.
fn @flow.Decimal::mul_int(self : @flow.Decimal, factor : Int) -> @flow.Decimal {
  { ..self, coeff: mul_digits_int(self.coeff, factor), }
}

///|
/// Value comparison, mirroring `BigDecimal.compareTo`: equal values with
/// different scales compare equal.
fn @flow.Decimal::compare(self : @flow.Decimal, other : @flow.Decimal) -> Int {
  if self.sign != other.sign {
    return compare_int(self.sign, other.sign)
  }
  if self.sign < 0 {
    return other.compare(self)
  }
  let scale = self.scale.max(other.scale)
  let a = self.scaled(scale)
  let b = other.scaled(scale)
  if a.length() != b.length() {
    return if a.length() > b.length() { 1 } else { -1 }
  }
  if a == b {
    return 0
  }
  if a > b {
    1
  } else {
    -1
  }
}

///|
fn compare_int(a : Int, b : Int) -> Int {
  if a > b {
    1
  } else if a < b {
    -1
  } else {
    0
  }
}

///|
/// Renders the value like `BigDecimal.toPlainString`: no exponent, no
/// trailing dot, keeping the fraction exactly as scaled.
fn @flow.Decimal::to_plain_string(self : @flow.Decimal) -> String {
  let output = StringBuilder()
  if self.sign < 0 && !self.is_zero() {
    output.write_char('-')
  }
  if self.scale == 0 {
    output.write_string(self.coeff)
  } else {
    let digits = self.coeff
    let integral = if digits.length() <= self.scale {
      "0"
    } else {
      digits[:digits.length() - self.scale].to_owned()
    }
    output.write_string(integral)
    output.write_char('.')
    if digits.length() <= self.scale {
      for _ in 0..<(self.scale - digits.length()) {
        output.write_char('0')
      }
    }
    output.write_string(digits[digits.length() - self.scale:].to_owned())
  }
  output.to_string()
}

///|
fn @flow.TimeTick::compare(
  self : @flow.TimeTick,
  other : @flow.TimeTick,
) -> Int {
  self.time.compare(other.time)
}

///|
/// Render a decimal time value in its plain source form.
pub fn decimal_to_plain_string(decimal : @flow.Decimal) -> String {
  decimal.to_plain_string()
}
