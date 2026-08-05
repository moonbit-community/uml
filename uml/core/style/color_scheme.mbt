///|
/// Per-role paint overrides applied on top of the built-in light-theme
/// defaults. Every value may be a CSS variable (`var(--uml-text)`) or a
/// literal color, so a caller can target a specific light/dark theme without
/// touching each diagram.
pub struct ColorScheme {
  text : String
  line : String
  canvas : String
  node : String
  note : String
  partition : String
  participant : String
  activation : String
  lifeline : String
  divider : String
  divider_title : String
  delay : String
  reference_tab : String
  page_break : String
  transparent : String
  spot_abstract : String
  spot_interface : String
  spot_enum : String
  spot_annotation : String
  spot_class : String
  visibility_public_stroke : String
  visibility_public_fill : String
  visibility_private_stroke : String
  visibility_private_fill : String
  visibility_protected_stroke : String
  visibility_protected_fill : String
  visibility_package_stroke : String
  visibility_package_fill : String
} derive(Eq, Debug)

///|
/// Build a color scheme. `text` and `line` are required because those are the
/// ink colors that become unreadable in a dark theme; every other role keeps
/// its literal light-theme default unless overridden.
pub fn ColorScheme::ColorScheme(
  text : String,
  line : String,
  canvas? : String = "none",
  node? : String = "#F1F1F1",
  note? : String = "#FEFFDD",
  partition? : String = "none",
  participant? : String = "#E2E2F0",
  activation? : String = "#FFFFFF",
  lifeline? : String = "#777",
  divider? : String = "#777",
  divider_title? : String = "#f6f6f6",
  delay? : String = "#777",
  reference_tab? : String = "#eee",
  page_break? : String = "#555",
  transparent? : String = "none",
  spot_abstract? : String = "#A9DCDF",
  spot_interface? : String = "#B4A7E5",
  spot_enum? : String = "#EB937F",
  spot_annotation? : String = "#E3664A",
  spot_class? : String = "#ADD1B2",
  visibility_public_stroke? : String = "#038048",
  visibility_public_fill? : String = "#84BE84",
  visibility_private_stroke? : String = "#C82930",
  visibility_private_fill? : String = "#F24D5C",
  visibility_protected_stroke? : String = "#B38D22",
  visibility_protected_fill? : String = "#FFFF44",
  visibility_package_stroke? : String = "#1963A0",
  visibility_package_fill? : String = "#4177AF",
) -> ColorScheme {
  {
    text,
    line,
    canvas,
    node,
    note,
    partition,
    participant,
    activation,
    lifeline,
    divider,
    divider_title,
    delay,
    reference_tab,
    page_break,
    transparent,
    spot_abstract,
    spot_interface,
    spot_enum,
    spot_annotation,
    spot_class,
    visibility_public_stroke,
    visibility_public_fill,
    visibility_private_stroke,
    visibility_private_fill,
    visibility_protected_stroke,
    visibility_protected_fill,
    visibility_package_stroke,
    visibility_package_fill,
  }
}

///|
/// The scheme that reproduces the built-in light-theme defaults verbatim.
pub fn ColorScheme::default() -> ColorScheme {
  ColorScheme::ColorScheme("#000000", "#181818")
}
