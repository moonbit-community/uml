///|
test "parses class declarations, members, packages, and relations" {
  let source =
    #|@startuml
    #|package domain {
    #|abstract class "User" as U {
    #|  + id : Int
    #|  + login()
    #|}
    #|interface Auth
    #|  U <|.. Auth : implements
    #|}
    #|@enduml
  let diagram = parse(source)
  @test.assert_eq(diagram.entities.length(), 2)
  @test.assert_eq(diagram.entity("U").unwrap().display, "User")
  @test.assert_eq(diagram.entity("U").unwrap().members.length(), 2)
  @test.assert_eq(diagram.relations.length(), 1)
  @test.assert_eq(diagram.relations[0].label, Some("implements"))
  @test.assert_eq(diagram.packages.length(), 1)
}

///|
test "reports malformed class input with a source line" {
  try parse("@startuml\nclass A {\n@enduml") catch {
    SyntaxError(line, _) => @test.assert_eq(line, 4)
  } noraise {
    _ => @test.fail("expected syntax error")
  }
}

///|
test "creates relation endpoints and preserves cardinalities" {
  let diagram = parse(
    "@startuml\npackage model\nOrder \"1\" *-- \"many\" Item : items\nend package\n@enduml",
  )
  @test.assert_eq(diagram.entities.length(), 2)
  @test.assert_eq(diagram.entity("Order").unwrap().scope, "model")
  @test.assert_eq(diagram.relations[0].kind, Composition)
  @test.assert_eq(diagram.relations[0].left_cardinality, Some("1"))
  @test.assert_eq(diagram.relations[0].right_cardinality, Some("many"))
}

///|
test "parses declaration modifiers and derived relations" {
  let diagram = parse(
    "@startuml\n+ static class Repository<T> <<storage>> extends BaseRepository\ninterface Cache\nclass RedisCache implements Cache\n@enduml",
  )
  let repository = diagram.entity("Repository").unwrap()
  @test.assert_eq(repository.visibility, Public)
  @test.assert_eq(repository.is_static, true)
  @test.assert_eq(repository.generic, Some("T"))
  @test.assert_eq(repository.stereotype, Some("<<storage>>"))
  @test.assert_eq(diagram.relations.length(), 2)
  @test.assert_eq(diagram.relations[0].kind, Extension)
  @test.assert_eq(diagram.relations[1].kind, Realization)
}

///|
test "parses entity notes" {
  let diagram = parse(
    "@startuml\nclass User\nnote right of User : authenticated user\n@enduml",
  )
  @test.assert_eq(diagram.notes.length(), 1)
  @test.assert_eq(diagram.notes[0].target, "User")
  @test.assert_eq(diagram.notes[0].position, Right)
  @test.assert_eq(diagram.notes[0].text, "authenticated user")
}

///|
test "parses multiline entity notes" {
  let diagram = parse(
    "@startuml\nclass User\nnote bottom of User\nfirst\nsecond\nend note\n@enduml",
  )
  @test.assert_eq(diagram.notes.length(), 1)
  @test.assert_eq(diagram.notes[0].position, Bottom)
  @test.assert_eq(diagram.notes[0].text, "first\nsecond")
}

///|
test "parses relationship roles" {
  let diagram = parse("@startuml\nUser /author -- /books Book\n@enduml")
  @test.assert_eq(diagram.relations[0].left, "User")
  @test.assert_eq(diagram.relations[0].right, "Book")
  @test.assert_eq(diagram.relations[0].left_role, Some("author"))
  @test.assert_eq(diagram.relations[0].right_role, Some("books"))
}

///|
test "parses relationship qualifiers" {
  let diagram = parse("@startuml\nOrder [id] -- [sku] Item\n@enduml")
  @test.assert_eq(diagram.relations[0].left, "Order")
  @test.assert_eq(diagram.relations[0].right, "Item")
  @test.assert_eq(diagram.relations[0].left_qualifier, Some("id"))
  @test.assert_eq(diagram.relations[0].right_qualifier, Some("sku"))
}

///|
test "applies hide and show commands before or after declarations" {
  let diagram = parse(
    "@startuml\nhide Secret\nclass Secret\nhide Secret\nshow Secret\n@enduml",
  )
  @test.assert_eq(diagram.entity("Secret").unwrap().is_hidden, false)
}

///|
test "parses empty class bodies without changing the entity code" {
  let diagram = parse("@startuml\nclass Empty {}\n@enduml")
  @test.assert_eq(diagram.has_entity("Empty"), true)
  @test.assert_eq(diagram.entities.length(), 1)
}

///|
test "keeps class-body separators distinct from members" {
  let diagram = parse(
    "@startuml\nclass User {\n+ id : Int\n--\n+ login()\n}\n@enduml",
  )
  let members = diagram.entity("User").unwrap().members
  @test.assert_eq(members.length(), 3)
  @test.assert_eq(members[1].is_separator, true)
}

///|
test "accepts directional association arrows" {
  let diagram = parse("@startuml\nUser -left-> Account\n@enduml")
  @test.assert_eq(diagram.relations.length(), 1)
  @test.assert_eq(diagram.relations[0].left, "User")
  @test.assert_eq(diagram.relations[0].right, "Account")
}

///|
test "parses members declared outside a class body" {
  let diagram = parse("@startuml\nUser : + id : Int\nUser : + login()\n@enduml")
  let user = diagram.entity("User").unwrap()
  @test.assert_eq(user.members.length(), 2)
  @test.assert_eq(user.members[0].visibility, Public)
  @test.assert_eq(user.members[1].is_method, true)
}

