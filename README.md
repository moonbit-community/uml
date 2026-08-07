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

Available:

- sequence
- class
- usecase
- mindmap
- yaml
- toml
- json

Under construction:

- object
- state
- component
