///|
fn try_participant_ref(src : Source) -> PartRef? {
  let saved = src.save()
  if src.consume('"') {
    let display = src.take_while(c => c != '"')
    if !src.consume('"') {
      src.restore(saved)
      return None
    }
    src.skip_whitespace()
    if src.try_keyword("as") {
      src.skip_whitespace()
      let code = src.take_while(is_ident_char)
      guard code.length() > 0 else {
        src.restore(saved)
        return None
      }
      return Some({ code, display })
    }
    return Some({ code: display, display })
  }
  let code = src.take_while(is_ident_char)
  guard code.length() > 0 else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  if src.try_keyword("as") {
    src.skip_whitespace()
    if src.consume('"') {
      let display = src.take_while(c => c != '"')
      guard src.consume('"') else {
        src.restore(saved)
        return None
      }
      return Some({ code, display })
    }
    let display = src.take_while(is_ident_char)
    if display.length() > 0 {
      return Some({ code, display })
    }
    return Some({ code, display: code })
  }
  Some({ code, display: code })
}

///|
fn left_dressing(src : Source) -> DressingResult {
  let circle : Bool = src.consume('o')
  let cross : Bool = src.consume('x')
  let mut part = Full
  let head : ArrowHead = if src.consume('<') {
    if src.consume('<') {
      Async
    } else {
      Normal
    }
  } else if src.consume('/') {
    part = TopPart
    if src.consume('/') {
      Async
    } else {
      Normal
    }
  } else if src.consume('\\') {
    part = BottomPart
    if src.consume('\\') {
      Async
    } else {
      Normal
    }
  } else {
    NoneHead
  }
  let has_dir = head.has_direction()
  if src.consume('(') {
    let _ = src.take_while(Char::is_ascii_digit)
    let _ = src.consume(')')
  }
  { head, circle, cross, has_dir, part }
}

///|
fn right_dressing(src : Source) -> DressingResult {
  let _ = src.consume('_')
  let mut part = Full
  let head : ArrowHead = if src.consume('>') {
    if src.consume('>') {
      Async
    } else {
      Normal
    }
  } else if src.consume('/') {
    part = BottomPart
    if src.consume('/') {
      Async
    } else {
      Normal
    }
  } else if src.consume('\\') {
    part = TopPart
    if src.consume('\\') {
      Async
    } else {
      Normal
    }
  } else {
    NoneHead
  }
  let has_dir = head.has_direction()
  let circle : Bool = src.consume('o')
  let cross : Bool = src.consume('x')
  if src.consume('(') {
    let _ = src.take_while(Char::is_ascii_digit)
    let _ = src.consume(')')
  }
  { head, circle, cross, has_dir, part }
}

///|
fn activation_spec(src : Source) -> ActivationSpec? {
  if src.try_string("++") {
    Some(Activate)
  } else if src.try_string("--") {
    Some(Deactivate)
  } else if src.try_string("!!") {
    Some(Destroy)
  } else if src.try_string("**") {
    Some(Create)
  } else {
    None
  }
}

///|
fn build_arrow_cfg(
  left : DressingResult,
  right : DressingResult,
  body : ArrowBody,
  reverse : Bool,
) -> ArrowConfig {
  let (l, r) = if reverse { (right, left) } else { (left, right) }
  let mut cfg = ArrowConfig::default()
  if l.head.has_direction() {
    cfg = cfg.with_head1(l.head)
  }
  if r.head.has_direction() {
    cfg = cfg.with_head2(r.head)
  }
  if l.cross {
    cfg = cfg.with_head1(CrossX)
  }
  if r.cross {
    cfg = cfg.with_head2(CrossX)
  }
  let cfg = match (l.part, r.part) {
    (Full, Full) => cfg
    (TopPart, _) | (_, TopPart) => { ..cfg, part: TopPart }
    (BottomPart, _) | (_, BottomPart) => { ..cfg, part: BottomPart }
  }
  cfg.with_circle_start(l.circle).with_circle_end(r.circle).with_body(body)
}

