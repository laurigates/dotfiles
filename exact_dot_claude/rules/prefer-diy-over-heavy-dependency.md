# Prefer a Transparent DIY Reimplementation Over a Heavy Single-Purpose Dependency

Promoted to a skill: invoke `software-design-plugin:design-diy-vs-dependency`
before depending on a heavy single-purpose tool — a GUI wrapping a mechanical
operation, a bundled runtime, an unaudited or non-cross-platform binary — it
carries the trigger list, the DIY-vs-keep decision criteria, and the
verify-against-an-authoritative-reference protocol (including the diff test
that catches divergence before it ships).

Not a mandate to always DIY — most of the time the existing tool is still the
right call — but the *evaluation* itself is never optional.
