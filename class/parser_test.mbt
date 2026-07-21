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
test "decodes PlantUML shape-encoded element names" {
  let diagram = parse(
    "@startuml\nusecase (Login)\nactor :User:\ncomponent [API] as Api\n@enduml",
  )
  @test.assert_eq(diagram.entity("Login").unwrap().kind, Usecase)
  @test.assert_eq(diagram.entity("User").unwrap().kind, Actor)
  @test.assert_eq(diagram.entity("Api").unwrap().kind, Component)
  @test.assert_eq(diagram.entity("Api").unwrap().display, "API")
}

///|
test "accepts mix-prefixed element declarations" {
  let diagram = parse(
    "@startuml\nmix_component [API]\nmix_actor :User:\n@enduml",
  )
  @test.assert_eq(diagram.entity("API").unwrap().kind, Component)
  @test.assert_eq(diagram.entity("User").unwrap().kind, Actor)
}

///|
test "accepts PlantUML's registered element keywords" {
  let diagram = parse(
    "@startuml\nperson Person\nartifact Artifact\nactor/ ActorSlash\nfolder Folder\ncard Card\nfile File\nrectangle Rectangle\nhexagon Hexagon\nlabel Label\nnode Node\nframe Frame\ncloud Cloud\naction Action\nprocess Process\ndatabase Database\nqueue Queue\nstack Stack\nstorage Storage\nagent Agent\nusecase/ UsecaseSlash\nusecase Usecase\ncomponent Component\nboundary Boundary\ncontrol Control\nentity Entity\ninterface Interface\ncircle Circle\ncollections Collections\nport Port\nportin PortIn\nportout PortOut\n@enduml",
  )
  @test.assert_eq(diagram.entities.length(), 31)
}

///|
test "adds members to qualified and quoted entity names" {
  let diagram = parse(
    "@startuml\npackage pkg {\nclass A\n}\nclass \"Display B\" as B\npkg.A : +field\nB : -method()\n@enduml",
  )
  @test.assert_eq(diagram.entity("pkg.A").unwrap().members.length(), 1)
  @test.assert_eq(diagram.entity("B").unwrap().members.length(), 1)
}

///|
test "preserves interface declaration metadata" {
  let diagram = parse(
    "@startuml\n() Api <<service>> [[https://example.com/api]] #lightblue\n@enduml",
  )
  let api = diagram.entity("Api").unwrap()
  @test.assert_eq(api.kind, Interface)
  @test.assert_eq(api.stereotype, Some("<<service>>"))
  @test.assert_eq(api.url, Some("https://example.com/api"))
  @test.assert_eq(api.color, Some("lightblue"))
}

