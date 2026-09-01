# UML CLI Cram Tests

These Moon Cram tests document the native `uml` executable. `moon cram`
builds the native CLI and puts `uml` on `PATH`:

```bash
moon cram test --release cram
```

## Help And Version

```mooncram
$ uml --version
0.1.0
```

```mooncram
$ uml --help
Usage: uml [options] [file] [command]

Render PlantUML diagrams as SVG.

Run it from mooncakes.io without installing (the binary is fetched and
cached on first use; pin a version with moonbit-community/uml-cli/uml@<version>):

  moonx moonbit-community/uml-cli/uml diagram.puml > diagram.svg
  moonx moonbit-community/uml-cli/uml render diagram.puml -o diagram.svg
  moonx moonbit-community/uml-cli/uml check diagram.puml

`mod` reads a `moon tree --package --json` dependency graph from stdin and
prints it as SVG (default) or D2 (`--format d2`) to stdout. By default it
keeps packages with `in > 1 or out > 1` together with the edges touching
them; `--keep` replaces the selection rule (`>1`, `==max`, `in>1 && out>1`,
...), repeatable as a union. `--stats` prints the in/out degree minima and
maxima instead of rendering.

Exit codes:
  0  success
  1  the file could not be read or rendered; a human-readable error is
     printed to stdout
  2  usage error (unknown subcommand or missing file argument)

`render` prints the SVG to stdout unless `--output` names a file; it never
rewrites the input file.

Commands:
  render  Render PlantUML and print SVG.
  check   Parse PlantUML and report the detected diagram kind.
  mod     Render a package dependency graph from stdin as SVG or D2.
  help    Print help for the subcommand(s).

Arguments:
  file  Render PlantUML and print SVG.

Options:
  -h, --help             Show help information.
  -V, --version          Show version information.
  -o, --output <output>  Write the SVG to this path instead of stdout.
```

## Check A File

`check` parses without rendering and reports the diagram family the source
selects:

```mooncram
$ cat > hello.puml <<'EOF'
> @startuml
> participant Alice
> Alice -> Bob : hello
> @enduml
> EOF
> uml check hello.puml
hello.puml: OK (sequence diagram)
```

```mooncram
$ cat > user.puml <<'EOF'
> @startuml
> class User {
> - secret
> }
> @enduml
> EOF
> uml check user.puml
user.puml: OK (class diagram)
```

Object diagrams are recognized as their own family:

```mooncram
$ cat > object.puml <<'EOF'
> @startuml
> object "Ada Lovelace" as ada <<customer>> {
>   + id = "customer-42"
> }
> json Profile {
>   "active": true
> }
> map Index {
>   id => 42
> }
> @enduml
> EOF
> uml check object.puml
object.puml: OK (object diagram)
```

Malformed JSON bodies keep the exit-1 contract:

```mooncram
$ cat > broken-object.puml <<'EOF'
> @startuml
> json Broken {
> "missing":
> }
> @enduml
> EOF
> uml check broken-object.puml
error: broken-object.puml:4: bad JSON data
[1]
```

## Render To A File

`render --output` writes the SVG and prints nothing on success:

```mooncram
$ cat > hello.puml <<'EOF'
> @startuml
> participant Alice
> Alice -> Bob : hello
> @enduml
> EOF
> uml render hello.puml -o hello.svg
> head -c 60 hello.svg
<svg xmlns="http://www.w3.org/2000/svg" width="117" height=" (no-eol)
```

## Render To Stdout

Without `--output` the SVG goes to stdout, so it can be piped:

```mooncram
$ cat > hello.puml <<'EOF'
> @startuml
> participant Alice
> Alice -> Bob : hello
> @enduml
> EOF
> uml hello.puml | head -c 15
<svg xmlns="htt (no-eol)
```

Object rendering keeps a parseable `<svg>` root and paints the typed nodes:

