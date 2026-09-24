---
paths:
  - "**/package.json"
  - "**/bun.lock"
  - "**/package-lock.json"
  - "**/yarn.lock"
  - "**/pnpm-lock.yaml"
  - "**/Cargo.toml"
  - "**/Cargo.lock"
  - "**/go.mod"
  - "**/go.sum"
  - "**/pyproject.toml"
  - "**/uv.lock"
  - "**/renovate.json"
---

# Two Copies of a Stateful Module Fight Each Other

A dependency tree can contain the **same library at two versions** without any
error, warning, or type failure. When that library keeps **module-level global
state** — a stack, a registry, a counter, a context map — the two copies each
own a private instance, cannot see each other, and treat the other's state as
foreign. They then actively fight, rather than merely duplicating work.

> The law: for a module holding global state, **duplication is not
> redundancy — it is two competing authorities**. Version-range satisfaction
> says nothing about this, because both copies are individually correct.

## Why it is invisible until it isn't

- **No build error.** Both copies typecheck; each satisfies its own range.
- **No import error.** Bundlers happily ship both.
- **Nothing names the real problem at runtime.** The failure surfaces as a
  recursion, a lost event, a wrong z-order, a stuck focus — far from the cause.
- **Lockfile diffs bury it.** A "pin dependencies" or lockfile-maintenance PR
  can fork a tree from 6 duplicated packages to 44 in one merge, and the diff
  reads as routine version bumps.

## Stateful vs. stateless duplicates

Only the stateful ones are bugs. Triage before spending time:

| Duplicate holds… | Verdict | Examples (React/Radix flavour) |
|---|---|---|
| A stack/registry/counter shared across instances | **bug** | focus-scope (focus-trap stack), focus-guards, dismissable-layer (layer stack), portal, presence, context providers |
| Code that inspects the identity of what it is handed (`isValidElement`, `instanceof`, symbol brands) | **bug** | slot |
| Pure functions, hooks, type-only helpers | harmless | id, compose-refs, `use-*` hooks |

The same split applies outside React: a duplicated logging *formatter* is fine;
a duplicated logging *root registry* is not. Ask two questions: "does this
module own a process-wide singleton?" and "does it check the identity of
values created elsewhere?" A yes to either makes a duplicate a bug.

`slot` holds no registry, which is why it once sat in the harmless row. That
was the wrong test: `Slot` checks its child with
`Children.count(children) === 1 && isValidElement(children)`, and element
identity does not survive two copies of the module. In thelma (2026-08-19),
`@radix-ui/react-slot` was in the tree at 1.2.3, 1.3.0 and 1.3.3, and a
`<Button asChild>` wrapping a single `<Link>` threw `Slot failed to slot onto
its children`, so `/admin/users` returned 500 on a cold server. The failure is
perturbation-sensitive: editing unrelated props or deleting a neighbouring
element changes the module graph and makes it vanish, so an HMR-driven bisect
blames whichever line was touched last. Bisect against a cold server and check
the lockfile before the component. The fix was an `overrides` pin on
`@radix-ui/react-slot` to the version `radix-ui` bundles, re-checked on every
`radix-ui` bump. Primitive wrappers that re-export `Slot` are suspect for the
same reason.

## Check the tree, not the intent

Enumerate duplicates mechanically — never reason from `package.json`:

```sh
python3 -c "
import re,collections
d=collections.defaultdict(set)
for _,p,v in re.findall(r'\"([^\"]*?)\": \[\"(@scope/[a-z-]+)@([0-9][0-9.]*)\"',open('bun.lock').read()): d[p].add(v)
print({k:sorted(v) for k,v in d.items() if len(v)>1})"
```

`npm ls <pkg>` / `bun pm ls --all` / `cargo tree -d` / `pip list` do the same
job per ecosystem. Compare the count against a known-good commit — a jump is
the signal.

## The usual root cause: mixing a meta-package with direct sub-packages

A library that ships **both** an umbrella package and individual sub-packages
(`radix-ui` vs. `@radix-ui/react-*`; `@aws-sdk/client-*` vs. bundles; Babel
presets vs. plugins) forks the moment the two drift. Depending on both is the
bug; the version bump only exposes it.

**Fix: pick one distribution and use it everywhere**, so the tree cannot fork
on a future bump. Pinning versions to match is whack-a-mole — it re-forks on
the next upgrade. Where a *transitive* dep pulls the other copy, an
`overrides`/`resolutions` pin to the version the chosen distribution bundles
settles it, and that pin must be updated whenever the parent is bumped (note it
in the config, since nothing enforces it).

## The diagnostic signature to recognise

Mutual interference tends to present as **runaway recursion**, because each
copy undoes the other and re-triggers it:

- Read the stack for **two frames from the same library at different paths**
  (`node_modules/X/...` and `node_modules/Y/node_modules/X/...`) — that pairing
  is the fingerprint.
- **A test suite can report every test passing and still fail the job.** A
  worker that dies on `RangeError: Maximum call stack size exceeded` (then
  heap OOM) is counted as an *unhandled error*, not a test failure. Under
  jsdom this compounds: `reportException` calls `console.error`, which needs
  stack it no longer has, so error *reporting* recurses too and floods the log.
- **Runtime and log size are themselves evidence.** Suspect this class when a
  suite's wall-clock or output balloons by an order of magnitude with no
  corresponding change in test count.

> Evidence (2026-08, thelma): a renovate "pin dependencies" PR moved
> `radix-ui` `^1.4.3 → 1.6.0`; because 15 direct `@radix-ui/react-*` deps also
> existed, duplicated primitives went 6 → 44. Two `react-focus-scope` copies
> (1.1.7 and 1.1.10) gave a nested `Dialog` > `AlertDialog` two independent
> focus-trap stacks that ping-ponged focus forever. **All 4,466 tests passed**
> while the job failed on one unhandled error; 679 MB of log, 709 s runtime.
> Unifying on the meta-package took it to 9 duplicates (all stateless) and 27 s.

## Related

- `diagnose-at-the-failure-point.md` — measure at the failing call site rather
  than theorising; the duplicate count *is* that measurement here.
- `verify-upstream-before-patching.md` — check whether the upgrade, not your
  code, is the change that broke things.
- `tool-use-patterns.md` — the family trait: output that is well-formed and
  confident while not meaning what it appears to.
