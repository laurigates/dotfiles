---
reviewed: 2026-11-06
paths:
  - "**/CHANGELOG.md"
  - "**/package.json"
  - "release-please-config.json"
  - ".release-please-manifest.json"
  - "**/pyproject.toml"
  - "**/Cargo.toml"
---

# Release-Please Automation

Promoted to a skill: invoke `git-plugin:release-please-protection` before
editing a changelog or a version field, bumping a version, or wiring a version
file into a generated, committed artifact.

Inline invariant: never edit a release-please-managed file by hand — any
`CHANGELOG.md`, the version field of a manifest (`package.json`,
`pyproject.toml`, `Cargo.toml`, `plugin.json`), or the release-please config
and manifest. The version comes from conventional commits (`feat:` minor,
`fix:` patch, `!`/`BREAKING CHANGE:` major) via the release PR. Override steps
are the human operator's to run, never Claude's.
