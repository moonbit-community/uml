///|
/// Adapt a parsed .mbti interface to the shared entity graph so the class
/// diagram layout and SVG pipeline render it unchanged.
///
/// Declaration kinds map to entity kinds; `impl` and trait inheritance map
/// to relations (the .mbti grammar has no arrow syntax). Top-level functions,
/// constants and values are not owned by any type and are not rendered.
fn adapt(mbti : @mbti_ast.Mbti, standalone_alias : Bool) -> MbtiDiagram {
  let adapter = Adapter::new()
  mbti.sigs.each(fn(sig) {
    match sig.0 {
      Type(sig) => adapter.declare_type(sig)
      Trait(sig) => adapter.declare_trait(sig)
      _ => ()
    }
  })
  mbti.sigs.each(fn(sig) {
    match sig.0 {
      Type(sig) => adapter.fill_type(sig)
      Trait(sig) => {
        adapter.fill_trait(sig)
        adapter.inherit_trait(sig)
      }
      Impl(sig) => adapter.apply_impl(sig)
      Func(sig) => adapter.apply_func(sig)
      Alias(TypeAlias(name~, type_=ty, ..)) =>
        adapter.merge_alias(name, ty, standalone_alias)
      _ => ()
    }
  })
  {
    package_name: mbti.package_name,
    imports: mbti.imports.map(imp => imp.name).to_array(),
    graph: {
      family: @entity.Mbti,
      entities: adapter.entities,
      relations: adapter.relations,
      packages: [],
      notes: [],
      constraints: [],
      together_groups: [],
      style: @style.DocumentStyle::empty(),
    },
  }
}

///|
priv struct Adapter {
  entities : Array[@entity.Entity]
  entity_indices : Map[String, Int]
  relations : Array[@entity.Relation]
}

///|
fn Adapter::new() -> Adapter {
  { entities: [], entity_indices: Map([]), relations: [] }
}

///|
fn Adapter::entity_index(self : Adapter, code : String) -> Int? {
  self.entity_indices.get(code)
}

///|
/// Return the index of the entity for `code`, creating an implicit one when
/// the interface references a type declared elsewhere.
fn Adapter::ensure_entity(
  self : Adapter,
  code : String,
  kind : @entity.EntityKind,
  stereotype? : String? = None,
) -> Int {
  match self.entity_index(code) {
    Some(index) => index
    None => {
      let index = self.entities.length()
      self.entities.push({
        code,
        qualified_code: code,
        display: code,
        kind,
        scope: "",
        visibility: @entity.Public,
        is_static: false,
        generic: None,
        stereotype,
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
      })
      self.entity_indices[code] = index
      index
    }
  }
}

///|
fn Adapter::declare_type(self : Adapter, sig : @mbti_ast.TypeSig) -> Unit {
  let (kind, stereotype) = match sig.components {
    Abstract => (@entity.AbstractClass, None)
    Newtype(_) | Alias(_) => (@entity.Class, Some("alias"))
    Error(_) => (@entity.Exception, None)
    TupleStruct(_) | Record(_) => (@entity.Struct, None)
    ExtensibleEnum(_) | ExtendEnum(..) | Variant(_) => (@entity.Enum, None)
  }
  ignore(self.ensure_entity(sig.name.name, kind, stereotype~))
}

///|
fn Adapter::declare_trait(self : Adapter, sig : @mbti_ast.TraitSig) -> Unit {
  ignore(self.ensure_entity(sig.name.name, @entity.Interface))
}

///|
/// An alias of a type declared in the same interface becomes an `alias Name`
/// annotation on that type's node, rendered below the title. An alias of an
/// undeclared target is dropped unless `standalone_alias` requests a
/// fallback node.
fn Adapter::merge_alias(
  self : Adapter,
  name : @mbti_ast.Name,
  ty : @mbti_ast.Type,
  standalone_alias : Bool,
) -> Unit {
  match type_top_name(ty) {
    Some(target) =>
      match self.entity_index(target) {
        Some(index) => {
          let entity = self.entities[index]
          let annotation = match entity.annotation {
            Some(existing) => existing + ", " + name.name
            None => "alias " + name.name
          }
          self.entities[index] = { ..entity, annotation: Some(annotation) }
        }
        None => self.ensure_standalone_alias(name, standalone_alias)
      }
    None => self.ensure_standalone_alias(name, standalone_alias)
  }
}

///|
fn Adapter::ensure_standalone_alias(
  self : Adapter,
  name : @mbti_ast.Name,
  standalone_alias : Bool,
) -> Unit {
  if standalone_alias {
    ignore(
      self.ensure_entity(name.name, @entity.Class, stereotype=Some("alias")),
    )
  }
}

///|
fn Adapter::fill_type(self : Adapter, sig : @mbti_ast.TypeSig) -> Unit {
  let index = self.ensure_entity(sig.name.name, @entity.Struct)
  match sig.components {
    Record(fields~) =>
      for field in fields {
        let mut_prefix = if field.mut_ { "mut " } else { "" }
        self.entities[index].members.push(
          entity_member(
            "+" +
            mut_prefix +
            field.name.label +
            ": " +
            type_to_string(field.ty),
            @entity.Public,
            false,
          ),
        )
      }
    Variant(constructors) | ExtensibleEnum(constructors) =>
      for constr in constructors {
        self.entities[index].members.push(constructor_entity_member(constr))
      }
    ExtendEnum(constructors~, ..) =>
      for constr in constructors {
        self.entities[index].members.push(constructor_entity_member(constr))
      }
    _ => ()
  }
}

