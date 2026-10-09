///|
/// Read the polygon from Graphviz's node-only _draw_ stream. This adapter
/// handles the pen/fill/style records preceding the outline; labels are in
/// _ldraw_ and are not part of the geometry path.
fn legacy_activity_outline(
  node : @dot_layout.DotLayoutNode,
  bbox : @geom.Rect,
) -> Array[@graphics.Point] raise @dot_layout.DotLayoutError {
  let invalid = @dot_layout.InvalidGraph(
    message="missing or invalid Graphviz polygon for legacy activity " +
      node.node.name(),
  )
  guard node.node.get_attr("_draw_") is Some(source) else { raise invalid }
  let cursor = @tokenizer.Cursor::new(source)
  let token = () => {
    ignore(cursor.skip_while(Char::is_whitespace))
    cursor.take_while(char => !char.is_whitespace())
  }
  let integer = () => @string.parse_int(token()) catch { _ => raise invalid }
  let number = () => @string.parse_double(token()) catch { _ => raise invalid }
  while !cursor.is_eof() {
    match token() {
      "c" | "C" | "S" => {
        let length = integer()
        guard length >= 0 else { raise invalid }
        ignore(cursor.skip_while(Char::is_whitespace))
        guard cursor.consume('-') else { raise invalid }
        // Our DOT nodes use Graphviz's generated ASCII paint/style payloads.
        // Their byte lengths equal their character lengths; do not scan payload
        // contents for polygon opcodes, or interpret this as general xdot input.
        for _ in 0..<length {
          guard cursor.advance() is Some(char) && char.is_ascii() else {
            raise invalid
          }
        }
      }
      "p" | "P" => {
        let count = integer()
        guard count >= 3 else { raise invalid }
        let (left, top, _, _) = @graphviz.graphviz_node_rect(node, bbox)
        let points : Array[@graphics.Point] = []
        for _ in 0..<count {
          let x = number()
          let y = number()
          let point = @graphviz.graphviz_point_to_svg({ x, y, }, bbox)
          points.push({ x: point.x - left, y: point.y - top, })
        }
        return points
      }
      _ => raise invalid
    }
  }
  raise invalid
}
