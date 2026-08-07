# uml_cli

A command-line tool to render PlantUML diagrams as SVG, built on
[`kokic/uml`](https://mooncakes.io/docs/kokic/uml).

## Run without installing

The prebuilt binary can be run directly from mooncakes.io — it is fetched
and cached on first use, and arguments are passed straight through (no `--`
separator needed). Pin a version with `moonbit-community/uml_cli@<version>`
for reproducible behavior:

```bash
moonx moonbit-community/uml_cli --help
moonx moonbit-community/uml_cli diagram.puml > diagram.svg
moonx moonbit-community/uml_cli render diagram.puml -o diagram.svg
moonx moonbit-community/uml_cli check diagram.puml
```

## Usage

```
uml_cli <file>           Render PlantUML and print SVG (same as `render`)
uml_cli render <file>    Render PlantUML and print SVG
uml_cli check <file>     Parse PlantUML and report the detected diagram kind
```

`render` prints the SVG to stdout so it can be piped; `--output`/`-o` writes
it to a file instead. Exit codes: `0` on success, `1` on read/parse/render
failure, `2` on usage errors.

Diagram families are detected from the source with the same per-line
heuristics PlantUML uses to pick a diagram factory: sequence, class, use
case, mindmap, JSON, YAML, and TOML today, with object, state, component,
and activity under construction. `check` names the detected family:

```console
$ uml_cli check hello.puml
hello.puml: OK (sequence diagram)
```

## Run from source

```bash
moon runwasm . -- diagram.puml          # in this directory
moon run --target native . -- --help    # native build
```

The cram tests in [`tests/cram/uml_cli.md`](./tests/cram/uml_cli.md) document
the exact CLI behavior; run them with `moon cram test --release tests/cram`.
