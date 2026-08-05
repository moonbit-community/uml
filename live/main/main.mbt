///|
using @html {button, div, h1, li, textarea, ul}

///|
using @rabbita {type Html, type Val}

///|
enum Theme {
  Light
  Dark
} derive(Eq, Debug)

///|
fn Theme::css_name(self : Theme) -> String {
  match self {
    Light => "light"
    Dark => "dark"
  }
}

///|
fn Theme::toggle(self : Theme) -> Theme {
  match self {
    Light => Dark
    Dark => Light
  }
}

///|
enum Msg {
  EditorChanged(String)
  FileSelected(String)
  SizesChanged(Array[Int])
  ManifestLoaded(Result[Map[String, Array[String]], String])
  SourceLoaded(String, Result[String, String])
  ThemeToggled
}

///|
struct AppState {
  active_file : String
  source : String
  sizes : Array[Int]
  categories : Map[String, Array[String]]
  sources : Map[String, String]
  load_error : String?
  theme : Theme
} derive(Eq)

///|
fn update(
  emit : @rabbita.Emit[Msg],
  msg : Msg,
  state : AppState,
) -> (AppState, @cmd.Cmd) {
  match msg {
    EditorChanged(value) => ({ ..state, source: value }, @cmd.none)
    FileSelected(file) => (select_source(state, file), @cmd.none)
    SizesChanged(sizes) => ({ ..state, sizes, }, @cmd.none)
    ManifestLoaded(Ok(categories)) =>
      ({ ..state, categories, }, source_fetch_cmds(emit, categories))
    ManifestLoaded(Err(error)) =>
      ({ ..state, load_error: Some(error) }, @cmd.none)
    SourceLoaded(path, Ok(source)) =>
      (apply_source(state, path, source), @cmd.none)
    SourceLoaded(path, Err(_)) => (apply_source(state, path, ""), @cmd.none)
    ThemeToggled => (toggle_theme(state), apply_theme(state.theme.toggle()))
  }
}

///|
fn toggle_theme(state : AppState) -> AppState {
  { ..state, theme: state.theme.toggle() }
}

///|
fn apply_theme(theme : Theme) -> @cmd.Cmd {
  @cmd.custom_cmd(_ => {
    match @dom.document().get_document_element() {
      Some(element) => element.set_attribute("data-theme", theme.css_name())
      None => ()
    }
  })
}

