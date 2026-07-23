///|
test "sequence line dispatcher accepts complete example commands" {
  guard left_exo_message_parser().parse(
      @talcparsec.Input::new("[-> client : HTTP request"),
    )
    is Ok(_) else {
    @test.fail("left exo parser rejected")
  }
  let lines = [
    "participant \"Web Client\" as client #lightblue", "boundary Gateway", "control Service",
    "database Store", "& {request} client -> Gateway & Service : Fetch account",
    "activate Service #lime", "Service ->> Store : load profile", "note right of Service #yellow : cache miss",
    "alt #palegreen cache hit", "Service --> client : cached", "else cache miss",
    "Service -> Store ++ : query", "Store --> Service -- : rows", "end", "ref over client, Service : External system",
    "== Processing ==", "... waiting for upstream ...", "return response", "deactivate Service",
    "[-> client : HTTP request", "client ->] : audit", "box Infrastructure #lightblue",
    "participant Logger", "end box", "autonumber 1.2 3 \"(0)\"", "autonumber inc b",
    "autoactivate on", "hide footbox", "hide unlinked", "autonewpage 10", "ignore newpage",
    "newpage summary",
  ]
  for line in lines {
    guard parse_sequence_line(line) is Some(_) else {
      @test.fail("line dispatcher rejected: " + line)
    }
  }
}
