///|
let version : String = "0.1.0"

///|
let about : String =
  #|Render PlantUML diagrams as SVG.
  #|
  #|Run it from mooncakes.io without installing (the binary is fetched and
  #|cached on first use; pin a version with moonbit-community/uml_cli@<version>):
  #|
  #|  moonx moonbit-community/uml_cli diagram.puml > diagram.svg
  #|  moonx moonbit-community/uml_cli render diagram.puml -o diagram.svg
  #|  moonx moonbit-community/uml_cli check diagram.puml
  #|
  #|Exit codes:
  #|  0  success
  #|  1  the file could not be read or rendered; a human-readable error is
  #|     printed to stdout
  #|  2  usage error (unknown subcommand or missing file argument)
  #|
  #|`render` prints the SVG to stdout unless `--output` names a file; it never
  #|rewrites the input file.

///|
fn output_option() -> @argparse.OptionArg {
  @argparse.OptionArg::OptionArg(
    "output",
    short='o',
    long="output",
    about="Write the SVG to this path instead of stdout.",
  )
}

///|
fn uml_command() -> @argparse.Command {
  Command(
    "uml_cli",
    about~,
    version~,
    arg_required_else_help=true,
    positionals=[PositionArg("file", about="Render PlantUML and print SVG.")],
    options=[output_option()],
    subcommands=[
      Command(
        "render",
        about="Render PlantUML and print SVG.",
        positionals=[
          PositionArg(
            "file",
            about="PlantUML file to render.",
            num_args=@argparse.ValueRange::single(),
          ),
        ],
        options=[output_option()],
      ),
      Command(
        "check",
        about="Parse PlantUML and report the detected diagram kind.",
        positionals=[
          PositionArg(
            "file",
            about="PlantUML file to validate.",
            num_args=@argparse.ValueRange::single(),
          ),
        ],
      ),
    ],
  )
}

///|
fn main {
  let code = run(@env.args()[1:])
  if code != 0 {
    @sys.exit(code)
  }
}

///|
fn run(args : ArrayView[String]) -> Int {
  let matches = @argparse.parse(uml_command(), argv=args, env=Map([])) catch {
    err => {
      println(err)
      return 2
    }
  }
  match matches.subcommand {
    Some(("render", child)) => dispatch_file(child, render_file)
    Some(("check", child)) => dispatch_file(child, check_file)
    Some((name, _)) => {
      println("error: unsupported command `\{name}`")
      2
    }
    None => dispatch_file(matches, render_file)
  }
}

///|
fn dispatch_file(
  matches : @argparse.Matches,
  action : (String, @argparse.Matches) -> Int,
) -> Int {
  match matches.values.get("file") {
    Some([path]) => action(path, matches)
    _ => 2
  }
}

///|
fn render_file(path : String, matches : @argparse.Matches) -> Int {
  let source = @fs.read_file_to_string(path) catch {
    IOError(message) => {
      println("error: failed to read \{path}: \{message}")
      return 1
    }
  }
  let svg = @api.render_svg(source) catch {
    err => {
      println(render_error(path, "render", err))
      return 1
    }
  }
  match matches.values.get("output") {
    Some([target]) =>
      try @fs.write_string_to_file(target, svg) catch {
        IOError(message) => {
          println("error: failed to write \{target}: \{message}")
          1
        }
      } noraise {
        _ => 0
      }
    _ => {
      println(svg)
      0
    }
  }
}

///|
fn check_file(path : String, _matches : @argparse.Matches) -> Int {
  let source = @fs.read_file_to_string(path) catch {
    IOError(message) => {
      println("error: failed to read \{path}: \{message}")
      return 1
    }
  }
  let document = @api.parse(source) catch {
    err => {
      println(render_error(path, "parse", err))
      return 1
    }
  }
  println("\{path}: OK (\{kind_name(document.kind())} diagram)")
  0
}

///|
fn render_error(path : String, action : String, err : Error) -> String {
  match err {
    @parse.SyntaxError(line, message) => "error: \{path}:\{line}: \{message}"
    _ => "error: failed to \{action} \{path}: \{err}"
  }
}

///|
fn kind_name(kind : @api.DiagramKind) -> String {
  match kind {
    Sequence => "sequence"
    Class => "class"
    Activity => "activity"
    State => "state"
    Component => "component"
    Object => "object"
    UseCase => "use case"
    Mindmap => "mindmap"
    Json => "json"
    Yaml => "yaml"
    Toml => "toml"
  }
}
