///|
/// Render a bare mbti interface to SVG in one step.
///
/// Unlike `render_svg`, `source` is the mbti interface body itself without the
/// `@startuml '.mbti` / `@enduml` markers: the diagram family is known, so the
/// marker extraction and family dispatch are skipped. `parse_mbti_body` and the
/// mbti renderer are reused unchanged.
///
/// `color_scheme` is the cross-diagram theme boundary. With
/// `class_member_collapsible`, the host handles member controls and rerenders
/// with `member_states` keyed by qualified node code. `render_options`
/// provides default states for nodes without an override.
pub fn render_mbti_svg(
  source : String,
  standalone_alias? : Bool = false,
  color_scheme? : @style.ColorScheme = @style.ColorScheme::default(),
  class_member_collapsible? : Bool = false,
  member_states? : Map[String, @entity.ClassMemberState] = {},
  options? : @entity.MbtiOptions = @entity.MbtiOptions::default(),
  render_options? : @entity.MbtiRenderOptions = @entity.MbtiRenderOptions::default(),
) -> String raise {
  @render.render_mbti_svg(
    @parser.parse_mbti_body(source, standalone_alias~, options~),
    color_scheme~,
    class_member_collapsible~,
    member_states~,
    render_options~,
  )
}
