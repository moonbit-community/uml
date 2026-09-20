///|
/// Linear ruler shared by all timing tracks. One trailing interval is retained.
pub(all) struct TimingRulerLayout {
  minimum : Double
  maximum : Double
  unit : Double
  interval : Double
  width : Double
  marks : Array[Double]
}

///|
fn timing_decimal(value : @flow.Decimal) -> Double {
  timing_number(value.coeff + "e" + (-value.scale).to_string(), 0.0) *
  value.sign.to_double()
}

///|
fn timing_tick(value : @flow.TimeTick) -> Double {
  timing_decimal(value.time)
}

///|
/// Project absolute time onto the common wave origin, without rounding.
pub fn TimingRulerLayout::position(
  self : TimingRulerLayout,
  time : Double,
) -> Double {
  (time - self.minimum) / self.unit * self.interval
}

///|
fn timing_gcd(a : Int64, b : Int64) -> Int64 {
  for a = a.abs(), b = b.abs() {
    guard b != 0L else { break a }
    continue b, a % b
  }
}

///|
fn timing_ruler(diagram : @flow.TimingDiagram) -> TimingRulerLayout {
  let marks = diagram.time_marks.map(timing_tick)
  if marks.is_empty() {
    marks.push(0.0)
  }
  let minimum = marks[0]
  let maximum = marks[marks.length() - 1]
  if minimum < 0.0 && maximum > 0.0 && !marks.contains(0.0) {
    marks.push(0.0)
    marks.sort_by((a, b) => a.compare(b))
  }
  let gcd = marks.fold(init=0L, (gcd, mark) => timing_gcd(gcd, mark.to_int64()))
  // Degenerate or entirely fractional marks have no positive integer HCF.
  let common = if gcd > 0L { gcd.to_double() } else { 1.0 }
  let interval = diagram.scale.map_or(TIMING_TICK_PIXELS, scale => {
    scale.1.to_double()
  })
  let unit = diagram.scale.map_or_else(
    () => {
      if common == 1.0 &&
        ((maximum - minimum) / common + 1.0) * interval > TIMING_MAX_AUTO_WIDTH {
        (1.0 + interval * (maximum - minimum) / TIMING_MAX_AUTO_WIDTH).round()
      } else {
        common
      }
    },
    scale => scale.0.to_double(),
  )
  {
    minimum,
    maximum,
    unit,
    interval,
    width: ((maximum - minimum) / unit + 1.0) * interval,
    marks,
  }
}

///|
fn TimingRulerLayout::tick_count(self : TimingRulerLayout) -> Int {
  (1.0 + (self.maximum.trunc() - self.minimum.trunc()) / self.unit)
  .to_int()
  .min(TIMING_MAX_TICKS)
  .max(0)
}

///|
fn timing_time_label(diagram : @flow.TimingDiagram, value : Double) -> String {
  let format = diagram.time_marks.fold(init=@flow.TimingFormat::Decimal, (
    format,
    mark,
  ) => {
    if mark.format is @flow.TimingFormat::Decimal {
      format
    } else {
      mark.format
    }
  })
  let seconds = value.to_int64()
  let pad = (number : Int64) => {
    if number >= 0L && number < 10L {
      "0" + number.to_string()
    } else {
      number.to_string()
    }
  }
  if diagram.date_format is Some(_) || format is @flow.TimingFormat::Date {
    // Inverse of the parser's days_from_civil, in GMT like TimingFormat.
    let days = (value / 86400.0).floor().to_int64() + 719468L
    let era = (if days >= 0L { days } else { days - 146096L }) / 146097L
    let doe = days - era * 146097L
    let yoe = (doe - doe / 1460L + doe / 36524L - doe / 146096L) / 365L
    let year = yoe + era * 400L
    let doy = doe - (365L * yoe + yoe / 4L - yoe / 100L)
    let mp = (5L * doy + 2L) / 153L
    let day = doy - (153L * mp + 2L) / 5L + 1L
    let month = mp + (if mp < 10L { 3L } else { -9L })
    let year = year + (if month <= 2L { 1L } else { 0L })
    return diagram.date_format
      .unwrap_or("MM/dd")
      .replace(old="yyyy", new=year.to_string())
      .replace(old="MM", new=pad(month))
      .replace(old="dd", new=pad(day))
      .replace(old="HH", new=pad(seconds / 3600L % 24L))
      .replace(old="mm", new=pad(seconds / 60L % 60L))
      .replace(old="ss", new=pad(seconds % 60L))
  }
  if format is @flow.TimingFormat::Hour {
    seconds.div(3600L).to_string() +
    ":" +
    pad(seconds / 60L % 60L) +
    ":" +
    pad(seconds % 60L)
  } else if value == value.trunc() {
    seconds.to_string()
  } else {
    value.to_string()
  }
}