```mooncram
$ cat > object.puml <<'EOF'
> @startuml
> object Cart {
>   + total = "42.00"
> }
> json Profile {
>   "name": "Ada"
> }
> @enduml
> EOF
> uml render object.puml | head -c 15
<svg xmlns="htt (no-eol)
```

```mooncram
$ cat > json-rows.puml <<'EOF'
> @startuml
> json Profile {
>   "name": "Ada",
>   "active": true
> }
> @enduml
> EOF
> uml render json-rows.puml | grep -o '<line class="json-row-separator"' | wc -l
       2
```

## Render Package Dependency Graphs

`mod` reads a `moon tree --package --json` graph from stdin, keeps only
packages with `in > 1 or out > 1`, and prints the SVG to stdout:

```mooncram
$ cat <<'EOF' | uml mod | head -c 15
> {"nodes":[{"module":"m/a","source":{"kind":"local"},"rel":"a"},{"module":"m/a","source":{"kind":"local"},"rel":"f"},{"module":"m/a","source":{"kind":"local"},"rel":"b"},{"module":"m/a","source":{"kind":"local"},"rel":"c"},{"module":"m/a","source":{"kind":"local"},"rel":"d"},{"module":"m/a","source":{"kind":"local"},"rel":"e"}],"edges":[{"from":0,"to":2,"alias":"","kinds":["source"]},{"from":0,"to":3,"alias":"","kinds":["source"]},{"from":4,"to":1,"alias":"","kinds":["source"]},{"from":5,"to":1,"alias":"","kinds":["source"]},{"from":0,"to":1,"alias":"","kinds":["source"]}]}
> EOF
<?xml version=" (no-eol)
```

The default selection keeps packages with `in > 1 or out > 1` (the two hubs)
and draws every edge touching them, together with the packages at the other
end:

```mooncram
$ cat <<'EOF' | uml mod --format d2
> {"nodes":[{"module":"m/a","source":{"kind":"local"},"rel":"a"},{"module":"m/a","source":{"kind":"local"},"rel":"f"},{"module":"m/a","source":{"kind":"local"},"rel":"b"},{"module":"m/a","source":{"kind":"local"},"rel":"c"},{"module":"m/a","source":{"kind":"local"},"rel":"d"},{"module":"m/a","source":{"kind":"local"},"rel":"e"}],"edges":[{"from":0,"to":2,"alias":"","kinds":["source"]},{"from":0,"to":3,"alias":"","kinds":["source"]},{"from":4,"to":1,"alias":"","kinds":["source"]},{"from":5,"to":1,"alias":"","kinds":["source"]},{"from":0,"to":1,"alias":"","kinds":["source"]}]}
> EOF
direction: down

`m/a/a`: {
  label: "a\nm/a"
}

`m/a/f`: {
  label: "f\nm/a"
}

`m/a/b`: {
  label: "b\nm/a"
}

`m/a/c`: {
  label: "c\nm/a"
}

`m/a/d`: {
  label: "d\nm/a"
}

`m/a/e`: {
  label: "e\nm/a"
}

`m/a/a` -> `m/a/b`

`m/a/a` -> `m/a/c`

`m/a/d` -> `m/a/f`

`m/a/e` -> `m/a/f`

`m/a/a` -> `m/a/f`
```

`--keep` replaces the selection rule: `==1` selects the packages with exactly
one incoming or outgoing edge and draws their connections, which omits the
edge between the two hubs:

