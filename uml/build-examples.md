
```shell
ls examples/<dir>/*.uml | each { |it| plantuml -tsvg -o uml $it.name }

ls examples/<dir>/*.uml | each { |it| moon run ./uml $it.name }
```

调用 plantuml 时, `<dir>` 可取除了 toml 以外的文件夹 (因为原版 plantuml 未实现 toml 的可视化). 
