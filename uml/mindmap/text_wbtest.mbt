///|
test "strikethrough spans preserve surrounding text" {
  let spans = parse_mindmap_text_line("a <s>b</s> c")
  @test.assert_eq(spans.length(), 3)
  @test.assert_eq(spans[0].text, "a ")
  @test.assert_eq(spans[1].text, "b")
  @test.assert_eq(spans[1].strike, true)
  @test.assert_eq(spans[2].text, " c")
}

///|
fn int_attribute(chunk : String, name : String) -> Int {
  let start = chunk.find("\{name}=\"")
  match start {
    None => -1
    Some(offset) => {
      let value = chunk[offset + name.length() + 2:]
      let end = value.find("\"")
      match end {
        None => -1
        Some(end_offset) =>
          @string.parse_int(value[:end_offset].to_owned()) catch {
            _ => -1
          }
      }
    }
  }
}

///|
test "strikethrough text never stretches beyond its node" {
  let svg = @parser.parse_mindmap(
    "* Root\n** <s>Raspmbc</s> => OSMC\n** plain <s>mid</s> tail",
  ).render_svg()
  for chunk in svg.split("<g class=\"mindmap-node") {
    let box_width = int_attribute(chunk.to_owned(), "width")
    let text_length = int_attribute(chunk.to_owned(), "textLength")
    if box_width >= 0 && text_length >= 0 {
      @test.assert_eq(text_length < box_width, true)
    }
  }
}
