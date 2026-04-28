# Visualization & Diagrams

Reach for a diagram when the **relationships are the answer**. When structure
or flow *is* the explanation, prose is the long way around — sketch it.
Default to **D2** (rich layouts, SQL/class shapes, themes); fall back to
Mermaid only when the diagram needs to render natively in GitHub Markdown.

## When To Use a Diagram

Diagram if **two or more** of these are true:

- **3+ entities with relationships** — components, services, tables, actors
- **Temporal flow** — request/response, event chain, lifecycle
- **Hierarchy or containment** — nesting, namespaces, module trees
- **Branching logic** — decisions with multiple terminal states
- **Topology** — networks, dependency graphs, data flow
- **User says** "show me", "draw", "diagram", "visualize", "what does X look like"

## When *Not* To Use a Diagram

- The answer is a single concept, definition, or one-liner
- The flow is linear (`A → B → C`) — a sentence is faster
- Numerical or feature comparison — use a table
- Code is the better medium — a 5-line snippet beats a 5-box diagram
- The diagram would just restate the prose without adding structural insight

## Problem → Diagram Routing

| Problem type                                  | Diagram form              | D2 building blocks                              |
| --------------------------------------------- | ------------------------- | ----------------------------------------------- |
| System architecture, components & links       | Block / box-and-arrow     | rectangles + containers + icons; `direction: right` |
| Request/response between actors over time     | Sequence-like flow        | numbered arrow labels (`1. POST /foo`)          |
| Branching logic, decision points              | Flowchart / decision tree | `shape: diamond` decisions, `shape: oval` terminals, colored Yes/No edges |
| State machines (lifecycle, FSM)               | State diagram             | rectangles + labeled edges, self-loops          |
| Database schema, table relations              | ERD                       | `shape: sql_table` + FK arrows (`a.id <-> b.a_id`) |
| Class structure, OO model                     | Class diagram             | `shape: class` with `+/-/#` field prefixes      |
| Network / cluster topology (k8s, services)    | Topology                  | nested containers + `cylinder`/`cloud`/`hexagon` |
| Dependency graph, build/import topology       | DAG                       | `direction: down`, glob edge styling            |
| File / directory hierarchy                    | Tree                      | nested containers, `direction: right`           |
| Code path / call graph                        | Call graph                | rectangles + labeled edges                      |
| Pipeline / CI/CD stages                       | Pipeline                  | `shape: step` chain                             |
| Algorithm walkthrough, pseudocode in context  | Code-in-diagram           | `code: \|lang ... \|` block as a node           |
| Comparison of two architectures               | Side-by-side layers       | `layers:` block with two named layers           |

For full D2 syntax, see the `tools-plugin:d2-diagrams` skill (`SKILL.md` +
`REFERENCE.md`). Use `direction: right` for left-to-right reads and the `elk`
layout for dense graphs.

## Delivery

Claude Code can't render images inline — Bash output is captured as tool
result, not passed to the terminal. So:

1. Write the source to `/tmp/<name>.d2` (or alongside related code if the
   diagram belongs in the repo, e.g. `docs/diagrams/<name>.d2`).
2. Render with `d2 /tmp/<name>.d2 /tmp/<name>.svg` (or `.png` if the user
   needs a raster).
3. Tell the user the path, and — when on kitty — suggest they run
   `! kitty +kitten icat /tmp/<name>.png` so the `!`-prefix executes in
   *their* shell where the graphics protocol works.
4. For diagrams that live in a repo, commit `<name>.d2` + `<name>.svg`
   together so the source and the rendered artifact stay in sync.

## Rationale

Most explanations are prose-shaped. A diagram earns its keep when relationships
are dense enough that prose forces the reader to reconstruct a graph in their
head. The routing table above is the shortcut: match the problem type, pick
the form, write the D2.
