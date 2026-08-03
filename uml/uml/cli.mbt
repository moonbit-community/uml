///|
fn main raise {
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
  let svg = @api.render_svg(source)
  try @fs.write_string_to_file(output_path, svg) catch {
    IOError(message) =>
      println("error: unable to write \{output_path}: \{message}")
  } noraise {
    _ => println("output: \{output_path}")
  }
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
