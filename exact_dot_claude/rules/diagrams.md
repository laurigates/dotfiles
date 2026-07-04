# Visualization & Diagrams

Reach for a diagram when the **relationships are the answer** — 3+ entities
with relationships, temporal flow, hierarchy, branching logic, or topology.
Skip it when the answer is a definition, a linear `A → B → C` (a sentence),
a comparison (table), or a 5-line snippet (code).

Default to **D2**; fall back to Mermaid only when the diagram must render
natively in GitHub Markdown. The problem-type → diagram-form routing table,
D2 building blocks, and full syntax live in the `tools-plugin:d2-diagrams`
skill — invoke it before authoring.

Delivery: Bash can't render images inline. Write the `.d2` source (in
`/tmp/`, or `docs/diagrams/` if it belongs in the repo), render with
`d2 <src> <out>.svg`, and tell the user the path — on kitty, suggest
`! kitty +kitten icat <out>.png`. Commit `.d2` + rendered output together
when repo-resident.
