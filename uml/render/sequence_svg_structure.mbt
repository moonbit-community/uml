///|
fn DiagramLayout::group_bounds(
  self : DiagramLayout,
  group : GroupSpan,
) -> (Int, Int) {
  guard self.participants.length() > 0 else { (18, self.width - 36) }
  let first_index = group.first_participant.unwrap_or(0)
  let last_index = group.last_participant.unwrap_or(
    self.participants.length() - 1,
  )
  let first = self.participants[first_index]
  let last = self.participants[last_index]
  let inset = 10 + group.depth * 8
  let x = first.center_x - first.width / 2 - inset
  let right = last.center_x + last.width / 2 + inset
  (x, (right - x).max(1))
}

///|
fn GroupSpan::header_text(self : GroupSpan) -> String {
  match self.keyword {
    @seq.Group => self.header
    _ => self.keyword.label()
  }
}

///|
fn GroupSpan::comment_text(self : GroupSpan) -> String? {
  match self.keyword {
    @seq.Group => None
    _ => @tokenizer.normalize_label(self.header)
  }
}

///|
fn append_groups(output : StringBuilder, layout : DiagramLayout) -> Unit {
  for group in layout.groups {
    let (x, width) = layout.group_bounds(group)
    let height = (group.end_y - group.start_y).max(1)
    output <+
      $|<g class="group" data-keyword="\{group.keyword.label()}">
    if !group.parallel {
      let body_fill = group.color.map_or("none", _ => {
        svg_color(group.color, layout.defaults)
      })
      output <+
        $|<rect x="\{x}" y="\{group.start_y}" width="\{width}" height="\{height}" class="group-body" fill="\{body_fill}"/>
    }
    for branch_index, branch in group.branches {
      match branch.color {
        Some(color) => {
          let branch_height = (branch.end_y - branch.start_y).max(1)
          output <+
            $|<rect x="\{x}" y="\{branch.start_y}" width="\{width}" height="\{branch_height}" class="group-branch" fill="\{svg_color(Some(color), layout.defaults)}"/>
        }
        None => ()
      }
      if branch_index > 0 {
        append_line(
          output,
          x,
          branch.start_y,
          x + width,
          branch.start_y,
          "group-separator",
        )
        if branch.label is Some(label) {
          append_text(
            output,
            x + 8,
            branch.start_y + 12,
            "[\{label}]",
            "group-label",
            layout.defaults,
            anchor="start",
            line_height=layout.text_metrics.body_bold.line_height,
            font_metrics=Some(layout.text_metrics.body_bold),
          )
        }
      }
    }
    if !group.parallel {
      let header = group.header_text()
      let comment = group.comment_text()
      let label = comment.map_or(header, value => "\{header} [\{value}]")
      let header_width = (TextSize::of_with(
        label,
        layout.text_metrics.body_bold,
      ).width +
      38).max(54)
      output <+
        $|<path d="M\{x} \{group.start_y}h\{header_width}v22h-8l-5 5-5-5h-\{header_width - 18}z" class="group-header" fill="\{svg_color(group.header_color, layout.defaults)}"/>
      append_text(
        output,
        x + 8,
        group.start_y + 16,
        label,
        "group-label",
        layout.defaults,
        anchor="start",
        line_height=layout.text_metrics.body_bold.line_height,
        font_metrics=Some(layout.text_metrics.body_bold),
      )
    }
    output.write_string("</g>\n")
  }
}

///|
fn delay_ranges(
  layout : DiagramLayout,
  events : Array[@seq.Event],
) -> Array[(Int, Int)] {
  let ranges = []
  events.eachi((index, event) => {
    if event is @seq.Delay(_) {
      let placement = layout.placements[index]
      ranges.push((placement.y, placement.y + placement.height))
    }
  })
  ranges
}

///|
fn append_lifelines(
  output : StringBuilder,
  layout : DiagramLayout,
  events : Array[@seq.Event],
) -> Unit {
  let delays = delay_ranges(layout, events)
  for participant in layout.participants {
    let mut start = participant.birth_y.map_or(layout.body_top, birth_y => {
      birth_y + 9
    })
    let end = participant.death_y.map_or(layout.body_bottom, death_y => death_y)
    for _, delay in delays {
      let (delay_start, delay_end) = delay
      if start < delay_start && delay_start < end {
        append_line(
          output,
          participant.center_x,
          start,
          participant.center_x,
          delay_start,
          "lifeline",
        )
      }
      start = start.max(delay_end)
    }
    if start < end {
      append_line(
        output,
        participant.center_x,
        start,
        participant.center_x,
        end,
        "lifeline",
      )
    }
  }
}

///|
fn append_activations(output : StringBuilder, layout : DiagramLayout) -> Unit {
  for activation in layout.activations {
    guard layout.participant_at(activation.participant_code)
      is Some(participant) else {
      continue
    }
    let width = 10
    let x = participant.center_x - width / 2 + activation.depth * 8
    let height = (activation.end_y - activation.start_y).max(12)
    output <+
      $|<rect x="\{x}" y="\{activation.start_y}" width="\{width}" height="\{height}" class="activation" fill="\{activation_color(activation.color, layout.defaults)}"/>
  }
}

///|
