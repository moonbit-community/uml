///|
/// Current member visibility for one node, keyed by its qualified code in
/// render calls. Class diagrams toggle both portions together; MBTI toggles
/// fields and methods independently. The host owns state and requests a new
/// layout after each change.
pub(all) struct ClassMemberState {
  fields_expanded : Bool
  methods_expanded : Bool
} derive(Eq, Debug)

///|
pub extend ClassMemberState with Eq::{not_equal, equal}

///|
pub extend ClassMemberState with Debug::{to_repr}
