///|
using @html {div, h1, li, textarea, text, ul}

///|
using @rabbita {type Html, type Val}

///|
enum Msg {
  EditorChanged(String)
  FileSelected(String)
}

///|
struct AppState {
  active_file : String
  sequence_source : String
  class_source : String
  activity_source : String
} derive(Eq)

///|
fn current_source(state : AppState) -> String {
  match state.active_file {
    "sequence.uml" => state.sequence_source
    "class.uml" => state.class_source
    "activity.uml" => state.activity_source
    _ => state.sequence_source
  }
}

///|
fn update_active_source(state : AppState, source : String) -> AppState {
  match state.active_file {
    "sequence.uml" => { ..state, sequence_source: source }
    "class.uml" => { ..state, class_source: source }
    "activity.uml" => { ..state, activity_source: source }
    _ => state
  }
}

///|
fn app() -> Val[Html] {
  let (state, emit) = @rabbita.create_pure_state(
    {
      active_file: "sequence.uml",
      sequence_source: "@startuml\nAlice -> Bob: Request\nBob --> Alice: Response\n@enduml",
      class_source: "@startuml\nclass User {\n  +name: String\n  +login()\n}\nclass Session\nUser --> Session\n@enduml",
      activity_source: "@startuml\nstart\n:Receive request;\nif (Valid?) then (yes)\n  :Process request;\nelse (no)\n  :Return error;\nendif\nstop\n@enduml",
    },
    update=(msg, state) => {
      match msg {
        EditorChanged(value) => update_active_source(state, value)
        FileSelected(file) => { ..state, active_file: file }
      }
    },
  )

  state.view(state => {
    div(class="workspace") <| [
      div(class="file-panel") <| [
        h1(class="panel-title", "Files"),
        ul(class="file-list") <| [
          li(
            class=if state.active_file == "sequence.uml" {
              "file-item active"
            } else {
              "file-item"
            },
            on_click=emit(FileSelected("sequence.uml")),
            "sequence.uml",
          ),
          li(
            class=if state.active_file == "class.uml" {
              "file-item active"
            } else {
              "file-item"
            },
            on_click=emit(FileSelected("class.uml")),
            "class.uml",
          ),
          li(
            class=if state.active_file == "activity.uml" {
              "file-item active"
            } else {
              "file-item"
            },
            on_click=emit(FileSelected("activity.uml")),
            "activity.uml",
          ),
        ],
      ],
      div(class="editor-panel") <| [
        h1(class="panel-title", "Editor"),
        textarea(
          "",
          class="editor",
          value=current_source(state),
          on_input=emit.map(value => EditorChanged(value)),
        ),
      ],
      div(class="preview-panel") <| [
        h1(class="panel-title", "Preview"),
        div(class="preview") <| [
          text(current_source(state)),
        ],
      ],
    ]
  })
}

///|
fn main {
  @rabbita.new(app).mount("app")
}
