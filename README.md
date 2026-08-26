# uml

A MoonBit project that converts UML strings to SVG, aiming to align with PlantUML's behavior, including its layout.

| Sequence | Class |
|---|---|
| ![Sequence diagram](./uml/__snapshot__/sequence.svg) | ![Class diagram](./uml/__snapshot__/class.svg) |

| Mindmap | JSON |
|---|---|
| ![Mindmap diagram](./uml/__snapshot__/mindmap.svg) | ![JSON diagram](./uml/__snapshot__/json.svg) |

Every image above is a test snapshot: the [library README](./uml/README.mbt.md)
is an executable document whose code blocks run under `moon test` and write
these SVGs into [`uml/__snapshot__/`](./uml/__snapshot__/). See it for the full
gallery (use case, YAML, TOML, dark theming) and API walkthrough.

## Supported diagrams

Two families are supported: the standard UML diagrams (OMG UML 2.5) and the
diagrams that only exist in PlantUML or in this project. Diagram types that
render a picture match PlantUML's `DiagramType`; `toml` and `mbti` are
extensions not present in PlantUML.

### Standard UML diagrams

PlantUML has dedicated syntax for 11 of the 14 standard UML diagram types.

| Diagram | Kind | Status |
|---|---|---|
| Class | structure | done |
| Object | structure | done |
| Component | structure | done |
| Deployment | structure | done |
| Package | structure | done (class grammar) |
| Use Case | behavior | done |
| Activity | behavior | done |
| State Machine | behavior | done |
| Sequence | interaction | done |
| Timing | interaction | parsed, renderer pending |

### Project extensions

| Diagram | Status |
|---|---|
| TOML | done |
| MBTI | done |

### PlantUML extensions

| Diagram | Status |
|---|---|
| Mindmap | done |
| WBS | parsed, renderer pending |
| JSON | done |
| YAML | done |
| DOT | done |
| BPMN | planned |
| Gantt | planned |
| Nwdiag family (nwdiag, seqdiag, actdiag, blockdiag, rackdiag) | planned |
| Salt / Wire | planned |
| Packet | planned |
| Chart | planned |
| Chen / IE entity-relationship | planned |
| Chronology | planned |
| Composite (legacy) | planned |
| EBNF | planned |
| Regex | planned |
| Git | planned |
| Files | planned |
| Board | planned |
| HCL | planned |
| Flow | planned |
| Ditaa | planned |
| JCCKit | planned |
