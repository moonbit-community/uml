///|
test "shared inline lexical parsers preserve PlantUML token values" {
  @test.assert_eq(
    quoted_value_parser().parse(@talc.Input::new("\"service api\"")),
    Ok("service api"),
  )
  @test.assert_eq(
    stereotype_value_parser().parse(@talc.Input::new("<<choice>>")),
    Ok("<<choice>>"),
  )
  @test.assert_eq(
    url_value_parser().parse(@talc.Input::new("[[https://example.com/docs]]")),
    Ok("https://example.com/docs"),
  )
  @test.assert_eq(
    color_value_parser("color").parse(@talc.Input::new("#lightblue")),
    Ok("lightblue"),
  )
}
