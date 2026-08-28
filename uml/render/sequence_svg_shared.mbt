///|
fn svg_color(color : String?, defaults : @style.SequenceColors) -> String {
  @svg.svg_color(color, defaults.participant)
}

///|
fn activation_color(
  color : String?,
  defaults : @style.SequenceColors,
) -> String {
  @svg.svg_color(color, defaults.activation)
}

///|
fn note_color(
  color : String?,
  _stereotype : String?,
  defaults : @style.SequenceColors,
) -> String {
  // Java resolves stereotype-tagged noteBackground/noteBorder skinparam
  // colors (`Colors.applyStereotypeForNote`); the modeled style set has no
  // stereotype variants, so both resolve to the shared note color.
  @svg.svg_color(color, defaults.note)
}

///|
fn append_line(
  output : StringBuilder,
  x1 : Int,
  y1 : Int,
  x2 : Int,
  y2 : Int,
  class_name : String,
  fill? : String = "none",
) -> Unit {
  output <+
    $|<line x1="\{x1}" y1="\{y1}" x2="\{x2}" y2="\{y2}" fill="\{fill}" class="\{class_name}"/>
}

///|
fn append_text(
  output : StringBuilder,
  x : Int,
  y : Int,
  text : String,
  class_name : String,
  defaults : @style.SequenceColors,
  anchor? : String = "middle",
  line_height? : Int = 15,
  font_metrics? : @metrics.FontMetrics? = None,
) -> Unit {
  let text_metrics = font_metrics.unwrap_or(
    @metrics.FontMetrics::from_defaults(
      font_size=(line_height - 2).max(1),
      line_height~,
    ),
  )
  @svg.append_text_markup(
    output,
    x.to_double(),
    y.to_double(),
    text,
    [("text-anchor", anchor), ("fill", defaults.text), ("class", class_name)],
    line_height=line_height.to_double(),
    anchor=Baseline,
    text_metrics=Some(text_metrics),
  )
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
  participant.birth_y.map_or(
    self.body_top - participant.participant.typ.header_height(),
    birth_y => birth_y + 9 - participant.participant.typ.header_height(),
  )
}

///|
fn DiagramLayout::participant_tail_y(self : DiagramLayout) -> Int {
  self.body_bottom + 9
}

///|
fn @seq.GroupKeyword::label(self : @seq.GroupKeyword) -> String {
  match self {
    @seq.Opt => "opt"
    @seq.Alt => "alt"
    @seq.Loop => "loop"
    @seq.Par => "par"
    @seq.Par2 => "par"
    @seq.Break => "break"
    @seq.Critical => "critical"
    @seq.Group => "group"
    @seq.Partition => "partition"
  }
}

///|
