# Back-Port Instance Fixes Into Their Scaffold/Generator

Promoted to a skill: invoke `code-quality-plugin:code-scaffold-backport` when
fixing, reviewing, or auditing a file that a generator emitted — a cookiecutter
or copier template, a justfile `new-*` recipe, a scaffolding skill, or a "copy
the example app" doc. It carries the three-step failure shape (instance fixed →
generator still emits the bug → next generation reproduces it), the
fix/review/audit rules, the list of where generators hide, the
generate-a-throwaway-and-diff verification, and the cost-asymmetry rationale.
