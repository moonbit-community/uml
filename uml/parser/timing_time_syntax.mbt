///|
/// A time expression as matched by `TimeTickBuilder.expressionAtWithoutArobase`.
///
/// The variant order mirrors the regex alternation order; resolution follows
/// `TimeTickBuilder.parseTimeTick`.
priv enum TimeExpr {
  Code(String, @flow.Decimal?)
  Date(Int, Int, Int)
  Hour(Int, Int, Int)
  Digit(Bool, @flow.Decimal)
  Clock(String, Int)
}

///|
fn parse_positive_int(value : String) -> Int {
  let mut result = 0
  for char in value {
    result = result * 10 + (char.to_int() - 48)
  }
  result
}

///|
/// Seconds since the Unix epoch of `yyyy/mm/dd` at 00:00 GMT, mirroring
/// `@flow.TimingFormat.createDate` with its GregorianCalendar in the GMT zone.
fn epoch_seconds(yyyy : Int, mm : Int, dd : Int) -> Int64 {
  let days = days_from_civil(yyyy, mm, dd)
  days * 86400L
}

///|
/// Days since 1970-01-01 of the proleptic Gregorian calendar.
fn days_from_civil(y : Int, m : Int, d : Int) -> Int64 {
  let shifted = if m <= 2 { y - 1 } else { y }
  let era = (if shifted >= 0 { shifted } else { shifted - 399 }) / 400
  let yoe = shifted - era * 400
  let month_adjust = if m > 2 { -3 } else { 9 }
  let doy = ((153 * (m + month_adjust) + 2) / 5 + d - 1).to_int64()
  let doe = (yoe * 365 + yoe / 4 - yoe / 100).to_int64() + doy
  era.to_int64() * 146097L + doe - 719468L
}

///|
/// Matches `:CODE([-+][.\d]+)?`, the first time-expression alternative.
fn match_code_expr(cursor : @parse.Cursor) -> TimeExpr? {
  guard cursor.consume(':') else { return None }
  let code = cursor.take_while(is_code_dot_char)
  guard code.length() > 0 else { return None }
  let delta = match cursor.peek() {
    Some(char) if char == '+' || char == '-' => {
      ignore(cursor.advance())
      let digits = cursor.take_while(char => {
        char == '.' || (char >= '0' && char <= '9')
      })
      if digits.length() == 0 {
        ignore(cursor.restore(cursor.offset() - 1))
      }
      digits
    }
    _ => ""
  }
  let delta = if delta.length() > 0 {
    guard @flow.Decimal::parse(delta) is Some(value) else { return None }
    Some(value)
  } else {
    None
  }
  Some(TimeExpr::Code(code, delta))
}

///|
/// Matches `\d+/\d+/\d+`, the second time-expression alternative, with
/// `yyyy/mm/dd` captured in that order.
fn match_date_expr(cursor : @parse.Cursor) -> TimeExpr? {
  guard match_ascii_digits(cursor) is Some(year) else { return None }
  guard cursor.consume('/') else { return None }
  guard match_ascii_digits(cursor) is Some(month) else { return None }
  guard cursor.consume('/') else { return None }
  guard match_ascii_digits(cursor) is Some(day) else { return None }
  Some(TimeExpr::Date(year, month, day))
}

///|
/// Matches `\d+:\d+:\d+`, the third time-expression alternative.
fn match_hour_expr(cursor : @parse.Cursor) -> TimeExpr? {
  guard match_ascii_digits(cursor) is Some(hour) else { return None }
  guard cursor.consume(':') else { return None }
  guard match_ascii_digits(cursor) is Some(minute) else { return None }
  guard cursor.consume(':') else { return None }
  guard match_ascii_digits(cursor) is Some(second) else { return None }
  Some(TimeExpr::Hour(hour, minute, second))
}

