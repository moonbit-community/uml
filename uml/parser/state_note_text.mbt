///|
/// BlocLines.removeEmptyColumns removes shared leading spaces/tabs one
/// column at a time. Empty lines do not constrain the indent; relative
/// indent, trailing spaces, and the number of body lines remain intact.
/// Previously verified: common indentation, tabs, NBSP, trailing spaces and
/// blank lines; empty block link notes differ from explicit empty inline notes.
fn state_note_block_text(lines : Array[String]) -> String {
  let columns : Int? = lines.fold(init=None, (columns, line) => {
    let trimmed = line.trim_start(chars=" \t")
    guard !trimmed.is_empty() else { return columns }
    let leading = line.length() - trimmed.length()
    Some(columns.map_or(leading, current => current.min(leading)))
  })
  lines
  .map(line => {
    let removed = columns.map_or(line.length(), columns => {
      columns.min(line.length())
    })
    line[removed:].to_owned()
  })
  .join("\n")
}
