
```nushell
ls examples/<dir>/*.uml | each { |it| plantuml -tsvg -o uml $it.name }

ls examples/<dir>/*.uml | each { |it| moon run ./uml $it.name }
```

When calling plantuml, `<dir>` can be any folder other than toml (because the original plantuml does not implement visualization of toml).

```nushell
ls examples/*/*.uml | each { |it| moon run ./uml $it.name }
```
