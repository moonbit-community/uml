///|
/// Control which parts of a MoonBit interface the adapter renders.
pub(all) struct MbtiOptions {
  /// `trait Sub : Super` inheritance draws an extension edge.
  trait_inheritance_edges : Bool
  /// `impl Trait for T` draws a realization edge.
  impl_edges : Bool
  /// A struct field or enum payload whose type is declared in the interface
  /// draws an association edge labeled with the member name.
  member_type_edges : Bool
  /// Trait methods and extension methods (`fn T::method`) are listed in
  /// their node. Off by default: interfaces render as type skeletons.
  show_methods : Bool
}

///|
pub fn MbtiOptions::default() -> MbtiOptions {
  {
    trait_inheritance_edges: true,
    impl_edges: true,
    member_type_edges: true,
    show_methods: false,
  }
}

///|
/// The member portion that an mbti node exposes through its disclosure control.
pub(all) enum MbtiCollapsibleSection {
  AllMembers
  Fields
  Methods
} derive(Eq, Debug)

///|
pub extend MbtiCollapsibleSection with Eq::{not_equal, equal}

///|
pub extend MbtiCollapsibleSection with Debug::{to_repr}

///|
/// The initial disclosure state of the selected mbti member portion.
pub(all) enum MbtiCollapseState {
  Expanded
  Collapsed
} derive(Eq, Debug)

///|
pub extend MbtiCollapseState with Eq::{not_equal, equal}

///|
pub extend MbtiCollapseState with Debug::{to_repr}

///|
/// Rendering-only controls for mbti member disclosures.
///
/// This is deliberately separate from `MbtiOptions`: parsing decides which
/// members exist, while these settings only decide which existing portion is
/// interactive and whether it initially appears.
pub(all) struct MbtiRenderOptions {
  collapsible_section : MbtiCollapsibleSection
  initial_state : MbtiCollapseState
} derive(Eq, Debug)

///|
pub extend MbtiRenderOptions with Eq::{not_equal, equal}

///|
pub extend MbtiRenderOptions with Debug::{to_repr}

///|
pub fn MbtiRenderOptions::default() -> MbtiRenderOptions {
  { collapsible_section: AllMembers, initial_state: Expanded, }
}
