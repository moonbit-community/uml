///|
priv struct RelationNameSyntax {
  name : String
  port_base : String?
  port_value : String?
}

///|
priv struct RelationEndpointSyntax {
  name : RelationNameSyntax
  cardinality : String?
  role : String?
  qualifier : String?
  couple : (String, String)?
}

///|
priv struct RelationLineSyntax {
  weight : String?
  left : RelationEndpointSyntax
  arrow : String
  right : RelationEndpointSyntax
  label : String?
  color : String?
  url : String?
  stereotype : String?
}

///|
priv enum RelationEndpointModifier {
  RelationCardinality(String)
  RelationRole(String)
  RelationQualifier(String)
}

///|
priv enum RelationMetadataSyntax {
  RelationColor(String)
  RelationUrl(String)
  RelationStereotype(String)
}

///|
fn relation_name_parser(
  stop_at_arrow : Bool,
) -> @talc.StringParser[RelationNameSyntax] {
  let shaped = @talc.string("()")
    .then(inline_spaces())
    .then(
      @talc.many_chars1(
        @talc.satisfy("interface relation name", char => {
          !char.is_whitespace() &&
          char != ':' &&
          char != '[' &&
          char != ']' &&
          char != '(' &&
          char != ')'
        }),
      ),
    )
    .map(name => { name: "()" + name, port_base: None, port_value: None })
  let usecase = @talc.char('(')
    .then(@talc.many_chars1(@talc.none_of(")")))
    .skip(@talc.char(')'))
    .map(name => { name: "(" + name + ")", port_base: None, port_value: None })
  let actor = @talc.char(':')
    .then(@talc.many_chars1(@talc.none_of(":")))
    .skip(@talc.char(':'))
    .map(name => { name: ":" + name + ":", port_base: None, port_value: None })
  let component = @talc.char('[')
    .then(@talc.many_chars1(@talc.none_of("]")))
    .skip(@talc.char(']'))
    .map(name => { name: "[" + name + "]", port_base: None, port_value: None })
  let quoted = quoted_value_parser().map(name => {
    name,
    port_base: None,
    port_value: None,
  })
  let base_name_character = @talc.satisfy("relation name", char => {
    !char.is_whitespace() &&
    char != ':' &&
    char != '[' &&
    char != ']' &&
    char != ',' &&
    char != '(' &&
    char != ')'
  })
  let name_character = if stop_at_arrow {
    relation_separator_parser()
    .not_followed_by("relation separator")
    .then(base_name_character)
  } else {
    base_name_character
  }
  let segment = @talc.many_chars1(name_character)
  let qualified = segment
    .sep_by1(@talc.string("::"))
    .map(parts => {
      let name = parts.join("::")
      if parts.length() > 1 {
        {
          name,
          port_base: Some(parts[0]),
          port_value: Some(parts[1:].to_owned().join("::")),
        }
      } else {
        { name, port_base: None, port_value: None }
      }
    })
  shaped
  .attempt()
  .or(usecase.attempt())
  .or(actor.attempt())
  .or(component.attempt())
  .or(quoted.attempt())
  .or(qualified)
}

///|
fn relation_couple_parser() -> @talc.StringParser[
  (RelationNameSyntax, (String, String)),
] {
  @talc.char('(')
  .then(inline_spaces())
  .then(relation_name_parser(false))
  .bind(first => {
    inline_spaces()
    .then(@talc.char(','))
    .then(inline_spaces())
    .then(relation_name_parser(false))
    .bind(second => {
      inline_spaces()
      .then(@talc.char(')'))
      .map(_ => {
        let left = normalize_name(first.name)
        let right = normalize_name(second.name)
        ({ name: left, port_base: None, port_value: None }, (left, right))
      })
    })
  })
}

///|
fn relation_target_parser(
  stop_at_arrow : Bool,
) -> @talc.StringParser[(RelationNameSyntax, (String, String)?)] {
  relation_couple_parser()
  .attempt()
  .map(pair => {
    let (name, couple) = pair
    (name, Some(couple))
  })
  .or(relation_name_parser(stop_at_arrow).map(name => (name, None)))
}

///|
fn relation_role_value_parser() -> @talc.StringParser[String] {
  quoted_value_parser()
  .attempt()
  .or(
    @talc.many_chars1(
      @talc.satisfy("relation role", char => !char.is_whitespace()),
    ),
  )
  .map(normalize_name)
}

///|
fn relation_modifier_parser() -> @talc.StringParser[
  RelationEndpointModifier,
] {
  let cardinality = quoted_value_parser().map(value => {
    RelationCardinality(value)
  })
  let role = @talc.char('/')
    .then(relation_role_value_parser())
    .map(value => RelationRole(value))
  let qualifier = @talc.char('[')
    .then(@talc.many_chars1(@talc.none_of("]")))
    .skip(@talc.char(']'))
    .map(value => RelationQualifier(value.trim().to_owned()))
  @talc.choice([cardinality.attempt(), role.attempt(), qualifier])
}

