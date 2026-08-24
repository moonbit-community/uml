///|
priv enum TestLayoutPath {
  GraphvizPath
  FallbackPath
} derive(Eq, Debug)

///|
fn unsupported_layout_for_test() -> TestLayoutPath raise @dot_layout.DotLayoutError {
  raise @dot_layout.DotLayoutError::UnsupportedFeature(
    message="unsupported state layout",
  )
}

///|
test "Graphviz success does not evaluate the fallback" {
  let mut fallback_called = false
  let layout = layout_or_fallback(
    () => GraphvizPath,
    Some(() => {
      fallback_called = true
      FallbackPath
    }),
  )
  @test.assert_eq(layout, GraphvizPath)
  @test.assert_eq(fallback_called, false)
}

///|
test "unsupported Graphviz features use an available fallback" {
  let layout = layout_or_fallback(
    () => {
      raise @dot_layout.DotLayoutError::UnsupportedFeature(
        message="unsupported test feature",
      )
    },
    Some(() => FallbackPath),
  )
  @test.assert_eq(layout, FallbackPath)
}

///|
test "invalid Graphviz input remains a rendering failure" {
  let error = @test.expect_error(() => {
    layout_or_fallback(
      () => {
        raise @dot_layout.DotLayoutError::InvalidGraph(
          message="invalid test graph",
        )
      },
      Some(() => FallbackPath),
    )
  })
  match error {
    @dot_layout.DotLayoutError::InvalidGraph(message~) =>
      @test.assert_eq(message, "invalid test graph")
    _ => @test.fail("expected invalid Graphviz input")
  }
}

///|
test "unsupported Graphviz features fail when no fallback exists" {
  let error = @test.expect_error(() => {
    layout_or_fallback(unsupported_layout_for_test, None)
  })
  match error {
    @dot_layout.DotLayoutError::UnsupportedFeature(message~) =>
      @test.assert_eq(message, "unsupported state layout")
    _ => @test.fail("expected unsupported Graphviz feature")
  }
}