///|
fn source_fetch_cmds(
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
fn select_source(state : AppState, path : String) -> AppState {
  { ..state, active_file: path, source: state.sources.get(path).unwrap_or("") }
}

///|
fn example_count(categories : Map[String, Array[String]]) -> Int {
  let mut total = 0
  for _, files in categories {
    total += files.length()
  }
  total
}

///|
fn first_path(categories : Map[String, Array[String]]) -> String? {
  for cat, files in categories {
    if files.length() > 0 {
      return Some("\{cat}/\{files[0]}")
    }
  }
  None
}

///|
fn apply_source(state : AppState, path : String, source : String) -> AppState {
  state.sources[path] = source
  if path == state.active_file {
    { ..state, source, }
  } else if state.active_file == "" &&
    state.sources.length() == example_count(state.categories) {
    match first_path(state.categories) {
      Some(first) =>
        {
          ..state,
          active_file: first,
          source: state.sources.get(first).unwrap_or(""),
        }
      None => state
    }
  } else {
    state
  }
}

///|
fn workspace_default_sizes() -> Array[Int] {
  [26, 44, 30]
}

///|
fn workspace_min_sizes() -> Array[Int] {
  [16, 24, 18]
}

///|
fn workspace_max_sizes() -> Array[Int] {
  [52, 68, 54]
}

///|
fn initial_state() -> AppState {
  {
    active_file: "",
    source: "",
    sizes: workspace_default_sizes(),
    categories: Map([]),
    sources: Map([]),
    load_error: None,
    theme: Light,
  }
}

///|
fn app_state_tag(state : AppState) -> String {
  "\{state.active_file}|\{state.source}|\{state.categories.length()}|\{state.load_error.unwrap_or("")}|\{state.theme.css_name()}"
}

///|
fn file_panel(state : AppState, emit : @rabbita.Emit[Msg]) -> Html {
  let file_item = fn(cat : String, file : String) -> Html {
    let path = "\{cat}/\{file}"
    li(
      class=if state.active_file == path {
        "file-item active"
      } else {
        "file-item"
      },
      on_click=emit(FileSelected(path)),
      file,
    )
  }
  div(class="file-panel") <| [
    div(class="panel-header") <| [
      h1(class="panel-title", "Files"),
      theme_toggle(state, emit),
    ],
    if state.load_error is Some(_) {
      div(class="file-placeholder", "加载失败")
    } else if state.categories.is_empty() {
      div(class="file-placeholder", "加载中…")
    } else {
      ul(class="file-list") <| ({
        let items : Array[Html] = []
        for cat, files in state.categories {
          items.push(li(class="file-category", cat))
          for file in files {
            items.push(file_item(cat, file))
          }
        }
        items
      })
    },
  ]
}

///|
fn editor_panel(state : AppState, emit : @rabbita.Emit[Msg]) -> Html {
  div(class="editor-panel") <| [
    h1(class="panel-title", "Editor"),
    textarea(
      "",
      class="editor",
      value=state.source,
      on_input=emit.map(value => EditorChanged(value)),
    ),
  ]
}

///|
/// The paint scheme used for the preview. Every role maps to a CSS variable,
/// so a single SVG adapts to the active light/dark theme without re-rendering.
fn theme_color_scheme() -> @style.ColorScheme {
  @style.ColorScheme::ColorScheme(
    "var(--uml-text)",
    "var(--uml-line)",
    canvas="var(--uml-canvas)",
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
fn theme_toggle(state : AppState, emit : @rabbita.Emit[Msg]) -> Html {
  let target = state.theme.toggle()
  button(
    class="theme-toggle",
    title=if target is Dark {
      "Switch to dark theme"
    } else {
      "Switch to light theme"
    },
    on_click=emit(ThemeToggled),
    if target is Dark {
      "Dark"
    } else {
      "Light"
    },
  )
}

///|
#warnings("-alert_xss_vulnerable")
fn preview_content(state : AppState) -> Array[Html] {
  if state.load_error is Some(error) {
    [div(class="preview-message", error)]
  } else if state.source == "" {
    [div(class="preview-message", "加载中…")]
  } else {
    let svg : String = @api.render_svg(
      state.source,
      color_scheme=theme_color_scheme(),
    ) catch {
      e => "\{e}"
    }
    [div(attrs=@html.Attrs::build().inner_html(svg), "")]
  }
}

///|
fn preview_panel(state : AppState) -> Html {
  div(class="preview-panel") <| [
    h1(class="panel-title", "Preview"),
    div(class="preview") <| preview_content(state),
  ]
}

///|
fn workspace(state : AppState, emit : @rabbita.Emit[Msg]) -> Val[Html] {
  @rui.resizable_group(
    id="workspace-resizable",
    default_sizes=state.sizes,
    min_sizes=workspace_min_sizes(),
    max_sizes=workspace_max_sizes(),
    orientation=@rui.Horizontal,
    on_resize=@cmd.Emit(sizes => emit(SizesChanged(sizes))),
    class="workspace",
    scope => {
      @html.fragment([
        @rui.resizable_group_panel(
          scope~,
          index=0,
          style=["height:100%"],
          file_panel(state, emit),
        ),
        @rui.resizable_group_handle(
          scope~,
          between=0,
          with_handle=true,
          aria_label="Resize files and editor",
        ),
        @rui.resizable_group_panel(
          scope~,
          index=1,
          style=["height:100%"],
          editor_panel(state, emit),
        ),
        @rui.resizable_group_handle(
          scope~,
          between=1,
          with_handle=true,
          aria_label="Resize editor and preview",
        ),
        @rui.resizable_group_panel(
          scope~,
          index=2,
          style=["height:100%"],
          preview_panel(state),
        ),
      ])
    },
  )
}

///|
fn app() -> Val[Html] {
  let (state, emit) = @rabbita.create_state_with_init(
    init=fn(emit) {
      (
        initial_state(),
        @http.get("examples-manifest.json").expect_json(result => {
          emit(ManifestLoaded(result.map_err(error => "\{error}")))
        }),
      )
    },
    update~,
  )
  state.switch_by(state => workspace(state, emit), by=app_state_tag)
}

///|
fn main {
  @rabbita.new(app).mount("app")
}
