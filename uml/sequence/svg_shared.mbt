///|
fn svg_color(color : String?) -> String {
  @style.svg_color(
    color,
    @style.render_defaults().sequence_participant_background,
  )
}

///|
fn activation_color(color : String?) -> String {
  @style.svg_color(
    color,
    @style.render_defaults().sequence_activation_background,
  )
}

///|
fn note_color(color : String?) -> String {
  @style.svg_color(color, @style.render_defaults().note_background)
}

///|
fn append_line(
  output : StringBuilder,
  x1 : Int,
  y1 : Int,
  x2 : Int,
  y2 : Int,
  class_name : String,
) -> Unit {
  output <+
    $|<line x1="\{x1}" y1="\{y1}" x2="\{x2}" y2="\{y2}" class="\{class_name}"/>
}

///|
fn append_text(
  output : StringBuilder,
  x : Int,
  y : Int,
  text : String,
  class_name : String,
  anchor? : String = "middle",
  line_height? : Int = 15,
) -> Unit {
  output.write_string(
    @svg.multiline_text_markup(
      x.to_double(),
      y.to_double(),
      text,
      [
        ("text-anchor", anchor),
        ("fill", @style.render_defaults().diagram_text),
        ("class", class_name),
      ],
      line_height=line_height.to_double(),
      offset=false,
    ),
  )
  output.write_string("\n")
}

///|
fn DiagramLayout::participant_at(
  self : DiagramLayout,
  code : String,
) -> ParticipantLayout? {
  self.participant_index.get(code).map(index => self.participants[index])
}

///|
fn DiagramLayout::participant_head_y(
  self : DiagramLayout,
  participant : ParticipantLayout,
) -> Int {
  match participant.birth_y {
    Some(birth_y) => birth_y + 9 - participant.participant.typ.header_height()
    None => self.body_top - participant.participant.typ.header_height()
  }
}

///|
fn DiagramLayout::participant_tail_y(self : DiagramLayout) -> Int {
  self.body_bottom + 9
}

///|
fn GroupKeyword::label(self : GroupKeyword) -> String {
  match self {
    Opt => "opt"
    Alt => "alt"
    Loop => "loop"
    Par => "par"
    Par2 => "par"
    Break => "break"
    Critical => "critical"
    Group => "group"
    Partition => "partition"
  }
}

///|
