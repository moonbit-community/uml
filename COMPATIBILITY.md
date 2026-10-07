# PlantUML compatibility

The implementation follows the Java checkout in `.local/plantuml`. Existing
reference SVGs in `live/public/examples/*/puml/` take precedence over source
constants. Java is not rebuilt or instrumented for compatibility work.

The current completion scope is the README's `done` diagrams: Class, Object,
Component, Deployment, Package, Use Case, Activity, State, Sequence, Mindmap,
JSON, YAML, DOT, TOML and MBTI. Timing and WBS retain their separately stated
status; changes to shared code must continue to support them.

This is a checkpoint of completed corrections, not a claim that every syntax
and presentation option in those diagram families has been fully implemented.
The unfinished legacy Activity parser and its State/DOT integration are excluded
from this checkpoint and remain in the working tree. Full TIM/source mapping,
entity pagination and `layout newline`, complete stereotype style cascading,
and some advanced modern Activity action/note forms still need follow-up.

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

## Input and output APIs

`api.parse`, `api.render_svg` and `api.render_svg_pages` accept an optional
`resources : Map[String, String]`. Includes are resolved from this map, keeping
the library synchronous and independent of filesystem/network access. The
caller supplies resource contents instead of relying on implicit I/O.

Sequence `newpage` creates independent SVG pages. `render_svg` returns the
first page; `render_svg_pages` returns all pages. Participant columns, message
numbering and activation state are maintained across pages. `ignore newpage`
suppresses page boundaries. `autonewpage` preserves the reference implementation's
current no-op behavior.

TOML and MBTI are project extensions, not PlantUML diagram types. MBTI's type
forest deliberately chooses tree edges and omits extra parent relations and
cycles; this is its existing display model, not a complete type-dependency graph.

## Verification boundaries

Parser and layout checks use semantic properties: ownership and containment,
non-overlap, edge connectivity, direction and visibility, resource resolution,
page membership, retained fractional geometry, and deterministic rendering.
Temporary verification tests are removed after use. Existing tests remain.

The example corpus is exercised through the public API with SVG strings kept
in memory. Generated SVG files and README image snapshots are not refreshed;
visual comparison with the existing PlantUML reference images remains a separate
review. Passing compilation and these properties does not certify pixel identity.

Preprocessing supports the constructs used by the bundled themes and the
supported diagram sources. It is not a claim to reproduce every TIM builtin.
Diagnostics after multiline macro/include/theme expansion currently refer to
expanded source lines; preservation of complete source maps remains unfinished.
