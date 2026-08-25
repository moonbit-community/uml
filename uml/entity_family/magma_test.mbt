///|
/// Core properties of the `applySingleStrategy` magma grid, exercised through
/// `magma_grid_edges`. Tests assert the snake-grid structure (row cells joined
/// by minlen-0 links, row starts by minlen-1 links) and the minlen rules for
/// explicit direction arrows — never absolute layout values.

///|
/// `SquareMaker.computeBranch` is the smallest column count whose square
/// covers the group.
test "magma branch covers the group size tightly" {
  for size in 1..<=30 {
    let branch = @entity.magma_branch(size)
    @test.assert_eq(branch * branch >= size, true)
    if branch > 1 {
      @test.assert_eq((branch - 1) * (branch - 1) < size, true)
    }
  }
  @test.assert_eq(@entity.magma_branch(4), 2)
  @test.assert_eq(@entity.magma_branch(9), 3)
  @test.assert_eq(@entity.magma_branch(10), 4)
}

///|
/// The last-row start is the first cell of the bottom row.
test "magma bottom-left index lands on the last row" {
  @test.assert_eq(@entity.magma_bottom_left_index(3), 2)
  @test.assert_eq(@entity.magma_bottom_left_index(5), 3)
  @test.assert_eq(@entity.magma_bottom_left_index(10), 8)
  @test.assert_eq(@entity.magma_bottom_left_index(22), 20)
}

///|
/// Standalone entities of one group are joined by one snake link per item:
/// `n - 1` links, row cells linked to their left neighbour with minlen 0 and
/// each row start linked down with minlen 1.
test "grid edges snake through the group in declaration order" {
  let sources : Array[String] = []
  for index in 0..<22 {
    sources.push("node n\{index} as n\{index}")
  }
  let diagram = parse(
    "@startuml\n" + sources.join("\n") + "\n@enduml",
    family=DeploymentDiagram,
  )
  let edges = diagram.magma_grid_edges()
  @test.assert_eq(edges.length(), 21)
  let branch = @entity.magma_branch(22)
  @test.assert_eq(branch, 5)
  let mut horizontal = 0
  let mut vertical = 0
  for edge in edges {
    let tail_index = @string.parse_int(edge.0.replace(old="n", new="")) catch {
      _ => -1
    }
    let head_index = @string.parse_int(edge.1.replace(old="n", new="")) catch {
      _ => -1
    }
    if edge.2 == 0 {
      horizontal += 1
      @test.assert_eq(head_index - tail_index, 1)
      @test.assert_eq(head_index % branch != 0, true)
    } else {
      vertical += 1
      @test.assert_eq(head_index - tail_index, branch)
      @test.assert_eq(tail_index % branch, 0)
    }
  }
  @test.assert_eq(horizontal, 17)
  @test.assert_eq(vertical, 4)
}

///|
/// An entity attached to a note is not standalone, so it leaves the grid.
test "annotated entities do not join the grid" {
  let diagram = parse(
    "@startuml\nnode a\nnode b\nnode c\nnode d\nnote right of a : used\n@enduml",
    family=DeploymentDiagram,
  )
  let edges = diagram.magma_grid_edges()
  for edge in edges {
    @test.assert_eq(edge.0 != "a", true)
    @test.assert_eq(edge.1 != "a", true)
  }
  @test.assert_eq(edges.length(), 2)
}

///|
/// Explicit left/right direction words collapse the queue to a single dash,
/// so those links carry dot `minlen=0`; plain multi-dash arrows keep
/// `minlen = dash count - 1`.
test "explicit direction arrows collapse the queue length" {
  let rightward = parse(
    "@startuml\nnode a\nnode b\na -right-> b : side\n@enduml",
    family=DeploymentDiagram,
  )
  @test.assert_eq(rightward.relations.length(), 1)
  @test.assert_eq(relation_graphviz_minlen(rightward.relations[0]), 0)
  let plain = parse(
    "@startuml\nnode a\nnode b\na --> b : side\n@enduml",
    family=DeploymentDiagram,
  )
  @test.assert_eq(relation_graphviz_minlen(plain.relations[0]), 1)
  let heavy = parse(
    "@startuml\nnode a\nnode b\na ==> b : side\n@enduml",
    family=DeploymentDiagram,
  )
  @test.assert_eq(relation_graphviz_minlen(heavy.relations[0]), 1)
}

///|
/// A relation targeting a package attaches to the group: no phantom entity is
/// created and the grid ignores the group name.
test "relations to packages do not create phantom entities" {
  let diagram = parse(
    "@startuml\nnode app {\n  port http\n  portin ingress\n  portout egress\n}\nnode client\nclient --> app\n@enduml",
    family=DeploymentDiagram,
  )
  @test.assert_eq(diagram.entities.length(), 4)
  let edges = diagram.magma_grid_edges()
  @test.assert_eq(edges.length(), 2)
}

///|
/// Plain `port` entities share `LeafType.PORTIN` in PlantUML, so a port
/// cluster with an incoming link pins its input ports to the source rank and
/// its output ports to the sink rank: the input ports render on the same row
/// as the external node.
test "port clusters pin inputs to the source rank" {
  let svg = render_entity_svg(
    parse(
      "\nnode app {\n  port http\n  portin ingress\n  portout egress\n}\nnode client\nclient --> app\n",
      family=DeploymentDiagram,
    ),
  )
  let port_y = (code : String) => {
    let marker = "class=\"port-node\" data-code=\"\{code}\""
    match @parse.find_unquoted_literal(svg, marker) {
      Some(start) => {
        let segment = svg[start:].to_owned()
        match @parse.find_unquoted_literal(segment, "y=\"") {
          Some(y_start) => {
            let y_value = segment[y_start + 3:]
            let y_token = y_value.split("\"").nth(0).unwrap_or("")
            Some(@string.parse_double(y_token) catch { _ => 0.0 })
          }
          None => None
        }
      }
      None => None
    }
  }
  let title_y = () => {
    match @parse.find_unquoted_literal(svg, "class=\"package-title\"") {
      Some(start) => {
        // The title's own `y="` sits before its class attribute; scan the
        // prefix for the last occurrence.
        let prefix = svg[:start].to_owned()
        let mut y_pos : Int? = None
        let mut offset = 0
        while @parse.find_unquoted_literal(prefix[offset:].to_owned(), "y=\"")
              is Some(at) {
          y_pos = Some(offset + at)
          offset = offset + at + 3
        }
        match y_pos {
          Some(pos) => {
            let y_value = svg[pos + 3:].to_owned()
            let y_token = y_value.split("\"").nth(0).unwrap_or("")
            Some(@string.parse_double(y_token) catch { _ => 0.0 })
          }
          None => None
        }
      }
      None => None
    }
  }
  let http_y = port_y("app.http").unwrap_or(-1.0)
  let ingress_y = port_y("app.ingress").unwrap_or(-1.0)
  let egress_y = port_y("app.egress").unwrap_or(-1.0)
  let title = title_y().unwrap_or(-1.0)
  // Input ports share the top rank with the external node; the output port
  // lands below the cluster title.
  @test.assert_eq((http_y - ingress_y).abs() < 4.0, true)
  @test.assert_eq(http_y < title, true)
  @test.assert_eq(egress_y > title, true)
}
