///|
fn ClassTextMetrics::for_entity(
  self : ClassTextMetrics,
  entity : @entity.Entity,
) -> ClassTextMetrics {
  let style = self.style
    .with_stereotypes(entity.stereotype)
    .with_color_scheme(self.style.defaults())
  let role = match entity.kind {
    Object | Map | Json => "Object"
    Component => "Component"
    Actor | BusinessActor => "Actor"
    Usecase | BusinessUsecase => "Usecase"
    _ => "Class"
  }
  if style.property(role + "FontName") is Some(family) {
    style.apply(@style.FontFamily(family))
  }
  if style.property(role + "FontSize") is Some(size) {
    style.apply(@style.FontSize(size))
  }
  {
    ..ClassTextMetrics::new(style, role~),
    member_interaction: self.member_interaction,
    member_defaults: self.member_defaults,
    member_states: self.member_states,
  }
}
