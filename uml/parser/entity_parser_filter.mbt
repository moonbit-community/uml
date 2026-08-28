///|
fn member_portion(word : String) -> @entity.EntityPortion? {
  let word = word.to_lower()
  if word.has_prefix("member") {
    Some(@entity.EntityPortion::MemberPortion)
  } else if word.has_prefix("attribute") || word.has_prefix("field") {
    Some(@entity.EntityPortion::FieldPortion)
  } else if word.has_prefix("method") {
    Some(@entity.EntityPortion::MethodPortion)
  } else if word.has_prefix("circle") || word.has_prefix("circled") {
    Some(@entity.EntityPortion::CirclePortion)
  } else if word.has_prefix("stereotype") {
    Some(@entity.EntityPortion::StereotypePortion)
  } else {
    None
  }
}

///|
fn visibility_word(word : String) -> @entity.Visibility? {
  match word.to_lower() {
    "public" => Some(Public)
    "private" => Some(Private)
    "protected" => Some(Protected)
    "package" => Some(@entity.Package)
    _ => None
  }
}

///|
fn selector_for_tokens(tokens : Array[String]) -> @entity.EntitySelector {
  if tokens.is_empty() {
    return AllEntities
  }
  if tokens.length() > 1 {
    return AnyEntities(tokens.map(token => selector_for_tokens([token])))
  }
  let raw = tokens[0]
  if raw.has_prefix("<<") && @tokenizer.normalize_stereotype(raw) is Some(value) {
    return StereotypedEntities(value)
  }
  if raw.to_lower() == "abstract" {
    return KindEntities(@entity.EntityKind::AbstractClass)
  }
  declaration_kind(raw).map_or(
    NamedEntity(@tokenizer.unquote_identifier(raw)),
    kind => KindEntities(kind),
  )
}

///|
fn visibility_list(tokens : Array[String]) -> Array[@entity.Visibility]? {
  let result : Array[@entity.Visibility] = []
  for token in tokens {
    for item in @tokenizer.split_unquoted(token, ',') {
      let item = item.trim().to_owned()
      guard item.length() > 0 else { continue }
      guard visibility_word(item) is Some(visibility) else { return None }
      result.push(visibility)
    }
  }
  if result.is_empty() {
    None
  } else {
    Some(result)
  }
}

///|
fn portion_rule_from_tokens(tokens : Array[String]) -> @entity.PortionRule? {
  guard tokens.length() >= 2 else { return None }
  let show = match tokens[0].to_lower() {
    "hide" => false
    "show" => true
    _ => return None
  }
  let last_portion = member_portion(tokens[tokens.length() - 1])
  let portion = match last_portion {
    Some(value) => value
    None => {
      // CommonHides also registers `hide public` (and the other visibility
      // modifiers) as shorthand for hiding members of that visibility.
      guard tokens.length() == 2 && visibility_word(tokens[1]) is Some(_) else {
        return None
      }
      @entity.EntityPortion::MemberPortion
    }
  }
  let middle = if last_portion is Some(_) {
    tokens[1:tokens.length() - 1].to_owned()
  } else {
    tokens[1:].to_owned()
  }
  let empty_only = middle.any(token => token.to_lower() == "empty")
  let selector_tokens = middle.filter(token => token.to_lower() != "empty")
  match visibility_list(selector_tokens) {
    Some(visibilities) =>
      Some({
        selector: AllEntities,
        portion,
        show,
        empty_only,
        visibilities,
        scope: "",
      })
    None =>
      Some({
        selector: selector_for_tokens(selector_tokens),
        portion,
        show,
        empty_only,
        visibilities: [],
        scope: "",
      })
  }
}

///|
fn entity_rule_from_tokens(tokens : Array[String]) -> @entity.EntityRule? {
  guard tokens.length() >= 2 else { return None }
  let command = tokens[0].to_lower()
  let action = match command {
    "hide" | "hide-class" => @entity.EntityAction::HideEntity
    "show" | "show-class" => @entity.EntityAction::ShowEntity
    "remove" => @entity.EntityAction::RemoveEntity
    "restore" => @entity.EntityAction::RestoreEntity
    _ => return None
  }
  Some({ selector: selector_for_tokens(tokens[1:].to_owned()), action, })
}

///|
priv enum FilterLineSyntax {
  ParsedPortionRule(@entity.PortionRule)
  ParsedEntityRule(@entity.EntityRule)
}

///|
fn filter_token(cursor : @tokenizer.Cursor) -> String? {
  if cursor.take_stereotype_value() is Some(value) {
    return Some(value)
  }
  if cursor.take_quoted_value() is Some(value) {
    return Some(value)
  }
  let value = cursor.take_while(char => !char.is_whitespace())
  if value.length() > 0 {
    Some(value)
  } else {
    None
  }
}

///|
fn filter_line(cursor : @tokenizer.Cursor) -> FilterLineSyntax? {
  let start = cursor.offset()
  guard filter_token(cursor) is Some(first) else { return None }
  let tokens = [first]
  while true {
    let sep_start = cursor.offset()
    guard cursor.skip_inline_space1() && filter_token(cursor) is Some(token) else {
      ignore(cursor.restore(sep_start))
      break
    }
    tokens.push(token)
  }
  cursor.skip_inline_spaces()
  guard cursor.is_eof() else {
    ignore(cursor.restore(start))
    return None
  }
  match portion_rule_from_tokens(tokens) {
    Some(rule) => Some(ParsedPortionRule(rule))
    None =>
      match entity_rule_from_tokens(tokens) {
        Some(rule) => Some(ParsedEntityRule(rule))
        None => {
          ignore(cursor.restore(start))
          None
        }
      }
  }
}