///|
fn Adapter::fill_trait(self : Adapter, sig : @mbti_ast.TraitSig) -> Unit {
  let index = self.ensure_entity(sig.name.name, @entity.Interface)
  for method_sig in sig.methods {
    self.entities[index].members.push(
      entity_member(
        "+" + trait_method_to_string(method_sig),
        @entity.Public,
        true,
      ),
    )
  }
}

///|
/// `trait Sub : Super1 + Super2` renders as extension edges `Sub --|> Super`.
fn Adapter::inherit_trait(self : Adapter, sig : @mbti_ast.TraitSig) -> Unit {
  let sub = sig.name.name
  ignore(self.ensure_entity(sub, @entity.Interface))
  for super_trait in sig.super_traits {
    let super_ = qualified_name_to_string(super_trait)
    ignore(self.ensure_entity(super_, @entity.Interface))
    self.relations.push(extension_relation(sub, super_, "--|>"))
  }
}

///|
/// `impl Trait for T` renders as the realization edge `T ..|> Trait`.
fn Adapter::apply_impl(self : Adapter, sig : @mbti_ast.ImplSig) -> Unit {
  match (type_top_name(sig.type_), qualified_name_to_string(sig.trait_name)) {
    (Some(sub), super_) => {
      ignore(self.ensure_entity(sub, @entity.Class))
      ignore(self.ensure_entity(super_, @entity.Interface))
      self.relations.push(extension_relation(sub, super_, "..|>"))
    }
    _ => ()
  }
}

///|
/// `fn T::method(...)` attaches a method member to the entity for `T`.
/// Top-level functions have no owning type and are ignored.
fn Adapter::apply_func(self : Adapter, sig : @mbti_ast.FuncSig) -> Unit {
  match sig.type_name {
    Some(type_name) => {
      let index = self.ensure_entity(type_name.name, @entity.Class)
      self.entities[index].members.push(
        entity_member("+" + func_sig_to_string(sig), @entity.Public, true),
      )
    }
    None => ()
  }
}

///|
fn extension_relation(
  left : String,
  right : String,
  arrow : String,
) -> @entity.Relation {
  {
    left,
    right,
    kind: if arrow.contains(".") {
      @entity.RelationKind::Realization
    } else {
      @entity.RelationKind::Extension
    },
    left_cardinality: None,
    right_cardinality: None,
    left_role: None,
    right_role: None,
    left_qualifier: None,
    right_qualifier: None,
    label: None,
    dotted: arrow.contains("."),
    raw_arrow: arrow,
    left_end: @entity.Plain,
    right_end: @entity.Extension,
    direction: @entity.Automatic,
    line_style: None,
    color: None,
    url: None,
    stereotype: None,
    weight: None,
    inside: None,
    left_port: None,
    right_port: None,
    left_couple: None,
    right_couple: None,
  }
}

///|
fn entity_member(
  raw : String,
  visibility : @entity.Visibility,
  is_method : Bool,
) -> @entity.Member {
  {
    raw,
    visibility,
    is_method,
    is_static: false,
    is_abstract: false,
    is_separator: false,
    is_hidden: false,
  }
}

///|
fn constructor_entity_member(constr : @mbti_ast.ConstrDecl) -> @entity.Member {
  let payload = match constr.args {
    Some(args) if !args.is_empty() =>
      "(" + args.map(constructor_param_to_string).to_array().join(", ") + ")"
    _ => ""
  }
  entity_member(
    constr.name.name + payload,
    @entity.Unknown,
    payload.length() > 0,
  )
}

///|
fn constructor_param_to_string(param : @mbti_ast.ConstrParam) -> String {
  match param.label {
    Some(label) => label.name + ": " + type_to_string(param.ty)
    None => type_to_string(param.ty)
  }
}

///|
fn func_sig_to_string(sig : @mbti_ast.FuncSig) -> String {
  let prefix = if sig.is_async is Some(_) { "async " } else { "" }
  prefix +
  sig.name.name +
  "(" +
  sig.params.map(parameter_to_string).to_array().join(", ") +
  ") -> " +
  type_to_string(sig.return_.0) +
  error_type_to_string(sig.return_.1)
}

///|
fn trait_method_to_string(method_sig : @mbti_ast.TraitMethodSig) -> String {
  let prefix = if method_sig.is_async is Some(_) { "async " } else { "" }
  prefix +
  method_sig.name.name +
  "(" +
  method_sig.params.map(parameter_to_string).to_array().join(", ") +
  ") -> " +
  type_to_string(method_sig.return_.0) +
  error_type_to_string(method_sig.return_.1)
}

///|
fn parameter_to_string(param : @mbti_ast.Parameter) -> String {
  match param {
    DiscardPositional(ty~, ..) => param_type_to_string(ty)
    Positional(binder~, ty~) => binder.name + ": " + param_type_to_string(ty)
    Labelled(binder~, ty~) => binder.name + ": " + param_type_to_string(ty)
    Optional(binder~, ty~, ..) => binder.name + ": " + param_type_to_string(ty)
    QuestionOptional(binder~, ty~) =>
      binder.name + "? : " + param_type_to_string(ty)
  }
}

///|
fn param_type_to_string(ty : @mbti_ast.Type?) -> String {
  match ty {
    Some(ty) => type_to_string(ty)
    None => "_"
  }
}

///|
/// The top-level type name of a type expression, if it is a plain name.
fn type_top_name(ty : @mbti_ast.Type) -> String? {
  match ty {
    Name(constr_id~, ..) => Some(ident_to_string(constr_id.id))
    _ => None
  }
}