///|
fn arrow(src : Source) -> Event? {
  let saved = src.save()
  let parallel : Bool = src.consume('&')
  if parallel {
    src.skip_whitespace()
  }
  let anchor = try_anchor(src)
  if anchor is Some(_) {
    src.skip_whitespace()
  }

  let p1_code : String = match try_participant_ref(src) {
    Some(r) => r.code
    None => {
      src.restore(saved)
      return None
    }
  }

  src.skip_whitespace()
  let _ = try_anchor(src)
  src.skip_whitespace()
  let is_a : Bool = match src.peek() {
    Some(c) if is_arrow_char(c) => true
    _ => false
  }
  if !is_a {
    src.restore(saved)
    return None
  }

  let left = left_dressing(src)
  let d1 = src.take_while(c => c == '-')
  let _ = if src.consume('[') {
    let _s = src.take_while(c => c != ']')
    let _ = src.consume(']')
    ()
  }
  let d2 = src.take_while(c => c == '-')
  if d1.length() == 0 && d2.length() == 0 {
    src.restore(saved)
    return None
  }

  let body : ArrowBody = if d1.length() + d2.length() > 1 {
    Dotted
  } else {
    Solid
  }
  let right = right_dressing(src)

  src.skip_whitespace()
  let p2_code : String = match try_participant_ref(src) {
    Some(r) => r.code
    None => {
      src.restore(saved)
      return None
    }
  }

  src.skip_whitespace()
  let multicast : Array[String] = []
  while src.consume('&') {
    src.skip_whitespace()
    let code = src.take_while(is_ident_char)
    guard code.length() > 0 else {
      src.restore(saved)
      return None
    }
    multicast.push(code)
    src.skip_whitespace()
  }
  let _ = try_anchor(src)

  let reverse : Bool = if right.has_dir {
    false
  } else if left.has_dir {
    true
  } else if left.cross || right.cross {
    false
  } else {
    src.restore(saved)
    return None
  }

  let mut from : String = p1_code
  let mut to : String = p2_code
  if reverse {
    from = p2_code
    to = p1_code
  }
  let cfg = build_arrow_cfg(left, right, body, reverse)

  src.skip_whitespace()
  let act = activation_spec(src)
  let lcolor : String? = if src.consume('#') {
    Some(src.take_while(is_ident_char))
  } else {
    None
  }
  src.skip_whitespace()
  let label : String? = if src.consume(':') {
    Some(src.collect_line().trim().to_owned())
  } else {
    None
  }

  Some(
    Message({
      from_code: from,
      to_code: to,
      label,
      arrow_config: cfg,
      parallel,
      anchor,
      multicast,
      activation_spec: act,
      life_color: lcolor,
    }),
  )
}

///|
fn try_exo_arrow(src : Source) -> Event? {
  let saved = src.save()
  let _ = src.consume('&')
  src.skip_whitespace()

  let from_left = src.consume('[')
  let mut short_arrow = false
  if from_left {
    short_arrow = src.consume('?')
    let left = left_dressing(src)
    let d1 = src.take_while(c => c == '-')
    let _ = if src.consume('[') {
      let _ = src.take_while(c => c != ']')
      let _ = src.consume(']')
      ()
    }
    let d2 = src.take_while(c => c == '-')
    let right = right_dressing(src)
    guard d1.length() + d2.length() > 0 else {
      src.restore(saved)
      return None
    }
    src.skip_whitespace()
    guard try_participant_ref(src) is Some(participant) else {
      src.restore(saved)
      return None
    }
    let exo_type = if right.has_dir {
      FromLeft
    } else if left.has_dir {
      ToLeft
    } else {
      src.restore(saved)
      return None
    }
    let body = if d1.length() + d2.length() > 1 { Dotted } else { Solid }
    src.skip_whitespace()
    let activation_spec = activation_spec(src)
    let life_color = if src.consume('#') {
      Some(src.take_while(is_ident_char))
    } else {
      None
    }
    src.skip_whitespace()
    let label = if src.consume(':') {
      Some(src.collect_line().trim().to_owned())
    } else {
      None
    }
    return Some(
      MessageExo({
        participant_code: participant.code,
        exo_type,
        label,
        arrow_config: build_arrow_cfg(left, right, body, left.has_dir),
        short_arrow,
        activation_spec,
        life_color,
      }),
    )
  }

  guard try_participant_ref(src) is Some(participant) else {
    src.restore(saved)
    return None
  }
  src.skip_whitespace()
  let left = left_dressing(src)
  let d1 = src.take_while(c => c == '-')
  let _ = if src.consume('[') {
    let _ = src.take_while(c => c != ']')
    let _ = src.consume(']')
    ()
  }
  let d2 = src.take_while(c => c == '-')
  let right = right_dressing(src)
  guard d1.length() + d2.length() > 0 else {
    src.restore(saved)
    return None
  }
  short_arrow = src.consume('?')
  guard src.consume(']') else {
    src.restore(saved)
    return None
  }
  let exo_type = if right.has_dir {
    ToRight
  } else if left.has_dir {
    FromRight
  } else {
    src.restore(saved)
    return None
  }
  let body = if d1.length() + d2.length() > 1 { Dotted } else { Solid }
  src.skip_whitespace()
  let activation_spec = activation_spec(src)
  let life_color = if src.consume('#') {
    Some(src.take_while(is_ident_char))
  } else {
    None
  }
  src.skip_whitespace()
  let label = if src.consume(':') {
    Some(src.collect_line().trim().to_owned())
  } else {
    None
  }
  Some(
    MessageExo({
      participant_code: participant.code,
      exo_type,
      label,
      arrow_config: build_arrow_cfg(left, right, body, left.has_dir),
      short_arrow,
      activation_spec,
      life_color,
    }),
  )
}
