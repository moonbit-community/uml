# uml-cli

A command-line tool to render PlantUML diagrams as SVG, built on
[`kokic/uml`](https://mooncakes.io/docs/kokic/uml).

## Run without installing

The prebuilt binary can be run directly from mooncakes.io — it is fetched
and cached on first use, and arguments are passed straight through (no `--`
separator needed). Pin a version with `moonbit-community/uml-cli/uml@<version>`
for reproducible behavior:

```bash
moonx moonbit-community/uml-cli/uml --help
moonx moonbit-community/uml-cli/uml diagram.puml > diagram.svg
moonx moonbit-community/uml-cli/uml render diagram.puml -o diagram.svg
moonx moonbit-community/uml-cli/uml check diagram.puml
```

## Usage

```
uml <file>           Render PlantUML and print SVG (same as `render`)
uml render <file>    Render PlantUML and print SVG
uml check <file>     Parse PlantUML and report the detected diagram kind
```

`render` prints the SVG to stdout so it can be piped; `--output`/`-o` writes
it to a file instead. Exit codes: `0` on success, `1` on read/parse/render
failure, `2` on usage errors.

Diagram families are detected from the source with the same per-line
heuristics PlantUML uses to pick a diagram factory: sequence, class, object,
use case, mindmap, JSON, YAML, and TOML today, with state, component, and
activity under construction. `check` names the detected family:

```console
$ uml check hello.puml
hello.puml: OK (sequence diagram)
```

## Run from source

```bash
moon runwasm uml -- diagram.puml          # in this directory
moon run --target native uml -- --help    # native build
```

The cram tests in [`cram/cli.md`](./cram/cli.md) document
the exact CLI behavior; run them with `moon cram test --release cram`.
