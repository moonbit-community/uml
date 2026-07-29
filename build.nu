ls examples/<dir>/*.uml | each { |it| plantuml -tsvg -o uml $it.name }
ls examples/<dir>/*.uml | each { |it| moon run . $it.name }
