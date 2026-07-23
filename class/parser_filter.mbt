///|
fn member_portion(word : String) -> EntityPortion? {
  let word = word.to_lower()
  if word.has_prefix("member") {
    Some(MemberPortion)
  } else if word.has_prefix("attribute") || word.has_prefix("field") {
    Some(FieldPortion)
  } else if word.has_prefix("method") {
    Some(MethodPortion)
  } else if word.has_prefix("circle") || word.has_prefix("circled") {
    Some(CirclePortion)
  } else if word.has_prefix("stereotype") {
    Some(StereotypePortion)
  } else {
    None
  }
}

///|
fn visibility_word(word : String) -> Visibility? {
  match word.to_lower() {
    "public" => Some(Public)
    "private" => Some(Private)
    "protected" => Some(Protected)
    "package" => Some(Package)
    _ => None
  }
}

///|
fn selector_for_tokens(tokens : Array[String]) -> EntitySelector {
  if tokens.is_empty() {
    return AllEntities
  }
  if tokens.length() > 1 {
    return AnyEntities(tokens.map(token => selector_for_tokens([token])))
  }
  let raw = tokens[0]
  if raw.has_prefix("<<") && @core.normalize_stereotype(raw) is Some(value) {
    return StereotypedEntities(value)
  }
  if raw.to_lower() == "abstract" {
    return KindEntities(AbstractClass)
  }
  match declaration_kind(raw) {
    Some(kind) => KindEntities(kind)
    None => NamedEntity(normalize_name(raw))
  }
}

///|
fn visibility_list(tokens : Array[String]) -> Array[Visibility]? {
  let result : Array[Visibility] = []
  for token in tokens {
    for item in @core.split_unquoted(token, ',') {
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
fn portion_rule_from_tokens(tokens : Array[String]) -> PortionRule? {
  guard tokens.length() >= 2 else { return None }
  let show = match tokens[0].to_lower() {
    "hide" => false
    "show" => true
    _ => return None
  }
  let portion = match member_portion(tokens[tokens.length() - 1]) {
    Some(value) => value
    None => {
      // CommonHides also registers `hide public` (and the other visibility
      // modifiers) as shorthand for hiding members of that visibility.
      guard tokens.length() == 2 && visibility_word(tokens[1]) is Some(_) else {
        return None
      }
      MemberPortion
    }
  }
  let middle = if member_portion(tokens[tokens.length() - 1]) is Some(_) {
    tokens[1:tokens.length() - 1].to_owned()
  } else {
    tokens[1:].to_owned()
  }
  let mut empty_only = false
  let selector_tokens : Array[String] = []
  for token in middle {
    if token.to_lower() == "empty" {
      empty_only = true
    } else {
      selector_tokens.push(token)
    }
  }
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
fn entity_rule_from_tokens(tokens : Array[String]) -> EntityRule? {
  guard tokens.length() >= 2 else { return None }
  let command = tokens[0].to_lower()
  let action = match command {
    "hide" | "hide-class" => HideEntity
    "show" | "show-class" => ShowEntity
    "remove" => RemoveEntity
    "restore" => RestoreEntity
    _ => return None
  }
  Some({ selector: selector_for_tokens(tokens[1:].to_owned()), action })
}

///|
priv enum FilterLineSyntax {
  ParsedPortionRule(PortionRule)
  ParsedEntityRule(EntityRule)
}

///|
fn filter_token_parser() -> @talcparsec.StringParser[String] {
  stereotype_value_parser()
  .attempt()
  .or(quoted_value_parser().attempt())
  .or(
    @talcparsec.many_chars1(
      @talcparsec.satisfy("filter token", char => !char.is_whitespace()),
    ),
  )
}

///|
fn filter_line_parser() -> @talcparsec.StringParser[FilterLineSyntax] {
  filter_token_parser()
  .sep_by1(inline_space1())
  .bind(tokens => {
    match portion_rule_from_tokens(tokens) {
      Some(rule) => @talcparsec.pure(ParsedPortionRule(rule))
      None =>
        match entity_rule_from_tokens(tokens) {
          Some(rule) => @talcparsec.pure(ParsedEntityRule(rule))
          None => @talcparsec.fail("class filter command")
        }
    }
  })
  .skip(inline_spaces())
  .skip(@talcparsec.eof())
}

///|
fn Parser::apply_filter_syntax(
  self : Parser,
  syntax : FilterLineSyntax,
) -> Unit {
  match syntax {
    ParsedPortionRule(rule) =>
      self.portion_rules.push({ ..rule, scope: self.current_package() })
    ParsedEntityRule(rule) => self.entity_rules.push(rule)
  }
}

///|
fn selector_matches(
  entity : Entity,
  selector : EntitySelector,
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
fn member_matches_portion(entry : Member, portion : EntityPortion) -> Bool {
  match portion {
    MemberPortion => !entry.is_separator
    FieldPortion => !entry.is_method && !entry.is_separator
    MethodPortion => entry.is_method && !entry.is_separator
    CirclePortion | StereotypePortion => false
  }
}

///|
fn Entity::has_portion(self : Entity, portion : EntityPortion) -> Bool {
  self.members.any(entry => member_matches_portion(entry, portion))
}

///|
fn Parser::apply_entity_rules(self : Parser) -> Unit {
  for rule in self.entity_rules {
    for index, entity in self.entities {
      guard selector_matches(entity, rule.selector, "") else { continue }
      self.entities[index] = match rule.action {
        HideEntity => { ..entity, is_hidden: true }
        ShowEntity => { ..entity, is_hidden: false }
        RemoveEntity => { ..entity, is_removed: true }
        RestoreEntity => { ..entity, is_removed: false }
      }
    }
  }
}

///|
fn Parser::set_portion_state(
  self : Parser,
  entity_index : Int,
  rule : PortionRule,
) -> Unit {
  let hidden = !rule.show
  let entity = self.entities[entity_index]
  match rule.portion {
    CirclePortion =>
      self.entities[entity_index] = { ..entity, circle_hidden: hidden }
    StereotypePortion =>
      self.entities[entity_index] = { ..entity, stereotype_hidden: hidden }
    FieldPortion =>
      self.entities[entity_index] = { ..entity, fields_hidden: hidden }
    MethodPortion =>
      self.entities[entity_index] = { ..entity, methods_hidden: hidden }
    MemberPortion =>
      self.entities[entity_index] = {
        ..entity,
        fields_hidden: hidden,
        methods_hidden: hidden,
      }
  }
}

///|
fn Parser::apply_portion_rule(self : Parser, rule : PortionRule) -> Unit {
  for entity_index, entity in self.entities {
    guard selector_matches(entity, rule.selector, rule.scope) else { continue }
    if rule.empty_only {
      match rule.portion {
        MemberPortion => {
          if !entity.has_portion(FieldPortion) {
            self.entities[entity_index] = {
              ..self.entities[entity_index],
              fields_hidden: !rule.show,
            }
          }
          if !entity.has_portion(MethodPortion) {
            self.entities[entity_index] = {
              ..self.entities[entity_index],
              methods_hidden: !rule.show,
            }
          }
        }
        FieldPortion | MethodPortion =>
          if !entity.has_portion(rule.portion) {
            self.set_portion_state(entity_index, rule)
          }
        CirclePortion | StereotypePortion => ()
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
fn Parser::apply_filter_rules(self : Parser) -> Unit {
  self.apply_entity_rules()
  for rule in self.portion_rules {
    self.apply_portion_rule(rule)
  }
}
