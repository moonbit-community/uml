///|
test "declaration line grammar accepts supported declarations" {
  guard declaration_target_list_parser().run(
      @talcparsec.Input::new("BaseA, BaseB implements APIA, APIB"),
    )
    is Ok(_) else {
    @test.fail("inheritance target list rejected")
  }
  guard declaration_suffix_parser().run(
      @talcparsec.Input::new("extends BaseA, BaseB implements APIA, APIB"),
    )
    is Ok(_) else {
    @test.fail("inheritance suffix parser rejected")
  }
  let lines = [
    "abstract class \"User\" as U {", "interface Auth", "+ static class Repository<T> <<storage>> extends BaseRepository",
    "class RedisCache implements Cache", "() Api <<service>> [[https://example.com/api]] #lightblue",
    "class Service $backend $critical #lightblue ##[dashed]red", "usecase (Login user)",
    "actor :User:", "component [API]", "mix_actor External", "map Config {}", "json Payload {",
    "<> association",
  ]
  for line in lines {
    guard declaration_line_parser().parse(@talcparsec.Input::new(line)) is Ok(_) else {
      @test.fail("declaration grammar rejected: " + line)
    }
  }
}
