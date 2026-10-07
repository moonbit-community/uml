///|
priv struct SequencePage {
  layout : DiagramLayout
  title : String?
}

///|
/// Pagination is applied after the common horizontal layout. Every page keeps
/// participant columns, message numbers and activation nesting from the whole
/// diagram, while repeating participant headers/footers in its own viewport.
fn sequence_pages(
  diagram : @seq.SequenceDiagram,
  layout : DiagramLayout,
) -> Array[SequencePage] {
  let pages : Array[SequencePage] = []
  let mut from = layout.body_top
  let mut title = diagram.style.title
  let append = (from : Double, until : Double, title : String?) => {
    let dy = layout.body_top - from
    let body_bottom = until + dy
    let placements = layout.placements.mapi((index, placement) => {
      ..placement,
      y: placement.y + dy,
      ignored: placement.ignored ||
      placement.y < from ||
      placement.y >= until ||
      diagram.events[index] is @seq.Newpage(_),
    })
    let participants = layout.participants.map(participant => {
      ..participant,
      birth_y: participant.birth_y.bind(y => {
        if y < from {
          None
        } else {
          Some(y + dy)
        }
      }),
      death_y: participant.death_y.map(y => (y + dy).max(layout.body_top)),
    })
    let activations = layout.activations
      .filter(span => span.end_y >= from && span.start_y < until)
      .map(span => {
        ..span,
        start_y: span.start_y.max(from) + dy,
        end_y: span.end_y.min(until) + dy,
      })
    let destroys = layout.destroys
      .filter(mark => mark.y >= from && mark.y < until)
      .map(mark => { ..mark, y: mark.y + dy, })
    let groups = layout.groups
      .filter(group => group.end_y >= from && group.start_y < until)
      .map(group => {
        ..group,
        start_y: group.start_y.max(from) + dy,
        end_y: group.end_y.min(until) + dy,
        branches: group.branches
        .filter(branch => branch.end_y >= from && branch.start_y < until)
        .map(branch => {
          ..branch,
          start_y: branch.start_y.max(from) + dy,
          end_y: branch.end_y.min(until) + dy,
        }),
      })
    pages.push({
      title,
      layout: {
        ..layout,
        placements,
        participants,
        activations,
        destroys,
        groups,
        body_bottom,
        height: body_bottom + layout.height - layout.body_bottom,
      },
    })
  }
  for index, event in diagram.events {
    guard event is @seq.Newpage(page) && !layout.placements[index].ignored else {
      continue
    }
    let placement = layout.placements[index]
    append(from, placement.y, title)
    from = placement.y + placement.height - 8
    title = page.title.map_or(title, value => Some(value))
  }
  append(from, layout.body_bottom, title)
  pages
}

///|
pub fn render_sequence_svg_pages(
  diagram : @seq.SequenceDiagram,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
) -> Array[String] {
  let diagram = {
    ..diagram,
    style: diagram.style.with_color_scheme(color_scheme),
  }
  sequence_pages(diagram, diagram.layout()).map(page => {
    let style = diagram.style.with_color_scheme(color_scheme)
    if page.title is Some(title) {
      style.apply(@style.Title(title))
    }
    { ..diagram, style, }.paint_sequence_svg(page.layout)
  })
}
