# `gh-pages` — benchmark data only

This branch is a **data store**, not a website. GitHub Pages is not enabled for
this repository; nothing here is served.

`.github/workflows/benchmarks.yml` runs `benchmark-action/github-action-benchmark`
on every push to `main`. That action keeps its historical series under
`dev/bench/` on this branch and appends one commit per run, which is what lets it
compare a run against previous ones and alert at the workflow's 150% threshold.

Without this branch the action fails at `fetch ... gh-pages:gh-pages` with
`couldn't find remote ref gh-pages`, before it measures anything — which is how
`Performance Benchmarks` came to fail on every push to `main` until 2026-09-22.

Do not commit here by hand; the action owns `dev/bench/`.
