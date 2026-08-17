///|
/// Cross-diagram theme colors applied on top of the built-in light-theme
/// defaults. This type is the public theme boundary: it stores document-wide,
/// shared-node, sequence, and entity paint roles, while each renderer owns the
/// rules that map those roles to concrete SVG elements and skinparams.
///
/// Every value may be a CSS variable (`var(--uml-text)`) or a literal color,
/// so a caller can target a specific light/dark theme without touching each
/// diagram. Use `sequence_colors` and `entity_colors` when implementing those
/// diagram families instead of making `DocumentStyle` aware of their roles.
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

pub extend ColorScheme with Eq::{not_equal, equal}
pub extend ColorScheme with Debug::{to_repr}


///|
/// Theme roles consumed by the sequence renderer. Sequence-specific fallback
/// and skinparam precedence remain owned by the sequence package.
pub struct SequenceColors {
  text : String
  line : String
  canvas : String
  note : String
  participant : String
  activation : String
  lifeline : String
  divider : String
  divider_title : String
  delay : String
  reference_tab : String
  page_break : String
} derive(Eq, Debug)

pub extend SequenceColors with Eq::{not_equal, equal}
pub extend SequenceColors with Debug::{to_repr}


///|
/// Theme roles consumed by the class/object/component/use-case renderer.
/// Entity-specific fallback and skinparam precedence remain owned by the
/// entity package.
pub struct EntityColors {
  text : String
  line : String
  node : String
  note : String
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

pub extend EntityColors with Eq::{not_equal, equal}
pub extend EntityColors with Debug::{to_repr}


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

///|
/// Returns the roles owned by the sequence painter.
pub fn ColorScheme::sequence_colors(self : ColorScheme) -> SequenceColors {
  {
    text: self.text,
    line: self.line,
    canvas: self.canvas,
    note: self.note,
    participant: self.participant,
    activation: self.activation,
    lifeline: self.lifeline,
    divider: self.divider,
    divider_title: self.divider_title,
    delay: self.delay,
    reference_tab: self.reference_tab,
    page_break: self.page_break,
  }
}

///|
/// Returns the roles owned by the entity painter.
pub fn ColorScheme::entity_colors(self : ColorScheme) -> EntityColors {
  {
    text: self.text,
    line: self.line,
    node: self.node,
    note: self.note,
    transparent: self.transparent,
    spot_abstract: self.spot_abstract,
    spot_interface: self.spot_interface,
    spot_enum: self.spot_enum,
    spot_annotation: self.spot_annotation,
    spot_class: self.spot_class,
    visibility_public_stroke: self.visibility_public_stroke,
    visibility_public_fill: self.visibility_public_fill,
    visibility_private_stroke: self.visibility_private_stroke,
    visibility_private_fill: self.visibility_private_fill,
    visibility_protected_stroke: self.visibility_protected_stroke,
    visibility_protected_fill: self.visibility_protected_fill,
    visibility_package_stroke: self.visibility_package_stroke,
    visibility_package_fill: self.visibility_package_fill,
  }
}