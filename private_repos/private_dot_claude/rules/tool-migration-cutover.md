# Tool-Migration Cutover: Verify the Replacement Is *Operational* Before Deprecating the Incumbent

When migrating from one tool to another (Dependabot → Renovate, a PAT-based
workflow → a GitHub App, one linter/CI/runner → another), **do not remove the
incumbent until the replacement is observed actually doing the job** — not merely
*configured* to. "Config exists" and "config works" are different claims, and the
gap between them is where coverage silently drops to zero.

## The failure mode

The incumbent is removed on the strength of the replacement's *presence*:

1. The replacement's config is committed and looks correct.
2. Someone reasons "Renovate is set up, so Dependabot is redundant — remove it."
3. The replacement was never actually running (broken credentials, missing
   step, unprovisioned secret, quota), so **neither** tool is now doing the work.
4. The gap is invisible: no error fires for "nothing is updating dependencies."

Config presence is not evidence of operation. A scheduled runner can fail every
single run and leave no trace in the place you're looking (the repo's PR list
stays empty, which reads identically to "no updates needed").

## The rule

**Removal of the incumbent is gated on a positive operational signal from the
replacement**, observed on the *actual* target repos:

| Replacement | Positive signal to require before deprecating incumbent |
|---|---|
| Renovate | A successful runner execution **and** a Dependency Dashboard issue / `renovate/*` branch / PR on the target repo |
| A CI/lint tool | A green run of the new check on a real PR, not just the workflow file merged |
| A GitHub App replacing a PAT | A workflow run that successfully mints **and uses** the App token |
| A new deploy path | One real deploy through the new path that reaches the target |

Until that signal exists, **stage the deprecation as a draft** (draft PRs, an
un-merged branch, a feature-flag off) so the work is ready the instant the signal
lands — but cannot be merged prematurely by you or anyone else.

## How to check operation (don't trust config presence)

- **Runner actually ran and succeeded** — `gh run list --workflow=<f> -L 5`
  (all `failure` = it has never worked). Read the failed log; an ~8s failure at
  step 1 is usually a credential/token problem, a ~2s zero-step failure is
  usually quota.
- **Side effects appeared on the target** — the dashboard issue, the branch, the
  PR. `gh issue list --search "Dependency Dashboard in:title"`,
  `gh api repos/<o>/<r>/branches --jq '.[].name|select(startswith("renovate/"))'`.
- **Credentials/secrets are present where consumed** — the secret/variable on the
  consuming repo, not just "set upstream" (in Scalr/CI/a vault). The push from
  upstream to the repo is a separate step that can itself be blocked.

## Worked example — Dependabot → Renovate (Bun), 2026-06

The premise "Renovate already manages these repos, overlapping with Dependabot"
was false: the centralized autodiscover runner **failed every run** (unprovisioned
GitHub App → empty `app-id` → token mint failed), so Dependabot was the *only*
working dependency automation. Deprecating it then would have left 9 repos with
no updates. Correct sequence: fix the latent runner bug, **stage the 9
`dependabot.yml` deletions as draft PRs**, hand off the (manual, user-only) App
provisioning, and gate the draft merges on a verified Renovate run.

Two Renovate/Bun facts that fell out of the same investigation, worth not
re-deriving:

- **There is no bun `postUpdateOptions` value** (`bunDedupe` does not exist;
  allowed values are npm/pnpm/yarn/bundler/go/nuget only). An invented value
  fails Renovate's `allowedValues` validation and breaks the **whole config** —
  for the *global* self-hosted config, that breaks every repo. Verify enum values
  against the Renovate docs before adding them.
- Renovate updates and commits `bun.lock` **natively** when it patches
  `package.json` (it runs the package manager and commits both). No option is
  needed for "generate a matching lockfile"; `lockFileMaintenance` is the
  separate periodic full-refresh.

## When it bites

- Dependency-bot swaps (Dependabot ↔ Renovate), where "no PRs" looks the same
  whether the tool is off or just has nothing to do.
- Credential/secret migrations where the value is set in the orchestrator
  (Scalr, a vault, org secrets) but the *push to the consuming repo* hasn't run.
- CI tool replacements merged as a workflow file but never exercised on a PR.

## Rationale

Removing a working tool is cheap to do and expensive to discover undone — the
loss is a *non-event* (updates that silently stop happening), so nothing alarms.
Gating on a positive operational signal, and staging the removal as a draft in
the meantime, costs one extra "is it actually running?" check and converts a
silent multi-week coverage gap into a no-op wait. This is the migration-time
sibling of `verify-upstream-before-patching.md` (check reality before acting) and
`ci-cd-multirepo.md` (fetch-first before diagnosing CI).
