///|
fn Parser::implicit_namespace_scope(self : Parser, code : String) -> String {
  guard self.current_package().length() == 0 &&
    self.namespace_separator is Some(separator) &&
    separator.length() > 0 else {
    return self.current_package()
  }
  let segments = code
    .split(separator)
    .map(part => part.trim().to_owned())
    .filter(part => part.length() > 0)
    .to_array()
  guard segments.length() > 1 else { return self.current_package() }
  segments[0:segments.length() - 1].to_owned().join(separator)
}

///|
fn Parser::ensure_implicit_namespaces(self : Parser, code : String) -> Unit {
  guard self.current_package().length() == 0 &&
    self.namespace_separator is Some(separator) &&
    separator.length() > 0 else {
    return
  }
  let segments = code
    .split(separator)
    .map(part => part.trim().to_owned())
    .filter(part => part.length() > 0)
    .to_array()
  guard segments.length() > 1 else { return }
  let mut parent = ""
  for index in 0..<(segments.length() - 1) {
    let segment = segments[index]
    let qualified_name = if parent.length() == 0 {
      segment
    } else {
      parent + separator + segment
    }
    if !self.packages.any(group => group.qualified_name == qualified_name) {
      self.packages.push({
        name: segment,
        qualified_name,
        display: segment,
        parent,
        is_namespace: true,
        visibility: Unknown,
        stereotype: None,
        url: None,
        color: None,
        symbol: None,
      })
    }
    parent = qualified_name
  }
}

///|
fn Parser::entity_index(self : Parser, qualified_code : String) -> Int? {
  self.entity_indices.get(qualified_code)
}

///|
fn Parser::has_entity(self : Parser, qualified_code : String) -> Bool {
  self.entity_index(qualified_code) is Some(_)
}

///|
fn Parser::append_entity(self : Parser, entity : Entity) -> Int {
  let index = self.entities.length()
  self.entities.push(entity)
  self.entity_indices[entity.qualified_code] = index
  if self.entity_code_indices.contains(entity.code) {
    self.ambiguous_entity_codes[entity.code] = ()
  } else {
    self.entity_code_indices[entity.code] = index
  }
  index
}

///|
/// Create a synthetic entity (lollipop interface circle or association
/// point) with an empty body and no display metadata.
fn Parser::append_synthetic_entity(
  self : Parser,
  code : String,
  display : String,
  kind : EntityKind,
) -> String {
  let qualified_code = self.qualify(code)
  guard !self.has_entity(qualified_code) else { return qualified_code }
  ignore(
    self.append_entity({
      code,
      qualified_code,
      display,
      kind,
      scope: self.implicit_namespace_scope(code),
      visibility: Unknown,
      is_static: false,
      generic: None,
      stereotype: None,
      annotation: None,
      is_hidden: false,
      is_removed: false,
      fields_hidden: false,
      methods_hidden: false,
      stereotype_hidden: false,
      circle_hidden: false,
      url: None,
      color: None,
      line_color: None,
      line_style: None,
      tags: [],
      members: [],
      map_entries: [],
      json_data: None,
      json_tree: None,
    }),
  )
  qualified_code
}

///|
fn Parser::add_entity(
  self : Parser,
  declaration : Declaration,
  open : Bool,
) -> Unit {
  self.ensure_implicit_namespaces(declaration.code)
  let qualified_code = self.qualify(declaration.code)
  let scope = self.implicit_namespace_scope(declaration.code)
  match self.entity_index(qualified_code) {
    Some(index) => {
      let entity = self.entities[index]
      self.entities[index] = {
        ..entity,
        display: declaration.display,
        kind: declaration.kind,
        scope,
        visibility: declaration.visibility,
        is_static: declaration.is_static,
        generic: declaration.generic,
        stereotype: declaration.stereotype,
        url: declaration.url,
        color: declaration.color,
        line_color: declaration.line_color,
        line_style: declaration.line_style,
        tags: declaration.tags,
      }
      if open {
        self.current_entity = Some(index)
        self.body_depth = 1
      }
      self.last_entity = Some(qualified_code)
    }
    None => {
      let index = self.append_entity({
        code: declaration.code,
        qualified_code,
        display: declaration.display,
        kind: declaration.kind,
        scope,
        visibility: declaration.visibility,
        is_static: declaration.is_static,
        generic: declaration.generic,
        stereotype: declaration.stereotype,
        annotation: None,
        is_hidden: false,
        is_removed: false,
        fields_hidden: false,
        methods_hidden: false,
        stereotype_hidden: false,
        circle_hidden: false,
        url: declaration.url,
        color: declaration.color,
        line_color: declaration.line_color,
        line_style: declaration.line_style,
        tags: declaration.tags,
        members: [],
        map_entries: [],
        json_data: None,
        json_tree: None,
      })
      if open {
        self.current_entity = Some(index)
        self.body_depth = 1
      }
      self.last_entity = Some(qualified_code)
    }
  }
}

