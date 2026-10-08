# PlantUML compatibility

The implementation follows the Java checkout in `.local/plantuml`. Existing
reference SVGs in `live/public/examples/*/puml/` take precedence over source
constants. Java is not rebuilt or instrumented for compatibility work.

The current completion scope is the README's `done` diagrams: Class, Object,
Component, Deployment, Package, Use Case, Activity, State, Sequence, Mindmap,
JSON, YAML, DOT, TOML and MBTI. Timing and WBS retain their separately stated
status; changes to shared code must continue to support them.

The current priority is diagram structure, notation, text metrics and layout.
The implemented corrections do not establish complete PlantUML equivalence.
Legacy Activity, advanced action/note forms and stereotype handling are included;
visual comparison with the reference SVGs remains pending.

## Upstream differences

| Dependency | Evidence and affected behavior | Handling |
| --- | --- | --- |
| `moonbit-community/graphviz@0.1.10` | PlantUML's JSON renderer sends premeasured record-cell dimensions through Smetana's private `_dim_` hook (`SmetanaForJson.java`, `smetana/core/Macro.java`). The MoonBit Graphviz record-label measurement API has no corresponding hook. This affects JSON/YAML and their shared TOML presentation. | Supply fixed-size HTML cells and named ports to the actual Graphviz engine. Ranking, crossing reduction, placement and spline routing still run in Graphviz. Differences caused by this upstream label interface are accepted; the former hand-positioned tree is not used. |
| `kokic/metrics@0.1.1` | Text measurement uses bundled advance tables and portable font profiles (`metrics/metrics.mbt`, `metrics/advance.mbt`), not the JVM's installed-font shaping engine. Custom fonts, fallback glyphs and complex scripts can therefore have different advances. | Keep layout and SVG text measurement consistent within the MoonBit implementation. Font-engine differences are accepted; they must not be used to excuse missing diagram layout stages. |

An `UnsupportedFeature` result from Graphviz remains an error at the API
boundary. Entity diagrams no longer silently substitute a grid. No failing
example should be called an upstream limitation without identifying the
dependency behavior that caused it.

## Explicitly deferred

`<math>` and `<latex>` formula embedding remain **unfinished**, as requested
on 2026-10-07. The reference uses a complete Java formula-layout engine. No
approximate formula renderer or new formula engine is included in this work.
This is a local missing capability, not an upstream Graphviz exception.

## Peripheral features moved out of the implementation

On 2026-10-08, peripheral implementations added during completion work were
moved to `.local/deferred-diagram-extras-2026-10-08/`. The archive contains source
snippets and a removal patch; it is not a buildable package or part of the
published library. Its README lists the affected files and retained boundaries.

The following additions are deferred: bundled themes; TIM variables, conditionals,
loops, functions and JSON builtins; include/resource loading and expanded-source
maps; inline images and sprite decoding (including DEFLATE); rich-text tables,
rules and hyperlinks; handwritten rendering; the shared gradient expansion;
and sequence/entity multi-page export. The optional `resources` argument and
`render_svg_pages` API have been removed. Existing simple `!define` processing,
inline font formatting, original hyperlink support and state gradients remain.
Sequence rendering uses the complete diagram layout in one SVG again.

TOML and MBTI are project extensions, not PlantUML diagram types. MBTI's type
forest deliberately chooses tree edges and omits extra parent relations and
cycles; this is its existing display model, not a complete type-dependency graph.

## Verification boundaries

After extraction, `moon check` passed and 305 existing parser, style, graphics
and layout tests passed. The root package README tests had 9 whole-SVG snapshot
mismatches out of 11 tests; those snapshots were not updated.
No SVG files or reference snapshots are regenerated during this extraction.
Passing compilation and tests does not certify visual or pixel equivalence.

The newly added temporary verification tests are stored in the local archive,
including the duplicated example smoke test. Pre-existing tests remain in place.
