///|
/// RFC 1951 DEFLATE decoding used by compressed sprite resources. This is a
/// byte decoder only; sprite alphabet, dimensions and gray levels remain in
/// the media parser. https://www.rfc-editor.org/rfc/rfc1951
priv struct DeflateBits {
  bytes : Bytes
  mut bit : Int
}

///|
fn DeflateBits::read(self : DeflateBits, count : Int) -> Int raise ParseError {
  guard self.bit + count <= self.bytes.length() * 8 else {
    raise SyntaxError(1, "truncated compressed sprite")
  }
  let mut value = 0
  for offset in 0..<count {
    let bit = (self.bytes[self.bit / 8].to_int() >> (self.bit % 8)) & 1
    value = value | (bit << offset)
    self.bit += 1
  }
  value
}

///|
priv struct DeflateTree {
  symbols : Map[(Int, Int), Int]
  maximum : Int
}

///|
fn DeflateTree::new(lengths : Array[Int]) -> DeflateTree raise ParseError {
  let counts = Array::make(16, 0)
  let mut maximum = 0
  for length in lengths {
    guard length >= 0 && length < counts.length() else {
      raise SyntaxError(1, "invalid deflate code length")
    }
    if length > 0 {
      counts[length] += 1
      maximum = maximum.max(length)
    }
  }
  let next = Array::make(counts.length(), 0)
  let mut code = 0
  for length in 1..<counts.length() {
    code = (code + counts[length - 1]) << 1
    guard code + counts[length] <= 1 << length else {
      raise SyntaxError(1, "oversubscribed deflate tree")
    }
    next[length] = code
  }
  let symbols : Map[(Int, Int), Int] = Map([])
  for symbol, length in lengths {
    if length > 0 {
      symbols[(length, next[length])] = symbol
      next[length] += 1
    }
  }
  { symbols, maximum, }
}

///|
fn DeflateTree::decode(
  self : DeflateTree,
  input : DeflateBits,
) -> Int raise ParseError {
  let mut code = 0
  for length in 1..<=self.maximum {
    code = (code << 1) | input.read(1)
    if self.symbols.get((length, code)) is Some(symbol) {
      return symbol
    }
  }
  raise SyntaxError(1, "invalid deflate symbol")
}

///|
fn deflate_dynamic_trees(
  input : DeflateBits,
) -> (DeflateTree, DeflateTree) raise ParseError {
  let literal_count = input.read(5) + 257
  let distance_count = input.read(5) + 1
  let length_count = input.read(4) + 4
  guard literal_count <= 286 else {
    raise SyntaxError(1, "invalid deflate literal count")
  }
  let order = [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15]
  let code_lengths = Array::make(order.length(), 0)
  for index in 0..<length_count {
    code_lengths[order[index]] = input.read(3)
  }
  let length_tree = DeflateTree::new(code_lengths)
  let lengths : Array[Int] = []
  let total = literal_count + distance_count
  while lengths.length() < total {
    let symbol = length_tree.decode(input)
    let (value, count) = match symbol {
      16 => {
        guard lengths.last() is Some(previous) else {
          raise SyntaxError(1, "deflate repeat has no predecessor")
        }
        (previous, input.read(2) + 3)
      }
      17 => (0, input.read(3) + 3)
      18 => (0, input.read(7) + 11)
      _ => (symbol, 1)
    }
    guard lengths.length() + count <= total else {
      raise SyntaxError(1, "deflate code repeat exceeds tree")
    }
    for _ in 0..<count {
      lengths.push(value)
    }
  }
  guard lengths[256] > 0 else {
    raise SyntaxError(1, "deflate tree has no end marker")
  }
  (
    DeflateTree::new(lengths[:literal_count].to_owned()),
    DeflateTree::new(lengths[literal_count:].to_owned()),
  )
}

///|
let deflate_length_base : FixedArray[Int] = [
  3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83,
  99, 115, 131, 163, 195, 227, 258,
]

///|
fn deflate_compressed_block(
  input : DeflateBits,
  output : Array[Byte],
  literals : DeflateTree,
  distances : DeflateTree,
) -> Unit raise ParseError {
  while true {
    let symbol = literals.decode(input)
    if symbol < 256 {
      output.push(symbol.to_byte())
    } else if symbol == 256 {
      break
    } else {
      guard symbol <= 285 else {
        raise SyntaxError(1, "reserved deflate length")
      }
      let length_index = symbol - 257
      let length_extra = if length_index < 8 || length_index == 28 {
        0
      } else {
        (length_index - 4) / 4
      }
      let length = deflate_length_base[length_index] + input.read(length_extra)
      let distance_code = distances.decode(input)
      guard distance_code < 30 else {
        raise SyntaxError(1, "reserved deflate distance")
      }
      let distance_extra = (distance_code / 2 - 1).max(0)
      let distance_base = if distance_code < 4 {
        distance_code + 1
      } else {
        ((2 + distance_code % 2) << distance_extra) + 1
      }
      let distance = distance_base + input.read(distance_extra)
      guard distance <= output.length() else {
        raise SyntaxError(1, "deflate distance precedes output")
      }
      // Reading from the growing output is required for overlapping matches.
      for _ in 0..<length {
        output.push(output[output.length() - distance])
      }
    }
  }
}

///|
pub fn inflate_raw(bytes : Bytes) -> Bytes raise ParseError {
  let input : DeflateBits = { bytes, bit: 0, }
  let output : Array[Byte] = []
  let mut final_block = false
  while !final_block {
    final_block = input.read(1) != 0
    match input.read(2) {
      0 => {
        input.bit = (input.bit + 7) / 8 * 8
        let count = input.read(16)
        let inverse = input.read(16)
        guard (count ^ inverse) == 65535 else {
          raise SyntaxError(1, "invalid deflate stored block length")
        }
        for _ in 0..<count {
          output.push(input.read(8).to_byte())
        }
      }
      1 => {
        let lengths = Array::makei(288, symbol => {
          if symbol <= 143 {
            8
          } else if symbol <= 255 {
            9
          } else if symbol <= 279 {
            7
          } else {
            8
          }
        })
        deflate_compressed_block(
          input,
          output,
          DeflateTree::new(lengths),
          DeflateTree::new(Array::make(32, 5)),
        )
      }
      2 => {
        let (literals, distances) = deflate_dynamic_trees(input)
        deflate_compressed_block(input, output, literals, distances)
      }
      _ => raise SyntaxError(1, "reserved deflate block type")
    }
  }
  Bytes::from_array(output[:])
}
