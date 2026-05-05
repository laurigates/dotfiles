# Local ↔ CI Parity

**Aspiration, not a hard rule.** When adding or changing a quality gate (linter, formatter, type check, test tier), prefer configurations where the local command and the CI step run the same checks. This prevents the "passes locally, fails in CI" footgun.

## Concrete patterns that help

- A `just lint` / `just test` (or `make`/`npm run`) recipe that invokes the *same* command as the corresponding CI step. If CI runs both `ruff check` and `ruff format --check`, the local recipe should too — not just one.
- Pre-commit hooks mirror the CI lint/format jobs so `pre-commit run --all-files` catches what CI would catch.
- When CI adds a new check, update the matching local recipe in the same PR.

## Known-acceptable deviations

Full parity isn't always feasible — heavy Playwright suites, integration tests requiring external services, or long-running security scans may be CI-only. When diverging intentionally:

- Note it in the recipe comment or the job, so the next person understands the gap.
- Prefer a lighter local variant (e.g. `just test-unit` locally, full suite in CI) over nothing.
- Track "fix properly" work as an issue when the divergence is a temporary workaround (e.g. runner capacity), not a permanent design choice.

Don't enforce parity strictly during reviews — surface the gap, suggest a lighter local equivalent, and move on.