///|
fn relation_endpoint_from(
  name : RelationNameSyntax,
  couple : (String, String)?,
  modifiers : Array[RelationEndpointModifier],
) -> RelationEndpointSyntax {
  let mut cardinality = None
  let mut role = None
  let mut qualifier = None
  for modifier in modifiers {
    match modifier {
      RelationCardinality(value) => cardinality = Some(value)
      RelationRole(value) => role = Some(value)
      RelationQualifier(value) => qualifier = Some(value)
    }
  }
  { name, cardinality, role, qualifier, couple }
}

///|
fn left_relation_endpoint_parser() -> @talc.StringParser[
  RelationEndpointSyntax,
] {
  relation_target_parser(true).bind(target => {
    let (name, couple) = target
    inline_space1()
    .then(relation_modifier_parser())
    .attempt()
    .many()
    .map(modifiers => relation_endpoint_from(name, couple, modifiers))
  })
}

///|
fn right_relation_endpoint_parser() -> @talc.StringParser[
  RelationEndpointSyntax,
] {
  relation_modifier_parser()
  .skip(inline_space1())
  .attempt()
  .many()
  .bind(modifiers => {
    relation_target_parser(false).map(target => {
      let (name, couple) = target
      relation_endpoint_from(name, couple, modifiers)
    })
  })
}

///|
fn relation_non_single_arrow_parser() -> @talc.StringParser[String] {
  relation_arrow_candidate_parser().bind(candidate => {
    guard candidate.first_length >= 2 ||
      candidate.has_direction ||
      candidate.has_left_decor ||
      candidate.has_right_decor else {
      return @talc.fail("relation arrow")
    }
    @talc.pure(candidate.text)
  })
}

///|
fn relation_separator_parser() -> @talc.StringParser[String] {
  let regular = inline_spaces()
    .then(relation_non_single_arrow_parser())
    .skip(inline_spaces())
  let single = inline_space1()
    .then(@talc.one_of("-=.").string_map(char => char.to_string()))
    .skip(inline_space1())
  regular.attempt().or(single)
}

///|
fn relation_color_parser() -> @talc.StringParser[RelationMetadataSyntax] {
  color_value_parser("relation color").map(value => RelationColor(value))
}

///|
fn relation_url_parser() -> @talc.StringParser[RelationMetadataSyntax] {
  url_value_parser().map(value => RelationUrl(value))
}

///|
fn relation_stereotype_parser() -> @talc.StringParser[
  RelationMetadataSyntax,
] {
  stereotype_value_parser().map(value => RelationStereotype(value))
}

///|
fn relation_metadata_parser() -> @talc.StringParser[
  RelationMetadataSyntax,
] {
  inline_space1().then(
    @talc.choice([
      relation_color_parser().attempt(),
      relation_url_parser().attempt(),
      relation_stereotype_parser(),
    ]),
  )
}

///|
fn relation_label_start_parser() -> @talc.StringParser[Unit] {
  inline_spaces()
  .then(@talc.char(':'))
  .skip(@talc.char(':').not_followed_by("qualified name"))
  .map(_ => ())
}

///|
fn right_relation_syntax_parser() -> @talc.StringParser[
  (RelationEndpointSyntax, Array[RelationMetadataSyntax], String?),
] {
  right_relation_endpoint_parser().bind(endpoint => {
    relation_metadata_parser()
    .attempt()
    .many()
    .bind(metadata => {
      relation_label_start_parser()
      .then(
        @talc.many_chars(@talc.satisfy("relation label", _ => true)),
      )
      .optional()
      .map(label => {
        let label = label.map(value => value.trim().to_owned())
        (endpoint, metadata, label)
      })
    })
  })
}

///|
fn relation_metadata_from(
  metadata : Array[RelationMetadataSyntax],
) -> (String?, String?, String?) {
  let mut color = None
  let mut url = None
  let mut stereotype = None
  for item in metadata {
    match item {
      RelationColor(value) => color = Some(value)
      RelationUrl(value) => url = Some(value)
      RelationStereotype(value) => stereotype = Some(value)
    }
  }
  (color, url, stereotype)
}

///|
fn left_relation_syntax_parser() -> @talc.StringParser[
  (String?, RelationEndpointSyntax),
] {
  let weight = @talc.char('@')
    .then(
      @talc.many_chars1(
        @talc.satisfy("relation weight", char => !char.is_whitespace()),
      ),
    )
    .skip(inline_space1())
    .attempt()
    .optional()
  weight.bind(weight => {
    left_relation_endpoint_parser().map(endpoint => (weight, endpoint))
  })
}

///|
fn relation_line_parser() -> @talc.StringParser[RelationLineSyntax] {
  left_relation_syntax_parser()
  .bind(left_syntax => {
    let (weight, left) = left_syntax
    relation_separator_parser().bind(arrow => {
      right_relation_syntax_parser().map(right_syntax => {
        let (right, metadata, label) = right_syntax
        let (color, url, stereotype) = relation_metadata_from(metadata)
        { weight, left, arrow, right, label, color, url, stereotype }
      })
    })
  })
  .skip(@talc.eof())
}
