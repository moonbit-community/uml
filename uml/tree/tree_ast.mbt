///|
/// Which side of a tree root a node attaches to.
#derive(Eq, Debug)
pub(all) enum TreeDirection {
  Left
  Right
}

///|
pub extend TreeDirection with Eq::{not_equal, equal}

///|
pub extend TreeDirection with Debug::{to_repr}