///|
test "parses relation ports without breaking qualified names" {
  let diagram = parse("@startuml\nclass A\nclass B\nA::out --> B::in\n@enduml")
  let relation = diagram.relations[0]
  @test.assert_eq(relation.left, "A")
  @test.assert_eq(relation.right, "B")
  @test.assert_eq(relation.left_port, Some("out"))
  @test.assert_eq(relation.right_port, Some("in"))
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

///|
test "keeps same-named classes distinct across packages" {
  let diagram = parse(
    "@startuml\npackage first {\nclass User\n}\npackage second {\nclass User\n}\n@enduml",
  )
  @test.assert_eq(diagram.entities.length(), 2)
  @test.assert_eq(diagram.entity("first.User").unwrap().scope, "first")
  @test.assert_eq(diagram.entity("second.User").unwrap().scope, "second")
}

///|
test "resolves relation endpoints in their package context" {
  let diagram = parse(
    "@startuml\npackage first {\nclass User\nUser --> Account\n}\npackage second {\nclass User\nUser --> Account\n}\n@enduml",
  )
  @test.assert_eq(diagram.entities.length(), 4)
  @test.assert_eq(diagram.relations[0].left, "first.User")
  @test.assert_eq(diagram.relations[0].right, "first.Account")
  @test.assert_eq(diagram.relations[1].left, "second.User")
  @test.assert_eq(diagram.relations[1].right, "second.Account")
}

///|
test "parses multiple extends and implements targets" {
  let diagram = parse(
    "@startuml\nclass Child extends BaseA, BaseB implements APIA, APIB\n@enduml",
  )
  @test.assert_eq(diagram.relations.length(), 4)
  @test.assert_eq(diagram.relations[0].right, "BaseA")
  @test.assert_eq(diagram.relations[1].right, "BaseB")
  @test.assert_eq(diagram.relations[2].right, "APIA")
  @test.assert_eq(diagram.relations[3].right, "APIB")
}

///|
test "accepts empty packages and namespaces" {
  let diagram = parse(
    "@startuml\npackage empty {}\nnamespace nested.empty {}\nclass User\n@enduml",
  )
  @test.assert_eq(diagram.packages.length(), 3)
  @test.assert_eq(diagram.entity("User").unwrap().scope, "")
}

///|
test "preserves relation endpoint decorations" {
  let diagram = parse(
    "@startuml\nParent <|-- Child\nOwner --* Part\nClient --[dashed]--> Service\n@enduml",
  )
  @test.assert_eq(diagram.relations[0].left_end, Extension)
  @test.assert_eq(diagram.relations[0].right_end, Plain)
  @test.assert_eq(diagram.relations[1].left_end, Plain)
  @test.assert_eq(diagram.relations[1].right_end, CompositionEnd)
  @test.assert_eq(diagram.relations[2].right_end, Arrow)
  @test.assert_eq(diagram.relations[2].line_style, Some("dashed"))
  let svg = diagram.render_svg()
  @test.assert_eq(svg.contains("marker-start=\"url(#triangle)\""), true)
  @test.assert_eq(svg.contains("marker-end=\"url(#diamond)\""), true)
}

///|
test "preserves relation directions and weights" {
  let diagram = parse("@startuml\n@2 User -left-> Account\n@enduml")
  @test.assert_eq(diagram.relations[0].direction, Leftward)
  @test.assert_eq(diagram.relations[0].weight, Some("2"))
}

///|
test "creates interface targets for implements and lollipop links" {
  let diagram = parse(
    "@startuml\nclass Service implements API\nService --( Port\n@enduml",
  )
  @test.assert_eq(diagram.entity("API").unwrap().kind, Interface)
  @test.assert_eq(diagram.entity("Port").unwrap().kind, Interface)
  @test.assert_eq(diagram.relations[1].right_end, Parenthesis)
}

///|
test "parses standalone urls and association diamonds" {
  let diagram = parse(
    "@startuml\nclass User\nurl of User is [[https://example.com/user]]\n<> membership\n@enduml",
  )
  @test.assert_eq(
    diagram.entity("User").unwrap().url,
    Some("https://example.com/user"),
  )
  @test.assert_eq(diagram.entity("membership").unwrap().kind, Diamond)
}

///|
test "preserves relation metadata" {
  let diagram = parse(
    "@startuml\nA --[dashed,#red]--> B #blue [[https://example.com]] <<critical>> : calls\n@enduml",
  )
  let relation = diagram.relations[0]
  @test.assert_eq(relation.line_style, Some("dashed,#red"))
  @test.assert_eq(relation.color, Some("blue"))
  @test.assert_eq(relation.url, Some("https://example.com"))
  @test.assert_eq(relation.stereotype, Some("<<critical>>"))
  @test.assert_eq(relation.label, Some("calls"))
}

///|
test "preserves package and namespace metadata" {
  let diagram = parse(
    "@startuml\n+ package \"Domain Model\" as domain <<Layer>> [[https://example.com/domain]] #lightblue {\nclass User\n}\nnamespace \"External API\" as external.api {}\n@enduml",
  )
  let domain = diagram.packages[0]
  @test.assert_eq(domain.name, "domain")
  @test.assert_eq(domain.qualified_name, "domain")
  @test.assert_eq(domain.display, "Domain Model")
  @test.assert_eq(domain.visibility, Public)
  @test.assert_eq(domain.stereotype, Some("<<Layer>>"))
  @test.assert_eq(domain.url, Some("https://example.com/domain"))
  @test.assert_eq(domain.color, Some("lightblue"))
  @test.assert_eq(diagram.packages[1].is_namespace, true)
  @test.assert_eq(diagram.packages[1].name, "external")
  @test.assert_eq(diagram.packages[2].qualified_name, "external.api")
  @test.assert_eq(diagram.packages[2].display, "External API")
}

///|
test "accepts package aliases in either display/code order" {
  let diagram = parse(
    "@startuml\npackage domain as \"Domain Model\" {}\npackage \"External API\" as external {}\n@enduml",
  )
  @test.assert_eq(diagram.packages[0].name, "domain")
  @test.assert_eq(diagram.packages[0].display, "Domain Model")
  @test.assert_eq(diagram.packages[1].name, "external")
  @test.assert_eq(diagram.packages[1].display, "External API")
}

///|
test "preserves declaration URL after stereotype" {
  let diagram = parse(
    "@startuml\nclass User <<entity>> [[https://example.com/user]] #lightblue\n@enduml",
  )
  let user = diagram.entity("User").unwrap()
  @test.assert_eq(user.stereotype, Some("<<entity>>"))
  @test.assert_eq(user.url, Some("https://example.com/user"))
  @test.assert_eq(user.color, Some("lightblue"))
}

///|
test "applies entity hide and remove selectors in command order" {
  let diagram = parse(
    "@startuml\nhide <<service>>\nclass API <<service>>\nclass Internal <<service>>\nshow API\nremove Internal\nrestore Internal\nhide-class Missing\nclass Missing\n@enduml",
  )
  @test.assert_eq(diagram.entity("API").unwrap().is_hidden, false)
  @test.assert_eq(diagram.entity("Internal").unwrap().is_hidden, true)
  @test.assert_eq(diagram.entity("Internal").unwrap().is_removed, false)
  @test.assert_eq(diagram.entity("Missing").unwrap().is_hidden, true)
}

///|
test "keeps remove state distinct from hide state" {
  let diagram = parse("@startuml\nclass User\nremove User\n@enduml")
  let user = diagram.entity("User").unwrap()
  @test.assert_eq(user.is_hidden, false)
  @test.assert_eq(user.is_removed, true)
}

///|
test "filters members by visibility and portion" {
  let diagram = parse(
    "@startuml\nclass User {\n+ id : Int\n- secret : String\n+ login()\n- reset()\n}\nhide private members\nhide public methods\n@enduml",
  )
  let members = diagram.entity("User").unwrap().members
  @test.assert_eq(members[0].is_hidden, false)
  @test.assert_eq(members[1].is_hidden, true)
  @test.assert_eq(members[2].is_hidden, true)
  @test.assert_eq(members[3].is_hidden, true)
}

///|
test "supports visibility-only member filters" {
  let diagram = parse(
    "@startuml\nclass User {\n+ publicField\n- privateField\n}\nhide private\n@enduml",
  )
  let members = diagram.entity("User").unwrap().members
  @test.assert_eq(members[0].is_hidden, false)
  @test.assert_eq(members[1].is_hidden, true)
}

///|
test "filters portions by kind name stereotype and package" {
  let diagram = parse(
    "@startuml\nclass Root {\n+ root()\n}\npackage domain {\nclass Empty\nhide empty fields\nclass Service <<service>> {\n+ run()\n}\nhide <<service>> methods\n}\ninterface API {\n+ call()\n}\nhide interface methods\n@enduml",
  )
  @test.assert_eq(diagram.entity("domain.Empty").unwrap().fields_hidden, true)
  @test.assert_eq(
    diagram.entity("domain.Service").unwrap().methods_hidden,
    true,
  )
  @test.assert_eq(diagram.entity("Root").unwrap().methods_hidden, false)
  @test.assert_eq(diagram.entity("API").unwrap().methods_hidden, true)
}

///|
test "attaches single and multiline notes to the last link" {
  let diagram = parse(
    "@startuml\nA --> B\nnote right on link #yellow : sync\nB --> C\nnote of link\nasync\nretry\nend note\n@enduml",
  )
  @test.assert_eq(diagram.notes.length(), 2)
  @test.assert_eq(diagram.notes[0].target_kind, LinkNote)
  @test.assert_eq(diagram.notes[0].relation_index, Some(0))
  @test.assert_eq(diagram.notes[0].position, Right)
  @test.assert_eq(diagram.notes[0].color, Some("yellow"))
  @test.assert_eq(diagram.notes[1].relation_index, Some(1))
  @test.assert_eq(diagram.notes[1].text, "async\nretry")
}

///|
test "parses member tips and named notes" {
  let diagram = parse(
    "@startuml\nclass User {\n+ login()\n}\nnote left of User::login() #lightblue\nchecks credentials\nend note\nnote \"shared note\" as N1 <<info>> #yellow\nN1 .. User\n@enduml",
  )
  @test.assert_eq(diagram.notes.length(), 2)
  @test.assert_eq(diagram.notes[0].target_kind, MemberTip)
  @test.assert_eq(diagram.notes[0].target, "User")
  @test.assert_eq(diagram.notes[0].member_name, Some("login()"))
  @test.assert_eq(diagram.notes[1].target_kind, FloatingNote)
  @test.assert_eq(diagram.entity("N1").unwrap().kind, NamedNote)
  @test.assert_eq(diagram.notes[1].stereotype, Some("<<info>>"))
  @test.assert_eq(diagram.relations[0].left, "N1")
}

///|
test "parses constraints on the two previous links" {
  let diagram = parse(
    "@startuml\nA --> B\nA --> C\nconstraint on links #pink : {xor}\n@enduml",
  )
  @test.assert_eq(diagram.constraints.length(), 1)
  @test.assert_eq(diagram.constraints[0].first_relation, 0)
  @test.assert_eq(diagram.constraints[0].second_relation, 1)
  @test.assert_eq(diagram.constraints[0].text, "{xor}")
  @test.assert_eq(diagram.constraints[0].color, Some("pink"))
}

///|
test "parses map entries and linked map ports" {
  let diagram = parse(
    "@startuml\nclass Customer\nmap \"Order index\" as Orders {\nid => 42\ncustomer *--> Customer\n}\n@enduml",
  )
  let map = diagram.entity("Orders").unwrap()
  @test.assert_eq(map.kind, Map)
  @test.assert_eq(map.display, "Order index")
  @test.assert_eq(map.map_entries.length(), 2)
  @test.assert_eq(map.map_entries[0].key, "id")
  @test.assert_eq(map.map_entries[0].value, Some("42"))
  @test.assert_eq(map.map_entries[1].link_target, Some("Customer"))
  @test.assert_eq(diagram.relations[0].left, "Orders")
  @test.assert_eq(diagram.relations[0].left_end, Arrow)
  @test.assert_eq(diagram.relations[0].left_port, Some("customer"))
}

///|
test "parses multiline and single-line JSON entities" {
  let diagram = parse(
    "@startuml\njson Profile {\n\"name\": \"Ada\",\n\"settings\": {\n  \"active\": true\n}\n}\njson Count 42\njson Flags [true, false]\n@enduml",
  )
  @test.assert_eq(diagram.entity("Profile").unwrap().kind, Json)
  @test.assert_eq(
    diagram.entity("Profile").unwrap().json_data,
    Some("{\"name\": \"Ada\",\n\"settings\": {\n\"active\": true\n}}"),
  )
  @test.assert_eq(diagram.entity("Count").unwrap().json_data, Some("42"))
  @test.assert_eq(
    diagram.entity("Flags").unwrap().json_data,
    Some("[true, false]"),
  )
}

///|
test "reports malformed map and JSON bodies" {
  try parse("@startuml\nmap Broken {\nnot an entry\n}\n@enduml") catch {
    SyntaxError(_, message) =>
      @test.assert_eq(message, "map definition should contain key => value")
  } noraise {
    _ => @test.fail("expected malformed map error")
  }
  try parse("@startuml\njson Broken {\n\"missing\":\n}\n@enduml") catch {
    SyntaxError(_, message) => @test.assert_eq(message, "bad JSON data")
  } noraise {
    _ => @test.fail("expected malformed JSON error")
  }
}

///|
test "stores shared layout, scale, text blocks, and custom skinparams" {
  let diagram = parse(
    "@startuml\nleft to right direction\nscale 2/3\ntitle\nDomain model\nend title\nskinparam ClassBorderColor #123456\nclass User\n@enduml",
  )
  @test.assert_eq(diagram.style.layout_direction, Some(LeftToRight))
  @test.assert_eq(diagram.style.scale, Some("2/3"))
  @test.assert_eq(diagram.style.title, Some("Domain model"))
  @test.assert_eq(diagram.style.properties["ClassBorderColor"], "#123456")
}

///|
test "accepts common class-diagram command directives" {
  let diagram = parse(
    "@startuml\nfootbox\nnewpage Chapter 2\nlayout newLine\nhide empty description\nclass User\n@enduml",
  )
  @test.assert_eq(diagram.has_entity("User"), true)
  @test.assert_eq(diagram.style.properties["hide empty description"], "true")
  @test.assert_eq(diagram.style.properties["newpage chapter 2"], "true")
}

///|
test "preserves multiline entity note metadata and braced termination" {
  let diagram = parse(
    "@startuml\nclass User\nnote bottom of User <<warning>> [[https://example.com/note]] #pink {\ncheck account\n}\n@enduml",
  )
  let note = diagram.notes[0]
  @test.assert_eq(note.target_kind, EntityNote)
  @test.assert_eq(note.position, Bottom)
  @test.assert_eq(note.text, "check account")
  @test.assert_eq(note.stereotype, Some("<<warning>>"))
  @test.assert_eq(note.url, Some("https://example.com/note"))
  @test.assert_eq(note.color, Some("pink"))
}

///|
test "preserves association-class couple endpoints" {
  let diagram = parse(
    "@startuml\nclass A\nclass B\nclass Label\n(A, B) -- Label : association\n@enduml",
  )
  let relation = diagram.relations[0]
  @test.assert_eq(relation.left_couple, Some(("A", "B")))
  @test.assert_eq(relation.right_couple, None)
  @test.assert_eq(relation.right, "Label")
  @test.assert_eq(relation.label, Some("association"))
}
