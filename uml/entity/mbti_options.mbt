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
    show_methods: true,
  }
}

///|
/// The two member portions of an mbti node.
pub(all) enum MbtiCollapsibleSection {
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
/// members exist, while these settings only decide whether each existing
/// portion starts expanded or collapsed.
pub(all) struct MbtiRenderOptions {
  fields_state : MbtiCollapseState
  methods_state : MbtiCollapseState
} derive(Eq, Debug)

///|
pub extend MbtiRenderOptions with Eq::{not_equal, equal}

///|
pub extend MbtiRenderOptions with Debug::{to_repr}

///|
pub fn MbtiRenderOptions::default() -> MbtiRenderOptions {
  {
    // Preserve the previous mbti default: fields start collapsed while
    // methods remain visible.
    fields_state: Collapsed,
    methods_state: Expanded,
  }
}
