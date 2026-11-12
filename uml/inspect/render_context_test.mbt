///|
let text_measurer : @metrics.Measurer = @heuristic.measurer()

///|
let text_context : @style.RenderContext = @style.RenderContext::new(
  text_measurer,
)
