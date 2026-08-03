# Class diagram examples

Each fixture isolates a class-diagram behavior so its SVG can be compared with
the Java PlantUML reference without having to untangle unrelated syntax. Render
one with `moon run . examples/class/<fixture>.uml`.

| Fixture | Coverage |
| - | - |
| `01-basic` | Package scope, aliases, abstract classes, interfaces, and realization |
| `02-members-and-kinds` | Class bodies, visibility, sections, return types, enum values, inheritance, and `implements` |
| `03-relationships` | Cardinalities, composition, dependency, realization, labels, and directional links |
| `04-packages-and-namespaces` | Nested packages, namespace qualification, package metadata, and cross-scope links |
| `05-notes-and-metadata` | Stereotypes, URLs, colors, entity notes, and link notes |
| `06-visibility-and-style` | Member filtering, layout direction, skin parameters, and targetless notes |
| `07-association-class` | Association-class endpoint pairs and labelled association links |
| `08-banking-domain` | A rich multi-class domain: 9 classes/enums/interfaces, 48 members, visibility, and 6 cardinality links |
