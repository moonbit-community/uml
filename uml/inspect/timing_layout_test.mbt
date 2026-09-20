///|
fn timing_panel(
  diagram : @flow.TimingDiagram,
  layout : @render.TimingLayout,
  code : String,
) -> @render.TimingPlayerLayout {
  for panel in layout.players {
    if diagram.players[panel.index].code == code {
      return panel
    }
  }
  abort("missing timing player")
}

///|
test "timing dispatch renders every player family and leaves entity rectangles unchanged" {
  for
    declaration in [
      "robust P", "concise P", "rectangle P", "binary P", "analog \"Voltage\" as P",
    ] {
    let source = "@startuml\n" +
      declaration +
      "\n@0\nP is 0\n@10\nP is 1\n@enduml"
    let document = @api.parse(source)
    @test.assert_eq(document.kind() is @api.Timing, true)
    @test.assert_eq(document.render_svg().is_empty(), false)
  }
  let clock = @api.parse(
    "@startuml\nclock CLK with period 10\n@0\n@20\n@enduml",
  )
  @test.assert_eq(clock.kind() is @api.Timing, true)
  @test.assert_eq(clock.render_svg().is_empty(), false)
  @test.assert_eq(
    @api.parse("@startuml\nrectangle Service\n@enduml").kind() is @api.Timing,
    false,
  )
}

///|
test "timing players retain declaration order and occupy separate vertical panels" {
  let diagram = @parser.parse_timing(
    "robust \"States\" as R\nconcise \"Bus\" as C\nrectangle \"Phase\" as Q\nbinary \"Bit\" as B\nclock \"Clock\" as K with period 4\nanalog \"Voltage\" as A\n@0\nR is idle\nC is data\nQ is phase\nB is 0\nA is 0\n@10\nR is busy\nC is result\nQ is done\nB is 1\nA is 1",
  )
  let layout = @render.layout_timing(diagram)
  @test.assert_eq(
    layout.players.map(panel => diagram.players[panel.index].code),
    diagram.players.map(player => player.code),
  )
  for index, panel in layout.players {
    @test.assert_eq(panel.height > 0.0, true)
    @test.assert_eq(panel.wave_y >= panel.panel_y, true)
    @test.assert_eq(panel.frame_y + panel.height <= layout.height, true)
    if index > 0 {
      @test.assert_eq(
        panel.frame_y,
        layout.players[index - 1].frame_y + layout.players[index - 1].height,
      )
    }
  }
  let svg = @render.render_timing_svg(diagram)
  @test.assert_eq(svg.contains("NaN") || svg.contains("Infinity"), false)
}

///|
test "timing ruler is linear across negative and fractional marks and honors explicit scale" {
  let diagram = @parser.parse_timing(
    "binary B\nscale 2 as 30 pixels\n@-4\nB is 0\n@-1.5\nB is 1\n@3\nB is 0",
  )
  let layout = @render.layout_timing(diagram)
  let ruler = layout.ruler
  let middle = (ruler.minimum + ruler.maximum) / 2.0
  @test.assert_eq(
    ruler.position(middle) * 2.0,
    ruler.position(ruler.minimum) + ruler.position(ruler.maximum),
  )
  let scale = diagram.scale.unwrap()
  @test.assert_eq(
    ruler.position(ruler.minimum + scale.0.to_double()) -
    ruler.position(ruler.minimum),
    scale.1.to_double(),
  )
  @test.assert_eq(ruler.width > ruler.position(ruler.maximum), true)
}

///|
test "robust declared states preserve vertical order and configured wave height" {
  let diagram = @parser.parse_timing(
    "robust R\nR has low,mid,high\nR is 60 pixels height\n@0\nR is low\n@5\nR is high",
  )
  let player = diagram.players[0]
  let panel = @render.layout_timing(diagram).players[0]
  @test.assert_eq(panel.states, player.states.map(state => state.1).rev())
  @test.assert_eq(
    panel.wave_height * (panel.states.length() - 1).to_double(),
    player.height.unwrap().to_double(),
  )
}

///|
test "timing notes and constraints reserve space outside the waveform" {
  let source = "concise \"Bus\" as C\n@0\nC is start\n@10\nC is end"
  let plain = @render.layout_timing(@parser.parse_timing(source))
  let annotated = @render.layout_timing(
    @parser.parse_timing(
      source +
      "\nnote top of C : Explanation\nnote bottom of C : Details\nC@0 <--> @10 : duration",
    ),
  )
  let before = plain.players[0]
  let after = annotated.players[0]
  @test.assert_eq(after.height > before.height, true)
  @test.assert_eq(after.top_notes > before.top_notes, true)
  @test.assert_eq(after.bottom_notes > before.bottom_notes, true)
  @test.assert_eq(after.constraint_height > before.constraint_height, true)
  @test.assert_eq(after.wave_height, before.wave_height)
}

///|
test "messages share ruler coordinates and attach to the nearest ribbon boundary" {
  let diagram = @parser.parse_timing(
    "concise \"Source\" as S\nconcise \"Target\" as T\n@0\nS is active\nT is ready\n@10\nS is done\nT is done\nS@2 --> T@7 : transfer",
  )
  let layout = @render.layout_timing(diagram)
  let source = timing_panel(diagram, layout, "S")
  let target = timing_panel(diagram, layout, "T")
  @test.assert_eq(layout.messages.length(), diagram.messages.length())
  let message = layout.messages[0]
  @test.assert_eq(message.start.y, source.wave_y + source.wave_height)
  @test.assert_eq(message.end.y, target.wave_y)
  @test.assert_eq(message.start.x < message.end.x, true)
}

///|
test "analog message contacts interpolate between neighboring samples" {
  let diagram = @parser.parse_timing(
    "analog \"Voltage\" from 0 to 10 as A\nbinary B\n@0\nA is 0\nB is 0\n@10\nA is 10\nA@0 --> B@0\nA@5 --> B@5\nA@10 --> B@10",
  )
  let layout = @render.layout_timing(diagram)
  @test.assert_eq(layout.messages.length(), diagram.messages.length())
  let first = layout.messages[0].start
  let middle = layout.messages[1].start
  let last = layout.messages[2].start
  @test.assert_eq(middle.x * 2.0, first.x + last.x)
  @test.assert_eq(middle.y * 2.0, first.y + last.y)
  @test.assert_eq(first.y > last.y, true)
}

///|
test "timing axis modes document text and themes pass through the public renderer" {
  let source = "@startuml\ntitle Timing overview\nlegend\nLegend\nendlegend\nbinary \"Signal\" as B\n@0 as :begin\nB is 0\n@10 as :finish\nB is 1\nhighlight 0 to 10 #yellow : active\n"
  for mode in ["", "manual time axis", "hide time axis"] {
    let document = @api.parse(source + mode + "\n@enduml")
    let plain = document.render_svg()
    let themed = document.render_svg(color_scheme=@style.ColorScheme::dark())
    @test.assert_eq(plain.is_empty() || themed.is_empty(), false)
    @test.assert_eq(plain == themed, false)
    @test.assert_eq(plain.contains("NaN") || plain.contains("Infinity"), false)
  }
  let wbs = @api.parse("@startwbs\ntitle Plan\n* Root\n** Work\n@endwbs")
  @test.assert_eq(wbs.render_svg().is_empty(), false)
}
