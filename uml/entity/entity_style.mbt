///|
pub fn class_background_color(style : @style.DocumentStyle) -> String {
  style.property_color(
    "ClassBackgroundColor",
    style.defaults().entity_colors().node,
  )
}

///|
pub fn class_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("ClassBorderColor", style.diagram_line_color())
}

///|
/// Object diagrams have their own PlantUML skinparam keys.  Falling back to
/// class colors keeps existing themes compatible when those keys are absent.
pub fn object_background_color(style : @style.DocumentStyle) -> String {
  style.property_color("ObjectBackgroundColor", class_background_color(style))
}

///|
pub fn object_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("ObjectBorderColor", class_border_color(style))
}

///|
pub fn object_font_color(style : @style.DocumentStyle) -> String {
  style.property_font_color("ObjectFontColor")
}

///|
pub fn EntityStyleRole::background_color(
  self : EntityStyleRole,
  style : @style.DocumentStyle,
) -> String {
  match self {
    ObjectStyle | MapStyle | JsonStyle => object_background_color(style)
    UsecaseStyle => usecase_background_color(style)
    ActorStyle => actor_background_color(style)
    LollipopStyle => style.defaults().entity_colors().node
    ClassStyle | ComponentStyle | DescriptionStyle =>
      class_background_color(style)
  }
}

///|
pub fn EntityStyleRole::border_color(
  self : EntityStyleRole,
  style : @style.DocumentStyle,
) -> String {
  match self {
    ObjectStyle | MapStyle | JsonStyle => object_border_color(style)
    UsecaseStyle => usecase_border_color(style)
    ActorStyle => actor_border_color(style)
    LollipopStyle => style.diagram_line_color()
    ClassStyle | ComponentStyle | DescriptionStyle => class_border_color(style)
  }
}

///|
pub fn EntityStyleRole::font_color(
  self : EntityStyleRole,
  style : @style.DocumentStyle,
) -> String {
  match self {
    ObjectStyle | MapStyle | JsonStyle => object_font_color(style)
    UsecaseStyle => usecase_font_color(style)
    ActorStyle => actor_font_color(style)
    LollipopStyle => style.diagram_text_color()
    ClassStyle | ComponentStyle | DescriptionStyle => style.diagram_text_color()
  }
}

///|
pub fn usecase_background_color(style : @style.DocumentStyle) -> String {
  style.property_color("UsecaseBackgroundColor", class_background_color(style))
}

///|
pub fn usecase_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("UsecaseBorderColor", class_border_color(style))
}

///|
pub fn actor_background_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActorBackgroundColor", class_background_color(style))
}

///|
pub fn actor_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActorBorderColor", class_border_color(style))
}

///|
pub fn actor_style(style : @style.DocumentStyle) -> String {
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
pub fn usecase_font_color(style : @style.DocumentStyle) -> String {
  style.property_color("UsecaseFontColor", style.diagram_text_color())
}

///|
pub fn actor_font_color(style : @style.DocumentStyle) -> String {
  style.property_color("ActorFontColor", style.diagram_text_color())
}

///|
pub fn class_stereotype_font_color(style : @style.DocumentStyle) -> String {
  style.property_color("ClassStereotypeFontColor", style.diagram_text_color())
}

///|
pub fn arrow_font_color(style : @style.DocumentStyle) -> String {
  style.property_color("ArrowFontColor", style.diagram_text_color())
}

///|
pub fn usecase_font_size(style : @style.DocumentStyle, fallback~ : Int) -> Int {
  style.property_font_size("UsecaseFontSize", fallback~)
}

///|
pub fn actor_font_size(style : @style.DocumentStyle, fallback~ : Int) -> Int {
  style.property_font_size("ActorFontSize", fallback~)
}

///|
pub fn class_stereotype_font_size(
  style : @style.DocumentStyle,
  fallback~ : Int,
) -> Int {
  style.property_font_size("ClassStereotypeFontSize", fallback~)
}

///|
pub fn arrow_font_size(style : @style.DocumentStyle, fallback~ : Int) -> Int {
  style.property_font_size("ArrowFontSize", fallback~)
}

///|
pub fn usecase_font_family(style : @style.DocumentStyle) -> String {
  style.property_font_family("UsecaseFontName")
}

///|
pub fn actor_font_family(style : @style.DocumentStyle) -> String {
  style.property_font_family("ActorFontName")
}

///|
pub fn class_stereotype_font_family(style : @style.DocumentStyle) -> String {
  style.property_font_family("ClassStereotypeFontName")
}

///|
pub fn arrow_font_family(style : @style.DocumentStyle) -> String {
  style.property_font_family("ArrowFontName")
}

///|
pub fn package_background_color(style : @style.DocumentStyle) -> String {
  style.property_color(
    "PackageBackgroundColor",
    style.defaults().entity_colors().transparent,
  )
}

///|
pub fn package_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("PackageBorderColor", class_border_color(style))
}

///|
pub fn note_background_color(style : @style.DocumentStyle) -> String {
  style.property_color(
    "NoteBackgroundColor",
    style.defaults().entity_colors().note,
  )
}

///|
pub fn note_border_color(style : @style.DocumentStyle) -> String {
  style.property_color("NoteBorderColor", class_border_color(style))
}
