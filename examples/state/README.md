# State diagram examples

These are focused acceptance fixtures for PlantUML state diagrams. Each input
exercises one parser or semantic property and intentionally avoids assertions
about SVG coordinates or dimensions. Once the state-diagram facade is exposed,
render a fixture with `moon run . examples/state/<fixture>.uml`.

| Fixture | Upstream parser focus | Expected structural behavior |
| - | - | - |
| `01-basic-lifecycle` | `CommandLinkState` | Initial and final pseudo-states attach to the lifecycle, while labelled transitions retain their direction. |
| `02-declarations-and-descriptions` | `CommandCreateState`, `CommandAddField` | Quoted display/alias, colour, stereotype, and inline description belong to the declared state. |
| `03-transition-directions` | `CommandLinkState`, `CommandLinkStateReverse` | Explicit directional arrows preserve their endpoint order and requested layout direction. |
| `04-composite-state` | `CommandCreatePackageState`, `CommandEndState` | Nested states and transitions are scoped inside the composite state; its external transitions remain attached to the composite. |
| `05-concurrent-regions` | `CommandConcurrentState` | Every separator starts another region of the same composite state instead of a sequential transition. |
| `06-history-and-synchronization` | `CommandLinkStateCommon` | Shallow history and synchronization bars are pseudo-states, not ordinary named states. |
| `07-notes-and-metadata` | `CommandCreateState`, `CommandFactoryNoteOnEntity`, `CommandFactoryNoteOnLink` | Entity metadata, a multiline entity note, and a transition note preserve their distinct targets. |
| `08-frame-and-aliases` | `CommandCreatePackage2` | A frame encloses the aliased states without changing their transition endpoints. |
| `09-reverse-and-decorated-transitions` | `CommandLinkState`, `CommandLinkStateReverse` | Reverse, dashed, bold, and crossed transitions retain endpoint decoration and line style. |

The syntax and intended semantics follow the commands registered by
`src/main/java/net/sourceforge/plantuml/statediagram/StateDiagramFactory.java`:
`CommandCreateState`, `CommandLinkState`, `CommandLinkStateReverse`,
`CommandCreatePackageState`, `CommandCreatePackage2`, `CommandEndState`,
`CommandAddField`, and `CommandConcurrentState`.
