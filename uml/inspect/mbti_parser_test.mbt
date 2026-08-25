///|
test "selects the mbti family from the header comment" {
  @test.assert_eq(
    @parser.is_mbti_source("@startuml '.mbti\npackage \"demo\";\n@enduml"),
    true,
  )
  @test.assert_eq(
    @parser.is_mbti_source("@startuml'.mbti\npackage \"demo\";\n@enduml"),
    true,
  )
  @test.assert_eq(@parser.is_mbti_source("@startuml\nclass A\n@enduml"), false)
  let diagram = @parser.parse_mbti(
    "@startuml '.mbti\npackage \"demo\";\n@enduml",
  )
  @test.assert_eq(diagram.package_name, "demo")
}

///|
test "reports a missing package declaration" {
  try
    @parser.parse_mbti("@startuml '.mbti\nstruct A { x : Int }\n@enduml")
  catch {
    SyntaxError(line, _) => @test.assert_eq(line > 1, true)
  } noraise {
    _ => @test.fail("expected syntax error")
  }
}

///|
test "maps impl and trait inheritance to relations" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|struct Point {
    #|  x : Int
    #|  mut y : Int
    #|}
    #|trait Eq
    #|trait Show : Eq {
    #|  fn to_string(Self) -> String
    #|}
    #|impl Show for Point;
    #|@enduml
  let graph = @parser.parse_mbti(source).graph
  @test.assert_eq(graph.entities.length(), 3)
  @test.assert_eq(graph.entity("Point").unwrap().kind, @entity.Struct)
  @test.assert_eq(graph.entity("Show").unwrap().kind, @entity.Interface)
  @test.assert_eq(graph.relations.length(), 2)
  let inheritance = graph.relations[0]
  @test.assert_eq(inheritance.left, "Show")
  @test.assert_eq(inheritance.right, "Eq")
  @test.assert_eq(inheritance.kind, @entity.RelationKind::Extension)
  let realization = graph.relations[1]
  @test.assert_eq(realization.left, "Point")
  @test.assert_eq(realization.right, "Show")
  @test.assert_eq(realization.kind, @entity.RelationKind::Realization)
  @test.assert_eq(realization.dotted, true)
}

///|
test "attaches fields, constructors, and methods as members" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|struct Point {
    #|  x : Int
    #|  mut y : Int
    #|}
    #|enum Color {
    #|  Red
    #|  Blue(Int, String)
    #|}
    #|fn Point::dist(Self, Point) -> Double
    #|@enduml
  let graph = @parser.parse_mbti(source, options={
      ..@entity.MbtiOptions::default(),
      show_methods: true,
    }).graph
  let point = graph.entity("Point").unwrap()
  @test.assert_eq(point.members.length(), 3)
  @test.assert_eq(point.members.filter(m => m.is_method).length(), 1)
  @test.assert_eq(point.members[0].raw.has_prefix("+x: Int"), true)
  @test.assert_eq(point.members[1].raw.has_prefix("+mut y: Int"), true)
  @test.assert_eq(
    point.members[2].raw.has_prefix("+dist(Self, Point) -> Double"),
    true,
  )
  let color = graph.entity("Color").unwrap()
  @test.assert_eq(color.kind, @entity.Enum)
  @test.assert_eq(color.members.length(), 2)
  @test.assert_eq(color.members[0].raw, "Red")
  @test.assert_eq(color.members[1].raw.has_prefix("Blue(Int, String)"), true)
}

///|
/// Methods are hidden by default: only fields and constructors remain, so
/// the nodes render as type skeletons.
test "hides trait and extension methods by default" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|trait Show : Eq {
    #|  fn to_string(Self) -> String
    #|}
    #|struct Point {
    #|  x : Int
    #|}
    #|fn Point::dist(Self, Point) -> Double
    #|@enduml
  let graph = @parser.parse_mbti(source).graph
  @test.assert_eq(graph.entity("Show").unwrap().members.length(), 0)
  let point = graph.entity("Point").unwrap()
  @test.assert_eq(point.members.length(), 1)
  @test.assert_eq(point.members.filter(m => m.is_method).length(), 0)
}

///|
test "ignores top-level functions, constants, and values" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|struct A {
    #|  x : Int
    #|}
    #|fn top_level() -> Unit
    #|const MAX : Int = 10
    #|let counter : Int
    #|@enduml
  let graph = @parser.parse_mbti(source).graph
  @test.assert_eq(graph.entities.length(), 1)
  @test.assert_eq(graph.has_entity("top_level"), false)
  @test.assert_eq(graph.has_entity("MAX"), false)
  @test.assert_eq(graph.has_entity("counter"), false)
}

///|
test "drops aliases of undeclared targets and marks abstract types" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|type Alias = Int
    #|type Abstract
    #|suberror MyError
    #|@enduml
  let graph = @parser.parse_mbti(source).graph
  @test.assert_eq(graph.has_entity("Alias"), false)
  @test.assert_eq(graph.entity("Abstract").unwrap().kind, @entity.AbstractClass)
  @test.assert_eq(graph.entity("MyError").unwrap().kind, @entity.Exception)
}

