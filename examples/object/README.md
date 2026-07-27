# Object diagram examples

Each fixture isolates an object-diagram behavior implemented by PlantUML's
`objectdiagram` parser. Render one with `moon run . examples/object/<fixture>.uml`
and compare the SVG with the Java PlantUML reference.

| Fixture | Coverage |
| - | - |
| `01-objects-and-slots` | Object aliases, display names, body slots, visibility markers, and external slot declarations |
| `02-links-and-roles` | Associations, directed links, cardinalities, roles, labels, and explicit link direction |
| `03-map-ports` | Map entries, display aliases, map metadata, and links emitted from map-key ports |
| `04-json-values` | Multiline JSON objects, inline scalar and array values, aliases, and JSON values containing braces in strings |
| `05-notes-and-presentation` | Object metadata, packages, relation metadata, entity/link notes, member tips, filters, and shared presentation directives |
