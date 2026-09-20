///|
/// Java-compatible pseudorandom generator for deterministic PlantUML geometry.
/// Callers own seed selection and the order of random draws.
priv struct JavaRandom {
  mut seed : Int64
}

///|
fn JavaRandom::new(seed : Int64) -> JavaRandom {
  { seed: (seed ^ 0x5DEECE66DL) & 0xFFFFFFFFFFFFL, }
}

///|
fn JavaRandom::next(self : JavaRandom, bits : Int) -> Int {
  self.seed = (self.seed * 0x5DEECE66DL + 0xBL) & 0xFFFFFFFFFFFFL
  (self.seed >> (48 - bits)).to_int()
}

///|
fn JavaRandom::next_double(self : JavaRandom) -> Double {
  let high = self.next(26)
  let low = self.next(27)
  (Int64::from_int(high << 27) + Int64::from_int(low)).to_double() /
  9007199254740992.0
}

///|
fn JavaRandom::ranged(self : JavaRandom, low : Double, high : Double) -> Double {
  self.next_double() * (high - low) + low
}
