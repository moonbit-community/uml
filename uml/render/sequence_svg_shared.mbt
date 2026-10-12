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
  output : SequenceDrawing,
  x1 : Double,
  y1 : Double,
  x2 : Double,
  y2 : Double,
  class_name : String,
  fill~ : @graphics.Paint = None,
) -> Unit {
  output.draw(
    Line(sequence_point(x1, y1), sequence_point(x2, y2)),
    class_name~,
    fill~,
  )
}

///|
fn append_text(
  output : SequenceDrawing,
  x : Double,
  y : Double,
  text : String,
  class_name : String,
  defaults : @style.SequenceColors,
  anchor~ : @graphics.TextAnchor = Middle,
  line_height~ : Int32 = 15,
  font_metrics~ : @metrics.FontMetrics? = None,
) -> Unit {
  let text_metrics = font_metrics.unwrap_or(
    @metrics.FontMetrics::from_defaults(
      font_size=(line_height - 2).max(1),
      line_height~,
    ),
  )
  append_state_text_at_top(
    output.graphic.with_style({
      ..Default::default(),
      fill: Color(defaults.text),
    }),
    text,
    x,
    y - text_metrics.ascent.to_double(),
    class_name,
    text_metrics,
    anchor~,
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
) -> Double {
  participant.birth_y.map_or(self.body_top - participant.height, birth_y => {
    birth_y + MESSAGE_ARROW_OFFSET - participant.height / 2
  })
}

///|
fn DiagramLayout::participant_tail_y(self : DiagramLayout) -> Double {
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
