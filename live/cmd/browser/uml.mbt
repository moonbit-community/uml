///|
/// Network and rendering access for the app: fetching the example manifest
/// and sources, and turning a source into a theme-aware SVG.

///|
/// Fetch the example manifest and schedule a load for every listed source.
fn fetch_manifest_cmd(emit : @rabbita.Emit[Msg]) -> @cmd.Cmd {
  @http.get("examples-manifest.json").expect_json(result => {
    emit(ManifestLoaded(result.map_err(error => "\{error}")))
  })
}

///|
fn fetch_sources_cmd(
  emit : @rabbita.Emit[Msg],
  categories : Map[String, Array[String]],
) -> @cmd.Cmd {
  let cmds : Array[@cmd.Cmd] = []
  for cat, files in categories {
    for file in files {
      let path = "\{cat}/\{file}"
      cmds.push(
        @http.get("examples/\{path}").expect_text(result => {
          emit(SourceLoaded(path, result.map_err(error => "\{error}")))
        }),
      )
    }
  }
  @cmd.batch(cmds)
}

///|
/// The paint scheme used for the preview. Every role maps to a CSS variable,
/// so a single SVG adapts to the active light/dark theme without re-rendering.
fn theme_color_scheme() -> @style.ColorScheme {
  @style.ColorScheme::ColorScheme(
    "var(--uml-text)",
    "var(--uml-line)",
    node="var(--uml-node)",
    note="var(--uml-note)",
    partition="var(--uml-partition)",
    participant="var(--uml-participant)",
    activation="var(--uml-activation)",
    lifeline="var(--uml-lifeline)",
    divider="var(--uml-divider)",
    divider_title="var(--uml-divider-title)",
    delay="var(--uml-delay)",
    reference_tab="var(--uml-reference-tab)",
    page_break="var(--uml-page-break)",
    transparent="var(--uml-transparent)",
    spot_abstract="var(--uml-spot-abstract)",
    spot_interface="var(--uml-spot-interface)",
    spot_enum="var(--uml-spot-enum)",
    spot_annotation="var(--uml-spot-annotation)",
    spot_class="var(--uml-spot-class)",
    visibility_public_stroke="var(--uml-visibility-public-stroke)",
    visibility_public_fill="var(--uml-visibility-public-fill)",
    visibility_private_stroke="var(--uml-visibility-private-stroke)",
    visibility_private_fill="var(--uml-visibility-private-fill)",
    visibility_protected_stroke="var(--uml-visibility-protected-stroke)",
    visibility_protected_fill="var(--uml-visibility-protected-fill)",
    visibility_package_stroke="var(--uml-visibility-package-stroke)",
    visibility_package_fill="var(--uml-visibility-package-fill)",
  )
}

///|
/// Render a source to a standalone SVG with the theme-aware color scheme,
/// stringifying any parse or render error for display in the preview pane.
fn render_source_svg(source : String) -> String {
  @api.render_svg(
    source,
    color_scheme=theme_color_scheme(),
    class_member_collapsible=true,
  ) catch {
    e => "\{e}"
  }
}
