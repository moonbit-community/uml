# Activity diagrams

These inputs are small, independent acceptance cases for PlantUML's modern
activity-diagram parser (`activitydiagram3.ActivityDiagramFactory3`).  Each
case exercises a structural property rather than an exact SVG size or
coordinate, so it remains useful while layout evolves.

| Example | Parser focus | Expected structural behavior |
| - | - | - |
| `01-basic-flow.uml` | `start`, activity nodes, explicit arrows, `stop` | A single linear flow has one entry and one terminal node. |
| `02-conditional-paths.uml` | `if`, `elseif`, `else`, `endif` | Every conditional branch is retained and rejoins after `endif`. |
| `03-loops.uml` | `while` / `endwhile`, `repeat` / `repeat while` | Both pre-test and post-test loops retain their back edge and exit label. |
| `04-parallel-work.uml` | `fork`, `fork again`, `end fork` | Parallel branches split once, retain every branch, then merge before the next activity. |
| `05-switch-cases.uml` | `switch`, `case`, `endswitch` | Every case belongs to the same decision and rejoins after the switch. |
| `06-partitions-and-swimlanes.uml` | swimlane declarations, `partition`, block note | Lane ownership, partition nesting, and the attached note survive parsing. |
| `07-flow-targets.uml` | `label`, `goto` | A named target resolves to a zero-size label anchor and produces an orthogonal non-linear edge. |

The syntax selection follows the commands registered by the upstream factory:
`src/main/java/net/sourceforge/plantuml/activitydiagram3/ActivityDiagramFactory3.java`.
