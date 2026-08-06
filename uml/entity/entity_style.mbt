///|
fn class_background_color(style : @style.DocumentStyle) -> String {
  style.property_color(
    "ClassBackgroundColor",
    style.defaults().entity_colors().node,
  )
}

///|
fn class_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("ClassBorderColor", style.diagram_line_color())
}

///|
fn usecase_background_color(style : @style.DocumentStyle) -> String {
  style.property_color("UsecaseBackgroundColor", class_background_color(style))
}

///|
fn usecase_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("UsecaseBorderColor", class_border_color(style))
}

///|
fn actor_background_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActorBackgroundColor", class_background_color(style))
}

///|
fn actor_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActorBorderColor", class_border_color(style))
}

///|
fn actor_style(style : @style.DocumentStyle) -> String {
  style
  .property("ActorStyle")
  .unwrap_or(
    style
    .property("actorStyle")
    .unwrap_or(style.property("actorstyle").unwrap_or("stickman")),
  )
  .to_lower()
}

///|
fn usecase_font_color(style : @style.DocumentStyle) -> String {
  style.property_color("UsecaseFontColor", style.diagram_text_color())
}

///|
fn actor_font_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActorFontColor", style.diagram_text_color())
}

///|
fn class_stereotype_font_color(style : @style.DocumentStyle) -> String {
  style.property_color("ClassStereotypeFontColor", style.diagram_text_color())
}

///|
fn arrow_font_color(style : @style.DocumentStyle) -> String {
  style.property_color("ArrowFontColor", style.diagram_text_color())
}

///|
fn usecase_font_size(style : @style.DocumentStyle, fallback~ : Int) -> Int {
  style.property_font_size("UsecaseFontSize", fallback~)
}

///|
fn actor_font_size(style : @style.DocumentStyle, fallback~ : Int) -> Int {
  style.property_font_size("ActorFontSize", fallback~)
}

///|
fn class_stereotype_font_size(
  style : @style.DocumentStyle,
  fallback~ : Int,
) -> Int {
  style.property_font_size("ClassStereotypeFontSize", fallback~)
}

///|
fn arrow_font_size(style : @style.DocumentStyle, fallback~ : Int) -> Int {
  style.property_font_size("ArrowFontSize", fallback~)
}

///|
fn usecase_font_family(style : @style.DocumentStyle) -> String {
  style.property_font_family("UsecaseFontName")
}

///|
fn actor_font_family(style : @style.DocumentStyle) -> String {
  style.property_font_family("ActorFontName")
}

///|
fn class_stereotype_font_family(style : @style.DocumentStyle) -> String {
  style.property_font_family("ClassStereotypeFontName")
}

///|
fn arrow_font_family(style : @style.DocumentStyle) -> String {
  style.property_font_family("ArrowFontName")
}

///|
fn package_background_color(style : @style.DocumentStyle) -> String {
  style.property_color(
    "PackageBackgroundColor",
    style.defaults().entity_colors().transparent,
  )
}

///|
fn package_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("PackageBorderColor", class_border_color(style))
}

///|
fn note_background_color(style : @style.DocumentStyle) -> String {
  style.property_color(
    "NoteBackgroundColor",
    style.defaults().entity_colors().note,
  )
}

///|
fn note_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("NoteBorderColor", class_border_color(style))
}