///|
test "accepts both PlantUML alias directions" {
  let diagram = parse(
    "@startuml\nclass \"Display A\" as A\nclass B as \"Display B\"\n@enduml",
  )
  @test.assert_eq(diagram.entity("A").unwrap().display, "Display A")
  @test.assert_eq(diagram.entity("B").unwrap().display, "Display B")
}

///|
test "accepts common mixed-diagram element declarations" {
  let diagram = parse(
    "@startuml\ncomponent Web\ndatabase Store\nqueue Jobs\nWeb --> Store\n@enduml",
  )
  @test.assert_eq(diagram.entity("Web").unwrap().kind, Component)
  @test.assert_eq(diagram.entity("Store").unwrap().kind, Database)
  @test.assert_eq(diagram.entity("Jobs").unwrap().kind, Queue)
}

///|
test "accepts the allowmixing directive" {
  let diagram = parse(
    "@startuml\nallowmixing\nclass Domain\ncomponent Adapter\n@enduml",
  )
  @test.assert_eq(diagram.entities.length(), 2)
}

///|
test "accepts remove and restore entity commands" {
  let diagram = parse(
    "@startuml\nclass User\nremove User\nrestore User\n@enduml",
  )
  @test.assert_eq(diagram.entity("User").unwrap().is_hidden, false)
}

///|
test "skips multiline diagram text blocks" {
  let diagram = parse(
    "@startuml\ntitle\nA title\nend title\nclass User\n@enduml",
  )
  @test.assert_eq(diagram.has_entity("User"), true)
}

///|
test "accepts preprocessing directives" {
  let diagram = parse(
    "@startuml\n!theme plain\n!define MODEL User\nclass User\n@enduml",
  )
  @test.assert_eq(diagram.has_entity("User"), true)
}

///|
test "expands shared object-like preprocessor macros" {
  let diagram = parse("@startuml\n!define MODEL User\nclass MODEL\n@enduml")
  @test.assert_eq(diagram.has_entity("User"), true)
}

///|
test "skips braced skinparam blocks" {
  let diagram = parse(
    "@startuml\nskinparam {\n  BackgroundColor white\n}\nclass User\n@enduml",
  )
  @test.assert_eq(diagram.has_entity("User"), true)
}

///|
test "skips together layout blocks" {
  let diagram = parse(
    "@startuml\nclass A\nclass B\ntogether {\nA\nB\n}\n@enduml",
  )
  @test.assert_eq(diagram.entities.length(), 2)
}

///|
test "parses lollipop interface declarations" {
  let diagram = parse("@startuml\n() \"Service\" as IService\n@enduml")
  let service = diagram.entity("IService").unwrap()
  @test.assert_eq(service.kind, Interface)
  @test.assert_eq(service.display, "Service")
}

///|
test "parses abstract shorthand declarations" {
  let diagram = parse("@startuml\nabstract Base\n@enduml")
  @test.assert_eq(diagram.entity("Base").unwrap().kind, AbstractClass)
}

///|
test "accepts state declarations in mixed diagrams" {
  let diagram = parse("@startuml\nallowmixing\nstate Ready\n@enduml")
  @test.assert_eq(diagram.entity("Ready").unwrap().kind, State)
}

///|
test "keeps declaration URLs out of the entity code" {
  let diagram = parse(
    "@startuml\nclass User [[https://example.com/user]]\n@enduml",
  )
  let user = diagram.entity("User").unwrap()
  @test.assert_eq(user.url, Some("https://example.com/user"))
}

///|
test "keeps a shared URL target when a label is present" {
  let diagram = parse(
    "@startuml\nclass User [[https://example.com profile]]\n@enduml",
  )
  @test.assert_eq(
    diagram.entity("User").unwrap().url,
    Some("https://example.com"),
  )
}

///|
test "keeps declaration background colors" {
  let diagram = parse("@startuml\nclass User #lightblue\n@enduml")
  @test.assert_eq(diagram.entity("User").unwrap().color, Some("lightblue"))
}

///|
test "applies standalone stereotypes" {
  let diagram = parse("@startuml\nclass User\nUser <<entity>>\n@enduml")
  @test.assert_eq(
    diagram.entity("User").unwrap().stereotype,
    Some("<<entity>>"),
  )
}

///|
test "parses shared document background style" {
  let diagram = parse(
    "@startuml\nskinparam BackgroundColor #102030\nclass User\n@enduml",
  )
  @test.assert_eq(diagram.style.background_color, Some("#102030"))
  @test.assert_eq(diagram.render_svg().contains("background:#102030"), true)
}

///|
test "parses shared braced skinparam background style" {
  let diagram = parse(
    "@startuml\nskinparam {\nBackgroundColor #203040\n}\nclass User\n@enduml",
  )
  @test.assert_eq(diagram.style.background_color, Some("#203040"))
}

///|
test "parses shared default font style" {
  let diagram = parse(
    "@startuml\nskinparam DefaultFontName Courier\nskinparam DefaultFontSize 16\nclass User\n@enduml",
  )
  @test.assert_eq(diagram.style.font_family, Some("Courier"))
  @test.assert_eq(diagram.style.font_size, Some("16"))
  @test.assert_eq(
    diagram.render_svg().contains("font-family:Courier;font-size:16px"),
    true,
  )
}

///|
test "parses shared arrow color style" {
  let diagram = parse(
    "@startuml\nskinparam ArrowColor #ff0000\nclass A\nA --> B\n@enduml",
  )
  @test.assert_eq(diagram.style.line_color, Some("#ff0000"))
  @test.assert_eq(
    diagram.render_svg().contains(".relation{stroke:#ff0000"),
    true,
  )
}
