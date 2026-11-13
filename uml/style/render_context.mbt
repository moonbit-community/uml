///|
/// Rendering requires a host-provided service; document parsing does not.
/// Reusing a context also reuses any caches owned by that service.
pub struct RenderContext {
  measurer : @metrics.Measurer
  graphviz_context : @graphviz_text.Context
}

///|
pub fn RenderContext::new(
  measurer : @metrics.Measurer,
  graphviz_context~ : @graphviz_text.Context,
) -> RenderContext {
  { measurer, graphviz_context, }
}
