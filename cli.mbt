///|
fn main {
  let command = @argparse.Command(
    "uml",
    about="Render a PlantUML diagram as SVG.",
    positionals=[
      PositionArg(
        "input",
        about="Path to the .uml input file.",
        num_args=@argparse.ValueRange::single(),
      ),
    ],
  )
  let matches = command.parse() catch { error => return println(error) }
  guard matches.values.get("input") is Some([input_path]) else {
    return println(command.render_help())
  }
  guard input_path.has_suffix(".uml") else {
    return println("error: input path must end with .uml")
  }

  let output_path = output_path_for(input_path)
  guard read_input(input_path) is Some(source) else { return }
  let svg = @api.render_svg(source) catch {
    SyntaxError(line, message) =>
      return println("error: line \{line}: \{message}")
  }
  guard write_output(output_path, svg) else { return }
  println("output: \{output_path}")
}

///|
fn output_path_for(input_path : String) -> String {
  let extension_start = input_path.length() - 4
  input_path.unsafe_substring(start=0, end=extension_start) + ".svg"
}

///|
fn read_input(path : String) -> String? {
  Some(@fs.read_file_to_string(path)) catch {
    IOError(message) => {
      println("error: unable to read \{path}: \{message}")
      None
    }
  }
}

///|
fn write_output(path : String, content : String) -> Bool {
  try {
    @fs.write_string_to_file(path, content)
    true
  } catch {
    IOError(message) => {
      println("error: unable to write \{path}: \{message}")
      false
    }
  }
}
