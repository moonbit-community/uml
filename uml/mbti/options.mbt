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
