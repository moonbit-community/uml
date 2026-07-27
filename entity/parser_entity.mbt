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
      })
    }
    parent = qualified_name
  }
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
  for index, entity in self.entities {
    if entity.qualified_code == qualified_code {
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
      return
    }
  }
  self.entities.push({
    code: declaration.code,
    qualified_code,
    display: declaration.display,
    kind: declaration.kind,
    scope,
    visibility: declaration.visibility,
    is_static: declaration.is_static,
    generic: declaration.generic,
    stereotype: declaration.stereotype,
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
  })
  if open {
    self.current_entity = Some(self.entities.length() - 1)
    self.body_depth = 1
  }
  self.last_entity = Some(qualified_code)
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
  for entity in self.entities {
    if entity.qualified_code == code {
      return entity.qualified_code
    }
  }
  let qualified = self.qualify(code)
  for entity in self.entities {
    if entity.qualified_code == qualified {
      return entity.qualified_code
    }
  }
  if self.current_package().length() > 0 {
    return qualified
  }
  let mut found = None
  for entity in self.entities {
    if entity.code == code {
      if found is Some(_) {
        return qualified
      }
      found = Some(entity.qualified_code)
    }
  }
  found.unwrap_or(qualified)
}

///|
fn Parser::ensure_entity(self : Parser, code : String) -> String {
  self.ensure_implicit_namespaces(code)
  let qualified_code = self.resolve(code)
  guard !self.entities.any(entity => entity.qualified_code == qualified_code) else {
    return qualified_code
  }
  self.entities.push({
    code,
    qualified_code,
    display: code,
    kind: Class,
    scope: self.implicit_namespace_scope(code),
    visibility: Unknown,
    is_static: false,
    generic: None,
    stereotype: None,
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
  })
  qualified_code
}

///|
fn Parser::ensure_entity_as(
  self : Parser,
  code : String,
  kind : EntityKind,
) -> String {
  let qualified_code = self.resolve(code)
  let existed = self.entities.any(entity => {
    entity.qualified_code == qualified_code
  })
  let qualified_code = self.ensure_entity(code)
  if !existed {
    for index, entity in self.entities {
      if entity.qualified_code == qualified_code {
        self.entities[index] = { ..entity, kind, }
        break
      }
    }
  }
  qualified_code
}

///|
fn Parser::set_entity_url(self : Parser, code : String, url : String) -> Bool {
  let qualified_code = self.resolve(code)
  for index, entity in self.entities {
    if entity.qualified_code == qualified_code {
      self.entities[index] = { ..entity, url: Some(url) }
      return true
    }
  }
  false
}

///|
fn Parser::set_entity_stereotype(
  self : Parser,
  code : String,
  stereotype : String,
) -> Bool {
  let qualified_code = self.resolve(code)
  for index, entity in self.entities {
    if entity.qualified_code == qualified_code {
      self.entities[index] = { ..entity, stereotype: Some(stereotype) }
      return true
    }
  }
  false
}

///|
fn Parser::add_member_to(self : Parser, code : String, entry : Member) -> Unit {
  let qualified_code = self.ensure_entity(code)
  for index, entity in self.entities {
    if entity.qualified_code == qualified_code {
      self.entities[index].members.push(entry)
      return
    }
  }
}

///|
