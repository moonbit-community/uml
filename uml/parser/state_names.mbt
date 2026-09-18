///|
priv enum StateNamePart {
  Root
  Identifier(String)
  Concurrent(Int)
} derive(Eq)

///|
/// Names exist independently of their state data, as in PlantUML's Quark.
/// Concurrent scopes have a separate identity from user-written names.
priv struct StateName {
  part : StateNamePart
  qualified : String
  parent : Int?
  code : String?
  group : Bool
}

///|
priv struct StateNameLocation {
  code : String
  display : String
  parent : String?
  region_index : Int
}

///|
fn state_root_name() -> StateName {
  { part: Root, qualified: "", parent: None, code: None, group: true, }
}

///|
fn Parser::state_name_child(
  self : Parser,
  parent : Int,
  part : StateNamePart,
) -> Int {
  if self.state_names.search_by(name => {
      name.parent == Some(parent) && name.part == part
    })
    is Some(index) {
    return index
  }
  let suffix = match part {
    Identifier(value) => value
    Concurrent(index) => "CONC" + index.to_string()
    Root => ""
  }
  let prefix = self.state_names[parent].qualified
  let index = self.state_names.length()
  self.state_names.push({
    part,
    qualified: if prefix.is_empty() {
      suffix
    } else {
      prefix + "." + suffix
    },
    parent: Some(parent),
    code: None,
    group: part is Concurrent(_),
  })
  index
}

///|
fn Parser::state_name_for_code(self : Parser, code : String) -> Int? {
  self.state_names.search_by(name => name.code == Some(code))
}

///|
fn Parser::current_state_namespace(self : Parser) -> Int {
  self.state_namespace_for_scope(self.stack.last())
}

///|
fn Parser::state_namespace_for_scope(self : Parser, scope : StateScope?) -> Int {
  guard scope is Some(scope) else { return 0 }
  let index = self.state_name_for_code(scope.code).unwrap()
  guard self.concurrent_region_at(scope.region_index) is Some(region) else {
    return index
  }
  self.state_name_child(index, Concurrent(region))
}

///|
/// CucaDiagram.quarkInContextSafe: absolute names start at the root;
/// unique short names are reused; qualified names prefer an existing root
/// package and otherwise start in the current scope.
/// Previously verified: qualified/absolute names, missing parent creation,
/// scoped ambiguity, existing aliases and invalid namespaces.
fn Parser::resolve_state_name(
  self : Parser,
  raw : String,
  allow_current~ : Bool,
) -> Int raise @tokenizer.ParseError {
  self.resolve_state_name_from(
    self.current_state_namespace(),
    raw,
    allow_current~,
  )
}

///|
fn Parser::resolve_state_name_from(
  self : Parser,
  current : Int,
  raw : String,
  allow_current~ : Bool,
) -> Int raise @tokenizer.ParseError {
  guard !raw.is_empty() && !raw.has_suffix(".") && !raw.contains("..") else {
    raise SyntaxError(self.line_number(), "invalid state namespace name")
  }
  let absolute = raw.has_prefix(".")
  let parts = raw
    .split(".")
    .filter(part => !part.is_empty())
    .map(StringView::to_owned)
    .to_array()
  guard !parts.is_empty() else {
    raise SyntaxError(self.line_number(), "state name is empty")
  }
  let mut scope_index = current
  if absolute {
    scope_index = 0
  } else if parts.length() == 1 {
    if allow_current && self.state_names[current].part == Identifier(raw) {
      return current
    }
    let matches = self.state_names.filter(name => name.part == Identifier(raw))
    if matches.length() == 1 {
      let index = self.state_names
        .search_by(name => name.part == Identifier(raw))
        .unwrap()
      if index != current {
        return index
      }
    }
  } else if self.state_names.search_by(name => {
      name.parent == Some(0) && name.part == Identifier(parts[0])
    })
    is Some(first) {
    let name = self.state_names[first]
    guard name.code is None || name.group else {
      raise SyntaxError(
        self.line_number(),
        "qualified state name starts with a non-container state",
      )
    }
    scope_index = 0
  }
  for part in parts {
    scope_index = self.state_name_child(scope_index, Identifier(part))
  }
  scope_index
}

///|
fn Parser::mark_state_group(self : Parser, code : String) -> Unit {
  let index = self.state_name_for_code(code).unwrap()
  self.state_names[index] = { ..self.state_names[index], group: true, }
}

///|
/// Keep existing unambiguous source codes. New colliding identities use their
/// qualified name, or its absolute spelling for a root/short-name collision.
fn Parser::assign_state_code(
  self : Parser,
  index : Int,
  preferred : String,
) -> String {
  let name = self.state_names[index]
  guard name.code is None else { return name.code.unwrap() }
  let candidate = if !preferred.contains(".") &&
    !self.states.any(state => state.code == preferred) {
    preferred
  } else {
    name.qualified
  }
  let code = if self.states.any(state => state.code == candidate) {
    "." + name.qualified
  } else {
    candidate
  }
  self.state_names[index] = { ..name, code: Some(code), }
  code
}

///|
/// CommandCreateState.ensureParentState materializes missing namespace
/// containers. All references to their children use the same name entries.
fn Parser::ensure_state_container(
  self : Parser,
  index : Int,
) -> Unit raise @tokenizer.ParseError {
  let name = self.state_names[index]
  guard name.part is Identifier(_) else { return }
  if name.code is None {
    let location = self.state_name_location(
      index,
      name.qualified,
      create_parents=true,
    )
    self.upsert_state({
      code: location.code,
      display: location.display,
      kind: @flow.StateKind::Normal,
      parent: location.parent,
      region_index: location.region_index,
      description: None,
      stereotype: None,
      url: None,
      color: None,
    })
  }
  let code = self.state_names[index].code.unwrap()
  self.mark_state_group(code)
  ignore(self.initial_state_region(code))
}

///|
fn Parser::state_name_location(
  self : Parser,
  index : Int,
  preferred : String,
  create_parents~ : Bool,
) -> StateNameLocation raise @tokenizer.ParseError {
  let name = self.state_names[index]
  guard name.part is Identifier(display) else {
    raise SyntaxError(
      self.line_number(),
      "state name refers to an internal scope",
    )
  }
  let parent_index = name.parent.unwrap()
  if create_parents {
    self.ensure_state_container(parent_index)
  }
  let parent_name = self.state_names[parent_index]
  let (parent, region_index) = match parent_name.part {
    Root => (None, -1)
    Concurrent(region) => {
      let enclosing = self.state_names[parent_name.parent.unwrap()].code.unwrap()
      (Some(enclosing), region)
    }
    Identifier(_) => {
      guard parent_name.code is Some(code) else {
        raise SyntaxError(
          self.line_number(),
          "unknown state namespace container",
        )
      }
      (Some(code), self.initial_state_region(code))
    }
  }
  {
    code: self.assign_state_code(index, preferred),
    display,
    parent,
    region_index,
  }
}