///|
test "keeps standalone alias nodes on request" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|type Alias = Int
    #|@enduml
  let graph = @parser.parse_mbti(source, standalone_alias=true).graph
  @test.assert_eq(graph.entity("Alias").unwrap().stereotype, Some("alias"))
  @test.assert_eq(graph.entity("Alias").unwrap().kind, @entity.Class)
}

///|
test "merges aliases into their declared target node" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|struct Point {
    #|  x : Int
    #|}
    #|type Alias = Point
    #|type Other = Point
    #|@enduml
  let graph = @parser.parse_mbti(source).graph
  @test.assert_eq(graph.entities.length(), 1)
  @test.assert_eq(graph.has_entity("Alias"), false)
  @test.assert_eq(graph.has_entity("Other"), false)
  @test.assert_eq(
    graph.entity("Point").unwrap().annotation,
    Some("alias Alias, Other"),
  )
  @test.assert_eq(graph.entity("Point").unwrap().members.length(), 1)
}

///|
/// An impl whose endpoints are not declared in this interface gets no nodes
/// and no edge: external terms are referenced, never drawn.
test "drops impls whose endpoints are not declared here" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|impl @std.Show for Point;
    #|@enduml
  let graph = @parser.parse_mbti(source).graph
  @test.assert_eq(graph.entities.length(), 0)
  @test.assert_eq(graph.relations.length(), 0)
}

///|
test "ignores content after the closing delimiter" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|struct A {
    #|  x : Int
    #|}
    #|@enduml
    #|class Noise
  let graph = @parser.parse_mbti(source).graph
  @test.assert_eq(graph.entities.length(), 1)
  @test.assert_eq(graph.has_entity("Noise"), false)
}

///|
test "renders the adapted graph to svg" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|trait Eq
    #|struct Point {
    #|  x : Int
    #|}
    #|impl Eq for Point;
    #|@enduml
  let svg = @render.render_mbti_svg(@parser.parse_mbti(source)) catch {
    _ => @test.fail("svg rendering failed")
  }
  @test.assert_eq(svg.contains("<svg"), true)
  @test.assert_eq(svg.contains("Point"), true)
  @test.assert_eq(svg.contains("Eq"), true)
}

///|
test "draws association edges for members whose type is declared" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|struct Point {
    #|  x : Int
    #|}
    #|struct Line {
    #|  start : Point
    #|  end : Point
    #|}
    #|enum Shape {
    #|  Circle(Point)
    #|}
    #|@enduml
  let graph = @parser.parse_mbti(source).graph
  let member_edges = graph.relations.filter(r => r.kind == @entity.Association)
  @test.assert_eq(member_edges.length(), 3)
  @test.assert_eq(member_edges[0].left, "Line")
  @test.assert_eq(member_edges[0].right, "Point")
  @test.assert_eq(member_edges[0].label, Some("start"))
  @test.assert_eq(member_edges[1].label, Some("end"))
  @test.assert_eq(member_edges[2].left, "Shape")
  @test.assert_eq(member_edges[2].right, "Point")
  @test.assert_eq(member_edges[2].label, None)
}

///|
test "skips member edges for undeclared member types" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|struct Point {
    #|  x : Int
    #|  y : Array[String]
    #|}
    #|@enduml
  let graph = @parser.parse_mbti(source).graph
  @test.assert_eq(graph.relations.length(), 0)
}

///|
test "optionally disables each edge family" {
  let source =
    #|@startuml '.mbti
    #|package "demo";
    #|struct Point {
    #|  x : Int
    #|}
    #|struct Line {
    #|  start : Point
    #|}
    #|trait Eq
    #|trait Show : Eq {
    #|  fn to_string(Self) -> String
    #|}
    #|impl Show for Line;
    #|@enduml
  let graph = @parser.parse_mbti(source).graph
  @test.assert_eq(
    graph.relations.filter(r => r.kind == @entity.Association).length(),
    1,
  )
  @test.assert_eq(
    graph.relations.filter(r => r.kind == @entity.Extension).length(),
    1,
  )
  @test.assert_eq(
    graph.relations.filter(r => r.kind == @entity.Realization).length(),
    1,
  )
  let no_member = @parser.parse_mbti(source, options={
      ..@entity.MbtiOptions::default(),
      member_type_edges: false,
    }).graph
  @test.assert_eq(
    no_member.relations.filter(r => r.kind == @entity.Association).length(),
    0,
  )
  @test.assert_eq(no_member.relations.length(), 2)
  let no_inheritance = @parser.parse_mbti(source, options={
      ..@entity.MbtiOptions::default(),
      trait_inheritance_edges: false,
    }).graph
  @test.assert_eq(
    no_inheritance.relations.filter(r => r.kind == @entity.Extension).length(),
    0,
  )
  let no_impl = @parser.parse_mbti(source, options={
      ..@entity.MbtiOptions::default(),
      impl_edges: false,
    }).graph
  @test.assert_eq(
    no_impl.relations.filter(r => r.kind == @entity.Realization).length(),
    0,
  )
}
