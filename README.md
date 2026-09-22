# `gh-pages` — benchmark data

`.github/workflows/benchmarks.yml` runs `benchmark-action/github-action-benchmark`
on every push to `main`. That action keeps its historical series under
`dev/bench/` on this branch and appends one commit per run, which is what lets it
compare a run against previous ones and alert at the workflow's 150% threshold.

Without this branch the action failed at `fetch ... gh-pages:gh-pages` with
`couldn't find remote ref gh-pages`, before it measured anything — which is how
`Performance Benchmarks` came to fail on every push to `main` until 2026-09-22.

## This branch is served publicly

Pushing it auto-enabled GitHub Pages (`build_type: legacy`), which serves this
branch's root at <https://laurigates.github.io/dotfiles/> — the benchmark chart
plus this file. That was a side effect of creating the branch, not a deliberate
choice, and it was kept because the dashboard is the point of the 150% alert
threshold. The REST API refuses to deactivate Pages here (HTTP 422); unpublishing
needs Settings → Pages.

Only this branch is served. Nothing from `main` is, and the data is commit
metadata plus timing numbers that are already public on the repository.

Do not commit here by hand; the action owns `dev/bench/`.
