///|
/// Which side of a tree root a node attaches to.
pub(all) enum TreeDirection {
  Left
  Right
} derive(Eq, Debug)

///|
pub extend TreeDirection with Eq::{not_equal, equal}

///|
pub extend TreeDirection with Debug::{to_repr}
