window.BENCHMARK_DATA = {
  "lastUpdate": 1790053645786,
  "repoUrl": "https://github.com/laurigates/dotfiles",
  "entries": {
    "Benchmark": [
      {
        "commit": {
          "author": {
            "email": "lauri.gates@gmail.com",
            "name": "Lauri Gates",
            "username": "laurigates"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "43fd03dc0ff5c66d653a5fc2adb0e30f8f33b33d",
          "message": "fix(ci): point setup-homebrew at main, not the deleted master branch (#430)\n\n## What\n\nRepoint `Homebrew/actions/setup-homebrew` from `@master` to `@main` in\n`smoke.yml` (two jobs), `coverage.yml`, `sbom.yml` and `claude.yml`.\n\n## Why\n\nHomebrew/actions renamed its default branch to `main` and deleted\n`master`. Every job pinned to `@master` now fails during action\nresolution, before a single step runs:\n\n```\n##[error]Unable to resolve action `Homebrew/actions@master`, unable to find version `master`\n```\n\nThat is the entire cause of the three red checks on every recent PR —\nLinters, Generate SBOM, Generate Coverage Report. #426 was merged over\nexactly these three, and #428 currently carries the same set.\n\n`benchmarks.yml` already pointed at `@main` and stayed green throughout,\nwhich is the control that separates \"the action ref is stale\" from \"the\nrepo's checks are broken\".\n\n## Verification\n\n`gh api repos/Homebrew/actions --jq .default_branch` returns `main`, and\nthe branch listing contains only `main`. `actionlint` exits 0 on the\nedited tree. All four workflows trigger on `pull_request`, so this PR's\nown checks exercise the fixed refs.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01M3uSDgzvBymKnJWgmMy8u1\n\nCo-authored-by: Claude Opus 5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-21T09:15:07+03:00",
          "tree_id": "34fc073f035cb2090e4d251a00eab2d14e1908bc",
          "url": "https://github.com/laurigates/dotfiles/commit/43fd03dc0ff5c66d653a5fc2adb0e30f8f33b33d"
        },
        "date": 1790053484842,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.0057703449533333335,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00126368534,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.00099338154,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.00806625634,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "lauri.gates@gmail.com",
            "name": "Lauri Gates",
            "username": "laurigates"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "0740ac28b26d237e81b2f0ccf6febcb483f5af9f",
          "message": "refactor(claude): promote four zsh rules into tools-plugin:zsh-gotchas (#431)\n\n## What\n\nReplace four always-loaded zsh rules with one pointer stub, and record\nthe measurement in the budget script's ledger.\n\n```\nexact_dot_claude/rules/zsh-colon-modifiers-after-variables.md   2,123  deleted\nexact_dot_claude/rules/zsh-equals-expansion.md                  1,846  deleted\nexact_dot_claude/rules/zsh-no-word-splitting.md                 2,455  deleted\nexact_dot_claude/rules/zsh-special-variables-path.md            2,819  deleted\nexact_dot_claude/rules/zsh-gotchas.md                           1,486  new stub\n```\n\nFull content moves to `tools-plugin:zsh-gotchas` —\nlaurigates/claude-plugins#2709, which must merge first.\n\n## Why\n\n#428 took the always-loaded surface to **105,649 of 104,000**, so\n`origin/main` is currently red on the `claude-context-budget` pre-commit\nhook (`Linters` job in Smoke Test CI). The three options were bump,\ndistil in place, or promote.\n\n`tests/test-claude-context-budget.sh`'s own ledger argues against the\nbump: it records the 2026-08-09 entry as justified \"on a premise that\nwas false\", and the 2026-09-12 entry as deferring 6,091 bytes of\nuntriaged debt with `NO cleanup is claimed here`. This PR repays that\ndebt rather than adding to it.\n\nThe four are one family — expansions with no bash equivalent that\nrewrite an ordinary command, three of them silently — so they promote as\na unit.\n\n## What stays always-loaded, and why that much\n\nThe stub keeps the **symptom → mechanism routing table** and nothing\nelse. That is the part which cannot be on-demand: three of the four\nmisattribute, so the error text never names the cause, and an agent that\nhas only seen `command not found: tail` has no reason to reach for a\nskill about `path`. The evidence, the fixes and the probes are what\nmove.\n\n## Measurement\n\nMeasured on disk in a clean worktree off `origin/main`:\n\n```\nbefore = 105,649   (44 unconditional rules)    FAIL, -1,649 over\nafter  =  97,892   (41 unconditional rules)    PASS, 6,108 free\npath_scoped_bytes = 58,140  (unchanged; not counted)\n```\n\n`TOTAL_BUDGET_BYTES` stays **104,000**. The 6,108 bytes free is 6.2% —\nthe margin the last two ledger entries chose deliberately (5,537 / 6.4%\nand 5,401 / 5.9%) for the stated reason that a razor-thin margin\ndestroys the gate's signal. Ratcheting to ~103,800 would move the number\nwithout changing what the gate does, so the entry records the cleanup\ninstead.\n\n## Verification\n\n- `tests/test-claude-context-budget.sh` → `PASS=4 FAIL=0 STATUS=PASS`\n- `scripts/check-doc-references.py` → `DANGLING_COUNT=0`. All\ncross-references to the four deleted files were *among* the four\nthemselves; the surviving `zsh-pattern-expansion-extended-glob.md`\n(path-scoped, unaffected) is still referenced by the new stub and by the\nbudget script's allowlist.\n- `shellcheck tests/test-claude-context-budget.sh` clean.\n\n## Follow-up\n\n`~/.claude/rules/` is a plain subdirectory of `exact_dot_claude/`, so it\ndoes not purge: the four deleted sources leave orphaned targets that\nkeep loading. They need deleting by hand after apply, which I'll do on\nthis machine once this merges.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01M3uSDgzvBymKnJWgmMy8u1\n\nCo-authored-by: Claude Opus 5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-21T14:45:40+03:00",
          "tree_id": "0bbff2f6e544efff8ed7f3998737cec07edb5b47",
          "url": "https://github.com/laurigates/dotfiles/commit/0740ac28b26d237e81b2f0ccf6febcb483f5af9f"
        },
        "date": 1790053645122,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.008173731173333332,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00152591446,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012617038600000003,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.01098115358,
            "unit": "s"
          }
        ]
      }
    ]
  }
}