```mooncram
$ cat <<'EOF' | uml mod --format d2 --keep '==1'
> {"nodes":[{"module":"m/a","source":{"kind":"local"},"rel":"a"},{"module":"m/a","source":{"kind":"local"},"rel":"f"},{"module":"m/a","source":{"kind":"local"},"rel":"b"},{"module":"m/a","source":{"kind":"local"},"rel":"c"},{"module":"m/a","source":{"kind":"local"},"rel":"d"},{"module":"m/a","source":{"kind":"local"},"rel":"e"}],"edges":[{"from":0,"to":2,"alias":"","kinds":["source"]},{"from":0,"to":3,"alias":"","kinds":["source"]},{"from":4,"to":1,"alias":"","kinds":["source"]},{"from":5,"to":1,"alias":"","kinds":["source"]},{"from":0,"to":1,"alias":"","kinds":["source"]}]}
> EOF
direction: down

`m/a/a`: {
  label: "a\nm/a"
}

`m/a/f`: {
  label: "f\nm/a"
}

`m/a/b`: {
  label: "b\nm/a"
}

`m/a/c`: {
  label: "c\nm/a"
}

`m/a/d`: {
  label: "d\nm/a"
}

`m/a/e`: {
  label: "e\nm/a"
}

`m/a/a` -> `m/a/b`

`m/a/a` -> `m/a/c`

`m/a/d` -> `m/a/f`

`m/a/e` -> `m/a/f`
```

`--related-edges induced` narrows the graph to exactly the selected nodes and
the edges between them:

```mooncram
$ cat <<'EOF' | uml mod --format d2 --related-edges induced
> {"nodes":[{"module":"m/a","source":{"kind":"local"},"rel":"a"},{"module":"m/a","source":{"kind":"local"},"rel":"f"},{"module":"m/a","source":{"kind":"local"},"rel":"b"},{"module":"m/a","source":{"kind":"local"},"rel":"c"},{"module":"m/a","source":{"kind":"local"},"rel":"d"},{"module":"m/a","source":{"kind":"local"},"rel":"e"}],"edges":[{"from":0,"to":2,"alias":"","kinds":["source"]},{"from":0,"to":3,"alias":"","kinds":["source"]},{"from":4,"to":1,"alias":"","kinds":["source"]},{"from":5,"to":1,"alias":"","kinds":["source"]},{"from":0,"to":1,"alias":"","kinds":["source"]}]}
> EOF
direction: down

`m/a/a`: {
  label: "a\nm/a"
}

`m/a/f`: {
  label: "f\nm/a"
}

`m/a/a` -> `m/a/f`
```

`--stats` reports the in/out degree minima and maxima of the graph:

```mooncram
$ cat <<'EOF' | uml mod --stats
> {"nodes":[{"module":"m/a","source":{"kind":"local"},"rel":"a"},{"module":"m/a","source":{"kind":"local"},"rel":"f"},{"module":"m/a","source":{"kind":"local"},"rel":"b"},{"module":"m/a","source":{"kind":"local"},"rel":"c"},{"module":"m/a","source":{"kind":"local"},"rel":"d"},{"module":"m/a","source":{"kind":"local"},"rel":"e"}],"edges":[{"from":0,"to":2,"alias":"","kinds":["source"]},{"from":0,"to":3,"alias":"","kinds":["source"]},{"from":4,"to":1,"alias":"","kinds":["source"]},{"from":5,"to":1,"alias":"","kinds":["source"]},{"from":0,"to":1,"alias":"","kinds":["source"]}]}
> EOF
in: min 0, max 3
out: min 0, max 3
```

Malformed input exits 1:

```mooncram
$ printf 'not json' | uml mod >/dev/null
[1]
```

An invalid `--keep` rule exits 1:

```mooncram
$ printf 'not json' | uml mod --keep 'bogus' >/dev/null
[1]
```

## Report Errors

Unreadable input exits 1:

```mooncram
$ uml check missing.puml
error: failed to read missing.puml: No such file or directory
[1]
```

Sources that select no diagram family exit 1:

```mooncram
$ cat > empty.puml <<'EOF'
> @startuml
> @enduml
> EOF
> uml check empty.puml
error: empty.puml:1: unknown diagram
[1]
```

Usage errors exit 2:

```mooncram
$ uml render
error: 'file' requires at least 1 values but only 0 were provided

Usage: uml render [options] <file>

Render PlantUML and print SVG.

Arguments:
  file  PlantUML file to render.

Options:
  -h, --help             Show help information.
  -o, --output <output>  Write the SVG to this path instead of stdout.

[2]
```