///|
fn EntityParser::apply_filter_syntax(
  self : EntityParser,
  syntax : FilterLineSyntax,
) -> Unit {
  match syntax {
    ParsedPortionRule(rule) =>
      self.portion_rules.push({ ..rule, scope: self.current_package(), })
    ParsedEntityRule(rule) => self.entity_rules.push(rule)
  }
}

///|
fn selector_matches(
  entity : @entity.Entity,
  selector : @entity.EntitySelector,
  scope : String,
) -> Bool {
  if scope.length() > 0 && entity.scope != scope {
    return false
  }
  match selector {
    AllEntities => true
    KindEntities(kind) => entity.kind == kind
    StereotypedEntities(stereotype) => entity.stereotype == Some(stereotype)
    AnyEntities(selectors) =>
      selectors.any(selector => selector_matches(entity, selector, scope))
    NamedEntity(name) =>
      entity.code == name ||
      entity.qualified_code == name ||
      entity.display == name ||
      (scope.length() > 0 && entity.qualified_code == scope + "." + name)
  }
}

///|
fn member_matches_portion(
  entry : @entity.Member,
  portion : @entity.EntityPortion,
) -> Bool {
  match portion {
    @entity.EntityPortion::MemberPortion => !entry.is_separator
    @entity.EntityPortion::FieldPortion =>
      !entry.is_method && !entry.is_separator
    @entity.EntityPortion::MethodPortion =>
      entry.is_method && !entry.is_separator
    @entity.EntityPortion::CirclePortion
    | @entity.EntityPortion::StereotypePortion => false
  }
}

///|
fn @entity.Entity::has_portion(
  self : @entity.Entity,
  portion : @entity.EntityPortion,
) -> Bool {
  self.members.any(entry => member_matches_portion(entry, portion))
}

///|
fn EntityParser::apply_entity_rules(self : EntityParser) -> Unit {
  for rule in self.entity_rules {
    for index, entity in self.entities {
      guard selector_matches(entity, rule.selector, "") else { continue }
      self.entities[index] = match rule.action {
        @entity.EntityAction::HideEntity => { ..entity, is_hidden: true, }
        @entity.EntityAction::ShowEntity => { ..entity, is_hidden: false, }
        @entity.EntityAction::RemoveEntity => { ..entity, is_removed: true, }
        @entity.EntityAction::RestoreEntity => { ..entity, is_removed: false, }
      }
    }
  }
}

///|
fn EntityParser::set_portion_state(
  self : EntityParser,
  entity_index : Int,
  rule : @entity.PortionRule,
) -> Unit {
  let hidden = !rule.show
  let entity = self.entities[entity_index]
  match rule.portion {
    @entity.EntityPortion::CirclePortion =>
      self.entities[entity_index] = { ..entity, circle_hidden: hidden, }
    @entity.EntityPortion::StereotypePortion =>
      self.entities[entity_index] = { ..entity, stereotype_hidden: hidden, }
    @entity.EntityPortion::FieldPortion =>
      self.entities[entity_index] = { ..entity, fields_hidden: hidden, }
    @entity.EntityPortion::MethodPortion =>
      self.entities[entity_index] = { ..entity, methods_hidden: hidden, }
    @entity.EntityPortion::MemberPortion =>
      self.entities[entity_index] = {
        ..entity,
        fields_hidden: hidden,
        methods_hidden: hidden,
      }
  }
}

///|
fn EntityParser::apply_portion_rule(
  self : EntityParser,
  rule : @entity.PortionRule,
) -> Unit {
  for entity_index, entity in self.entities {
    guard selector_matches(entity, rule.selector, rule.scope) else { continue }
    if rule.empty_only {
      match rule.portion {
        @entity.EntityPortion::MemberPortion => {
          if !entity.has_portion(@entity.EntityPortion::FieldPortion) {
            self.entities[entity_index] = {
              ..entity,
              fields_hidden: !rule.show,
            }
          }
          if !entity.has_portion(@entity.EntityPortion::MethodPortion) {
            self.entities[entity_index] = {
              ..entity,
              methods_hidden: !rule.show,
            }
          }
        }
        @entity.EntityPortion::FieldPortion
        | @entity.EntityPortion::MethodPortion =>
          if !entity.has_portion(rule.portion) {
            self.set_portion_state(entity_index, rule)
          }
        @entity.EntityPortion::CirclePortion
        | @entity.EntityPortion::StereotypePortion => ()
      }
      continue
    }
    if rule.visibilities.is_empty() {
      self.set_portion_state(entity_index, rule)
    }
    for member_index, entry in self.entities[entity_index].members {
      guard member_matches_portion(entry, rule.portion) else { continue }
      guard rule.visibilities.is_empty() ||
        rule.visibilities.contains(entry.visibility) else {
        continue
      }
      self.entities[entity_index].members[member_index] = {
        ..entry,
        is_hidden: !rule.show,
      }
    }
  }
}

///|
fn EntityParser::apply_filter_rules(self : EntityParser) -> Unit {
  self.apply_entity_rules()
  for rule in self.portion_rules {
    self.apply_portion_rule(rule)
  }
}
