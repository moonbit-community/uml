///|
fn DiagramLayout::note_anchor_center(
  self : DiagramLayout,
  note : @seq.Note,
  arrow_anchor : @seq.Message?,
) -> Int {
  guard note.on_arrow else {
    note.participant_codes
    .get(0)
    .map_or(self.width / 2, code => {
      self
      .participant_at(code)
      .map_or(self.width / 2, participant => participant.center_x)
    })
  }
  match arrow_anchor {
    Some(message) => {
      let from = self
        .participant_at(message.from_code)
        .map_or(self.width / 2, participant => participant.center_x)
      let to = self
        .participant_at(message.to_code)
        .map_or(self.width / 2, participant => participant.center_x)
      (from + to) / 2
    }
    None => self.width / 2
  }
}

///|
fn DiagramLayout::content_horizontal_bounds(
  self : DiagramLayout,
  events : Array[@seq.Event],
) -> (Int, Int) {
  guard self.participants.length() > 0 else { (0, self.width) }
  let first = self.participants[0]
  let last = self.participants[self.participants.length() - 1]
  let mut min_x = first.center_x - first.width / 2
  let mut max_x = last.center_x + last.width / 2
  let mut arrow_anchor : @seq.Message? = None
  for index, event in events {
    match event {
      @seq.Message(message) => {
        if message.is_self() {
          if self.participant_at(message.from_code) is Some(participant) {
            max_x = max_x.max(
              participant.center_x +
              40 +
              TextSize::of_with(message.display_label(), self.text_metrics.body).width,
            )
          }
        }
        arrow_anchor = Some(message)
      }
      @seq.MessageExo(message) =>
        if self.participant_at(message.participant_code) is Some(participant) {
          let label_width = TextSize::of_with(
              message.label.unwrap_or(""),
              self.text_metrics.body,
            ).width
          let extent = if message.short_arrow {
            40
          } else {
            (label_width + 32).max(90)
          }
          match message.exo_type {
            @seq.FromLeft | @seq.ToLeft =>
              min_x = min_x.min(participant.center_x - extent)
            @seq.FromRight | @seq.ToRight =>
              max_x = max_x.max(participant.center_x + extent)
          }
        }
      @seq.Note(note) => {
        let geometry = self.note_geometry(
          note,
          self.placements[index],
          arrow_anchor,
        )
        min_x = min_x.min(geometry.x)
        max_x = max_x.max(geometry.x + geometry.component.width)
      }
      @seq.Notes(notes) =>
        for note in notes {
          let geometry = self.note_geometry(
            note,
            self.placements[index],
            arrow_anchor,
          )
          min_x = min_x.min(geometry.x)
          max_x = max_x.max(geometry.x + geometry.component.width)
        }
      _ => ()
    }
  }
  for group in self.groups {
    let (x, width) = self.group_bounds(group)
    min_x = min_x.min(x)
    max_x = max_x.max(x + width)
  }
  let max_box_depth = max_participant_box_depth(self.participants)
  for depth in 0..<max_box_depth {
    for_each_participant_box_run(self.participants, depth, (start, end, box) => {
      let (left, right) = participant_box_horizontal_bounds(
        self.participants[start:end].to_owned(),
        box,
      )
      min_x = min_x.min(left)
      max_x = max_x.max(right)
    })
  }
  (min_x, max_x)
}

///|
fn participant_lifetimes(
  events : Array[@seq.Event],
  placements : Array[EventPlacement],
) -> (Map[String, Int], Map[String, Int]) {
  let births : Map[String, Int] = Map([])
  let deaths : Map[String, Int] = Map([])
  for index, event in events {
    match event {
      @seq.Message(message) =>
        match message.activation_spec {
          Some(@seq.Create) => births[message.to_code] = placements[index].y
          Some(@seq.Destroy) =>
            deaths[message.to_code] = placements[index].y + MESSAGE_ARROW_OFFSET
          _ => ()
        }
      @seq.MessageExo(message) =>
        match message.activation_spec {
          Some(@seq.Create) =>
            births[message.participant_code] = placements[index].y
          Some(@seq.Destroy) =>
            deaths[message.participant_code] = placements[index].y +
              MESSAGE_ARROW_OFFSET
          _ => ()
        }
      @seq.LifeEvent(life) =>
        match life.event_type {
          @seq.Create => births[life.participant_code] = placements[index].y
          @seq.Destroy => deaths[life.participant_code] = placements[index].y
          _ => ()
        }
      _ => ()
    }
  }
  (births, deaths)
}

///|
fn @seq.SequenceDiagram::layout(self : @seq.SequenceDiagram) -> DiagramLayout {
  let text_metrics = SequenceTextMetrics::new(self.style)
  let (participants, participant_index, width) = layout_participants(
    self, text_metrics,
  )
  let mut participant_header_height = 36 +
    self.participant_box_header_height(text_metrics)
  for participant in participants {
    participant_header_height = participant_header_height.max(
      participant.participant.typ.header_height(),
    )
  }
  let (placements, activations, groups, destroys, auto_page_breaks, body_bottom) = layout_events(
    self,
    participant_index,
    participant_header_height + vertical_margin + 8,
    text_metrics,
  )
  let (births, deaths) = participant_lifetimes(self.events, placements)
  let participants = participants.map(participant => {
    ..participant,
    birth_y: births.get(participant.participant.code),
    death_y: deaths.get(participant.participant.code),
  })
  let footbox_height = if self.show_footbox {
    participant_header_height + 10
  } else {
    24
  }
  let layout = {
    participants,
    participant_index,
    placements,
    activations,
    groups,
    destroys,
    auto_page_breaks,
    width,
    height: body_bottom + footbox_height + vertical_margin,
    body_top: participant_header_height + vertical_margin,
    body_bottom,
    text_metrics,
    defaults: self.style.defaults().sequence_colors(),
  }
  let (min_x, max_x) = layout.content_horizontal_bounds(self.events)
  let shift = (horizontal_margin - min_x).max(0)
  let participants = layout.participants.map(participant => {
    ..participant,
    center_x: participant.center_x + shift,
  })
  let width = (max_x + shift + horizontal_margin).max(
    self.minimum_text_width(text_metrics),
  )
  { ..layout, participants, width, }
}

///|
/// Calculate PlantUML-style sequence-diagram geometry without rendering it.
pub fn layout_sequence(diagram : @seq.SequenceDiagram) -> DiagramLayout {
  diagram.layout()
}

///|
/// Whether unlinked participants are hidden by the parsed directives.
pub fn sequence_hides_unlinked(diagram : @seq.SequenceDiagram) -> Bool {
  diagram.hides_unlinked()
}
