///|
/// Rendering requires a host-provided service; document parsing does not.
/// Reusing a context also reuses any caches owned by that service.
#derive(Debug)
pub struct RenderContext {
  measurer : @metrics.Measurer
}

///|
pub extend RenderContext with Debug::{to_repr}

///|
pub fn RenderContext::new(measurer : @metrics.Measurer) -> RenderContext {
  { measurer, }
}
