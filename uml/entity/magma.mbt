///|
/// PlantUML `applySingleStrategy` parity: standalone entities (no links) of a
/// group are joined by invisible grid edges so dot arranges them in a square.
/// Mirrors `SquareMaker`, `Magma` and `MagmaList` in PlantUML's cucadiagram.
pub(all) struct Magma {
  standalones : Array[String]
  /// The grandparent group scope: `None` for root-level standalones, whose
  /// PlantUML container (`root.getParentContainer()`) is null and therefore
  /// never participates in a second-level square.
  container : String?
}

///|
/// `SquareMaker.computeBranch`: the number of columns of the near-square grid.
pub fn magma_branch(size : Int) -> Int {
  let r = size.to_double().sqrt().floor().to_int()
  guard r * r == size else { return r + 1 }
  r
}

///|
/// `SquareMaker.getBottomLeft`: index of the first cell of the last row.
pub fn magma_bottom_left_index(size : Int) -> Int {
  (size - 1) / magma_branch(size) * magma_branch(size)
}

///|
/// `SquareMaker.putInSquare`: snake links — row cells get a left-right link,
/// the first cell of each new row a top-down link.
pub fn[T] put_in_square(
  data : Array[T],
  top_down : (T, T) -> Unit,
  left_right : (T, T) -> Unit,
) -> Unit {
  let branch = magma_branch(data.length())
  ignore(
    data.foldi(init=0, (i, head_branch, _) => {
      guard i > 0 else { return head_branch }
      guard i - head_branch == branch else {
        left_right(data[i - 1], data[i])
        return head_branch
      }
      top_down(data[head_branch], data[i])
      i
    }),
  )
}

///|
/// PlantUML applies `applySingleStrategy` in `ClassDiagram` and
/// `DescriptionDiagram` (component, deployment, use case).
fn EntityFamily::applies_magma_grid(self : EntityFamily) -> Bool {
  match self {
    ClassDiagram | ComponentDiagram | UseCaseDiagram | DeploymentDiagram => true
    ObjectDiagram | Mbti => false
  }
}

///|
/// `CucaDiagram.isStandalone`: the entity participates in no link. PlantUML
/// creates real links for notes attached to an entity, so an annotated entity
/// is not standalone either.
pub fn EntityDiagram::is_grid_standalone(
  self : EntityDiagram,
  code : String,
) -> Bool {
  let touched = self.relations.any(relation => {
      relation.left == code || relation.right == code
    }) ||
    self.notes.any(note => {
      (note.target_kind is EntityNote || note.target_kind is MemberTip) &&
      note.target == code
    })
  !touched
}

///|
/// The parent scope of a package scope, `None` for the root.
pub fn EntityDiagram::package_parent(
  self : EntityDiagram,
  scope : String,
) -> String? {
  self.packages
  .iter()
  .find_first(group => group.qualified_name == scope)
  .map(group => group.parent)
}

///|
pub fn EntityDiagram::find_package(
  self : EntityDiagram,
  code : String,
) -> Package? {
  self.packages.iter().find_first(group => group.qualified_name == code)
}

///|
/// Invisible grid edges for standalone entities, one entry per edge as
/// `(tail, head, minlen)` in entity codes. The caller resolves the codes to
/// graph nodes and marks the edges `style=invis`, so they steer the dot rank
/// assignment without being drawn.
pub fn EntityDiagram::magma_grid_edges(
  self : EntityDiagram,
) -> Array[(String, String, Int)] {
  let edges : Array[(String, String, Int)] = []
  guard self.family.applies_magma_grid() else { return edges }
  let scopes = [""] + self.packages.map(group => group.qualified_name)
  let magmas = scopes.filter_map(scope => {
    let standalones = self.entities
      .filter(entity => {
        !entity.is_hidden &&
        !entity.is_removed &&
        entity.scope == scope &&
        self.is_grid_standalone(entity.qualified_code)
      })
      .map(entity => entity.qualified_code)
    guard standalones.length() >= 3 else { return None }
    let container = if scope == "" { None } else { self.package_parent(scope) }
    put_in_square(standalones, (top, down) => edges.push((top, down, 1)), (
      left,
      right,
    ) => edges.push((left, right, 0)))
    Some({ standalones, container, })
  })
  for group in self.packages {
    let package_magmas = magmas.filter(magma => {
      magma.container == Some(group.qualified_name)
    })
    guard package_magmas.length() >= 3 else { continue }
    put_in_square(
      package_magmas,
      (top, down) => {
        let tail = top.standalones[magma_bottom_left_index(
            top.standalones.length(),
          )]
        let head = down.standalones[0]
        edges.push((tail, head, 1))
      },
      (left, right) => {
        let tail = left.standalones[magma_branch(left.standalones.length()) - 1]
        let head = right.standalones[0]
        edges.push((tail, head, 0))
      },
    )
  }
  edges
}