///|
fn Parser::qualify(self : Parser, code : String) -> String {
  if self.current_package().length() == 0 ||
    code.contains(".") ||
    code.contains("::") {
    code
  } else {
    self.current_package() + "." + code
  }
}

///|
fn Parser::resolve(self : Parser, code : String) -> String {
  if self.has_entity(code) {
    return code
  }
  let qualified = self.qualify(code)
  if self.has_entity(qualified) {
    return qualified
  }
  if self.current_package().length() > 0 {
    return qualified
  }
  if self.ambiguous_entity_codes.contains(code) {
    return qualified
  }
  match self.entity_code_indices.get(code) {
    Some(index) => self.entities[index].qualified_code
    None => qualified
  }
}

///|
fn Parser::ensure_entity(self : Parser, code : String) -> String {
  self.ensure_implicit_namespaces(code)
  let qualified_code = self.resolve(code)
  guard !self.has_entity(qualified_code) else { return qualified_code }
  ignore(
    self.append_entity({
      code,
      qualified_code,
      display: code,
      kind: Class,
      scope: self.implicit_namespace_scope(code),
      visibility: Unknown,
      is_static: false,
      generic: None,
      stereotype: None,
      annotation: None,
      is_hidden: false,
      is_removed: false,
      fields_hidden: false,
      methods_hidden: false,
      stereotype_hidden: false,
      circle_hidden: false,
      url: None,
      color: None,
      line_color: None,
      line_style: None,
      tags: [],
      members: [],
      map_entries: [],
      json_data: None,
      json_tree: None,
    }),
  )
  qualified_code
}

///|
fn Parser::ensure_entity_as(
  self : Parser,
  code : String,
  kind : EntityKind,
) -> String {
  let qualified_code = self.resolve(code)
  let existed = self.has_entity(qualified_code)
  let qualified_code = self.ensure_entity(code)
  if !existed && self.entity_index(qualified_code) is Some(index) {
    self.entities[index] = { ..self.entities[index], kind, }
  }
  qualified_code
}

///|
fn Parser::set_entity_url(self : Parser, code : String, url : String) -> Bool {
  let qualified_code = self.resolve(code)
  guard self.entity_index(qualified_code) is Some(index) else { return false }
  self.entities[index] = { ..self.entities[index], url: Some(url) }
  true
}

///|
fn Parser::set_entity_stereotype(
  self : Parser,
  code : String,
  stereotype : String,
) -> Bool {
  let qualified_code = self.resolve(code)
  guard self.entity_index(qualified_code) is Some(index) else { return false }
  self.entities[index] = {
    ..self.entities[index],
    stereotype: Some(stereotype),
  }
  true
}

///|
fn Parser::add_member_to(self : Parser, code : String, entry : Member) -> Unit {
  let qualified_code = self.ensure_entity(code)
  if self.entity_index(qualified_code) is Some(index) {
    self.entities[index].members.push(entry)
  }
}

///|
test "entity index keeps bare names ambiguous across packages" {
  let parser = Parser::new("")
  parser.package_stack.push("first")
  ignore(parser.ensure_entity("User"))
  ignore(parser.package_stack.pop())
  parser.package_stack.push("second")
  ignore(parser.ensure_entity("User"))
  ignore(parser.package_stack.pop())

  @test.assert_eq(parser.has_entity("first.User"), true)
  @test.assert_eq(parser.has_entity("second.User"), true)
  @test.assert_eq(parser.resolve("User"), "User")
}
