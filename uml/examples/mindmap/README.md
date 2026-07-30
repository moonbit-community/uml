# Mindmap examples

Each `.uml` file is a focused input fixture and the matching `.svg` file is
the renderer output.

| Fixture | Coverage |
| - | - |
| `01-basic` | Nested branches, long labels, and inline strike-through markup |
| `02-directions` | Right/left `+` and `-` branches, colors, and boxless nodes |
| `03-presentation` | Colors, boxless items, stereotypes, escaped text, and multiline labels |
| `04-styles` | Document skin parameters, `<style>` selectors, node/arrow styling, and alignment |
| `05-org-mode` | `*`/`#` hierarchy, deep descendants, and multiple roots |
| `06-explicit-root` | `0` root syntax and mixed directional descendants |

The final fixture is kept as a source-only regression case until the CLI is
rebuilt with the parser support for explicit `0` roots.
