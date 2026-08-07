# UML CLI Cram Tests

These Moon Cram tests document the native `uml_cli` executable. `moon cram`
builds the native CLI and puts `uml_cli.exe` on `PATH`:

```bash
moon cram test --release tests/cram
```

## Help And Version

```mooncram
$ uml_cli.exe --version
0.1.0
```

```mooncram
$ uml_cli.exe --help
Usage: uml_cli [options] [file] [command]

Render PlantUML diagrams as SVG.

Run it from mooncakes.io without installing (the binary is fetched and
cached on first use; pin a version with moonbit-community/uml_cli@<version>):

  moonx moonbit-community/uml_cli diagram.puml > diagram.svg
  moonx moonbit-community/uml_cli render diagram.puml -o diagram.svg
  moonx moonbit-community/uml_cli check diagram.puml

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
> uml_cli.exe check hello.puml
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
> uml_cli.exe check user.puml
user.puml: OK (class diagram)
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
> uml_cli.exe render hello.puml -o hello.svg
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
> uml_cli.exe hello.puml | head -c 15
<svg xmlns="htt (no-eol)
```

## Report Errors

Unreadable input exits 1:

```mooncram
$ uml_cli.exe check missing.puml
error: failed to read missing.puml: No such file or directory
[1]
```

Sources that select no diagram family exit 1:

```mooncram
$ cat > empty.puml <<'EOF'
> @startuml
> @enduml
> EOF
> uml_cli.exe check empty.puml
error: empty.puml:1: unknown diagram
[1]
```

Usage errors exit 2:

```mooncram
$ uml_cli.exe render
error: 'file' requires at least 1 values but only 0 were provided

Usage: uml_cli render [options] <file>

Render PlantUML and print SVG.

Arguments:
  file  PlantUML file to render.

Options:
  -h, --help             Show help information.
  -o, --output <output>  Write the SVG to this path instead of stdout.

[2]
```
