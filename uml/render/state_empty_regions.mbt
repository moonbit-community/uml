///|
/// GraphvizImageBuilder.EntityImageSimpleEmpty is an unpainted inner image.
const STATE_EMPTY_INNER_IMAGE_SIZE : Double = 10.0

///|
/// Empty explicit groups keep GroupMakerState's EntityImageState, even when
/// ordinary empty leaf states use the compact hidden-description image.
fn @flow.StateDiagram::state_uses_empty_image(
  self : @flow.StateDiagram,
  state : @flow.StateNode,
) -> Bool {
  state.kind == @flow.StateKind::Normal &&
  !state.has_description() &&
  self.hide_empty_description() &&
  !self.regions.any(region => region.parent == state.code)
}

///|
fn @flow.StateDiagram::state_region_is_empty(
  self : @flow.StateDiagram,
  parent : String,
  region_index : Int,
) -> Bool {
  !self.states.any(state => {
    state.parent == Some(parent) && state.region_index == region_index
  }) &&
  !self.notes.any(note => {
    note.parent == Some(parent) &&
    note.region_index == region_index &&
    !(note.target is @flow.TransitionNote(_))
  })
}

///|
/// StateDiagram.concurrentState creates an unnamed group. GroupMakerState
/// renders an empty CONCURRENT_STATE as EntityImageState, whose blank name
/// becomes a space in StripeSimple. It is a drawing inside the region, not
/// another source state or a new transition endpoint.
fn empty_concurrent_state() -> @flow.StateNode {
  {
    code: "",
    display: " ",
    kind: Normal,
    parent: None,
    region_index: -1,
    description: None,
    stereotype: None,
    url: None,
    color: None,
  }
}

///|
fn empty_concurrent_state_size(
  diagram : @flow.StateDiagram,
) -> (Double, Double) {
  empty_concurrent_state().leaf_size(
    resolve_state_font(diagram.style, StateLabel).metrics,
    resolve_state_font(diagram.style, StateDescription).metrics,
    false,
    left_to_right=false,
  )
}

///|
/// Previously verified: initial/later empty concurrent regions keep distinct
/// images; populating a region replaces its empty image and explicit empty
/// groups retain their compartments under hide-empty-description settings.
fn @flow.StateDiagram::empty_state_region_fragment(
  self : @flow.StateDiagram,
  region : @flow.StateRegion,
) -> StateFragment? {
  guard self.state_region_is_empty(region.parent, region.index) else {
    return None
  }
  let (width, height) = if region.separator is Some(_) {
    empty_concurrent_state_size(self)
  } else {
    (STATE_EMPTY_INNER_IMAGE_SIZE, STATE_EMPTY_INNER_IMAGE_SIZE)
  }
  Some({
    width,
    height,
    nodes: [],
    edges: [],
    regions: [],
    notes: [],
    note_connections: [],
    cluster_titles: Map([]),
  })
}

///|
fn append_empty_concurrent_region(
  output : @graphics.Graphic,
  diagram : @flow.StateDiagram,
  region : StateRegionLayout,
) -> Unit {
  guard region.separator is Some(_) &&
    diagram.state_region_is_empty(region.parent, region.region_index) else {
    return
  }
  let state = empty_concurrent_state()
  let (width, height) = empty_concurrent_state_size(diagram)
  output.group(state_class("state-empty-concurrent-region"), output => {
    append_state_node_body(
      output,
      diagram,
      state,
      { code: state.code, x: region.x, y: region.y, width, height, },
      composite=false,
      empty_description=false,
    )
  })
}
