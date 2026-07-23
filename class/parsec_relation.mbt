///|
priv struct RelationStroke {
  first_length : Int
  has_direction : Bool
  text : String
}

///|
priv struct RelationArrowCandidate {
  first_length : Int
  has_direction : Bool
  has_left_decor : Bool
  has_right_decor : Bool
  text : String
}

///|
fn relation_symbol(value : String) -> @talcparsec.StringParser[String] {
  @talcparsec.string(value).attempt()
}

///|
fn relation_stroke_parser() -> @talcparsec.StringParser[RelationStroke] {
  let stroke = @talcparsec.many_chars1(@talcparsec.one_of("-=."))
  let style = @talcparsec.char('[')
    .then(@talcparsec.many_chars(@talcparsec.none_of("]")))
    .skip(@talcparsec.char(']'))
    .attempt()
    .optional()
  let direction = @talcparsec.choice([
    relation_symbol("right"),
    relation_symbol("down"),
    relation_symbol("left"),
    relation_symbol("up"),
    relation_symbol("ri"),
    relation_symbol("do"),
    relation_symbol("le"),
    relation_symbol("r"),
    relation_symbol("d"),
    relation_symbol("l"),
    relation_symbol("u"),
  ]).optional()
  stroke.bind(first => {
    style.bind(first_style => {
      direction.bind(direction => {
        style.bind(second_style => {
          @talcparsec.many_chars(@talcparsec.one_of("-=.")).map(second => {
            let text = first +
              first_style.map_or("", value => "[" + value + "]") +
              direction.unwrap_or("") +
              second_style.map_or("", value => "[" + value + "]") +
              second
            {
              first_length: first.length(),
              has_direction: direction is Some(_),
              text,
            }
          })
        })
      })
    })
  })
}

///|
fn relation_arrow_candidate_parser() -> @talcparsec.StringParser[
  RelationArrowCandidate,
] {
  let left_decor = @talcparsec.choice([
      relation_symbol("<|:"),
      relation_symbol("<||"),
      relation_symbol("}o"),
      relation_symbol("|o"),
      relation_symbol("}|"),
      relation_symbol("<|"),
      relation_symbol("<<"),
      relation_symbol("0)"),
      relation_symbol("()"),
      relation_symbol("))"),
      relation_symbol("||"),
      relation_symbol("*"),
      relation_symbol("o"),
      relation_symbol("x"),
      relation_symbol("}"),
      relation_symbol("<_"),
      relation_symbol("<"),
      relation_symbol("0"),
      relation_symbol("@"),
      relation_symbol(")"),
      relation_symbol("#"),
      relation_symbol("+"),
    ])
    .attempt()
    .optional()
  let right_decor = @talcparsec.choice([
      relation_symbol(":|>"),
      relation_symbol("||>"),
      relation_symbol("o{"),
      relation_symbol("o|"),
      relation_symbol("|{"),
      relation_symbol("|>"),
      relation_symbol(">>"),
      relation_symbol("(0"),
      relation_symbol("()"),
      relation_symbol("(("),
      relation_symbol("||"),
      relation_symbol("*"),
      relation_symbol("o"),
      relation_symbol("x"),
      relation_symbol("{"),
      relation_symbol("_>"),
      relation_symbol(">"),
      relation_symbol("0"),
      relation_symbol("@"),
      relation_symbol("("),
      relation_symbol("#"),
      relation_symbol("+"),
      relation_symbol("\\"),
      relation_symbol("//"),
    ])
    .attempt()
    .optional()
  let inside = @talcparsec.choice([
      relation_symbol("(0)"),
      relation_symbol("(0"),
      relation_symbol("0)"),
      relation_symbol("0"),
    ])
    .bind(value => {
      @talcparsec.many_chars1(@talcparsec.one_of("-=.")).map(stroke => {
        value + stroke
      })
    })
    .attempt()
    .optional()
  left_decor.bind(left => {
    relation_stroke_parser().bind(stroke => {
      inside.bind(inside => {
        right_decor.map(right => {
          let left_text = left.unwrap_or("")
          let right_text = right.unwrap_or("")
          {
            first_length: stroke.first_length,
            has_direction: stroke.has_direction,
            has_left_decor: left is Some(_),
            has_right_decor: right is Some(_),
            text: left_text + stroke.text + inside.unwrap_or("") + right_text,
          }
        })
      })
    })
  })
}
