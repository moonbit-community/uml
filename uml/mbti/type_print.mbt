///|
/// Render a MoonBit .mbti type as source text.
fn type_to_string(ty : @mbti_ast.Type) -> String {
  match ty {
    Any(_) => "_"
    Name(constr_id~, tys~, ..) =>
      if tys.is_empty() {
        constr_id_to_string(constr_id)
      } else {
        constr_id_to_string(constr_id) +
        "[" +
        tys.map(type_to_string).to_array().join(", ") +
        "]"
      }
    Option(ty~, ..) => type_to_string(ty) + "?"
    Tuple(tys~, ..) => "(" + tys.map(type_to_string).to_array().join(", ") + ")"
    Arrow(args~, res~, err~, is_async~, ..) => {
      let prefix = if is_async is Some(_) { "async " } else { "" }
      prefix +
      "(" +
      args.map(type_to_string).to_array().join(", ") +
      ") -> " +
      type_to_string(res) +
      error_type_to_string(err)
    }
    Object(constr_id) => "&" + constr_id_to_string(constr_id)
  }
}

///|
fn error_type_to_string(err : @mbti_ast.ErrorType) -> String {
  match err {
    NoErrorType => ""
    Noraise(_) => " noraise"
    DefaultErrorType(_) => " raise"
    ErrorType(ty~) => " raise " + type_to_string(ty)
    MaybeError(ty~) => " raise " + type_to_string(ty) + "?"
  }
}

///|
fn constr_id_to_string(id : @mbti_ast.ConstrId) -> String {
  ident_to_string(id.id)
}

///|
fn ident_to_string(id : @mbti_ast.QualifiedIdent) -> String {
  match id {
    Ident(name~) => name
    Dot(pkg~, id=name) => pkg + "." + name
  }
}

///|
fn qualified_name_to_string(name : @mbti_ast.QualifiedName) -> String {
  ident_to_string(name.name)
}
