---
id: ADR-0020
status: Accepted
created: 2026-11-11
modified: 2026-11-11
deciders: "Lauri Gates"
domain: plugin-management
relates-to: [ADR-0005, ADR-0003]
---

# ADR-0020: Marketplace Plugins with a Project-Level Pin

## Context

ADR-0005 organised commands by namespace inside this repository. Skills,
commands and agents have since moved to the
[laurigates/claude-plugins](https://github.com/laurigates/claude-plugins)
marketplace, which is why ADR-0005 is Superseded. That left two questions for
this repository: which plugins are active here, and how the installed
marketplace stays current.

In 2026-05 the project `.claude/settings.json` listed every marketplace plugin
with an explicit `true` or `false` (#210). In 2026-06 the list was made
exhaustive again after four new plugins were missing from it (#286). That
change was justified by the belief that a project `enabledPlugins` map replaces
the global map as a whole, so a plugin missing from the project map would be
disabled.

The current `configure-claude-plugins` reference (configure-plugin 1.43.4,
`references/settings-json.md`) describes different behaviour: `enabledPlugins`
merges per key across the settings hierarchy. A project entry overrides the
matching global entry, and global entries the project does not mention still
take effect. The project pin now lists 44 plugins and the marketplace has 50
(`jq '.enabledPlugins | length' .claude/settings.json`; `marketplace.json` read
through `gh api` on 2026-11-11). One of the six unlisted plugins,
`linux-plugin`, loads in sessions in this repository, which agrees with per-key
merging.

Derived from commits e405c97 (#210, 2026-05-21), fac3a27 (#257), 74d441c
(#283), 2221a79 (#286) and e61d439 (#554, 2026-11-03).

## Decision

Skills, commands and agents come from the claude-plugins marketplace. The
project `.claude/settings.json` holds a pin that states this repository's
deliberate choices; it does not have to list every marketplace plugin.

- **The pin is a set of explicit overrides.** A `true` entry enables a plugin
  here whatever the global state. A `false` entry keeps a globally enabled
  plugin out of this repository. A plugin with no entry follows the global
  setting.
- **Exhaustive pinning is optional.** `/configure:claude-plugins --exhaustive`
  remains available when a repository needs a set that ignores every global
  toggle. New marketplace plugins do not require a pin update here.
- **The marketplace key is `laurigates-claude-plugins`**, equal to the
  marketplace `name`. `tests/test-claude-plugin-references.sh` fails on any
  other alias and on a `plugin@alias` naming a plugin the marketplace lacks.
- **Freshness is automated.** A debounced, detached SessionStart hook
  (`claude-plugins-refresh.sh`, 4 h) updates the marketplace, because Claude
  Code's own auto-update runs only at startup.
- **The baseline is policy.** `configure-plugin/policy/repo-baseline.json` in
  claude-plugins defines the required settings keys, and a reconciler opens PRs
  to bring this repository up to that floor (#554).

## Consequences

### Positive

- Plugin content is versioned and released in one place and shared by every
  repository.
- The pin records why a plugin is off here without needing maintenance each
  time the marketplace grows.
- Broken marketplace references fail a test before they reach a session.

### Negative

- With a non-exhaustive pin, a plugin enabled globally by accident is active
  here until someone adds a `false` entry.
- Web and CI sessions have no `~/.claude`, so only the project pin and the
  policy floor apply there. A plugin the pin does not list is off in those
  sessions.
- The per-key merge behaviour is taken from the configure-plugin reference and
  one observation in this repository. It has not been checked against Claude
  Code's own documentation for the installed version.

## Options Considered

### Option 1: Non-exhaustive project pin over a global default (chosen)

**Pros:** no update needed when the marketplace adds a plugin; the pin shows
only deliberate choices. **Cons:** global toggles leak into this repository.

### Option 2: Exhaustive pin, every plugin `true` or `false`

**Pros:** the plugin set is the same on every machine and in web sessions.
**Cons:** it drifts each time the marketplace adds a plugin (four behind in
2026-06, six behind in 2026-11). **Rejected because:** the reason given for it
in #286, whole-map replacement, does not match the behaviour the current
reference describes.

### Option 3: No project pin

**Pros:** nothing to maintain. **Cons:** web and CI sessions get no plugins,
and this repository cannot turn an irrelevant plugin off. **Rejected because:**
remote sessions need the project file to name the marketplace and its plugins.

## Related ADRs

- [ADR-0005: Namespace-Based Command Organization](0005-namespace-based-command-organization.md) — superseded by the marketplace this ADR builds on.
- [ADR-0003: Skill Activation via Trigger Keywords](0003-skill-activation-trigger-keywords.md) — skills delivered through the marketplace still activate this way.
- [ADR-0018: Byte Budget for Always-Loaded Claude Context](0018-always-loaded-context-budget.md) — rules promoted under that ADR become marketplace skills.