///|
/// Matches `(\+?)(-?\d+\.?\d*)`, the fourth time-expression alternative.
fn match_digit_expr(cursor : @parse.Cursor) -> TimeExpr? {
  let relative = cursor.consume('+')
  let start = cursor.offset()
  ignore(cursor.consume('-'))
  let whole = cursor.take_while(char => char >= '0' && char <= '9')
  guard whole.length() > 0 else {
    ignore(cursor.restore(start))
    return None
  }
  ignore(cursor.consume('.'))
  ignore(cursor.skip_while(char => char >= '0' && char <= '9'))
  let literal = cursor.slice(start, cursor.offset())
  guard @flow.Decimal::parse(literal) is Some(value) else { return None }
  Some(TimeExpr::Digit(relative, value))
}

///|
/// Matches `[%pLN_.@]+\*(\d+)`, the fifth time-expression alternative.
fn match_clock_expr(cursor : @parse.Cursor) -> TimeExpr? {
  let name = cursor.take_while(is_code_char)
  guard name.length() > 0 && cursor.consume('*') else { return None }
  guard match_ascii_digits(cursor) is Some(number) else { return None }
  Some(TimeExpr::Clock(name, number))
}

///|
fn match_ascii_digits(cursor : @parse.Cursor) -> Int? {
  let digits = cursor.take_while(char => char >= '0' && char <= '9')
  if digits.length() == 0 {
    None
  } else {
    Some(parse_positive_int(digits))
  }
}

///|
/// Tries every time-expression alternative at the current position, feeding
/// the first successful match to `continue_with`.
///
/// When the continuation rejects the match, the next alternative is tried,
/// mirroring the backtracking of the compiled regex alternation.
fn[T] with_time_expr(
  cursor : @parse.Cursor,
  continue_with : (TimeExpr) -> T?,
) -> T? {
  for branch in 0..<5 {
    let checkpoint = cursor.offset()
    let expr = match branch {
      0 => match_code_expr(cursor)
      1 => match_date_expr(cursor)
      2 => match_hour_expr(cursor)
      3 => match_digit_expr(cursor)
      _ => match_clock_expr(cursor)
    }
    if expr is Some(value) {
      if continue_with(value) is Some(result) {
        return Some(result)
      }
    }
    ignore(cursor.restore(checkpoint))
  }
  None
}

///|
/// Resolves a time expression against the diagram state, mirroring
/// `TimeTickBuilder.parseTimeTick`.
fn resolve_time_expr(
  parser : TimingParser,
  expr : TimeExpr?,
) -> @flow.TimeTick? {
  match expr {
    None => parser.diagram.now
    Some(expr) =>
      match expr {
        TimeExpr::Code(code, None) => parser.diagram.code_value(code)
        TimeExpr::Code(code, Some(delta)) => {
          guard parser.diagram.code_value(code) is Some(base) else {
            return None
          }
          Some(tick(base.time.add(delta), @flow.TimingFormat::Decimal))
        }
        TimeExpr::Clock(name, number) => {
          guard parser.diagram.clock(name) is Some(clock) else { return None }
          let period = clock.period.unwrap()
          let time = @flow.Decimal::parse(period).unwrap().mul_int(number)
          Some(tick(time, @flow.TimingFormat::Decimal))
        }
        TimeExpr::Hour(hour, minute, second) =>
          Some(
            tick(
              @flow.Decimal::parse(
                (3600 * hour + 60 * minute + second).to_string(),
              ).unwrap(),
              @flow.TimingFormat::Hour,
            ),
          )
        TimeExpr::Date(day, month, year) =>
          Some(
            tick(
              @flow.Decimal::parse(epoch_seconds(year, month, day).to_string()).unwrap(),
              @flow.TimingFormat::Date,
            ),
          )
        TimeExpr::Digit(relative, value) => {
          let time = if relative {
            guard parser.diagram.now is Some(current) else { value }
            current.time.add(value)
          } else {
            value
          }
          Some(tick(time, @flow.TimingFormat::Decimal))
        }
      }
  }
}

///|
fn tick(time : @flow.Decimal, format : @flow.TimingFormat) -> @flow.TimeTick {
  { time, format, }
}
