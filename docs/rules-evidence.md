# Evidence Behind the User-Global Rules

The rules in `exact_dot_claude/exact_rules/` (rendered to `~/.claude/rules/`)
load on every turn, so they carry the invariant and link here for the dated
incidents and measurements that justify it.

## agent-and-tool-selection.md — model selection

> 2026-06 (dotfiles #237): Opus 4.8 at low effort beat Sonnet 4.6 at high effort
> on quality and token efficiency. That result set the earlier Opus-only floor.
> It compared those model versions and says nothing about later ones.
>
> 2026-09-30 (FVH `infrastructure`): Sonnet 5.5 and Opus 5.5 got identical
> read-only briefs against a frozen snapshot, at the same default effort, graded
> against defects verified before the runs.
>
> | Task | Sonnet 5.5 | Opus 5.5 |
> |---|---|---|
> | Diagnosis: why a classifier resolves nothing (4 known causes) | 4/4 | 4/4 |
> | Review of three recipes (12 known defects) | 10/12 | 12/12 |
>
> Token use was within 3% on both tasks, and neither run made a false claim.
> Sonnet's one unique review find was a latent crash under macOS bash 3.2.
> Opus's unique finds included the recipe's silent exit without a terminal, and
> a plausible pattern (`client.id`) that would have rotated 14 third-party OAuth
> client IDs. A separate Sonnet 5.5 implementation task (infrastructure
> #2517–#2519) held on every claim re-run against the pushed branches. Four graded runs, scored by an Opus session, are
> a small sample. Re-run the comparison when either model changes.
>
> 2026-10-14 (claude-plugins #3088–#3090): three Sonnet 5.5 implementers at
> `high` effort, each followed by a fresh Sonnet verifier that re-ran the gates
> against the pushed branch. Not every claim held. A verifier caught a new helper
> reporting an unrunnable gate (exit 127) as a caught mutation, and one
> implementer's follow-up put a hook's timeout headroom at about 1 s when the
> worst case overran the 5 s budget by about 3 s; the main loop found that while
> checking the follow-up before filing it (claude-plugins #3093). The run had no
> Opus arm and was not graded.
>
> 2026-10-10 (claude-plugins `docs/audits/haiku-5.5-reevaluation-2026-10-10.md`):
> 16 Haiku 5.5 classifiers at `medium` effort sorted claude-plugins skills, agents,
> workflow harnesses and GitHub workflows into `haiku`, `haiku-stage`,
> `needs-test` or `keep`. 6 Opus 5.5 verifiers at `high` re-read the files
> behind all 204 non-`keep` verdicts and a control sample of 49 `keep` verdicts.
> Opus confirmed 93 of the 204 (46%), adjusted 38 and rejected 73; all 49
> control `keep` verdicts held. The verifiers found the files had been read,
> with concrete details checking out line by line. Most rejections came from one
> misreading (a skill's `model:` override lasts for the rest of the turn), and
> the classifier often listed a risk and assigned `haiku` anyway. No agent or
> GitHub workflow reached `haiku`.

## copy-paste-commands.md — incidents

- **Hidden input under `!` (2026-11-04):** `! gh secret set NAME -R <repo>`
  with no `--body` stored an **empty** secret, and nothing failed until the
  workflow that read it did.
- **Clipboard command pasted back (2026-11-10):** `pbpaste | gh secret set
  PORTFOLIO_ACTIONS_READ` pasted back with its output replaced the token with
  that text, and the workflow reading it failed 20 s later.
- **One action per call (2026-10-28):** Lauri rejected a Bash call that created
  five test files, ran a heredoc into a Python probe and printed the results in
  one command — "that command was too complex to understand or even read". It
  was redone as one action per call plus a commented script run by one command.
  Later in the session compound one-liners hit zsh four times (`set -- $spec`
  and an unquoted `$cmd` not word-splitting, a bare `=====` taken as a command
  lookup, a glob with no matches aborting an `ls` under `nomatch`), `rg -rn`
  read `-r` as `--replace`, and a trailing `&` backgrounded a whole `&&` chain
  over ssh. Writing the multi-step and remote work as bash scripts avoided all
  of them.

## CLAUDE.md § PR Reviews — blockers

> 2026-09 (R4C-Cesium-Viewer #959): a delegated review returned **DO NOT
> MERGE** on three blockers. Each died to one read — `tsconfig.json` sets
> `checkJs: true`, the "missing symbols" list was an exact match against
> `src/`, and the claimed "1–3% bundle gain" was a measured −13.95%.
