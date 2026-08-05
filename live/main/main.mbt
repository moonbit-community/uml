///|
using @html {div, h1, li, textarea, ul}

///|
using @rabbita {type Html, type Val}

///|
enum Msg {
  EditorChanged(String)
  FileSelected(String)
  SizesChanged(Array[Int])
}

///|
struct AppState {
  active_file : String
  source : String
  sizes : Array[Int]
} derive(Eq)

///|
fn default_source(file : String) -> String {
  match file {
    "class.uml" =>
      (
        #|@startuml
        #|class User {
        #|  +name: String
        #|  +login()
        #|}
        #|class Session
        #|User --> Session
        #|@enduml
      )
    "activity.uml" =>
      (
        #|@startuml
        #|start
        #|:Receive request;
        #|if (Valid?) then (yes)
        #|  :Process request;
        #|else (no)
        #|  :Return error;
        #|endif
        #|stop
        #|@enduml
      )
    _ =>
      (
        #|@startuml
        #|Alice -> Bob: Request
        #|Bob --> Alice: Response
        #|@enduml
      )
  }
}

///|
fn update(msg : Msg, state : AppState) -> AppState {
  match msg {
    EditorChanged(value) => { ..state, source: value }
    FileSelected(file) =>
      { ..state, active_file: file, source: default_source(file) }
    SizesChanged(sizes) => { ..state, sizes, }
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
    active_file: "sequence.uml",
    source: default_source("sequence.uml"),
    sizes: workspace_default_sizes(),
  }
}

///|
fn app_state_tag(state : AppState) -> String {
  "\{state.active_file}|\{state.source}"
}

///|
fn file_panel(state : AppState, emit : @rabbita.Emit[Msg]) -> Html {
  let file_item = fn(file : String) -> Html {
    li(
      class=if state.active_file == file {
        "file-item active"
      } else {
        "file-item"
      },
      on_click=emit(FileSelected(file)),
      file,
    )
  }
  div(class="file-panel") <| [
    h1(class="panel-title", "Files"),
    ul(class="file-list") <| [
      file_item("sequence.uml"),
      file_item("class.uml"),
      file_item("activity.uml"),
    ],
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
#warnings("-alert_xss_vulnerable")
fn preview_panel(state : AppState) -> Html {
  div(class="preview-panel") <| [
    h1(class="panel-title", "Preview"),
    div(class="preview") <| ({
      let svg : String = @api.render_svg(state.source) catch { e => "\{e}" }
      [div(attrs=@html.Attrs::build().inner_html(svg), "")]
    }),
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
  let (state, emit) = @rabbita.create_pure_state(initial_state(), update~)
  state.switch_by(state => workspace(state, emit), by=app_state_tag)
}

///|
fn main {
  @rabbita.new(app).mount("app")
}
