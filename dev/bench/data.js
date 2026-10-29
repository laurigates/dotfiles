window.BENCHMARK_DATA = {
  "lastUpdate": 1793274634031,
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
          "id": "a95de74b73f975b2a78e3b402040eb0f1ff2469c",
          "message": "feat(zsh): shadow macOS bsdtar with GNU tar for Linux/CI parity (#432)\n\n## What\n\nPrepends Homebrew's `gnu-tar` gnubin directory to `PATH` on macOS, so\n`tar` resolves to GNU tar 1.35 instead of the system bsdtar.\n\n## Why\n\nmacOS ships bsdtar (libarchive) as `/usr/bin/tar`. I probed the\ninstalled `bsdtar 3.5.3` directly and cross-checked every result against\nits man page — these GNU flags are simply absent:\n\n| Capability | GNU flags | Present in bsdtar 3.5.3 |\n|---|---|---|\n| Tarbomb guard | `--one-top-level` | no |\n| Reproducible archives | `--sort=name`, `--mtime=`, `--clamp-mtime` |\nno |\n| Archive surgery | `--delete`, `--concatenate` | no |\n| Incremental backups | `--listed-incremental` | no |\n| Overwrite policy | `--overwrite`, `--skip-old-files`, `--backup` | no\n|\n\nThe immediate motivation was the first row. Extracting an archive whose\nmembers sit at the root spills them into the current directory, and the\nflag that prevents it doesn't exist here. The broader motivation is that\nubuntu runners have GNU tar, so a `tar` invocation that works in CI can\nfail locally and vice versa.\n\nNot gaps, and worth recording so nobody \"fixes\" them later:\n`--transform` has a bsdtar equivalent in `-s`, and `-u`/`--update` and\n`--no-recursion` are both supported.\n\n## How\n\nTwo placement details, both load-bearing:\n\n- **Prepended, not appended.** `path+=(...)` would land gnubin behind\n`/usr/bin` and the shadow would silently do nothing.\n- **Above `mise activate`**, per the rule this file already documents,\nso the established order holds: `mise > gnubin > brew > system`. mise\ndoes not manage tar, so nothing contends.\n\nGuarded on the directory existing, so a machine without `gnu-tar`\ninstalled is unaffected.\n\n## Trade-off accepted\n\nGNU tar drops the macOS xattrs/ACLs that bsdtar stores in pax headers,\nand cannot read zip/7z/iso. `/usr/bin/tar` stays available for those,\nand the comment in the file says so. I checked the tree first: nothing\nuses `tar -s`, `--mac-metadata`, `COPYFILE_DISABLE`, or reads a zip\nthrough `tar`, so nothing regresses.\n\n## Verification\n\n- Fresh `zsh -ic` resolves `tar` to `.../gnu-tar/libexec/gnubin/tar`,\nreporting `tar (GNU tar) 1.35`\n- `tar --one-top-level=out -xzf <tarbomb>.tar.gz` wraps correctly end to\nend\n\n`tests/test-shell-precedence.sh` reports 29 failures on this branch, all\npre-existing and unrelated: every one is `~/.cargo/bin` shadowing a\nmise-managed Rust tool. `.cargo/bin` sits at PATH index 8, interleaved\ninside mise's own entries, while gnubin lands at index 77 — and gnubin\ncontains exactly two symlinks, `tar` and `man`, neither of which appears\nin the failure list. Worth a separate look, since `.cargo/bin` is not\nadded by this file at all.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_013G6Px3PdxeXEjihCjyQCKp\n\nCo-authored-by: Claude Opus 5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-22T17:11:28+03:00",
          "tree_id": "f6d36a35133965a9dcfef1211c97a0e8ed494b92",
          "url": "https://github.com/laurigates/dotfiles/commit/a95de74b73f975b2a78e3b402040eb0f1ff2469c"
        },
        "date": 1790086326213,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.008287842420000002,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00151497472,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012512151200000001,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.012547189019999998,
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
          "id": "be2fd3bdbd2436517d623673082bb10ecdfa4a7a",
          "message": "fix(scripts): use portable sed -i.bak in update-command-references (#433)\n\n## What\n\n`scripts/update-command-references.sh` rewrites references with `sed -i\n'' \"s|…|…|g\"`. That spelling is BSD-only. This switches it to `sed\n-i.bak` plus an immediate `rm -f`.\n\n## Why\n\nGNU sed's `-i` takes an *optional suffix that must be attached*, so `-i\n''` parses as `-i` with no suffix and the `''` becomes the script. The\nreal script is then read as a filename:\n\n```\n$ sed -i '' 's|a|b|g' file     # GNU sed 4.9\nsed: can't read s|a|b|g: No such file or directory\nexit=2\n```\n\nThe script runs under `set -euo pipefail`, so on a Linux machine it\naborts rather than doing the rewriting it exists to do. Dotfiles are the\none repo most likely to be cloned onto a Linux box, which is what makes\nthis worth fixing rather than noting.\n\n`-i.bak` is the only in-place spelling both implementations accept.\nMeasured on both:\n\n| Invocation | BSD sed (macOS) | GNU sed 4.9 |\n|---|---|---|\n| `sed -i '' 's/a/b/' f` | works | exit 2, file unchanged |\n| `sed -i 's/a/b/' f` | exit≠0, file unchanged | works |\n| `sed -i.bak 's/a/b/' f` | works | works |\n\n## Why not `perl -i -pe`\n\nIt is the tidier one-liner and is equally portable, but this call site\nbuilds its pattern from shell-escaped content (`$old_escaped`,\n`$new_escaped`, escaped for sed's BRE by the two lines directly above\nit). Perl's regex dialect has different escaping rules, so swapping\nengines would mean re-deriving that escaping. `-i.bak` changes only the\nflag spelling and leaves the substitution byte-identical.\n\n## Verification\n\n- `bash -n scripts/update-command-references.sh` passes\n- Both spellings exercised against real GNU sed 4.9 in a container and\nBSD sed on macOS\n- Repo pre-commit suite passes\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_013G6Px3PdxeXEjihCjyQCKp\n\nCo-authored-by: Claude Opus 5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-22T17:12:07+03:00",
          "tree_id": "6e65174ccdf6aee163921603c96a7d26af617f78",
          "url": "https://github.com/laurigates/dotfiles/commit/be2fd3bdbd2436517d623673082bb10ecdfa4a7a"
        },
        "date": 1790086371539,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.008254833833333334,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00152961462,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012411460200000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.011070930980000001,
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
          "id": "a00191306f42c2b83630a263f502eca5603a2483",
          "message": "fix(ci): authenticate pre-commit hook installs against the GitHub API (#435)\n\n## What\n\nCI jobs that run pre-commit now give it an authenticated path to the\nGitHub REST API. A new regression check fails any workflow job that\ncalls api.github.com through a tool without a credential that tool\nreads.\n\nFixes #434\n\n## Why\n\nStyLua's `stylua-github` hook (`.pre-commit-config.yaml`, rev v2.1.0) is\n`language: python`, and its wheel is built by release-gitter.\nrelease-gitter lists releases with\n`requests.get(remote.get_releases_url(), headers={\"Accept\":\n\"application/json\"})` (release_gitter.py:233-238) and reads no token\nvariable. Nothing caches `~/.cache/pre-commit`, so every Linters run\nmakes this call anonymously and it counts against the runner IP's 60/h\nlimit, which hosted runners share. 3 of 432 Smoke runs since the hook\nlanded failed with `403 Client Error: rate limit exceeded for url:\nhttps://api.github.com/repos/JohnnyMorganz/StyLua/releases`, most\nrecently 35728723228.\n\nThe fix proposed in the issue, setting `GITHUB_TOKEN`, has no effect.\nThe triage ran release-gitter 3.1.3's own `fetch_release` with\n`GITHUB_TOKEN`, `GH_TOKEN`, `GITHUB_API_TOKEN` and\n`HOMEBREW_GITHUB_API_TOKEN` set. The response still reported\n`X-RateLimit-Limit=60` and no `Authorization` header was sent. The\nfailing step in 35728723228 already had `HOMEBREW_GITHUB_API_TOKEN` in\nits env. requests does read `$NETRC` (else `~/.netrc`) when no auth is\npassed. The triage then ran an end-to-end A/B of the `stylua-github`\ninstall with a fresh `PRE_COMMIT_HOME`. With `NETRC` set, the install\nmade 1 authenticated API call. Without it, the install made only\nanonymous calls. So the variable reaches release-gitter through pip's\nisolated build.\n\n## How\n\n- `.github/scripts/github-api-netrc.sh` writes `machine api.github.com\nlogin x-access-token password <token>` to\n`$RUNNER_TEMP/github-api.netrc` under `umask 077`, which gives mode 600\noutside the workspace. It then appends `NETRC=<path>` to `$GITHUB_ENV`.\nThe token is written with the `printf` builtin, so it never appears in a\nprocess argv or in the log.\n- The script then calls `/rate_limit` through the netrc and fails the\nstep unless `.resources.core.limit > 60`. That call does not count\nagainst the limit. A rejected credential does not produce an HTTP error\nhere: locally, an invalid token returned 200 with limit 60. The limit is\ntherefore the check, and a failure stops the job before pre-commit can\nfall back to anonymous calls.\n- `smoke.yml` (Linters) and `claude.yml` (agent job) run the script with\n`GITHUB_TOKEN: ${{ github.token }}` before installing pre-commit. In\n`claude.yml` this adds no exposure: setup-homebrew already exports the\nsame token to every later step as `HOMEBREW_GITHUB_API_TOKEN`\n(setup-homebrew main.sh:172-174), and `allowed_non_write_users` is\nunset, so claude-code-action does not scrub subprocess env.\n- `tests/test-ci-github-api-auth.py` is wired as a local pre-commit hook\n(`language: python`, `additional_dependencies: [pyyaml]`, scoped to\n`.github/workflows/`, `.github/scripts/` and itself). It therefore runs\nin CI through the Linters job's `pre-commit run --all-files`. It parses\nevery workflow and fails when a job:\n- R1: runs or installs pre-commit (`pre-commit\nrun|install|install-hooks|try-repo|autoupdate`, `uses:\npre-commit/action`, or pip/pipx/uv/brew install) without `NETRC` in env\nor exported by an earlier step;\n- R2: runs `mise` without an earlier `jdx/mise-action` or a\n`MISE_GITHUB_TOKEN`/`GITHUB_API_TOKEN`/`GITHUB_TOKEN`;\n- R3: calls api.github.com with curl or wget and no\n`-u`/`-n`/`--netrc*`/`Authorization` on the command.\n\nRepo shell scripts invoked by a run step are scanned with it, so the\nhelper counts as the auth step. A 16-fixture self-test runs before every\nscan.\n\nThe check lives in `tests/`, which `.chezmoiignore` lists, so it never\ndeploys to `$HOME`. No pre-commit environment cache was added: a cache\nmiss, which happens on any hook bump, still needs the netrc. The cache\nis listed under Follow-ups.\n\n## Tests\n\nRED: the check run against the unfixed tree (be2fd3b plus the test\nfile):\n\n```\npython3 tests/test-ci-github-api-auth.py            # exit 1\nPASS self-test: 16 fixtures\nWORKFLOWS=13 JOBS=15 CONSUMERS=4\nFAIL R1 .github/workflows/claude.yml job `claude` step 5 `Install pre-commit`: runs or installs pre-commit without NETRC; ...\nFAIL R1 .github/workflows/smoke.yml job `lint` step 4 `Install Dependencies`: runs or installs pre-commit without NETRC; ...\nFAIL R1 .github/workflows/smoke.yml job `lint` step 5 `Run pre-commit`: runs or installs pre-commit without NETRC; ...\nSTATUS=FAIL\n```\n\nGREEN, after the fix:\n\n```\npython3 tests/test-ci-github-api-auth.py            # exit 0\nPASS self-test: 16 fixtures\nWORKFLOWS=13 JOBS=15 CONSUMERS=6\nPASS every GitHub-API consumer in CI carries a credential its tool reads\nSTATUS=PASS\n```\n\nThrough pre-commit, with only `smoke.yml` swapped back to its be2fd3b\ncontent: `pre-commit run ci-github-api-auth --all-files --verbose` exits\n1 with the two `smoke.yml` R1 lines. With the fixed file restored it\nexits 0.\n\nControls for the negatives:\n\n- A planted workflow (`pip install pre-commit && pre-commit\ninstall-hooks`, then `mise install` after mise-action, then an anonymous\n`curl -fsSL https://api.github.com/...` split over a `\\` continuation)\nis flagged R1 and R3, and not R2, via `--root`.\n- Mutating the check makes the self-test fail. A `pre-commit` subcommand\nregex that matches nothing gives 4 fixture failures. A `GITHUB_ENV`\nexport regex that matches nothing gives 2 fixture failures.\n- `github-api-netrc.sh` was run locally with scratch\n`RUNNER_TEMP`/`GITHUB_ENV` and a user token. It printed\n`{\"limit\":5000,...}`, exited 0, and wrote the netrc as `-rw-------`.\n  - With an invalid token it exits 1 with `core limit <= 60`.\n- With the netrc `machine` mutated to another host it exits 1 with `core\nlimit <= 60`.\n- requests, reading the netrc the script wrote, sent Basic auth and got\nlimit 5000. With `NETRC=/nonexistent` it sent no auth and got limit 60.\n\n## Other instances\n\n- `claude.yml` job `claude`: installs pre-commit for the agent\n(`claude-tools-config.json` allows `Bash(pre-commit:*)`). R1 flagged it\nat be2fd3b. Fixed in this PR.\n- `auto-fix-ci-failures.yml` calls `laurigates/.github`\n`reusable-auto-fix.yml@main`. At its current main that workflow installs\nneither pre-commit nor pip packages. The check skips `jobs.<id>.uses`\njobs because their steps live in another repo.\n- `jdx/mise-action@v4` in `smoke.yml` (Build jobs) and `benchmarks.yml`\nis already authenticated: `github_token` defaults to `github.token` and\nthe action exports `MISE_GITHUB_TOKEN`. R2 pins this.\n- Not in the check: brew. The api.github.com calls in its auto-update\n(`Library/Homebrew/cmd/update.sh`) run `--silent --max-time 3` and fall\nthrough on failure. They also read `HOMEBREW_GITHUB_API_TOKEN`, which\nsetup-homebrew sets on every Linux job. The triage's proposed R4 (Linux\nbrew without setup-homebrew) was dropped because no failure mode was\nshown for it.\n- Other hooks do not call the API: pre-commit-hooks and\nconventional-pre-commit install from PyPI, and actionlint and gitleaks\nbuild through the Go module proxy.\n\n## Verification\n\n- `shellcheck .github/scripts/github-api-netrc.sh`: clean.\n- `actionlint .github/workflows/smoke.yml .github/workflows/claude.yml`:\nclean.\n- `pre-commit run --all-files`: exit 0, including the new\n`ci-github-api-auth` hook, StyLua, actionlint and gitleaks. Both commits\nalso passed the commit hooks.\n- `ruff check --select E,F,W,B,UP tests/test-ci-github-api-auth.py`:\nclean.\n- Verified in this PR's Smoke Test CI (run 35829214635): with the\nActions `GITHUB_TOKEN`, the Linters step printed `api.github.com core\nrate limit via netrc: {\"limit\":5000,\"used\":0,\"remaining\":5000,...}`, and\nthe StyLua hook environment installed and passed. api.github.com accepts\nthe installation token through Basic auth.\n\n## Follow-ups\n\n- #447: exercise `claude.yml` once after merge; it has no `pull_request`\ntrigger, so this PR's CI does not run its new netrc step.\n- #440: cache `~/.cache/pre-commit` in the Linters job, with the other\nCI tools still resolved at run time.\n- IamTheFij/release-gitter#6: asks release-gitter to send `GITHUB_TOKEN`\n/ `GH_TOKEN` itself.\n- The \"Cache mise tools\" key in `smoke.yml` hashed files that do not\nexist; the chezmoi pin PR (#416, #418) removes those cache steps.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01Q6aDMonZX35gYM9ZsKUfPv\n\n---------\n\nCo-authored-by: Claude Opus 5.5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-23T10:02:23+03:00",
          "tree_id": "9331040b4898362add4c11ea3f839ee8f8d3cdb1",
          "url": "https://github.com/laurigates/dotfiles/commit/a00191306f42c2b83630a263f502eca5603a2483"
        },
        "date": 1790146983737,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.006337221053333334,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00123410598,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0009983925800000001,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.00914222206,
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
          "id": "d6d19c814d877e8700b0c5b91ec9272c7b81c25c",
          "message": "ci: pin chezmoi via .mise.toml and branch-ref actions to release SHAs (#449)\n\n## What\n\nCI stops taking chezmoi, mise and third-party actions from whatever\nupstream publishes at run time:\n\n- A new repo-root `.mise.toml` pins chezmoi to `2.72.2`. Every CI job\nthat needs chezmoi installs it with `jdx/mise-action`, and mise itself\nis pinned with `version: 2026.9.12`. The Docker smoke image installs the\nsame mise release (`MISE_VERSION=v2026.9.12`) and chezmoi from the same\nfile.\n- The smoke Build jobs no longer run their own `actions/cache` of\n`~/.local/share/mise`. Its prefix fallback would have restored main's\ncached mise over the pinned one.\n- `private_dot_config/mise/config.toml.tmpl` reads the pin through\n`include \".mise.toml\"`, so every machine runs the version CI tested.\n- Renovate's `mise` manager proposes chezmoi bumps as their own PR, with\nautomerge off.\n- `Homebrew/actions/setup-homebrew@main` and\n`benchmark-action/github-action-benchmark@v1` are both branches. They\nare pinned to release SHAs with a `# <version>` comment.\n- `tests/test-ci-pins.sh` fails when any of this regresses. It runs as a\npre-commit hook, in the smoke Linters job (`--self-test`, `--online`),\nand as an assertion step in each job that installs chezmoi.\n\n## Why\n\n#416 and #418 share one root cause: no string in this repo chose the\nversion, so an upstream change could turn main red without a commit\nhere.\n\n- `brew install chezmoi` took the version from the runner image's\nHomebrew snapshot. chezmoi 2.72.0, a minor release, broke main from\n2026-08-04 to 2026-08-18. In the green run 35738657555, Linux still got\n2.72.2 and macOS got 2.72.1.\n- The deletion of `Homebrew/actions@master` failed every job that used\nit from run 34810028957 until #430. #430 moved the ref to `@main`, which\nis still a branch. benchmark-action's `v1` is a branch too;\n`refs/tags/v1` does not exist.\n- mise-action without `version:` took mise from cache age. In the same\nrun, Ubuntu used 2026.6.1, restored from mise-action's constant cache\nkey `mise-v1-linux-x64-ubuntu24-no-config`, and macOS used 2026.9.12.\nmise carries the aqua registry that resolves the chezmoi download. With\n`version:` set, mise-action self-updates a restored binary to the pinned\nversion and includes the version in its cache key.\n- The Build jobs' extra \"Cache mise tools\" step keyed on\n`hashFiles('**/.mise.toml', ...)`. With no `.mise.toml` on main, that\nkey was `Linux-mise-` / `macOS-mise-`, and `gh cache list` shows both\nentries on `refs/heads/main` (29,729,800 and 30,769,345 bytes), each\nwithin 2 KB of mise-action's own mise-binary cache for that OS. Once\n`.mise.toml` exists the exact key misses, and the `<os>-mise-`\nrestore-key extracts main's entry after mise-action has installed\n2026.9.12.\n- Locally, chezmoi was `latest`, so a breaking release reached machines\non their next `mise upgrade` before any CI run saw it.\n\n## How\n\nEleven commits, one theme each:\n\n1. `ci(chezmoi)`: adds `.mise.toml` and replaces the six workflow\ninstalls with mise-action. Linters and SBOM drop Homebrew because it\nexisted only to install chezmoi, and SBOM never ran chezmoi. claude.yml\nkeeps Homebrew because the agent may run `brew bundle check`. The Docker\nsmoke image and script now install through mise instead of brew or the\nupstream installer script. chezmoi skips dot-prefixed files at the\nsource root, so `.mise.toml` is not deployed to `$HOME`. The commit also\ncorrects the chezmoi-conventions rule, which said CI installs chezmoi\nunpinned.\n2. `feat(mise)`: `chezmoi = \"{{ (fromToml (include\n\".mise.toml\")).tools.chezmoi }}\"`. It also added `trusted_config_paths =\n[\"{{ .chezmoi.sourceDir }}\"]` on the premise that mise would skip or\nprompt for the new `.mise.toml` without it. That premise is wrong\n(commit 8), and commit 10 removes the setting.\n3. `chore(renovate)`: adds `mise` to `enabledManagers`. Its default\npatterns already match `.mise.toml`. The chezmoi packageRule sets\n`groupName: chezmoi` and `automerge: false`, because the repo-wide rule\nautomerges minor updates and 2.72.0 was a minor release. The `schedule`\nline is unchanged.\n4. `ci`: pins `setup-homebrew` to\n`848c272c7bfe984a197bd4d16383f4c106ec61e6 # 2026.09.21.1`, the commit\n`@main` resolves to today. Pins `github-action-benchmark` to\n`4322e5726e6334590d251fc4f92bec0efafc45dc # v1.22.2`, the commit the\n`v1` branch points at today. Behaviour does not change until a bump. The\nfirst-party `laurigates/.github` reusable workflows stay on `@main` so\norg workflow fixes still propagate.\n5. `test(ci)`: `tests/test-ci-pins.sh`, the always-run `ci-pins`\npre-commit hook, the CI steps, the Docker smoke assertion, and a\n`test:ci-pins` mise task.\n6. `ci(smoke)`: deletes both \"Cache mise tools\" steps. mise-action\nalready caches `~/.local/share/mise` under a key built from the mise\nversion and the config hash. The old `Linux-mise-` / `macOS-mise-`\nentries age out on their own.\n7. `build(docker)`: `MISE_VERSION=v2026.9.12` on the mise.run install,\nso the local smoke runs the mise CI runs.\n8. `docs(mise)`: rewrites the template and Dockerfile comments on trust.\nmise's `mise trust` docs say: \"In normal mode, safe config files do not\nrequire trust: files that only contain `min_version`, `[tools]` entries\nwith plain version strings\". The setting's actual effect is that every\nmise config under the source dir is trusted, including worktrees checked\nout from PR branches, so their `[env]`, hooks and templates apply on\n`cd` without a prompt. It renders to the source dir of the last apply,\nso `just apply` from a worktree moves the trust to that worktree.\n9. `test(ci)`: closes the gaps review found. Details are under Tests.\n10. `fix(mise)`: removes `trusted_config_paths` from the global mise\nconfig. The pin does not need it, and it would have trusted every mise\nconfig under the source dir, including PR-branch worktrees.\n11. `test(ci)`: after rebasing onto #435, check B flagged a `brew\ninstall chezmoi` line inside a self-test fixture of\n`tests/test-ci-github-api-auth.py`. The line was incidental context\ncopied from the old `smoke.yml`, so the fixture now installs shellcheck;\nthe fixture still tests the unauthenticated `pip install pre-commit`.\n\nThe test checks four things offline:\n\n- **A.** A third-party `uses:` on a branch-named ref fails, as does a\n40-hex SHA without a `# <tag>` comment. It reads workflows and composite\nactions under `.github/actions/`, and matches `uses:` only as a step or\njob key.\n- **B.** `.mise.toml` pins chezmoi to an exact X.Y.Z. No tracked\nnon-Markdown file installs chezmoi another way: brew install, upgrade or\nreinstall, apt and similar, the installer script, a release download,\n`mise use`, `chezmoi@<v>`, a `.tool-versions`-style `chezmoi latest`, or\n`MISE_CHEZMOI_VERSION`. A mise tool entry for chezmoi must `include\n\".mise.toml\"`. Any explicit chezmoi version must equal the pin.\n- **C.** A job that runs chezmoi sets up mise-action. A job that\ninstalls or runs chezmoi runs `--assert-installed`. A job that runs\n`chezmoi apply` also runs `--assert-installed --rendered`, which checks\nthe global mise config that apply wrote.\n- **D.** Every mise-action step pins the same `version:`. A job with\nmise-action does not also cache `~/.local/share/mise`. A mise.run\ninstall sets `MISE_VERSION` to that same version.\n\n`--online` adds a `git ls-remote` lookup per remaining ref. This is the\nonly check that can tell the tag `codelytv/pr-size-labeler@v1` from the\nbranch `benchmark-action/...@v1`. It also verifies that each SHA comment\nnames a tag pointing at that SHA.\n\nKnown limits, recorded in the script header: C sees chezmoi only as a\nliteral `chezmoi <subcommand>` in a step, so a job that reaches it\nthrough `just apply` is caught only if it already runs\n`--assert-installed`. C and D do not parse composite actions.\n\nRenovate can bump the `.mise.toml` pin without the `workflows`\npermission, because the file is not a workflow. The SHA pins and mise\n`version:` inputs live in workflow files, so Renovate can bump them only\nafter the laurigates-renovate App is granted Workflows access. That\nchange is handled separately.\n\n## Tests\n\nRED, at `be2fd3b` with only the test file added:\n\n```\n$ tests/test-ci-pins.sh\nFAIL: .github/workflows/smoke.yml: job lint runs chezmoi but has no jdx/mise-action step\nFAIL: .github/workflows/smoke.yml:72: jdx/mise-action step has no version: input\nFAIL: .github/workflows/smoke.yml: job build runs chezmoi apply but never runs tests/test-ci-pins.sh --assert-installed --rendered\nFAIL: .github/workflows/smoke.yml:31: Homebrew/actions/setup-homebrew@main is a branch; pin a release SHA with a '# <tag>' comment\nFAIL: .mise.toml is missing; it must pin chezmoi = \"X.Y.Z\"\nFAIL: chezmoi installed outside the .mise.toml pin: .github/workflows/smoke.yml:35:          brew install chezmoi\nFAIL: chezmoi installed outside the .mise.toml pin: Dockerfile:53:RUN brew install chezmoi neovim\nFAIL: chezmoi installed outside the .mise.toml pin: scripts/smoke-test-docker.sh:73:            sh -c \"$(curl -fsSL https://www.chezmoi.io/get)\" -- -b \"$HOME/.local/bin\"\nFAIL: mise tool entry names its own chezmoi version instead of including .mise.toml: private_dot_config/mise/config.toml.tmpl:143:chezmoi = \"latest\"\n...\n27 failure(s). See tests/test-ci-pins.sh for what each check guards (#416, #418).\nexit=1\n\n$ tests/test-ci-pins.sh --online      # the 27 above, plus:\nFAIL: .github/workflows/benchmarks.yml:141: benchmark-action/github-action-benchmark@v1 is a branch, not a tag; pin a release SHA with a '# <tag>' comment\n28 failure(s).\n```\n\nRED for the review gaps (commit 9). First, the nine new self-test cases\nagainst the unchanged checks:\n\n```\n$ tests/test-ci-pins.sh --self-test\nnot ok - A: third-party ref on a branch in a composite action fails (expected fail, exit 0, wanted message: is a branch)\nnot ok - A: 'uses:' inside a run string is not a ref (expected pass, exit 1, wanted message: none)\n    FAIL: .github/workflows/ci.yml:29: uses: nothing has no @ref\nnot ok - B: brew upgrade chezmoi fails (expected fail, exit 0, wanted message: installed outside)\nnot ok - B: .tool-versions with chezmoi latest fails (expected fail, exit 0, wanted message: installed outside)\nnot ok - B: mise-action tool_versions input with chezmoi latest fails (expected fail, exit 0, wanted message: installed outside)\nnot ok - B: MISE_CHEZMOI_VERSION override fails (expected fail, exit 0, wanted message: installed outside)\nnot ok - D: actions/cache of the mise data dir in a mise-action job fails (expected fail, exit 0, wanted message: restores ~/.local/share/mise)\nnot ok - D: mise.run install without MISE_VERSION fails (expected fail, exit 0, wanted message: mise.run install does not pin MISE_VERSION)\nnot ok - D: mise.run install at another mise version fails (expected fail, exit 0, wanted message: but jdx/mise-action pins 2026.9.12)\nself-test: 27/36 cases behaved as expected\n```\n\nThen the new checks against the tree before commits 6 and 7:\n\n```\n$ tests/test-ci-pins.sh\nFAIL: .github/workflows/smoke.yml:94: job build restores ~/.local/share/mise with actions/cache, which can replace the mise that jdx/mise-action pinned; mise-action caches that dir itself\nFAIL: .github/workflows/smoke.yml:220: job build-macos restores ~/.local/share/mise with actions/cache, which can replace the mise that jdx/mise-action pinned; mise-action caches that dir itself\nFAIL: mise.run install does not pin MISE_VERSION: Dockerfile:56:RUN curl https://mise.run | sh\n3 failure(s).\n```\n\nGREEN, at the branch head:\n\n```\n$ tests/test-ci-pins.sh\nPASS: CI toolchain pins hold (chezmoi 2.72.2, online=0)\n$ tests/test-ci-pins.sh --online\nPASS: CI toolchain pins hold (chezmoi 2.72.2, online=1)\n$ tests/test-ci-pins.sh --self-test\nself-test: 36/36 cases behaved as expected\n```\n\nIn `--self-test`, 28 planted static fixtures must each fail with their\nspecific message, 3 runtime cases must fail, and 5 cases (3 static, 2\nruntime) must pass. It passed on macOS with bash 5.3 and BSD awk, on\n`/bin/bash` 3.2, and in an Ubuntu 24.04 container with mawk 1.3.4 and\nGNU grep 3.11.\n\nNegative controls:\n\n- A copy of the branch head with the pre-repair `smoke.yml` and\n`Dockerfile` (from `524d4aa`) fails with exactly the two cache steps and\nthe mise.run line. The unmodified copy passes.\n- The review's planted inputs, replayed on a copy of the branch head:\nall eight bypass attempts outside the documented limits fail offline,\nfive of them newly (`.tool-versions`, the `tool_versions:` input, `brew\nupgrade`, `MISE_CHEZMOI_VERSION`, the composite action). `run: echo\n\"this step uses: nothing\"` passes. `just apply` in a new job still\npasses, as documented. A SHA commented `# main` passes offline and fails\nunder `--online`, as before.\n- A copy without `.github/` (the Docker build context) passes, and fails\nonce `MISE_VERSION` is removed from the Dockerfile.\n- A `RUN brew install chezmoi` planted in the Dockerfile makes\n`pre-commit run ci-pins --all-files` fail (exit 1). Restoring the file\npasses.\n- An online fixture with `github-action-benchmark@v1`, a SHA commented\n`# v1.22.1`, and `actions/checkout@v999` fails all three: branch,\n\"resolves to 52576c9…, not the pinned 4322e57…\", and \"matches no tag or\nbranch\". `actions/checkout@v4` and the Homebrew SHA pin pass.\n- Mutation checks on scratch copies of the test each broke the self-test\nas intended: attributing failures to the wrong file, counting\n`Bash(chezmoi diff *)` in a reusable-workflow `with:` as a chezmoi run,\nand breaking the brew-install regex.\n- The online run found a bug in the test itself: an annotated tag lists\nits peeled commit only when `refs/tags/<t>^{}` is also requested. That\nis fixed.\n\n## Other instances\n\nFound and fixed:\n\n- chezmoi installs at `smoke.yml:35,70,185`, `benchmarks.yml:33`,\n`sbom.yml:33`, `claude.yml:78`, `Dockerfile:53` and\n`scripts/smoke-test-docker.sh:70,73`.\n- `config.toml.tmpl:143` `chezmoi = \"latest\"`.\n- mise-action without `version:` at `smoke.yml:73,188` and\n`benchmarks.yml:36`.\n- The Linters job ran chezmoi without mise.\n- `setup-homebrew@main` at six sites. Two were deleted with their jobs'\nHomebrew setup and four are SHA-pinned.\n- `github-action-benchmark@v1`.\n- The \"Cache mise tools\" steps in smoke.yml Build (Ubuntu) and Build\n(macOS).\n- The unversioned mise.run install in the Dockerfile.\n\nLeft, with reasons:\n\n- `.chezmoidata/packages.toml:14`, the Homebrew `chezmoi` in the core\nprofile. It bootstraps a machine before any mise config exists, and\n`mise activate` puts the pinned chezmoi ahead of it on PATH\n(`tests/test-shell-precedence.sh`). The test header records this\nexclusion.\n- `laurigates/.github/...@main` at `auto-fix-ci-failures.yml:25`,\n`claude-code-review.yml:18` and `renovate.yml:39`. These are first-party\nand allowlisted on purpose.\n- The same failure class outside this PR's scope: `python-version:\n'3.x'` and an unpinned `pip install pre-commit` in Linters and\nclaude.yml, `bun-version: latest`, an unpinned `npm install -g\n@anthropic-ai/claude-code`, and third-party actions on major tags\n(`actions/checkout@v4` and similar). Major tags are tags, not branches,\nso check A allows them.\n\n## Verification\n\n- `actionlint .github/workflows/*.yml`: exit 0. `shellcheck\ntests/test-ci-pins.sh scripts/smoke-test-docker.sh`: exit 0.\n- `pre-commit run --all-files`: exit 0, every hook passed, including\n`check CI toolchain pins`.\n- `gitleaks git --log-opts=origin/main..HEAD`: no leaks found.\n- `chezmoi managed` with the worktree source, a scratch destination,\nconfig and state: 369 targets, none of them `.mise.toml`. The controls\n`.config/mise/config.toml` and `.zshrc` are present.\n- Rendering the global mise template gives `chezmoi = \"2.72.2\"` and\nvalid TOML.\n- Trust, with mise 2026.9.11 in untrusted scratch dirs: a `.mise.toml`\nwith only `[tools] chezmoi = \"2.72.2\"` is read without a prompt (`mise\nls --current chezmoi` names it as the source). Adding `[env] FOO =\n\"bar\"` makes the same command fail with \"Config files ... are not\ntrusted\".\n- A read-only `chezmoi diff ~/.config/mise/config.toml` on this machine\nshows `chezmoi = \"latest\"` → `\"2.72.2\"` and the `test:ci-pins` task.\n- Docker smoke image, built from the branch head:\n- The mise.run layer installed `2026.9.12 linux-arm64`, and `mise --cd\n/tmp/dotfiles install chezmoi` installed `chezmoi@2.72.2`.\n- In the container, `chezmoi` resolves to the mise shim, reports\nv2.72.2, and `--assert-installed` passes.\n- From the earlier build of this branch, before commits 6 to 9: after\napplying `~/.config/mise/config.toml`, `--rendered` passed, and a\nplanted `chezmoi = \"latest\"` in the rendered config failed.\n- A full `chezmoi apply` in the container stops at\n`.claude/settings.json` because the image has no `jq`. That predates\nthis PR: the Dockerfile on main has no jq, and\n`exact_dot_claude/modify_settings.json` calls it.\n- Renovate 44.108.2:\n- `renovate-config-validator renovate.json5` exits 0. A planted unknown\nmanager exits 1.\n- `renovate --platform=local --dry-run=extract` lists the `mise` manager\non `.mise.toml` with `depName: chezmoi`, `packageName: twpayne/chezmoi`,\n`datasource: github-tags`, `currentValue: 2.72.2`. It also lists the\n`jdx/mise` `version:` inputs.\n- Not run: a lookup dry-run that would show the chezmoi update moving to\n`renovate/chezmoi` with automerge off. It needs a token, and the\npermission system denied it.\n- Not exercised by this PR's CI: claude.yml, which runs only on\n`@claude` comments and issues, and the SHA-pinned \"Store benchmark\nresults\" step, which runs only on push to main.\n\n## Follow-ups\n\n- #448: apply the updated global mise config on each machine after\nmerge.\n- #447: `claude.yml` runs only on `@claude` comments, so this PR's CI\ndoes not exercise its new \"Setup mise\" and \"Assert chezmoi matches the\n.mise.toml pin\" steps or the SHA-pinned setup-homebrew.\n- #446: vet the first `renovate/chezmoi` PR (runs Smoke Test CI, not\nautomerged, `--assert-installed` passes).\n- #440: the tools CI still resolves at run time (Python `3.x`, unpinned\npre-commit, bun, the Claude CLI) and the docs that claim a committed\n`mise.lock`.\n- #441: the Docker smoke image lacks jq, `benchmarks.yml` times a\nfailing apply, and `DOCKER.md` describes a container that no longer\nexists.\n- The SHA-pinned \"Store benchmark results\" step runs only on push to\nmain; the first post-merge Performance Benchmarks run is checked right\nafter merge.\n\nFixes #416\nFixes #418\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01Q6aDMonZX35gYM9ZsKUfPv\n\n---------\n\nCo-authored-by: Claude Opus 5.5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-23T10:09:50+03:00",
          "tree_id": "aa65af5f2013bbf89dc4d76903b362f3204d8557",
          "url": "https://github.com/laurigates/dotfiles/commit/d6d19c814d877e8700b0c5b91ec9272c7b81c25c"
        },
        "date": 1790147444021,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.008009507260000001,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00102470086,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.00086628506,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.06484195164,
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
          "id": "3f296f414e303c16b0df964b5cc5e90072863833",
          "message": "chore(claude): document why scheduled-tasks/ stays unversioned (#436)\n\n## What\n\n- `exact_dot_claude/.chezmoiignore`: `scheduled-tasks/` moves out of the\ngeneric \"Runtime directories created by Claude Code\" block into its own\ncommented block. The comment names the owner (Claude Desktop), what\n`SKILL.md` holds and does not hold, and why the line must stay (`exact_`\nparent). The directory stays deliberately unversioned.\n- The same file registers two runtime entries that were neither managed\nnor ignored: `state/` (Claude Code) and `settings.json.bak` (writer\nunknown, and the comment says so).\n- New `tests/test-claude-runtime-ignored.sh`, wired as a local\npre-commit hook, fails when any known app-written entry under\n`~/.claude` would be deleted by `chezmoi apply`.\n\nFixes #399\n\n## Why\n\n`~/.claude` is an `exact_` directory, so apply deletes every entry that\nis neither in the source nor in `.chezmoiignore`. `scheduled-tasks/`\ncame in as a drive-by in #190 with no comment of its own, so a later\nreader could not tell a deliberate exclusion from an oversight (#399).\n\nOption 3 of #399 (app-owned, deliberately unversioned) follows from the\nDesktop docs (code.claude.com/docs/en/desktop-scheduled-tasks):\n\n- The Desktop app creates, edits (Edit form, `update_scheduled_task` MCP\ntool) and deletes `scheduled-tasks/<name>/SKILL.md`.\n- \"Schedule, folder, model, and enabled state are not in this file.\"\nThey live in the app's registry outside `~/.claude`, so a versioned\n`SKILL.md` could not recreate a task on another machine.\n- Tracking the directory under an `exact_` parent would either delete\napp-created tasks (`exact_scheduled-tasks/`) or leave them unmanaged\n(plain subdir), and app edits would show up as drift.\n\n`chezmoi status ~/.claude` at `be2fd3b` also listed ` D .claude/state`\nand ` D .claude/settings.json.bak`. Both would have been deleted by the\nnext apply, and the exact-guard hook blocks every apply until they are\nhandled.\n\n## How\n\nThe test seeds a scratch destination with one fixture per known runtime\nentry, runs `chezmoi status --source=<repo> --destination=<tmp>` with\nscratch `--config`, `--cache` and `--persistent-state` and\n`--exclude=scripts,externals`, and fails on any ` D` line. The\ndestination holds only fixtures, so every ` D` line names one.\n\n- **Canary control:** a deliberately unregistered canary must be\nreported as ` D`. If it is not, the harness could not see a deletion and\nthe test fails.\n- **chezmoi errors:** a non-zero exit fails the test.\n- **Fixture list:** kept separate from `.chezmoiignore`, so removing an\nignore line cannot also remove its fixture.\n- **Dependencies:** `exact_dot_claude/modify_settings.json` still runs\nduring status. It reads stdin, writes stdout, and needs `jq`.\n\nThe hook runs on changes to `exact_dot_claude/.chezmoiignore` or the\ntest. It also runs in the Linters CI job, which installs chezmoi before\n`pre-commit run --all-files` (`.github/workflows/smoke.yml:35-39`).\n\n## Tests\n\nRED at `be2fd3b` (test file only, ignore file unchanged), exit 1:\n\n```\n$ tests/test-claude-runtime-ignored.sh\nFAIL: chezmoi apply would DELETE these runtime entries under ~/.claude.\n      Register each in exact_dot_claude/.chezmoiignore with an owner comment:\n        .claude/settings.json.bak\n        .claude/state\n```\n\nRED at `be2fd3b` with the `scheduled-tasks/` line deleted (scratch\ncopy), exit 1:\n\n```\n        .claude/scheduled-tasks\n        .claude/settings.json.bak\n        .claude/state\n```\n\nGREEN at branch tip, exit 0:\n\n```\nPASS: 45 runtime entries survive chezmoi apply (canary deletion detected)\n```\n\nNegative controls, each on a scratch copy of the fixed tree, all exit 1:\n\n| Planted change | Output |\n|---|---|\n| delete `scheduled-tasks/` | `FAIL: ... .claude/scheduled-tasks` |\n| delete `state/` | `FAIL: ... .claude/state` |\n| append `/bogus` (fatal ignore pattern) | `FAIL: chezmoi status exited\n1` / `.chezmoiignore:79: /bogus: invalid path` |\n| ignore the canary | `FAIL: control: the unregistered canary ... was\nnot reported as a pending deletion` |\n\nHook wiring, in a scratch clone of the branch: with `scheduled-tasks/`\ndeleted, `pre-commit run claude-runtime-ignored --files\nexact_dot_claude/.chezmoiignore` reports `Failed` and lists\n`.claude/scheduled-tasks`. On the unmodified clone, `pre-commit run\nclaude-runtime-ignored --all-files` reports `Passed`.\n\nClean environment: `env -i HOME=<empty dir> PATH=<chezmoi dir>:<jq\ndir>:/usr/bin:/bin /bin/bash tests/test-claude-runtime-ignored.sh`\nprints `PASS` (exit 0) under macOS `/bin/bash` 3.2, and the empty `HOME`\nis still empty afterwards. The test reads nothing from the real\n`~/.claude` or chezmoi config.\n\n## Other instances\n\n- `~/.claude/state/` holds `mcp-discover-verdicts.json`, a filename that\nappears in the Claude Code CLI binary's strings. Registered.\n- `~/.claude/settings.json.bak` has no known writer: nothing in this\nrepo, the plugin cache, or the CLI binary's strings names it. Registered\nwith a comment saying the writer is unknown.\n- The other entries in the generic runtime blocks keep their shared\nheader. They are now all fixtures in the test, so removing any of them\nfails the hook. `scheduled-tasks/` was the only one owned by a different\napp and holding user-authored content.\n- `private_repos/CLAUDE.md:41` says the Claude scheduled tasks'\n\"schedule and run history live at claude.ai/code/routines\". That holds\nfor cloud routines, but Desktop local tasks keep both in the Desktop\napp. This PR does not change it because the rendered `~/repos/CLAUDE.md`\nis also tracked in another repository, so an edit here would diverge\nfrom that copy. See Follow-ups.\n\n## Verification\n\n- `shellcheck tests/test-claude-runtime-ignored.sh`: exit 0.\n- `pre-commit run --files tests/test-claude-runtime-ignored.sh\n.pre-commit-config.yaml exact_dot_claude/.chezmoiignore`: all hooks\nPassed (trailing-whitespace, end-of-file, check-yaml, the new hook, doc\nreferences, gitleaks).\n- `chezmoi --source <worktree> status ~/.claude`: before, ` D\n.claude/settings.json.bak` and ` D .claude/state`. After, only `MM\n.claude/settings.json`, which is existing runtime drift in the `modify_`\ntarget and unrelated to this change.\n- `chezmoi --source <worktree> ignored` lists `.claude/scheduled-tasks`,\n`.claude/settings.json.bak` and `.claude/state`.\n- Not verified: the new hook inside the Linters CI job on Ubuntu. It\nruns there on the next push.\n\n## Follow-ups\n\n- #444: correct `private_repos/CLAUDE.md:41` on where Desktop local task\nschedules live (the file is also tracked in another repository), and\nname the writer of `~/.claude/settings.json.bak` once identified.\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01Q6aDMonZX35gYM9ZsKUfPv\n\n---------\n\nCo-authored-by: Claude Opus 5.5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-23T10:11:52+03:00",
          "tree_id": "38a3b037fa51d0f4398989d34ba842d8610dbe21",
          "url": "https://github.com/laurigates/dotfiles/commit/3f296f414e303c16b0df964b5cc5e90072863833"
        },
        "date": 1790147552333,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.00980133774,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00149343536,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.00122533536,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.011367556000000001,
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
          "id": "0de4b160e9693138b5c6b6141f4e1803ccc559c3",
          "message": "test(git): pin per-location identity and fix the includeIf location comment (#437)\n\n## What\n\n- `private_dot_config/git/personal.inc:1` now says the `includeIf` rules\nlive in `~/.gitconfig`. It used to say `~/.config/git/config`.\n- New `tests/test-git-identity.sh` runs\n`run_onchange_after_10-git-identity.sh` under a scratch `HOME` and\nchecks which file the script writes and which identity each location\nresolves.\n- New local pre-commit hook `git-identity` runs the test when the\nidentity script, `personal.inc`, or the test changes. CI already runs\n`pre-commit run --all-files` in `smoke.yml`, so the test runs there too.\n\nRefs #290\n\n## Why\n\n#290 was closed with option A (additive `git config --global` writes).\nThe triage traced its option B to a wrong assumption: that the scripted\nglobal config is `~/.config/git/config`. `git config --global` writes\n`~/.gitconfig` unless that file is absent and\n`$XDG_CONFIG_HOME/git/config` already exists (git-config(1),\n`--global`). On a fresh machine neither file exists, so the first write\nin `run_once_before_00-initial-setup.sh.tmpl` creates `~/.gitconfig` and\nall later writes go there. `personal.inc:1` recorded the same wrong\nassumption, and no check covered which file the identity script writes\nor whether the `includeIf` routing resolves.\n\nThe file matters for more than the comment. git reads the XDG file\nbefore `~/.gitconfig`, so an `includeIf` rule placed in the XDG file is\noverridden by the default `[user]` block in `~/.gitconfig`. The\n`includeif-written-to-xdg` mutation below shows this: all four personal\nlocations then resolve the work address.\n\n## How\n\nThe test copies `personal.inc` into `$HOME/.config/git/`, the same order\nchezmoi uses (files before `run_after` scripts). It then runs the\nidentity script under `env -i PATH=… HOME=<scratch>\nGIT_CONFIG_NOSYSTEM=1 GIT_CEILING_DIRECTORIES=<scratch>`. `env -i` also\ndrops the `GIT_DIR`/`GIT_INDEX_FILE` a calling git hook exports, and\n`XDG_CONFIG_HOME`/`GIT_CONFIG_GLOBAL` are unset. Assertions:\n\n1. Every config entry the script writes has origin `$HOME/.gitconfig`,\nand `includeIf.gitdir` entries are among them.\n2. `$HOME/.config/git/config` does not exist.\n3. Any `~/.gitconfig` or `~/.config/git/config` mention in\n`personal.inc` or the identity script names the file git actually wrote.\n4. New repos at `~/repos` (umbrella, exact `.git` match),\n`~/repos/laurigates/probe`, `~/.local/share/chezmoi` and\n`~/Documents/LakuVault` resolve `personal.inc`'s `user.email`.\n5. New repos at `~/work/probe` and `~/repos/other-org/probe` resolve the\ndefault `user.email`. The second one checks that the umbrella rule does\nnot widen to a `~/repos/` prefix.\n\nThe expected emails are not repeated in the test. The personal one is\nread with `git config --file personal.inc`, and the default is read from\nthe config the script wrote. A guard fails the run if either is empty or\nif they are equal, because the routing checks would then prove nothing.\n\nConfig reads use no scope flag and run outside any repo. On git 2.43,\n2.54 and 2.55, `git config --global --list` reads only `~/.gitconfig`\nonce that file exists and hides the XDG file, so a `--global` read would\nmiss entries written there. git-config(1) says `--global` reads both\nfiles. The hook's `files:` regex covers only the three files the test\nreads or executes. The triage suggested including\n`run_once_before_00-initial-setup.sh.tmpl`, but the test does not run\nit. There is no mise task because another PR is moving repo tasks into a\nrepo `.mise.toml`.\n\nTwo commits: the comment fix, then the test plus hook.\n\n## Tests\n\nIn the output below, `<default>` and `<personal>` stand for the two\naddresses.\n\nRED: the final test run against `be2fd3b`'s\n`run_onchange_after_10-git-identity.sh` and `personal.inc`, copied into\na scratch layout:\n\n```\ntests/test-git-identity.sh      # exit 1\n✗ FAIL: Comment names a file other than ~/.gitconfig:\n    private_dot_config/git/personal.inc:1:~/.config/git/config\nPassed: 5\nFailed: 1\n```\n\nThe same RED through the hook, with `be2fd3b`'s `personal.inc`\ntemporarily in the worktree:\n\n```\npre-commit run git-identity --files private_dot_config/git/personal.inc      # exit 1\ncheck per-location git identity routing..................................Failed\n✗ FAIL: Comment names a file other than ~/.gitconfig:\n    private_dot_config/git/personal.inc:1:~/.config/git/config\n```\n\nAt `be2fd3b` the behaviour was already correct, so assertions 1, 2, 4\nand 5 were checked against mutations. Each mutation is an exact-string\nedit of a scratch copy of the fixed files, and the harness first checks\nthat the edit string matched the expected number of times:\n\n| Mutation | Exit | Failing assertion(s) |\n|---|---|---|\n| none (control) | 0 | none |\n| script plants an empty `~/.config/git/config` before its first write |\n1 | 1 (all 6 entries in the XDG file), 2, 3 |\n| the four `includeIf` writes use `--file ~/.config/git/config` | 1 | 1\n(4 entries), 2, 4 (all four personal locations resolve `<default>`) |\n| umbrella `includeIf.gitdir:~/repos/.git` line removed | 1 | 4:\n`~/repos resolves '<default>', want personal` |\n| `~/repos/laurigates/` line removed | 1 | 4: `~/repos/laurigates/probe\nresolves '<default>'` |\n| trailing slash dropped (`gitdir:~/repos/laurigates`) | 1 | 4:\n`~/repos/laurigates/probe resolves '<default>'` |\n| umbrella widened to `gitdir:~/repos/` | 1 | 5:\n`~/repos/other-org/probe resolves '<personal>', want default` |\n| catch-all `includeIf.gitdir:~/` added | 1 | 5: both default locations\nresolve `<personal>` |\n| default `user.email` set to the personal address | 1 | guard (`Default\nand personal user.email are the same`), 5 |\n| `email` line removed from `personal.inc` | 1 | guard (`No user.email\nin …personal.inc`), 4 |\n| `personal.inc:1` comment reverted to `~/.config/git/config` | 1 | 3 |\n\nGREEN on the fixed tree:\n\n```\ntests/test-git-identity.sh      # exit 0\n✓ PASS: default=<default> personal=<personal>\n✓ PASS: 6 entries, all in ~/.gitconfig\n✓ PASS: ~/.config/git/config absent\n✓ PASS: 1 mention(s), all ~/.gitconfig\n✓ PASS: 4 personal locations resolve <personal>\n✓ PASS: 2 default locations resolve <default>\nPassed: 6\nFailed: 0\n```\n\n## Other instances\n\n`rg --hidden -g '!.git' -e '\\.config/git/config' -e\n'XDG_CONFIG_HOME[}]?/git/config' -e 'git/config\\b'` found only\n`personal.inc:1`, which is fixed. The control search for `personal.inc`\nfound its references in the identity script, so the search was reading\nthe tree. A wider search (`config/git`, `gitconfig`, `global git\nconfig`, `includeIf`, `git identity`) found no other wrong claims. The\nidentity script's own header names `~/.config/git/personal.inc`, which\nis correct, and assertion 3 now covers both files.\n\n## Verification\n\n- `shellcheck tests/test-git-identity.sh`: exit 0.\n- `tests/test-git-identity.sh` on macOS (git 2.55.0): exit 0, 6 passed.\n- Ubuntu 24.04 container (git 2.43.0), scratch copies: control exit 0.\nThe `removed-laurigates`, `planted-xdg-config`, `umbrella-widened` and\n`comment-reverted` mutations each exit 1 with the same failures as on\nmacOS.\n- `pre-commit run --all-files`: exit 0, including `check per-location\ngit identity routing ... Passed`.\n- `git commit` of the test ran the hook in the commit-hook environment:\n`Passed`.\n- Scoping: `pre-commit run git-identity --files README.md` reports `(no\nfiles to check) Skipped`.\n\n## Follow-ups\n\n- None. This PR needs no post-merge manual action. The next `chezmoi\napply` updates the comment in `~/.config/git/personal.inc`. The identity\nscript is unchanged, so its `run_onchange` hash does not change and it\ndoes not re-run.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01Q6aDMonZX35gYM9ZsKUfPv\n\n---------\n\nCo-authored-by: Claude Opus 5.5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-23T10:16:18+03:00",
          "tree_id": "692a0d7a3acbe2dc3f995962c4abc1329bd35233",
          "url": "https://github.com/laurigates/dotfiles/commit/0de4b160e9693138b5c6b6141f4e1803ccc559c3"
        },
        "date": 1790147817034,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.010892340833333333,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0016312093000000003,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013479191000000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.01193512596,
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
          "id": "3b2f2be1a4a428b7f9f20d7026d820fc14d5ae23",
          "message": "fix(mise): run repo tasks in the checkout and make lint tasks fail on findings (#450)\n\n## What\n\n- Moves the 24 tasks that read the dotfiles repo from the global mise\ntemplate (`private_dot_config/mise/config.toml.tmpl`) into the repo-root\n`.mise.toml`: `apply`, `diff`, `status`, `verify`, `check`, `edit`,\n`test` and the six `test:*` tasks, `lint` and the four `lint:*` tasks,\n`docker`, `qa`, `ci`, `clean`, `security:audit` and `security:scan`. The\nglobal template keeps the 13 tasks that do not read the repo (`setup*`,\n`update*`, `dev`, `info`, `doctor`, `docs`).\n- `lint:shell` runs shellcheck on every tracked `*.sh` and fails on\nfindings. Every lint task fails, and names the tool, when its linter is\nmissing or cannot run. `lint` runs all four linters and fails if any\nfailed.\n- Pins shellcheck 0.11.0 in `.mise.toml`, so a local `mise run\nlint:shell` and CI report the same findings. jdx/mise-action therefore\ninstalls it in the Build jobs too, and Renovate's mise manager will\npropose bumps. The Linters step runs on each bump PR, so a bump that\nadds findings fails before it can automerge.\n- Clears the 29 existing shellcheck findings and the 7 luacheck\nwarnings.\n- Adds `tests/test-mise-tasks.sh` and runs it in the smoke Linters job.\n\nBuilds on #449, which added the repo-root `.mise.toml` and the Linters\njob's \"Setup mise\" step.\n\n## Why\n\n`mise run lint:shell` never ran shellcheck (#398). The task block had\nthree causes:\n\n1. **Over-escaping.** The `lint:shell` run string is a TOML literal\nstring, which does no escape processing, so it kept `\\\\;`. find received\na stray `\\` and aborted with `find: -exec: no terminating \";\" or \"+\"`.\n2. **Lint tasks that cannot fail.** `find -exec shellcheck {} \\;`\ndiscards shellcheck's exit status, even once the escaping is fixed. The\naggregate `lint` also wrapped every linter in `|| { echo warning; }`.\n3. **Tasks ran in `$HOME`.** mise runs a task in the root of the config\nthat defines it, and for the global config that root is `$HOME`.\n`lint:actions` exited 3 with \"no project was found\". `lint:docs` ran the\nchezmoi-deployed copy `~/scripts/check-doc-references.py`, which crashed\non `git rev-parse` outside a repo. `clean` ran `find . -name \"*.tmp\"\n-delete` over the home directory. The #397\n`apply`/`diff`/`status`/`verify` guard resolved the chezmoi source from\n`$HOME`, so from a worktree those tasks acted on the main checkout. The\n`test:*` tasks ran the main checkout's copy of `tests/`.\n\nLauri chose to move the repo tasks into `.mise.toml`, to fix the\nexisting shellcheck findings in a separate commit, and to fold in\n`clean` and the #397 guard.\n\n## How\n\n1. `c445968 fix(mise)`: the move.\n- `apply`/`diff`/`status`/`verify` run `chezmoi --source \"$PWD\" …`,\nwhere `$PWD` is the root of the checkout running the task. `verify`\ndrops its `.` argument, which meant every target only while the task ran\nin `$HOME`.\n- `lint:shell` runs `git ls-files -z '*.sh' | xargs -0 shellcheck`.\nUnlike `find .`, it skips `.claude/worktrees/` and `tmp/`.\n- Each lint task runs `<linter> --version` first. `lint:lua` also prints\nthe Lua 5.5 crash (lunarmodules/luacheck#147) and the build that fixes\nit.\n- `lint` runs `mise run --continue-on-error --jobs 1 lint:shell :::\nlint:lua ::: lint:actions ::: lint:docs`. Its Brewfile step is gone: the\nrepo has no Brewfile, and the step checked `~/Brewfile` only because the\ntask ran in `$HOME`.\n   - The `test:*` tasks call `tests/…` by relative path.\n- `clean` excludes `.git` and `.claude/worktrees` with `-not -path`.\n`-prune` does not work here, because `-delete` implies `-depth` and\n`-prune` has no effect under `-depth`.\n- The global `dev` hint says `chezmoi apply` instead of `mise run\napply`. `CLAUDE.md` and `docs/mise-quick-reference.md` say where the\ntasks live.\n- `.mise.toml` contains no mise templates, so mise reads it without\n`mise trust`.\n2. `a9f7292 style(scripts)`: the 29 shellcheck findings, all\nbehaviour-preserving.\n- SC2155 is split into declaration and assignment where the command\ncannot fail on its input. Three sites keep the combined form with a\ndisable and a reason, because under `set -e` a split would abort where\nthe script now carries on: jq over the organize-stars state file,\norganize-stars' `gh api user/starred`, and `mktemp` in the unwired\n`generate-claude-completion.sh`.\n- Other disables, where a fix would change behaviour: SC2016 on GraphQL\nqueries, SC2153 for the `$NAME` that sketchybar sets, and SC1003 on an\nawk printf.\n3. `39cf76f style(nvim)`: the 7 luacheck warnings are six over-long\ncomments and the `MiniIcons` global, which is now listed in\n`.luacheckrc`. This is Claude's default; Lauri's decision covered only\nthe shellcheck findings.\n4. `8d3d935 ci(smoke)`: a Linters step runs `tests/test-mise-tasks.sh\n--require shellcheck,python3`.\n5. `14f306e docs(mise)`: the `Dockerfile` comment from #449 now says\nthat `.mise.toml` also holds template-free tasks. (Its second hunk\nedited the `trusted_config_paths` comment, which #449 removed before\nmerging, so the rebase dropped it.)\n6. `ffe566f test(mise)`: adds a second mise ceiling, so the test's\nscratch `$HOME` cannot load the real `~/.config/mise/config.toml` when\n`$TMPDIR` is under the real home.\n7. `9df58a7 test(mise)`: `${extra[@]+\"${extra[@]}\"}` for the optional\ntask args, because `\"${extra[@]}\"` on an empty array is an\nunbound-variable error under `set -u` before bash 4.4 (macOS `/bin/bash`\n3.2). Both bashes now report `passed=24 failed=0 skipped=2`.\n\nBehaviour changes:\n\n- These tasks exist only inside the dotfiles checkout or one of its\nworktrees. Outside it, use `chezmoi apply` and friends; outside the\nrepo, the old tasks also fell back to the pinned source dir.\n- A worktree whose branch predates this change has no tasks of its own.\nmise then loads the main checkout's `.mise.toml` as a parent config and\nruns its tasks there, so `mise run apply` applies main. That matches the\nbehaviour before this PR.\n\n## Tests\n\n`tests/test-mise-tasks.sh` checks six things:\n\n- **Static.** It renders the global template with chezmoi. No decoded\nrun string may hold `\\\\` or `-exec … \\;`. The 25 repo tasks must be in\n`.mise.toml` and not global. No global task may read the repo: the\nsource tree, a tracked top-level path, `.` as an input, a repo linter,\nor a dependency on a non-global task.\n- **Dir.** Every `.mise.toml` task runs in the repo root, from the root\nand from `tests/`. This runs with fresh mise state and no trust.\n- **Source.** A stub chezmoi confirms that apply/diff/status/verify pass\n`--source <this checkout>`.\n- **Clean.** `clean` deletes only inside the fixture checkout.\n- **Lint.** Each lint task must fail on a broken linter, pass a clean\nfixture, fail a planted finding and name its file, and pass this repo.\n- **Aggregate.** `lint` must show every available linter's finding.\n\nmise runs under `env -i` with an empty `HOME`.\n\nRED, the final test against the unfixed tree (a copy of 750463e):\n\n```\nMISE_TASKS_REPO=<copy of 750463e> tests/test-mise-tasks.sh\n  ✗ global task lint:shell: decoded run string holds a double backslash (TOML over-escaping): find . -name \"*.sh\" -not -path \"./node_modules/*\" -exec shellcheck {} \\;\n  ✗ global task lint: `-exec shellcheck ... \\;` discards shellcheck's exit status (use + or xargs)\n  ✗ global task clean runs in $HOME but reads `.` (the cwd): find . -name \"*.tmp\" -delete 2>/dev/null || true\n  ✗ status: chezmoi ran without --source <this checkout>: --source  status\n  ✗ clean deleted files outside this checkout: home/zz.tmp\n  ✗ lint:shell: rc=1 but zz-fixture.sh never named; it errored before checking: find: -exec: no terminating \";\" or \"+\"\n  ✗ lint:actions: rc=3 but zz-fixture.yml never named; it errored before checking: no project was found in any parent directories of \".../home\"\n  ✗ lint: exit 0 on the bad fixture (a linter failure was swallowed)\npassed=0 failed=100 skipped=0\n```\n\nGREEN:\n\n```\ntests/test-mise-tasks.sh                                   passed=24 failed=0 skipped=2   (macOS; Homebrew luacheck crashes, so lint:lua and lint-on-repo skip)\nPATH=<luarocks --dev luacheck>:$PATH tests/test-mise-tasks.sh   passed=28 failed=0 skipped=0\nubuntu:24.04, mise 2026.9.12, GNU find/xargs 4.9.0, no actionlint/luacheck:\ntests/test-mise-tasks.sh --require shellcheck,python3      passed=21 failed=0 skipped=3\ntests/test-mise-tasks.sh --require luacheck (macOS)        failed=1: \"luacheck is missing or cannot run here ... (--require luacheck)\"\n```\n\nControls: each regression was planted in a scratch copy and the\nunmodified test run against it. The clean copy passes (24/0/2), and\nevery planted copy fails:\n\n| Planted regression | Failing check |\n|---|---|\n| `clean` with `-prune` (the first version of this PR) | `clean deleted\nfiles outside this checkout: …/other/zz.tmp …/.git/zz.tmp` |\n| `lint:shell` as `find … -exec shellcheck {} \\;` | static `-exec … \\;`\n+ `exit 0 on a planted finding` |\n| `lint` ending in `\\|\\| true` | `lint: exit 0 on the bad fixture` |\n| `lint` without `--continue-on-error` | `these findings never appeared\n(it stopped early?): zz-fixture.yml zz-fixture-missing.md` |\n| `apply` as bare `chezmoi apply -v` | `apply: chezmoi ran without\n--source <this checkout>` |\n| global `shellcheck scripts/*.sh`, `nvim .`, `depends = [\"lint\"]` | one\nstatic failure each |\n| `clean` put back in the global template | `clean is a global task` +\nreads `.` |\n| `{{config_root}}` in a `.mise.toml` task | `mise tasks ls fails …\nConfig files … are not trusted` |\n| `lint:shell` without its `--version` check | `with a broken\nshellcheck, rc=1 and no 'shellcheck is missing or cannot run'` |\n| `xargs -0 shellcheck \\|\\| true` | `exit 0 on a planted finding` |\n| a new `.sh` with SC2086 / a doc with a dead link | `lint:shell: this\nrepo fails` / `lint:docs: this repo fails` |\n\n## Other instances\n\nFound and fixed:\n\n- The over-escaped `lint:shell`.\n- `lint`'s `-exec … \\;` and its warning-only wrappers.\n- `lint:actions`, `lint:docs`, `lint:lua` and `lint:shell` running in\n`$HOME`.\n- `clean` running in `$HOME`.\n- The four #397 tasks.\n- The `test:*` tasks that ran the main checkout's `tests/`.\n- `verify .`.\n- The 29 shellcheck findings and the 7 luacheck warnings.\n\nLeft, and why:\n\n- The justfile's `lint-shell`/`lint-lua`/`lint-actions`/`lint-brew`\nrecipes are the same \"cannot fail\" class. They print a warning and exit\n0 when the tool is missing, and `lint-shell`'s `find .` also walks\n`.claude/worktrees/` and `tmp/`. They are a second implementation\noutside the mise tasks this issue covers, so they are listed as a\nfollow-up.\n- `coverage.yml`'s shellcheck step reports to a step summary and never\nfails. It is a report by design; the Linters step is now the gate.\n- `[tasks.check] alias = \"status\"` defines `check` with the extra name\n`status` rather than aliasing `status`, so `mise run check` runs nothing\nand `qa`'s `check` dependency is a no-op. It moved unchanged.\n- `test:gh-completion` is not in `test`'s depends, and\n`tests/test-configure-makefile.sh` has no task. Both moved unchanged.\n- The Linters job does not install actionlint or luacheck, so those\nfixture checks skip in CI. Pre-commit already runs actionlint there.\n\n## Verification\n\n- `pre-commit run --all-files`: exit 0, every hook Passed or Skipped.\n- `actionlint .github/workflows/*.yml`: exit 0.\n- `git ls-files -z '*.sh' | xargs -0 shellcheck`: exit 0.\n- `tests/test-ci-pins.sh`: `PASS: CI toolchain pins hold (chezmoi\n2.72.2, online=0)`.\n- `bash tests/test-chezmoi-exact-guard.sh`: `Passed: 4, Failed: 0`.\n- `gitleaks git --log-opts=750463e..HEAD`: no leaks found.\n- Old vs new `generate-claude-completion-simple.sh`: byte-identical\n`dot_zfunc/_claude`, both with the real `claude` and with a stubbed\n`claude config --help`, so both brace-grouped sections ran.\n- The exact-guard hook's stderr is byte-identical old vs new on a\nstubbed pending deletion, scoped and unscoped. The replacement for `sed\n's/^/ /'` matches it on 6 inputs under bash 5.3 and `/bin/bash` 3.2.\n- On this machine, with the stale global config that still holds the old\ntasks, `mise tasks info lint:shell` from the worktree's `tests/`\nresolves to the worktree's `.mise.toml`, and `mise run lint:shell` exits\n0. `mise run test:ci-pins`, `test:context-budget` and `test:plugin-refs`\npass from `private_dot_config/`.\n- The global template renders to valid TOML. `tools.chezmoi` is 2.72.2\nthrough `include \".mise.toml\"`, and 13 tasks remain.\n- Not run: the new Linters step on a GitHub runner. The Ubuntu container\nrun above is the closest check.\n\n## Follow-ups\n\n- #448: apply the updated global mise config on each machine after\nmerge. Until then the stale global tasks remain, and outside the repo\n`mise run clean` still runs the old task that deletes `*.tmp` under\n`$HOME`.\n- #439: the remaining instances of this class: justfile lint recipes\nthat pass without their tool, the no-op `check` alias, tests no task\nruns, `security:audit` that cannot fail, and a luacheck that runs on Lua\n5.5 locally (`luarocks install --dev luacheck`; Homebrew's 1.2.0\ncrashes, lunarmodules/luacheck#147).\n- #443: `organize-stars.sh` reports success when `gh api` fails; the\nshellcheck commit kept that behaviour on purpose.\n\nFixes #398\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01Q6aDMonZX35gYM9ZsKUfPv\n\n---------\n\nCo-authored-by: Claude Opus 5.5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-23T10:16:45+03:00",
          "tree_id": "700386fe2c598e4ce5683bb74856e23553d29cc6",
          "url": "https://github.com/laurigates/dotfiles/commit/3b2f2be1a4a428b7f9f20d7026d820fc14d5ae23"
        },
        "date": 1790147862872,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.0077561909066666684,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00107036972,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0008966791200000001,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.018692997760000003,
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
          "id": "f603d54aedf6a9f5aa24afd27de1dce0b11b3f44",
          "message": "ci(renovate): retire the per-repo Renovate runner in favour of the account-wide App (#438)\n\n> **Pre-merge requirement.** The `laurigates-renovate` App permissions\nare granted: since 2026-09-23 `GET /apps/laurigates-renovate` lists\n`\"statuses\":\"write\"` and `\"workflows\":\"write\"`, and Lauri accepted them\non the installation. Still to confirm: the account-wide runner's next\nscheduled pass completes on this repo. Its log has no `Repository has\nchanged during renovation - aborting (repository=laurigates/dotfiles)`\nline, and #379's body is updated (its Detected Dependencies still list\n`Homebrew/actions master`, which #430 changed to `main`). The runner\nlogs that line at info level, so no dispatch is needed. Merge only after\nthat pass. If the abort persists, removing the per-repo runner leaves\nthe repo with no working Renovate.\n\n## What\n\n- Deletes `.github/workflows/renovate.yml`, the per-repo Renovate\nrunner.\n- Changes `renovate.json5` from `schedule:weekly` to\n`schedule:weekends`.\n- Adds `tests/test-renovate-single-owner.sh`, a guard that fails when a\nworkflow runs Renovate, and wires it into `.pre-commit-config.yaml`.\n\n## Why\n\nTwo Renovate identities process this repo, and neither completes:\n\n- The per-repo workflow calls `reusable-renovate.yml@main` without an\n`app-id`, so it runs on `GITHUB_TOKEN` as `github-actions[bot]` and\nmaintains dashboard #373.\n- The account-wide runner uses the `laurigates-renovate` App and\nmaintains dashboard #379.\n\nRenovate treats commits by another author on its branch as manual edits.\n`renovate/pre-commit` was last written by `laurigates-renovate[bot]`, so\n#373 lists it as \"PR Edited (Blocked)\" and never opens its PR. The App\nrebases the same branch on each pass, then aborts with\n`repository-changed`, so the App has not edited #379's body since it\ncreated the issue on 2026-08-20. `GITHUB_TOKEN` also has no `workflows`\nscope. The \"Pin dependencies\" and major GitHub Actions branches only\nedit `.github/workflows/*.yml`, so they were never created. #375 and\n#376, the two PRs this runner did open, show no CI checks.\n\nLauri decided that the account-wide App owns this repo, rather than\nkeeping the per-repo runner and excluding this repo from the App.\n\nUnder that runner, `schedule:weekly` also blocks every update. It\nresolves to `* 0-3 * * 1` in `Europe/Helsinki`, Monday 00:00-03:59. The\naccount-wide runner is scheduled twice a day, but GitHub starts it hours\nlate. Its 199 scheduled starts from 2026-06-15 to 2026-09-22 fell\nbetween 03:02Z and 08:59Z or between 12:45Z and 23:46Z, and none was on\na Monday before 04:00 Helsinki time. Renovate's docs on `schedule`\ndescribe this failure: a window that the runner rarely reaches means\nupdates are regularly skipped.\n\n## How\n\n- **Runner.** The workflow file is deleted. The App's global config\nalready includes this repo through autodiscovery.\n- **Schedule.** `schedule:weekends` is `* * * * 0,6`, the whole of\nSaturday and Sunday in Helsinki time (checked in Renovate's\n`lib/config/presets/internal/schedule.preset.ts`). It matches the App's\naccount-wide default. Keeping it explicit in `renovate.json5` makes the\nrepo config readable without the global one. `timezone`,\n`enabledManagers` and `vulnerabilityAlerts` are unchanged.\n- **Account-wide defaults.** Under the App, the account-wide defaults\nalso apply: updates wait 3 days after release (security updates\nexcepted), and major updates need approval on the Dependency Dashboard.\n- **Guard.** `tests/test-renovate-single-owner.sh` scans the `uses:`\nvalues of `.github/workflows/*.y{a,}ml` for the two runner shapes used\nin this account: `renovatebot/github-action` and callers of\n`reusable-renovate.yml`. Commented-out lines, step names and trailing\ncomments that mention a runner are not flagged. The pre-commit hook runs\nit when a workflow file changes, and CI runs it through `pre-commit run\n--all-files` in `smoke.yml`. A per-repo runner can come back without\nanyone choosing it: the claude-plugins configure-workflows skill lists\n`renovate` as a required workflow for each of its project types, and the\nfoundryvtt-module template emits one. Each run also checks the pattern\nagainst planted fixtures (two runner shapes that must be flagged, and\ntwo non-runner workflows that must not be), so a broken pattern fails\nthe test instead of passing silently. A missing workflows directory also\nfails. The guard does not detect a Renovate container image or `npx\nrenovate` in a `run:` step.\n\nNo repo docs describe the per-repo runner. A grep of `docs/`, `README*`,\nevery `CLAUDE.md` and `.github/` for `renovate.yml`, `reusable-renovate`\nand Renovate `workflow_dispatch` instructions matches only the deleted\nfile. `scripts/check-doc-references.py` reports `DANGLING_COUNT=0`.\n\n## Tests\n\nRED, the guard run against the unfixed tree (be2fd3b's\n`.github/workflows`, extracted with `git archive`):\n\n```\n$ tests/test-renovate-single-owner.sh .github/workflows\nFAIL: per-repo Renovate runner found in .github/workflows:\n  .github/workflows/renovate.yml:39:    uses: laurigates/.github/.github/workflows/reusable-renovate.yml@main\nexit=1\n```\n\nGREEN, at this branch's HEAD, under bash 5 and macOS `/bin/bash` 3.2:\n\n```\n$ tests/test-renovate-single-owner.sh\nPASS: no per-repo Renovate runner in .github/workflows\nexit=0\n```\n\nThe commit `test(renovate): flag only uses: values in the runner guard`\nnarrows the pattern to `uses:` values. Its new fixture, a step named\n`Validate renovatebot/github-action inputs`, failed against the previous\npattern before the change:\n\n```\nFAIL: control fixture name-mention.yml was flagged; the patterns match non-runner lines\nexit=1\n```\n\nControls:\n\n- Four mutated copies of the script were each run against an empty\ndirectory, which the unmutated script passes. Each substitution was\nchecked to occur exactly once before it was applied.\n- Breaking `RUNNER_RE`: `FAIL: control fixture reusable-caller.yml was\nnot flagged` and `... action.yaml was not flagged`.\n- Dropping the `^[^#]*` comment filter: `FAIL: control fixture\nvalidator-only.yml was flagged`.\n- Reverting to the previous unanchored pattern: `FAIL: control fixture\nname-mention.yml was flagged`.\n- Letting the `uses:` value run into a trailing comment: `FAIL: control\nfixture name-mention.yml was flagged`.\n  - All four exit 1.\n- Planted workflows: a SHA-pinned `renovatebot/github-action`, a\nsingle-quoted `reusable-renovate.yaml@v1` caller, a double-quoted\naction, a local `./.github/workflows/reusable-renovate.yml` caller, and\na flow-mapping `- { uses: renovatebot/github-action@v46 }` are flagged\n(exit 1). A step name and a trailing comment that mention a runner pass\n(exit 0).\n- The pre-commit hook with a planted\n`.github/workflows/zz-planted-renovate.yml` (a copy of the deleted\nworkflow) fails: `hook id: renovate-single-owner`, `exit code: 1`.\n- The pre-#369 version of the workflow, `git show\n1166447^:.github/workflows/renovate.yml`, is flagged on the action\nshape: `renovate.yml:40: uses: renovatebot/github-action@v41.0.22`.\n\nFor the schedule, both configs were evaluated with Renovate's own code\n(renovate 44.108.2): `resolveConfigPresets` followed by\n`isScheduledNow`, with luxon's clock set to each of the runner's 199\nscheduled start times. The account-wide runner currently uses 43.288.0.\n`schedule.preset.ts` and\n`lib/workers/repository/update/branch/schedule.ts` are byte-identical at\nboth tags.\n\n```\nold  schedule=[\"* 0-3 * * 1\"]  timezone=Europe/Helsinki  in_schedule=0/199   weeks_with_in_schedule_run=0/15\nnew  schedule=[\"* * * * 0,6\"]  timezone=Europe/Helsinki  in_schedule=56/199  weeks_with_in_schedule_run=14/15\n```\n\nEvery complete week gets 4 in-schedule starts. The one week with 0 is\nthe current one, which has only reached Tuesday. As a control on the\nevaluator, Mon 01:30 and Mon 03:31 Helsinki are in schedule under the\nold config and out under the new one, and Sat 13:00 is the reverse. The\ntwo resolved configs differ only in the schedule cron and its preset\ndescription.\n\n## Other instances\n\nThe same pairing of the App with a per-repo `reusable-renovate.yml`\ncaller exists outside this repo, so this PR cannot fix it. The guard\nflags all three when pointed at their workflow files:\n\n- `laurigates/foundryvtt-mediasoup-webrtc` (`renovate.yml:26`,\ndashboards #134 and #139)\n- `laurigates/foundryvtt-render-on-demand` (`renovate.yml:26`,\ndashboards #2 and #7)\n- `laurigates/claude-plugins`\n`foundryvtt-plugin/templates/foundryvtt-module/.github/workflows/renovate.yml:26`,\nthe template both repos were generated from\n\nA schedule window the runner does not reach also exists for lock file\nmaintenance. `laurigates/claude-plugins` `renovate.json:115-118` and the\nApp's account-wide default both set `lockFileMaintenance.schedule` to\n`before 4am on the first day of the month`. One of the 199 starts fell\nbefore 04:00 Helsinki (a Friday, 02:46), and the six first-of-month\nstarts fell between 08:34 and 20:48 Helsinki. `isScheduledNow` puts 0 of\n199 starts in that window, so no pass in that period could run lock file\nmaintenance. This repo is not affected: its enabled managers\n(`github-actions`, `pre-commit`, `custom.regex`) have no lock files.\n\n## Verification\n\n- `shellcheck tests/test-renovate-single-owner.sh`: exit 0.\n- `actionlint`: exit 0.\n- `pre-commit run --from-ref origin/main --to-ref HEAD`: all hooks pass,\nincluding `check no per-repo Renovate runner workflow`. `pre-commit run\nrenovate-single-owner --all-files`, the CI shape, passes.\n- The guard runs from pre-commit, both on commit and in CI. It is not a\n`mise run test` task.\n- `renovate-config-validator --strict` passes on the old and the new\n`renovate.json5`. It also passes a planted `schedule:weekendz`, so it\ndoes not check preset names. That is why the validator is not added as a\npre-commit hook: it does not detect this class of problem, and it would\nadd the full `renovate` npm package to pre-commit.\n`resolveConfigPresets` rejects the planted typo with `Cannot find\npreset's package (schedule:weekendz)`.\n- `chezmoi managed` with an isolated config and state:\n`tests/test-renovate-single-owner.sh` is not managed, because `tests/`\nis in `.chezmoiignore`.\n\n## Follow-ups\n\n- **Pre-merge:** confirm from the next scheduled run's log that the pass\non this repo has no `repository-changed` abort (permissions granted\n2026-09-23).\n- #446: post-merge handover checks (#379 refreshes, #373 closed by hand,\n`renovate/pre-commit` rebuilt, the first App PR carries CI checks, the\nfirst `renovate/chezmoi` PR is not automerged).\n- laurigates/claude-plugins#2708: the `foundryvtt-module` scaffold emits\nthe same per-repo runner; two generated repos carry it (evidence comment\nadded there).\n- laurigates/claude-plugins#2745: the `configure-workflows` skill still\nrequires a per-repo Renovate workflow, and claude-plugins'\n`lockFileMaintenance` window is never reached by the account runner.\n- #442: `renovate.json5` is not in `.chezmoiignore`, so `chezmoi apply`\nwrites it to `~/renovate.json5`.\n\nRefs #373, #379\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01Q6aDMonZX35gYM9ZsKUfPv\n\n---------\n\nCo-authored-by: Claude Opus 5.5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-23T10:59:21+03:00",
          "tree_id": "9790a04c1b398e4192af893b122fabe5d2c87289",
          "url": "https://github.com/laurigates/dotfiles/commit/f603d54aedf6a9f5aa24afd27de1dce0b11b3f44"
        },
        "date": 1790150392187,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.010369372993333332,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015415704400000001,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.00125654184,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.011669722000000002,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "b8f9fccaead99438404111aa3adc7a7d731cbb31",
          "message": "chore(deps): Pin dependencies (#451)\n\nThis PR contains the following updates:\n\n| Package | Type | Update | Change |\n|---|---|---|---|\n| [actions/cache](https://redirect.github.com/actions/cache) | action |\npin | `v4` → `v4.3.0` |\n| [actions/checkout](https://redirect.github.com/actions/checkout) |\naction | pin | `v4` → `v4.4.0` |\n|\n[actions/github-script](https://redirect.github.com/actions/github-script)\n| action | pin | `v7` → `v7.1.0` |\n| [actions/labeler](https://redirect.github.com/actions/labeler) |\naction | pin | `v5` → `v5.0.0` |\n| [actions/setup-node](https://redirect.github.com/actions/setup-node) |\naction | pin | `v4` → `v4.4.0` |\n|\n[actions/setup-python](https://redirect.github.com/actions/setup-python)\n| action | pin | `v5` → `v5.6.0` |\n|\n[actions/upload-artifact](https://redirect.github.com/actions/upload-artifact)\n| action | pin | `v4` → `v4.6.2` |\n| [anchore/sbom-action](https://redirect.github.com/anchore/sbom-action)\n| action | pin | `v0` → `v0.24.2` |\n| [anchore/scan-action](https://redirect.github.com/anchore/scan-action)\n| action | pin | `v4` → `v4.1.2` |\n|\n[anthropics/claude-code-action](https://redirect.github.com/anthropics/claude-code-action)\n| action | pin | `v1` → `v1.0.232` |\n|\n[codelytv/pr-size-labeler](https://redirect.github.com/codelytv/pr-size-labeler)\n| action | pin | `v1` → `v1.10.4` |\n| [jdx/mise-action](https://redirect.github.com/jdx/mise-action) |\naction | pin | `v4` → `v4.3.0` |\n| [laurigates/.github](https://redirect.github.com/laurigates/.github) |\naction | pinDigest | → `308861c` |\n|\n[lycheeverse/lychee-action](https://redirect.github.com/lycheeverse/lychee-action)\n| action | pinDigest | → `e747777` |\n| [oven-sh/setup-bun](https://redirect.github.com/oven-sh/setup-bun) |\naction | pin | `v2` → `v2.2.0` |\n\n---\n\n> [!WARNING]\n> Some dependencies could not be looked up. Check the [Dependency\nDashboard](../issues/379) for more information.\n\nAdd the preset `:preserveSemverRanges` to your config if you don't want\nto pin your dependencies.\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-09-23T18:24:18Z",
          "tree_id": "5b95859056a80a1a30b445c0bf4ca04a18aba877",
          "url": "https://github.com/laurigates/dotfiles/commit/b8f9fccaead99438404111aa3adc7a7d731cbb31"
        },
        "date": 1790187898209,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.008493268126666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00108274282,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0009237776200000001,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.007971688680000002,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "45f075c38d9cc8d3aae01e827d22654468a6f54f",
          "message": "chore(deps): update pre-commit hooks (#452)\n\nThis PR contains the following updates:\n\n| Package | Type | Update | Change |\n|---|---|---|---|\n|\n[JohnnyMorganz/StyLua](https://redirect.github.com/JohnnyMorganz/StyLua)\n| repository | minor | `v2.1.0` → `v2.5.2` |\n|\n[compilerla/conventional-pre-commit](https://redirect.github.com/compilerla/conventional-pre-commit)\n| repository | minor | `v4.2.0` → `v4.4.0` |\n| [gitleaks/gitleaks](https://redirect.github.com/gitleaks/gitleaks) |\nrepository | patch | `v8.30.0` → `v8.30.1` |\n| [rhysd/actionlint](https://redirect.github.com/rhysd/actionlint) |\nrepository | patch | `v1.7.7` → `v1.7.12` |\n\n---\n\n> [!WARNING]\n> Some dependencies could not be looked up. Check the [Dependency\nDashboard](../issues/379) for more information.\n\nNote: The `pre-commit` manager in Renovate is not supported by the\n`pre-commit` maintainers or community. Please do not report any problems\nthere, instead [create a Discussion in the Renovate\nrepository](https://redirect.github.com/renovatebot/renovate/discussions/new)\nif you have any questions.\n\n---\n\n### Release Notes\n\n<details>\n<summary>JohnnyMorganz/StyLua (JohnnyMorganz/StyLua)</summary>\n\n###\n[`v2.5.2`](https://redirect.github.com/JohnnyMorganz/StyLua/releases/tag/v2.5.2)\n\n[Compare\nSource](https://redirect.github.com/JohnnyMorganz/StyLua/compare/v2.5.1...v2.5.2)\n\n*There were no code changes in this release, it was just a fix to npm\npublishing, see\n<https://github.com/JohnnyMorganz/StyLua/releases/tag/v2.5.0> for the\nmain updates*\n\n#### \\[2.5.2] - 2026-05-16\n\n##### Fixed\n\n- Fixed npm publishing failing provenance validation due to\nnormalization of repository URL\n\n**Full Changelog**:\n<https://github.com/JohnnyMorganz/StyLua/compare/v2.5.1...v2.5.2>\n\n###\n[`v2.5.1`](https://redirect.github.com/JohnnyMorganz/StyLua/releases/tag/v2.5.1)\n\n[Compare\nSource](https://redirect.github.com/JohnnyMorganz/StyLua/compare/v2.5.0...v2.5.1)\n\n*There were no code changes in this release, it was an attempt to fix\nnpm publishing, see\n<https://github.com/JohnnyMorganz/StyLua/releases/tag/v2.5.0> for the\nmain updates*\n\n#### \\[2.5.1] - 2026-05-16\n\n##### Fixed\n\n- Fixed npm publishing by bumping Node.js from 22 to 24 in CI workflows\nto support npm trusted publishing\n\n**Full Changelog**:\n<https://github.com/JohnnyMorganz/StyLua/compare/v2.5.0...v2.5.1>\n\n###\n[`v2.5.0`](https://redirect.github.com/JohnnyMorganz/StyLua/releases/tag/v2.5.0)\n\n[Compare\nSource](https://redirect.github.com/JohnnyMorganz/StyLua/compare/v2.4.1...v2.5.0)\n\n#### \\[2.5.0] - 2026-05-16\n\n##### Added\n\n- Luau: Added support for `const` variable assignments (`const x = 1`)\nand `const function` declarations\n([#&#8203;1102](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1102))\n\n##### Changed\n\n- The npm package `@johnnymorganz/stylua-bin` now ships pre-built\nbinaries via platform-specific optional packages\n(`@johnnymorganz/stylua-bin-linux-x64`, `-linux-arm64`, `-darwin-x64`,\n`-darwin-arm64`, `-win32-x64`) instead of downloading the binary at\ninstall time. This makes the packages self-contained with no extra\ndependencies.\n\n##### Fixed\n\n- Fixed npm publishing by bumping Node.js from 16 to 22 in CI workflows\nto support npm trusted publishing\n- Luau: Fixed union/intersection type definitions not being hung when\nthe type alone fits within the column width but the full line (including\n`=`) exceeds it\n([#&#8203;1104](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1104))\n- Luau: Fixed stray leading newlines not being removed from `local\nfunction` and `const function` declarations that have attributes (e.g.\n`@native`) at the start of a block\n([#&#8203;1109](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1109))\n\n***\n\n**Full Changelog**:\n<https://github.com/JohnnyMorganz/StyLua/compare/v2.4.1...v2.5.0>\n\n###\n[`v2.4.1`](https://redirect.github.com/JohnnyMorganz/StyLua/releases/tag/v2.4.1)\n\n[Compare\nSource](https://redirect.github.com/JohnnyMorganz/StyLua/compare/v2.4.0...v2.4.1)\n\n#### \\[2.4.1] - 2026-04-06\n\n##### Fixed\n\n- Luau: Fixed panic when formatting explicit type instantiation\n(`f<<T>>()`) inside a nested function call argument (e.g. as a callback)\n([#&#8203;1088](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1088))\n- Luau: Fixed parentheses being incorrectly removed from single-element\ntype packs in explicit type instantiation, e.g. `f<<(number)>>(10)`\nbecoming `f<<number>>(10)`\n([#&#8203;1089](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1089))\n\n***\n\n**Full Changelog**:\n<https://github.com/JohnnyMorganz/StyLua/compare/v2.4.0...v2.4.1>\n\n###\n[`v2.4.0`](https://redirect.github.com/JohnnyMorganz/StyLua/releases/tag/v2.4.0)\n\n[Compare\nSource](https://redirect.github.com/JohnnyMorganz/StyLua/compare/v2.3.1...v2.4.0)\n\n#### \\[2.4.0] - 2026-03-07\n\n##### Added\n\n- Added flag `--no-ignore-vcs` to continue formatting files listed in a\n`.gitignore` file, instead of skipping over them\n([#&#8203;895](https://redirect.github.com/JohnnyMorganz/StyLua/issues/895))\n- Support `call_parentheses = Input` in editorconfig\n([#&#8203;1057](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1057))\n- Luau: Support formatting explicit type instantiations (`f<<T>>()`,\n`obj:method<<T>>()`)\n- Support `stylua_syntax` and `stylua_block_newline_gaps` properties in\neditorconfig\n([#&#8203;1054](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1054))\n\n##### Fixed\n\n- Fixed syntax error in output when a single-line comment appears\nbetween an index suffix and a table call argument, e.g. `foo.bar --\ncomment { }`\n([#&#8203;873](https://redirect.github.com/JohnnyMorganz/StyLua/issues/873))\n- Fixed malformed formatting when a binary expression inside of a\nfunction call with comments around the operators is incorrectly\ncollapsed onto one line\n([#&#8203;996](https://redirect.github.com/JohnnyMorganz/StyLua/issues/996))\n- Fixed repeated unary minus on long lines being collapsed into a\ncomment, e.g. `- - - - -5` becoming `-----5`\n([#&#8203;1075](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1075))\n- Fixed `--preserve-block-newline-gaps` CLI flag not being applied as a\nconfig override\n- Fixed LSP not respecting `.stylua.toml` on Windows due to incorrect\nfile URI to path conversion\n([#&#8203;1051](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1051))\n\n***\n\n#### External Contributions\n\n- Remove WASM build workaround by\n[@&#8203;magic-akari](https://redirect.github.com/magic-akari) in\n[#&#8203;1060](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1060)\n- Fix `call_parentheses = Input` don't work in editorconfig by\n[@&#8203;phanen](https://redirect.github.com/phanen) in\n[#&#8203;1057](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1057)\n- Fix path conversion on Windows by\n[@&#8203;8LWXpg](https://redirect.github.com/8LWXpg) in\n[#&#8203;1068](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1068)\n\n#### New Contributors\n\n- [@&#8203;8LWXpg](https://redirect.github.com/8LWXpg) made their first\ncontribution in\n[#&#8203;1068](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1068)\n\n**Full Changelog**:\n<https://github.com/JohnnyMorganz/StyLua/compare/v2.3.1...v2.4.0>\n\n###\n[`v2.3.1`](https://redirect.github.com/JohnnyMorganz/StyLua/releases/tag/v2.3.1)\n\n[Compare\nSource](https://redirect.github.com/JohnnyMorganz/StyLua/compare/v2.3.0...v2.3.1)\n\n#### \\[2.3.1] - 2025-11-01\n\n##### Fixed\n\n- Use character-wised diff instead of byte-wise diff in the LSP server\nso that it can handle multi-byte characters\n([#&#8203;1042](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1042),\n[#&#8203;1043](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1043)).\n\n***\n\n#### External Contributions\n\n- fix: Handle Unicode characters in LSP formatting by\n[@&#8203;Davidyz](https://redirect.github.com/Davidyz) in\n[#&#8203;1044](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1044)\n\n#### New Contributors\n\n- [@&#8203;Davidyz](https://redirect.github.com/Davidyz) made their\nfirst contribution in\n[#&#8203;1044](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1044)\n\n**Full Changelog**:\n<https://github.com/JohnnyMorganz/StyLua/compare/v2.3.0...v2.3.1>\n\n###\n[`v2.3.0`](https://redirect.github.com/JohnnyMorganz/StyLua/releases/tag/v2.3.0)\n\n[Compare\nSource](https://redirect.github.com/JohnnyMorganz/StyLua/compare/v2.2.0...v2.3.0)\n\n#### \\[2.3.0] - 2025-09-27\n\n##### Added\n\n- The language server has an initialization option called\n`respect_editor_formatting_options`.\nIf it's true, the formatting handler will override the configurations\n`indent-width` and `indent-type` with values from\n[FormattingOptions](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#formattingOptions)\n\n##### Changed\n\n- In language server mode, compute the difference between the\nunformatted and formatted document and only respond with the changes,\nrather than sending an edit for the whole file\n- Include `serverInfo` in the language server's\n[`InitializeResponse`](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#initializeResult)\n\n##### Fixed\n\n- Fixed comments lost from expression after parentheses are removed when\nwe are attempting to \"hang\" the expression.\n([#&#8203;1033](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1033))\n- Fixed `document_range_formatting_provider` capability missing from\n`ServerCapabilities` in language server mode\n- Fixed current working directory incorrectly used as config search root\nin language server mode -- now, the root of the opened workspace is used\ninstead\n([#&#8203;1032](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1032))\n- Language server mode now correctly respects `.styluaignore` files\n([#&#8203;1035](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1035))\n- Luau: Fixed parentheses incorrectly removed on a single type that is\nthe default for a variadic generic parameter\n([#&#8203;1038](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1038))\n\n***\n\n#### External Contributions\n\n- Smaller text edits in lsp formatting handler by\n[@&#8203;TungstnBallon](https://redirect.github.com/TungstnBallon) in\n[#&#8203;1031](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1031)\n\n#### New Contributors\n\n- [@&#8203;TungstnBallon](https://redirect.github.com/TungstnBallon)\nmade their first contribution in\n[#&#8203;1031](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1031)\n\n**Full Changelog**:\n<https://github.com/JohnnyMorganz/StyLua/compare/v2.2.0...v2.3.0>\n\n###\n[`v2.2.0`](https://redirect.github.com/JohnnyMorganz/StyLua/releases/tag/v2.2.0)\n\n[Compare\nSource](https://redirect.github.com/JohnnyMorganz/StyLua/compare/v2.1.0...v2.2.0)\n\n#### \\[2.2.0] - 2025-09-14\n\n##### Added\n\n- Added option `block_newline_gaps` to determine whether newline gaps at\nthe start / end of blocks should be preserved. Defaults to `Never`,\nwhich is the original behaviour.\n([#&#8203;857](https://redirect.github.com/JohnnyMorganz/StyLua/pull/857))\n- StyLua can now run in a language server mode. Start StyLua with\n`stylua --lsp` and connect with a language client.\n([#&#8203;936](https://redirect.github.com/JohnnyMorganz/StyLua/issues/936))\n\n##### Changed\n\n- Luau: Improved union of tables formatting to hang the union type\nrather than attempt to hug all the tables together\n([#&#8203;958](https://redirect.github.com/JohnnyMorganz/StyLua/issues/958))\n\n##### Fixed\n\n- Fixed formatting of index containing brackets string in parentheses\n([#&#8203;992](https://redirect.github.com/JohnnyMorganz/StyLua/pull/992))\n- Fixed goto not being recognised for LuaJIT\n([#&#8203;986](https://redirect.github.com/JohnnyMorganz/StyLua/issues/986))\n- Fixed semicolon removed after a statement ending with an if-expression\nleading to ambiguous syntax when the next line begins with parentheses\n([#&#8203;1010](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1010))\n- Luau: Fixed malformed formatting when there is a comment after a type\nspecifier in a local assignment\n([#&#8203;995](https://redirect.github.com/JohnnyMorganz/StyLua/issues/995))\n- Luau: Fixed long type union formatted onto a single line if there is a\ncomment in between the equals sign and the type union in a type\ndeclaration\n([#&#8203;1007](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1007))\n- Fixed StyLua installation via pip / uv for Windows\n([#&#8203;1018](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1018))\n\n***\n\n#### External Contributions\n\n- Fix formatting of index containing brackets string in parentheses by\n[@&#8203;phanen](https://redirect.github.com/phanen) in\n[#&#8203;992](https://redirect.github.com/JohnnyMorganz/StyLua/pull/992)\n- Fix goto not being recognised for LuaJIT by\n[@&#8203;Sainan](https://redirect.github.com/Sainan) in\n[#&#8203;998](https://redirect.github.com/JohnnyMorganz/StyLua/pull/998)\n- Add option to preserve newline gaps for blocks by\n[@&#8203;InoUno](https://redirect.github.com/InoUno) in\n[#&#8203;857](https://redirect.github.com/JohnnyMorganz/StyLua/pull/857)\n- feat: Stylua LSP server by\n[@&#8203;PolyMeilex](https://redirect.github.com/PolyMeilex) in\n[#&#8203;970](https://redirect.github.com/JohnnyMorganz/StyLua/pull/970)\n- fix(release-gitter): correct Windows asset name for pip build by\n[@&#8203;izzalDev](https://redirect.github.com/izzalDev) in\n[#&#8203;1018](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1018)\n\n#### New Contributors\n\n- [@&#8203;Sainan](https://redirect.github.com/Sainan) made their first\ncontribution in\n[#&#8203;998](https://redirect.github.com/JohnnyMorganz/StyLua/pull/998)\n- [@&#8203;InoUno](https://redirect.github.com/InoUno) made their first\ncontribution in\n[#&#8203;857](https://redirect.github.com/JohnnyMorganz/StyLua/pull/857)\n- [@&#8203;PolyMeilex](https://redirect.github.com/PolyMeilex) made\ntheir first contribution in\n[#&#8203;970](https://redirect.github.com/JohnnyMorganz/StyLua/pull/970)\n- [@&#8203;izzalDev](https://redirect.github.com/izzalDev) made their\nfirst contribution in\n[#&#8203;1018](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1018)\n\n**Full Changelog**:\n<https://github.com/JohnnyMorganz/StyLua/compare/v2.1.0...v2.2.0>\n\n</details>\n\n<details>\n<summary>compilerla/conventional-pre-commit\n(compilerla/conventional-pre-commit)</summary>\n\n###\n[`v4.4.0`](https://redirect.github.com/compilerla/conventional-pre-commit/releases/tag/v4.4.0)\n\n[Compare\nSource](https://redirect.github.com/compilerla/conventional-pre-commit/compare/v4.3.0...v4.4.0)\n\n#### What's Changed\n\n- chore(pre-commit): autoupdate hooks by\n[@&#8203;pre-commit-ci](https://redirect.github.com/pre-commit-ci)\\[bot]\nin\n[#&#8203;141](https://redirect.github.com/compilerla/conventional-pre-commit/pull/141)\n- feat: allow # in scope by\n[@&#8203;aeyoll](https://redirect.github.com/aeyoll) in\n[#&#8203;148](https://redirect.github.com/compilerla/conventional-pre-commit/pull/148)\n- chore(pre-commit): autoupdate hooks by\n[@&#8203;pre-commit-ci](https://redirect.github.com/pre-commit-ci)\\[bot]\nin\n[#&#8203;144](https://redirect.github.com/compilerla/conventional-pre-commit/pull/144)\n- chore(deps): bump actions/checkout from 5 to 6 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;143](https://redirect.github.com/compilerla/conventional-pre-commit/pull/143)\n\n#### New Contributors\n\n- [@&#8203;aeyoll](https://redirect.github.com/aeyoll) made their first\ncontribution in\n[#&#8203;148](https://redirect.github.com/compilerla/conventional-pre-commit/pull/148)\n\n**Full Changelog**:\n<https://github.com/compilerla/conventional-pre-commit/compare/v4.3.0...v4.4.0>\n\n###\n[`v4.3.0`](https://redirect.github.com/compilerla/conventional-pre-commit/releases/tag/v4.3.0)\n\n[Compare\nSource](https://redirect.github.com/compilerla/conventional-pre-commit/compare/v4.2.0...v4.3.0)\n\n#### What's Changed\n\n- fix: scope now allows usage of dots by\n[@&#8203;ddluke](https://redirect.github.com/ddluke) in\n[#&#8203;140](https://redirect.github.com/compilerla/conventional-pre-commit/pull/140)\n- chore(deps): bump actions/setup-python from 5 to 6 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;138](https://redirect.github.com/compilerla/conventional-pre-commit/pull/138)\n- chore(deps): bump actions/checkout from 4 to 5 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;137](https://redirect.github.com/compilerla/conventional-pre-commit/pull/137)\n- chore(pre-commit): autoupdate hooks by\n[@&#8203;pre-commit-ci](https://redirect.github.com/pre-commit-ci)\\[bot]\nin\n[#&#8203;136](https://redirect.github.com/compilerla/conventional-pre-commit/pull/136)\n\n#### New Contributors\n\n- [@&#8203;ddluke](https://redirect.github.com/ddluke) made their first\ncontribution in\n[#&#8203;140](https://redirect.github.com/compilerla/conventional-pre-commit/pull/140)\n\n**Full Changelog**:\n<https://github.com/compilerla/conventional-pre-commit/compare/v4.2.0...v4.3.0>\n\n</details>\n\n<details>\n<summary>gitleaks/gitleaks (gitleaks/gitleaks)</summary>\n\n###\n[`v8.30.1`](https://redirect.github.com/gitleaks/gitleaks/releases/tag/v8.30.1)\n\n[Compare\nSource](https://redirect.github.com/gitleaks/gitleaks/compare/v8.30.0...v8.30.1)\n\n#### Changelog\n\n-\n[`83d9cd6`](https://redirect.github.com/gitleaks/gitleaks/commit/83d9cd684c87d95d656c1458ef04895a7f1cbd8e)\nupdate goreleaser\n-\n[`8d1f98c`](https://redirect.github.com/gitleaks/gitleaks/commit/8d1f98c7967eb1e79cb44ac6241a124e145d2165)\nRemoved unnecessary functions from report template\n([#&#8203;2040](https://redirect.github.com/gitleaks/gitleaks/issues/2040))\n-\n[`ca20267`](https://redirect.github.com/gitleaks/gitleaks/commit/ca20267a84aa1fa2c2a9c1a13cdb50cafb48eeb0)\nits the simple things\n([#&#8203;2020](https://redirect.github.com/gitleaks/gitleaks/issues/2020))\n-\n[`b66ac75`](https://redirect.github.com/gitleaks/gitleaks/commit/b66ac75e4fa93d86d78fccd6e2f36d2c0698b2a2)\nbuild: switch to Go 1.24\n([#&#8203;2002](https://redirect.github.com/gitleaks/gitleaks/issues/2002))\n\n</details>\n\n<details>\n<summary>rhysd/actionlint (rhysd/actionlint)</summary>\n\n###\n[`v1.7.12`](https://redirect.github.com/rhysd/actionlint/blob/HEAD/CHANGELOG.md#v1712---2026-03-30)\n\n[Compare\nSource](https://redirect.github.com/rhysd/actionlint/compare/v1.7.11...v1.7.12)\n\n- Support the [`timezone` configuration in\n`on.schedule`](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onschedule)\nwith checks for IANA timezone string. See the\n[documentation](https://redirect.github.com/rhysd/actionlint/blob/main/docs/checks.md#check-cron-syntax-and-timezone)\nfor more details. Note that actionlint starts to embed the timezone\ndatabase in the executables from this version so the binary sizes\nslightly increase.\n([#&#8203;641](https://redirect.github.com/rhysd/actionlint/issues/641),\nthanks\n[@&#8203;martincostello](https://redirect.github.com/martincostello))\n  ```yaml\n  on:\n    schedule:\n      # ERROR: The timezone is not a valid IANA timezone string\n      - cron: '*/5 * * * *'\n        timezone: 'Asia/Somewhere'\n  ```\n- Support the [`jobs.<job_name>.environment.deployment`\nconfiguration](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/control-deployments#using-environments-without-deployments).\n([#&#8203;639](https://redirect.github.com/rhysd/actionlint/issues/639),\nthanks [@&#8203;springmeyer](https://redirect.github.com/springmeyer))\n- Support the [`macos-26-intel` runner\nlabel](https://github.blog/changelog/2026-02-26-macos-26-is-now-generally-available-for-github-hosted-runners/).\n([#&#8203;629](https://redirect.github.com/rhysd/actionlint/issues/629),\nthanks [@&#8203;hugovk](https://redirect.github.com/hugovk))\n- Fix the [table of webhook activity\ntypes](https://redirect.github.com/rhysd/actionlint/blob/main/all_webhooks.go)\nare outdated by rebuilding the [script to scrape the\ntable](https://redirect.github.com/rhysd/actionlint/tree/main/scripts/generate-webhook-events)\nfrom scratch.\n- Support Go 1.26 and drop the support for Go 1.24. Now supported\nversions are 1.25 and 1.26.\n- Tests are run on arm64 Windows in CI.\n- Update the popular actions data set to the latest.\n\n\\[Changes]\\[v1.7.12]\n\n<a id=\"v1.7.11\"></a>\n\n###\n[`v1.7.11`](https://redirect.github.com/rhysd/actionlint/blob/HEAD/CHANGELOG.md#v1711---2026-02-14)\n\n[Compare\nSource](https://redirect.github.com/rhysd/actionlint/compare/v1.7.10...v1.7.11)\n\n- Support the [`case()`\nfunction](https://docs.github.com/en/actions/reference/workflows-and-actions/expressions#case)\nin `${{ }}` expressions which was recently added to GitHub Actions.\n([#&#8203;612](https://redirect.github.com/rhysd/actionlint/issues/612),\n[#&#8203;614](https://redirect.github.com/rhysd/actionlint/issues/614),\nthanks [@&#8203;heppu](https://redirect.github.com/heppu))\n  ```yaml\n  env:\n    # ERROR: case() requires an odd number of arguments\n    ENVIRONMENT: |-\n      ${{ case(\n        github.ref == 'refs/heads/main', 'production',\n        github.ref == 'refs/heads/staging', 'staging'\n      ) }}\n  ```\n- Support new `macos-26-large` and `windows-2025-vs2026` runner labels.\nSee the [GitHub's\nannounce](https://github.blog/changelog/2026-02-05-github-actions-early-february-2026-updates/)\nfor more details.\n([#&#8203;615](https://redirect.github.com/rhysd/actionlint/issues/615),\nthanks [@&#8203;hugovk](https://redirect.github.com/hugovk) and\n[@&#8203;muzimuzhi](https://redirect.github.com/muzimuzhi))\n- Enable [Artifact\nattestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)\nfor the released binaries. From v1.7.11 [`gh`\ncommand](https://cli.github.com/) can verify the integrity of the\ndownloaded binaries as follows. The verification is highly recommended\nin terms of supply chain security.\n([#&#8203;608](https://redirect.github.com/rhysd/actionlint/issues/608),\nthanks [@&#8203;takaram](https://redirect.github.com/takaram))\n  ```console\n$ gh release download --repo rhysd/actionlint --pattern\n'*_darwin_amd64.tar.gz' v1.7.11\n$ gh attestation verify --repo rhysd/actionlint\nactionlint_1.7.11_darwin_amd64.tar.gz\nLoaded digest\nsha256:17ffc17fed8f0258ef6ad4aed932d3272464c7ef7d64e1cb0d65aa97c9752107\nfor file://actionlint_1.7.11_darwin_amd64.tar.gz\n  Loaded 1 attestation from GitHub API\n\n  The following policy criteria will be enforced:\n- Predicate type must match:................\nhttps://slsa.dev/provenance/v1\n  - Source Repository Owner URI must match:... https://github.com/rhysd\n- Source Repository URI must match:.........\nhttps://github.com/rhysd/actionlint\n- Subject Alternative Name must match regex:\n(?i)^https://github.com/rhysd/actionlint/\n- OIDC Issuer must match:...................\nhttps://token.actions.githubusercontent.com\n\n  ✓ Verification succeeded!\n\n  The following 1 attestation matched the policy criteria\n\n  - Attestation #&#8203;1\n    - Build repo:..... rhysd/actionlint\n    - Build workflow:. .github/workflows/release.yaml@refs/tags/v1.7.11\n    - Signer repo:.... rhysd/actionlint\n    - Signer workflow: .github/workflows/release.yaml@refs/tags/v1.7.11\n  ```\n- Report path filters with `./` as error because they never match\nanything.\n([#&#8203;521](https://redirect.github.com/rhysd/actionlint/issues/521))\n  ```yaml\n  on:\n    push:\n      paths:\n        # ERROR: This never matches anything. `foo/bar.txt` is correct.\n        - ./foo/bar.txt\n  ```\n- Fix comparing matrix items when an item is a super set of another\nitem.\n([#&#8203;523](https://redirect.github.com/rhysd/actionlint/issues/523),\n[#&#8203;613](https://redirect.github.com/rhysd/actionlint/issues/613),\nthanks\n[@&#8203;michaelgruenewald](https://redirect.github.com/michaelgruenewald))\n- Fix stack overflow crash by a recursive anchor in matrix items.\n([#&#8203;610](https://redirect.github.com/rhysd/actionlint/issues/610))\n- Fix an unassigned variable false positive from shellcheck by disabling\nSC2153 rule.\n([#&#8203;573](https://redirect.github.com/rhysd/actionlint/issues/573))\n- Reduce the number of memory allocations on resolving anchors.\n- Update the popular actions data set to the latest.\n- Update Go dependencies to the latest.\n- Remove legacy Homebrew formula in rhysd/actionlint repository in favor\nof the [cask\npackage](https://redirect.github.com/rhysd/actionlint/blob/main/Casks/actionlint.rb).\nNote that this change does not affect Homebrew's official formula.\n- Add a link to the release page of the version in the\n[playground](https://rhysd.github.io/actionlint/).\n\n\\[Changes]\\[v1.7.11]\n\n<a id=\"v1.7.10\"></a>\n\n###\n[`v1.7.10`](https://redirect.github.com/rhysd/actionlint/blob/HEAD/CHANGELOG.md#v1710---2025-12-30)\n\n[Compare\nSource](https://redirect.github.com/rhysd/actionlint/compare/v1.7.9...v1.7.10)\n\n- Support [YAML anchors and\naliases](https://yaml.org/spec/1.2.2/#&#8203;71-alias-nodes) (`&anchor`\nand `*anchor`) in workflow files. In addition to parsing YAML anchors\ncorrectly, actionlint checks unused and undefined anchors. See the\n[document](https://redirect.github.com/rhysd/actionlint/blob/main/docs/checks.md#yaml-anchors)\nfor more details.\n([#&#8203;133](https://redirect.github.com/rhysd/actionlint/issues/133),\nthanks [@&#8203;srz-zumix](https://redirect.github.com/srz-zumix) for\nthe initial implementation at\n[#&#8203;568](https://redirect.github.com/rhysd/actionlint/issues/568)\nand [@&#8203;alexaandru](https://redirect.github.com/alexaandru) for\ntrying another approach at\n[#&#8203;557](https://redirect.github.com/rhysd/actionlint/issues/557))\n  ```yaml\n  jobs:\n    test:\n      runs-on: ubuntu-latest\n      services:\n        nginx:\n          image: nginx:latest\n          credentials: &credentials\n            username: ${{ secrets.user }}\n            password: ${{ secrets.password }}\n      steps:\n        - run: ./download.sh\n          # OK: Valid alias to &credentials\n          env: *credentials\n        - run: ./check.sh\n          # ERROR: Undefined anchor 'credential'\n          env: *credential\n        - run: ./upload.sh\n          # ERROR: Unused anchor 'credentials'\n          env: &credentials\n  ```\n- Remove support for `*-xl` macOS runner labels because they were\n[dropped](https://github.blog/changelog/2024-08-19-notice-of-upcoming-deprecations-and-breaking-changes-in-github-actions-runners/).\n([#&#8203;592](https://redirect.github.com/rhysd/actionlint/issues/592),\nthanks [@&#8203;muzimuzhi](https://redirect.github.com/muzimuzhi))\n- Remove support for the macOS 13 runner labels because they were\n[dropped on Dec 4,\n2025](https://github.blog/changelog/2025-09-19-github-actions-macos-13-runner-image-is-closing-down/).\n([#&#8203;593](https://redirect.github.com/rhysd/actionlint/issues/593),\nthanks [@&#8203;muzimuzhi](https://redirect.github.com/muzimuzhi))\n  - `macos-13`\n  - `macos-13-large`\n  - `macos-13-xlarge`\n- Increase the maximum number of inputs in the `workflow_dispatch` event\nfrom 10 to 25 because the limitation [was recently\nrelaxed](https://github.blog/changelog/2025-12-04-actions-workflow-dispatch-workflows-now-support-25-inputs/).\n([#&#8203;598](https://redirect.github.com/rhysd/actionlint/issues/598),\nthanks [@&#8203;Haegi](https://redirect.github.com/Haegi))\n- Support [`artifact-metadata`\npermission](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#defining-access-for-the-github_token-scopes)\nfor workflow permissions.\n([#&#8203;602](https://redirect.github.com/rhysd/actionlint/issues/602),\nthanks\n[@&#8203;martincostello](https://redirect.github.com/martincostello))\n- Detect more complicated constants at `if:` conditions as error. See\nthe [rule\ndocument](https://redirect.github.com/rhysd/actionlint/blob/main/docs/checks.md#if-cond-constant)\nfor more details.\n- Refactor the workflow parser with [Go\niterators](https://pkg.go.dev/iter#hdr-Iterators). This slightly\nimproves the performance and memory usage.\n- Fix parsing extra `{` and `}` characters in format string of\n`format()` function call. For example v1.7.9 didn't parse `\"{{0} {1}\n{2}}\"` correctly.\n- Detect an invalid value at `type` in workflow call inputs as error.\n- Report [YAML merge key](https://yaml.org/type/merge.html) `<<` as\nerror because GitHub Actions doesn't support the syntax.\n- Check available contexts in expressions at\n`jobs.<job_id>.snapshot.if`.\n  ```yaml\n  snapshot:\n    image-name: my-custom-image\n    # ERROR: `env` context is not allowed here\n    if: ${{ env.USE_SNAPSHOT == 'true' }}\n  ```\n- Fix the instruction to install actionlint with `mise` in the\ninstallation document.\n([#&#8203;591](https://redirect.github.com/rhysd/actionlint/issues/591),\nthanks [@&#8203;risu729](https://redirect.github.com/risu729))\n- Update the popular actions data set to the latest to include new major\nversions of the actions.\n\n\\[Changes]\\[v1.7.10]\n\n<a id=\"v1.7.9\"></a>\n\n###\n[`v1.7.9`](https://redirect.github.com/rhysd/actionlint/blob/HEAD/CHANGELOG.md#v179---2025-11-21)\n\n[Compare\nSource](https://redirect.github.com/rhysd/actionlint/compare/v1.7.8...v1.7.9)\n\n- Add support for [`ubuntu-slim`\nrunner](https://github.blog/changelog/2025-10-28-1-vcpu-linux-runner-now-available-in-github-actions-in-public-preview/)\nlabel.\n([#&#8203;585](https://redirect.github.com/rhysd/actionlint/issues/585),\nthanks [@&#8203;cestorer](https://redirect.github.com/cestorer))\n- Check input deprecation in action by checking [`deprecationMessage`\nproperty](https://docs.github.com/en/actions/reference/workflows-and-actions/metadata-syntax#inputsinput_iddeprecationmessage).\nUsing a deprecated input is reported as error if it is not marked as\n`required`. See [the\ndocument](https://redirect.github.com/rhysd/actionlint/blob/main/docs/checks.md#deprecated-inputs-usage)\nfor more details.\n([#&#8203;580](https://redirect.github.com/rhysd/actionlint/issues/580))\n  ```yaml\n  - uses: reviewdog/action-actionlint@v1\n    with:\n      # ERROR: Using a deprecated input\n      fail_on_error: true\n  ```\n- Add support for the [Custom\nimages](https://docs.github.com/en/actions/how-tos/manage-runners/larger-runners/use-custom-images)\nfeature.\n- Support [`image_version` workflow\ntrigger](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#image_version).\n    ```yaml\n    on:\n      image_version:\n        names:\n          - \"MyNewImage\"\n          - \"MyOtherImage\"\n        versions:\n          - 1.*\n          - 2.*\n    ```\n- Support [`jobs.<job_id>.snapshot`\nsyntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idsnapshot).\nTo make actionlint recognize your own image generation runner, use\n[`self-hosted-runner.labels`\nconfig](https://redirect.github.com/rhysd/actionlint/blob/main/docs/config.md).\n    ```yaml\n    jobs:\n      build:\n        runs-on: my-image-generation-runner\n        snapshot:\n            image-name: my-custom-image\n            version: 2.*\n    ```\n- Report constant conditions at `if:` like `if: true` as error. Only\nvery simple expressions like `true` or `false` are detected for now. See\nthe\n[document](https://redirect.github.com/rhysd/actionlint/blob/main/docs/checks.md#if-cond-constant)\nfor more details.\n- Check unexpected keys in inputs in [action\nmetadata](https://docs.github.com/en/actions/reference/workflows-and-actions/metadata-syntax).\n  ```yaml\n  inputs:\n    some_input:\n      # Error: `type` is not supported for inputs in action metadata\n      type: boolean\n  ```\n- Fix some invalid permissions are not reported as error in `id-token`\nand `models` scopes.\n([#&#8203;582](https://redirect.github.com/rhysd/actionlint/issues/582),\nthanks [@&#8203;holtkampjs](https://redirect.github.com/holtkampjs))\n- Fix `args` and `entrypoint` inputs are not recognized at `uses:` when\nit's not a Docker action.\n([#&#8203;550](https://redirect.github.com/rhysd/actionlint/issues/550))\n- Set correct column in source position of YAML parse error.\n- Fix `credentials` cannot be configured with `${{ }}`.\n([#&#8203;590](https://redirect.github.com/rhysd/actionlint/issues/590))\n- Improve messages in syntax errors on parsing steps (`run:` and\n`uses:`). Available keys suggestion is now more accurate and unexpected\nkeys are detected more accurately.\n- Fix the order of errors can be non-deterministic when multiple errors\nare caused at the same source positions.\n- Improve error messages showing suggestions on detecting invalid\npermissions.\n- Add instruction for installing actionlint with [mise package\nmanager](https://mise.jdx.dev/getting-started.html).\n([#&#8203;589](https://redirect.github.com/rhysd/actionlint/issues/589),\nthanks [@&#8203;jylenhof](https://redirect.github.com/jylenhof))\n- Fix outdated URLs in the document.\n- Add new [`actionlint.AllContexts` map\nconstant](https://pkg.go.dev/github.com/rhysd/actionlint#pkg-variables)\nin Go API that contains the information about all context availability.\n- Update popular actions data set to the latest with several major\nversions of actions and the following new actions.\n  - `anthropics/claude-code-action`\n  - `openai/codex-action`\n  - `google-github-actions/run-gemini-cli`\n- Add `make cov` task to easily generate a code coverage report.\n- Make installing the formula version of `actionlint` pacakge from tap\nof this repository with Homebrew a hard error. Install the cask version\ninstead following the instruction in the error message.\n\n\\[Changes]\\[v1.7.9]\n\n<a id=\"v1.7.8\"></a>\n\n###\n[`v1.7.8`](https://redirect.github.com/rhysd/actionlint/blob/HEAD/CHANGELOG.md#v178---2025-10-11)\n\n[Compare\nSource](https://redirect.github.com/rhysd/actionlint/compare/v1.7.7...v1.7.8)\n\n- Support `models` permission in `permissions` section.\n([#&#8203;531](https://redirect.github.com/rhysd/actionlint/issues/531),\nthanks [@&#8203;muzimuzhi](https://redirect.github.com/muzimuzhi))\n- Support [`job.check_run_id`\nproperty](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#job-context).\n([#&#8203;576](https://redirect.github.com/rhysd/actionlint/issues/576),\nthanks [@&#8203;muzimuzhi](https://redirect.github.com/muzimuzhi) for\nfixing the type at\n[#&#8203;577](https://redirect.github.com/rhysd/actionlint/issues/577))\n- Support `node24` runtime at `using` section in action metadata.\n([#&#8203;561](https://redirect.github.com/rhysd/actionlint/issues/561),\nthanks [@&#8203;salmanmkc](https://redirect.github.com/salmanmkc))\n- Add support for the following runner labels.\n- [`macos-26` and\n`macos-26-xlarge`](https://github.blog/changelog/2025-09-11-actions-macos-26-image-now-in-public-preview/)\n([#&#8203;572](https://redirect.github.com/rhysd/actionlint/issues/572),\nthanks [@&#8203;muzimuzhi](https://redirect.github.com/muzimuzhi))\n-\n[`macos-15`](https://github.blog/changelog/2025-09-19-github-actions-macos-13-runner-image-is-closing-down/#what-you-need-to-do)\n([#&#8203;572](https://redirect.github.com/rhysd/actionlint/issues/572),\nthanks [@&#8203;muzimuzhi](https://redirect.github.com/muzimuzhi))\n- Drop support for the following runner labels which are no longer\nsupported by GitHub.\n-\n[`ubuntu-20.04`](https://redirect.github.com/actions/runner-images/issues/11101)\n([#&#8203;534](https://redirect.github.com/rhysd/actionlint/issues/534),\nthanks [@&#8203;shogo82148](https://redirect.github.com/shogo82148))\n-\n[`windows-2019`](https://github.blog/changelog/2025-04-15-upcoming-breaking-changes-and-releases-for-github-actions/#windows-server-2019-is-closing-down)\n([#&#8203;572](https://redirect.github.com/rhysd/actionlint/issues/572),\nthanks [@&#8203;muzimuzhi](https://redirect.github.com/muzimuzhi))\n- Support\n[`deprecationMessage`](https://docs.github.com/en/actions/reference/workflows-and-actions/metadata-syntax#inputsinput_iddeprecationmessage)\nin action inputs metadata.\n([#&#8203;540](https://redirect.github.com/rhysd/actionlint/issues/540),\nthanks [@&#8203;saansh45](https://redirect.github.com/saansh45))\n- Support [`windows-11-arm`\nrunner](https://github.blog/changelog/2025-04-14-windows-arm64-hosted-runners-now-available-in-public-preview/).\n([#&#8203;542](https://redirect.github.com/rhysd/actionlint/issues/542),\nthanks [@&#8203;trim21](https://redirect.github.com/trim21))\n- Handle `ubuntu-latest` runner label as `ubuntu-24.04` and\n`macos-latest` runner label as `macos-15`.\n- Report mixing Intel Mac labels and Arm Mac labels as error.\n- Add new types to `issues` and `pull_request_target` webhooks.\n- Update the popular actions data set to the latest and add more actions\nto it. (thanks\n[@&#8203;sethvargo](https://redirect.github.com/sethvargo) for fixing\nthe `go generate` scripts)\n  - `actions/create-github-app-token`\n  - `actions/attest-sbom`\n  - `actions/ai-inference`\n  - `peter-evans/create-or-update-comment`\n  - `release-drafter/release-drafter`\n  - `SamKirkland/FTP-Deploy-Action`\n- Fix the version value in `actionlint -version` output can be empty.\n- Fix outdated URL links in some error messages and documents.\n- [Homebrew formula in this\nrepository](https://redirect.github.com/rhysd/actionlint/blob/main/HomebrewFormula/actionlint.rb)\nis deprecated and [Homebrew\ncask](https://redirect.github.com/rhysd/actionlint/blob/main/Casks/actionlint.rb)\nis newly added instead because [GoReleaser no longer supports Homebrew\nformula update](https://goreleaser.com/deprecations/#brews). Note that\nHomebrew's official `actionlint` formula is still maintained. Please\nread the\n[documentation](https://redirect.github.com/rhysd/actionlint/blob/main/docs/install.md#homebrew)\nfor more details.\n- Drop support for Go 1.23 and earlier because they are no longer\nmaintained officially. Go 1.24 and later are supported to build\nactionlint.\n- Replace [`go-yaml/yaml@v3`](https://redirect.github.com/go-yaml/yaml)\npackage with\n[`yaml/go-yaml@v4`](https://redirect.github.com/yaml/go-yaml) package.\n`go-yaml/yaml` was used for parsing workflow files however it was\nunmaintained. `yaml/go-yaml` is a successor of the library officially\nmaintained by YAML organization.\n([#&#8203;575](https://redirect.github.com/rhysd/actionlint/issues/575))\n- Improve error messages on parsing workflow and action metadata files.\n\n\\[Changes]\\[v1.7.8]\n\n<a id=\"v1.7.7\"></a>\n\n</details>\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-09-23T18:25:03Z",
          "tree_id": "3e961ca131e72dc9f21632a5d330e1f2cabd5d23",
          "url": "https://github.com/laurigates/dotfiles/commit/45f075c38d9cc8d3aae01e827d22654468a6f54f"
        },
        "date": 1790187977893,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.00964763144,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0014947495999999998,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012518694,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.01107282754,
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
          "id": "7b39ac51b6ebcad3339c4964d59b84ceaac2a672",
          "message": "docs(claude): wave 1 context diet — react-slot rule, podio skill, ~/repos stub repoint (#455)\n\nPart of wave 1 of the Claude context diet. Always-loaded instructions\nmeasured 278k chars against a 150k limit; wave 1 brings it to about\n211k.\n\n## Changes\n\n- **`duplicate-stateful-module.md`**: `react-slot` is reclassified from\nharmless to harmful. `Slot` inspects its child's element identity, which\ndoes not survive two copies of the module. One paragraph records the\nthelma 2026-08-19 incident (`<Button asChild>` 500 on `/admin/users`).\n- **`skills/podio-ticket-updates`**: moved here from\n`~/repos/ForumViriumHelsinki/.claude/skills/`. Skills are not discovered\nabove a repo root, so the old copy was never offered in subrepo\nsessions. Because this repo is public, the skill was sanitised with the\n`public-export-sanitization` tripwire. Board and space labels, the\nresponsible person and the org now come from `PODIO_ORG_LABEL`,\n`PODIO_SPACE_LABEL`, `PODIO_APP_LABEL`, `PODIO_RESPONSIBLE` and\n`PODIO_GITHUB_ORG`; the skill asks for them when they are unset.\n-\n**`private_repos/.../rules/{ci-cd-multirepo,tool-migration-cutover}.md`**:\nsame one-line repoint as laurigates/repos-claude-config#60 (bare skill\nnames to `github-actions-plugin:multirepo-ci-cd` /\n`migration-patterns-plugin:tool-migration-cutover`). chezmoi owns these\ntwo files, so without this edit the next `chezmoi apply` reverts #60 and\nleaves `~/repos` dirty.\n\n## Merge order\n\n1. laurigates/claude-plugins#2810 and this PR\n2. ForumViriumHelsinki/.github#144\n3. laurigates/repos-claude-config#60 (deletes the portfolio copies of\nthe skills)\n\n## Follow-up\n\n- Set the five `PODIO_*` variables in `~/.api_tokens`.\n\n## Verification\n\n- `check-public-export.sh` over the skill: clean. The control run on the\noriginal FVH copy flagged the internal identifiers.\n- pre-commit on every commit: no failures.\n- `chezmoi --source <worktree> diff` shows only the intended hunks.\n- Not verified: skill discovery after `chezmoi apply`.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01Sdq9pGAa4Fe2KhFdQPrnbm\n\n---------\n\nCo-authored-by: Claude Opus 5.5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-24T13:45:24+03:00",
          "tree_id": "ba7772e64cef7e5e92bda3980166619a3821dc6e",
          "url": "https://github.com/laurigates/dotfiles/commit/7b39ac51b6ebcad3339c4964d59b84ceaac2a672"
        },
        "date": 1790246761246,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.008115565966666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00131015416,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.00107491196,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.00967093972,
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
          "id": "7c0b211c14d3cd83fc2ffebac4cc856c152a0776",
          "message": "docs(claude): wave-2 context diet — promote four user rules to plugin skills (#456)\n\nWave 2 of the Claude context diet. Four user-tier rules that load into\nevery session become stubs. Each stub keeps the gate lines that apply\nwhile a decision is being made and names the plugin skill that now\ncarries the body.\n\n| Rule | Bytes before → after | Skill home |\n|---|---:|---|\n| `tool-use-patterns.md` | 9,447 → 1,455 |\n`agent-patterns-plugin:harness-tool-errors` (Read/Edit errors),\n`code-quality-plugin:ast-grep-search` (reference ladder),\n`git-plugin:gh-cli-agentic` (`gh api -f`/`-F`),\n`agent-patterns-plugin:tool-result-traps` (parseFloat control example) |\n| `git-hazards.md` | 7,727 → 1,316 | `git-plugin:git-local-hazards` |\n| `never-fabricate-test-identifiers.md` | 6,917 → 904 |\n`agent-patterns-plugin:probe-input-integrity` |\n| `diagnose-at-the-failure-point.md` | 4,901 → 669 |\n`code-quality-plugin:debugging-methodology` |\n\nThese stay inline: the Bash-permission-denial rule, the\ncontrol-test-negatives line, the existing WebFetch pointer, and the\nper-rule gates (cut PR branches from `origin/main`, `gh pr list --head`\nbefore the second push, one pathspec per `git add`, list before you get,\n`chmod +x` a stub and assert it, verify that a zero/default identifier\ncame from a real success, read the resource at the failing call).\n\n**Budget.** The always-loaded surface measured on disk goes from 97,892\nto 73,244 bytes. `TOTAL_BUDGET_BYTES` ratchets down from 104,000 to\n77,700, which leaves 6.1% headroom. The dated history note in\n`tests/test-claude-context-budget.sh` cites the measured bytes.\n\n**Dependency.** `harness-tool-errors`, `git-local-hazards` and\n`probe-input-integrity` are new skills, and the other homes gain\nsections. All of them land in the claude-plugins wave-2 PR. Merge this\nPR after that release is installed, then run `chezmoi apply`. The\ndoc-reference checker does not resolve `plugin:skill` names, so its\nclean result says nothing about whether those skills exist.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_014iSXiKVfiBKcxGsSX1WnnH\n\n---------\n\nCo-authored-by: Claude Opus 5.5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-24T23:11:42+03:00",
          "tree_id": "55f70a7a9947226db8d85791ddf4e0c739750977",
          "url": "https://github.com/laurigates/dotfiles/commit/7c0b211c14d3cd83fc2ffebac4cc856c152a0776"
        },
        "date": 1790280750948,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.007078163346666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00099205172,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.00085230732,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.02321595082,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "631791eac6c438b7d92854073e0bc69caa6cddac",
          "message": "chore(deps): update GitHub Actions (major) (#453)\n\n> ℹ️ **Note**\n> \n> This PR body was truncated due to platform limits.\n\nThis PR contains the following updates:\n\n| Package | Type | Update | Change |\n|---|---|---|---|\n| [actions/cache](https://redirect.github.com/actions/cache) | action |\nmajor | `v4.3.0` → `v6.1.0` |\n| [actions/checkout](https://redirect.github.com/actions/checkout) |\naction | major | `v4.4.0` → `v7.0.1` |\n|\n[actions/github-script](https://redirect.github.com/actions/github-script)\n| action | major | `v7.1.0` → `v9.0.0` |\n| [actions/labeler](https://redirect.github.com/actions/labeler) |\naction | major | `v5.0.0` → `v7.0.0` |\n| [actions/setup-node](https://redirect.github.com/actions/setup-node) |\naction | major | `v4.4.0` → `v7.0.0` |\n|\n[actions/setup-python](https://redirect.github.com/actions/setup-python)\n| action | major | `v5.6.0` → `v7.0.0` |\n|\n[actions/upload-artifact](https://redirect.github.com/actions/upload-artifact)\n| action | major | `v4.6.2` → `v7.0.1` |\n| [anchore/scan-action](https://redirect.github.com/anchore/scan-action)\n| action | major | `v4.1.2` → `v7.4.2` |\n\n---\n\n> [!WARNING]\n> Some dependencies could not be looked up. Check the [Dependency\nDashboard](../issues/379) for more information.\n\n---\n\n### Release Notes\n\n<details>\n<summary>actions/cache (actions/cache)</summary>\n\n###\n[`v6.1.0`](https://redirect.github.com/actions/cache/releases/tag/v6.1.0)\n\n[Compare\nSource](https://redirect.github.com/actions/cache/compare/v6.0.0...v6.1.0)\n\n##### What's Changed\n\n- Bump\n[@&#8203;actions/cache](https://redirect.github.com/actions/cache) to\nv6.1.0 - handle read-only cache access by\n[@&#8203;jasongin](https://redirect.github.com/jasongin) in\n[#&#8203;1768](https://redirect.github.com/actions/cache/pull/1768)\n\n**Full Changelog**:\n<https://github.com/actions/cache/compare/v6...v6.1.0>\n\n###\n[`v6.0.0`](https://redirect.github.com/actions/cache/releases/tag/v6.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/cache/compare/v6.0.0...v6.0.0)\n\n##### What's Changed\n\n- Update packages, migrate to ESM by\n[@&#8203;Samirat](https://redirect.github.com/Samirat) in\n[#&#8203;1760](https://redirect.github.com/actions/cache/pull/1760)\n\n**Full Changelog**:\n<https://github.com/actions/cache/compare/v5...v6.0.0>\n\n###\n[`v6`](https://redirect.github.com/actions/cache/compare/v5.1.0...v6.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/cache/compare/v5.1.0...v6.0.0)\n\n###\n[`v5.1.0`](https://redirect.github.com/actions/cache/releases/tag/v5.1.0)\n\n[Compare\nSource](https://redirect.github.com/actions/cache/compare/v5.0.5...v5.1.0)\n\n##### What's Changed\n\n- Bump\n[@&#8203;actions/cache](https://redirect.github.com/actions/cache) to\nv5.1.0 - handle read-only cache access by\n[@&#8203;jasongin](https://redirect.github.com/jasongin) in\n[#&#8203;1775](https://redirect.github.com/actions/cache/pull/1775)\n\n**Full Changelog**:\n<https://github.com/actions/cache/compare/v5...v5.1.0>\n\n###\n[`v5.0.5`](https://redirect.github.com/actions/cache/releases/tag/v5.0.5)\n\n[Compare\nSource](https://redirect.github.com/actions/cache/compare/v5.0.4...v5.0.5)\n\n##### What's Changed\n\n- Update ts-http-runtime dependency by\n[@&#8203;yacaovsnc](https://redirect.github.com/yacaovsnc) in\n[#&#8203;1747](https://redirect.github.com/actions/cache/pull/1747)\n\n**Full Changelog**:\n<https://github.com/actions/cache/compare/v5...v5.0.5>\n\n###\n[`v5.0.4`](https://redirect.github.com/actions/cache/releases/tag/v5.0.4)\n\n[Compare\nSource](https://redirect.github.com/actions/cache/compare/v5.0.3...v5.0.4)\n\n##### What's Changed\n\n- Add release instructions and update maintainer docs by\n[@&#8203;Link-](https://redirect.github.com/Link-) in\n[#&#8203;1696](https://redirect.github.com/actions/cache/pull/1696)\n- Potential fix for code scanning alert no. 52: Workflow does not\ncontain permissions by\n[@&#8203;Link-](https://redirect.github.com/Link-) in\n[#&#8203;1697](https://redirect.github.com/actions/cache/pull/1697)\n- Fix workflow permissions and cleanup workflow names / formatting by\n[@&#8203;Link-](https://redirect.github.com/Link-) in\n[#&#8203;1699](https://redirect.github.com/actions/cache/pull/1699)\n- docs: Update examples to use the latest version by\n[@&#8203;XZTDean](https://redirect.github.com/XZTDean) in\n[#&#8203;1690](https://redirect.github.com/actions/cache/pull/1690)\n- Fix proxy integration tests by\n[@&#8203;Link-](https://redirect.github.com/Link-) in\n[#&#8203;1701](https://redirect.github.com/actions/cache/pull/1701)\n- Fix cache key in examples.md for bun.lock by\n[@&#8203;RyPeck](https://redirect.github.com/RyPeck) in\n[#&#8203;1722](https://redirect.github.com/actions/cache/pull/1722)\n- Update dependencies & patch security vulnerabilities by\n[@&#8203;Link-](https://redirect.github.com/Link-) in\n[#&#8203;1738](https://redirect.github.com/actions/cache/pull/1738)\n\n##### New Contributors\n\n- [@&#8203;XZTDean](https://redirect.github.com/XZTDean) made their\nfirst contribution in\n[#&#8203;1690](https://redirect.github.com/actions/cache/pull/1690)\n- [@&#8203;RyPeck](https://redirect.github.com/RyPeck) made their first\ncontribution in\n[#&#8203;1722](https://redirect.github.com/actions/cache/pull/1722)\n\n**Full Changelog**:\n<https://github.com/actions/cache/compare/v5...v5.0.4>\n\n###\n[`v5.0.3`](https://redirect.github.com/actions/cache/releases/tag/v5.0.3)\n\n[Compare\nSource](https://redirect.github.com/actions/cache/compare/v5.0.2...v5.0.3)\n\n##### What's Changed\n\n- Bump `@actions/cache` to v5.0.5 (Resolves:\n<https://github.com/actions/cache/security/dependabot/33>)\n- Bump `@actions/core` to v2.0.3\n\n**Full Changelog**:\n<https://github.com/actions/cache/compare/v5...v5.0.3>\n\n###\n[`v5.0.2`](https://redirect.github.com/actions/cache/releases/tag/v5.0.2):\nv.5.0.2\n\n[Compare\nSource](https://redirect.github.com/actions/cache/compare/v5.0.1...v5.0.2)\n\n##### v5.0.2\n\n##### What's Changed\n\nWhen creating cache entries, 429s returned from the cache service will\nnot be retried.\n\n###\n[`v5.0.1`](https://redirect.github.com/actions/cache/releases/tag/v5.0.1)\n\n[Compare\nSource](https://redirect.github.com/actions/cache/compare/v5...v5.0.1)\n\n> \\[!IMPORTANT]\n> **`actions/cache@v5` runs on the Node.js 24 runtime and requires a\nminimum Actions Runner version of `2.327.1`.**\n>\n> If you are using self-hosted runners, ensure they are updated before\nupgrading.\n\n***\n\n##### v5.0.1\n\n##### What's Changed\n\n- fix: update\n[@&#8203;actions/cache](https://redirect.github.com/actions/cache) for\nNode.js 24 punycode deprecation by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;1685](https://redirect.github.com/actions/cache/pull/1685)\n- prepare release v5.0.1 by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;1686](https://redirect.github.com/actions/cache/pull/1686)\n\n##### v5.0.0\n\n##### What's Changed\n\n- Upgrade to use node24 by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;1630](https://redirect.github.com/actions/cache/pull/1630)\n- Prepare v5.0.0 release by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;1684](https://redirect.github.com/actions/cache/pull/1684)\n\n**Full Changelog**:\n<https://github.com/actions/cache/compare/v5...v5.0.1>\n\n###\n[`v5.0.0`](https://redirect.github.com/actions/cache/releases/tag/v5.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/cache/compare/v5...v5)\n\n> \\[!IMPORTANT]\n> **`actions/cache@v5` runs on the Node.js 24 runtime and requires a\nminimum Actions Runner version of `2.327.1`.**\n>\n> If you are using self-hosted runners, ensure they are updated before\nupgrading.\n\n***\n\n##### What's Changed\n\n- Upgrade to use node24 by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;1630](https://redirect.github.com/actions/cache/pull/1630)\n- Prepare v5.0.0 release by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;1684](https://redirect.github.com/actions/cache/pull/1684)\n\n**Full Changelog**:\n<https://github.com/actions/cache/compare/v4.3.0...v5.0.0>\n\n###\n[`v5`](https://redirect.github.com/actions/cache/compare/v4.3.0...v5)\n\n[Compare\nSource](https://redirect.github.com/actions/cache/compare/v4.3.0...v5)\n\n</details>\n\n<details>\n<summary>actions/checkout (actions/checkout)</summary>\n\n###\n[`v7.0.1`](https://redirect.github.com/actions/checkout/blob/HEAD/CHANGELOG.md#v701)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v7...v7.0.1)\n\n- Skip running unsafe pr check if input is default by\n[@&#8203;aiqiaoy](https://redirect.github.com/aiqiaoy) in\n[#&#8203;2518](https://redirect.github.com/actions/checkout/pull/2518)\n- Trim only ascii whitespace for branch by\n[@&#8203;aiqiaoy](https://redirect.github.com/aiqiaoy) in\n[#&#8203;2521](https://redirect.github.com/actions/checkout/pull/2521)\n- Escape values passed to --unset by\n[@&#8203;aiqiaoy](https://redirect.github.com/aiqiaoy) in\n[#&#8203;2530](https://redirect.github.com/actions/checkout/pull/2530)\n- Various dependency updates\n\n###\n[`v7.0.0`](https://redirect.github.com/actions/checkout/blob/HEAD/CHANGELOG.md#v700)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v7...v7)\n\n- Block checking out fork PR for pull\\_request\\_target and workflow\\_run\nby [@&#8203;aiqiaoy](https://redirect.github.com/aiqiaoy) in\n[#&#8203;2454](https://redirect.github.com/actions/checkout/pull/2454)\n- Various dependency updates\n\n###\n[`v7`](https://redirect.github.com/actions/checkout/blob/HEAD/CHANGELOG.md#v701)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v6.1.0...v7)\n\n- Skip running unsafe pr check if input is default by\n[@&#8203;aiqiaoy](https://redirect.github.com/aiqiaoy) in\n[#&#8203;2518](https://redirect.github.com/actions/checkout/pull/2518)\n- Trim only ascii whitespace for branch by\n[@&#8203;aiqiaoy](https://redirect.github.com/aiqiaoy) in\n[#&#8203;2521](https://redirect.github.com/actions/checkout/pull/2521)\n- Escape values passed to --unset by\n[@&#8203;aiqiaoy](https://redirect.github.com/aiqiaoy) in\n[#&#8203;2530](https://redirect.github.com/actions/checkout/pull/2530)\n- Various dependency updates\n\n###\n[`v6.1.0`](https://redirect.github.com/actions/checkout/releases/tag/v6.1.0)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v6.0.3...v6.1.0)\n\n##### What's Changed\n\n- **\\[BREAKING]** backport `allow-unsafe-pr-checkout` to v6 by\n[@&#8203;aiqiaoy](https://redirect.github.com/aiqiaoy) in\n[#&#8203;2500](https://redirect.github.com/actions/checkout/pull/2500)\n- backport fixes to releases-v6 by\n[@&#8203;aiqiaoy](https://redirect.github.com/aiqiaoy) in\n[#&#8203;2527](https://redirect.github.com/actions/checkout/pull/2527)\n\n\n<https://github.blog/changelog/2026-06-18-safer-pull_request_target-defaults-for-github-actions-checkout/>\nfor more details about this breaking change\n\n**Full Changelog**:\n<https://github.com/actions/checkout/compare/v6.0.3...v6.1.0>\n\n###\n[`v6.0.3`](https://redirect.github.com/actions/checkout/blob/HEAD/CHANGELOG.md#v603)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v6.0.2...v6.0.3)\n\n- Fix checkout init for SHA-256 repositories by\n[@&#8203;yaananth](https://redirect.github.com/yaananth) in\n[#&#8203;2439](https://redirect.github.com/actions/checkout/pull/2439)\n- fix: expand merge commit SHA regex and add SHA-256 test cases by\n[@&#8203;yaananth](https://redirect.github.com/yaananth) in\n[#&#8203;2414](https://redirect.github.com/actions/checkout/pull/2414)\n\n###\n[`v6.0.2`](https://redirect.github.com/actions/checkout/blob/HEAD/CHANGELOG.md#v602)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v6.0.1...v6.0.2)\n\n- Fix tag handling: preserve annotations and explicit fetch-tags by\n[@&#8203;ericsciple](https://redirect.github.com/ericsciple) in\n[#&#8203;2356](https://redirect.github.com/actions/checkout/pull/2356)\n\n###\n[`v6.0.1`](https://redirect.github.com/actions/checkout/blob/HEAD/CHANGELOG.md#v601)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v6...v6.0.1)\n\n- Add worktree support for persist-credentials includeIf by\n[@&#8203;ericsciple](https://redirect.github.com/ericsciple) in\n[#&#8203;2327](https://redirect.github.com/actions/checkout/pull/2327)\n\n###\n[`v6.0.0`](https://redirect.github.com/actions/checkout/blob/HEAD/CHANGELOG.md#v600)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v6...v6)\n\n- Persist creds to a separate file by\n[@&#8203;ericsciple](https://redirect.github.com/ericsciple) in\n[#&#8203;2286](https://redirect.github.com/actions/checkout/pull/2286)\n- Update README to include Node.js 24 support details and requirements\nby [@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;2248](https://redirect.github.com/actions/checkout/pull/2248)\n\n###\n[`v6`](https://redirect.github.com/actions/checkout/blob/HEAD/CHANGELOG.md#v603)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v5.1.0...v6)\n\n- Fix checkout init for SHA-256 repositories by\n[@&#8203;yaananth](https://redirect.github.com/yaananth) in\n[#&#8203;2439](https://redirect.github.com/actions/checkout/pull/2439)\n- fix: expand merge commit SHA regex and add SHA-256 test cases by\n[@&#8203;yaananth](https://redirect.github.com/yaananth) in\n[#&#8203;2414](https://redirect.github.com/actions/checkout/pull/2414)\n\n###\n[`v5.1.0`](https://redirect.github.com/actions/checkout/releases/tag/v5.1.0)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v5.0.1...v5.1.0)\n\n##### What's Changed\n\n- **\\[BREAKING]** backport `allow-unsafe-pr-checkout` to v5 by\n[@&#8203;aiqiaoy](https://redirect.github.com/aiqiaoy) in\n[#&#8203;2501](https://redirect.github.com/actions/checkout/pull/2501)\n- backport fixes to releases-v5 by\n[@&#8203;aiqiaoy](https://redirect.github.com/aiqiaoy) in\n[#&#8203;2523](https://redirect.github.com/actions/checkout/pull/2523)\n\n\n<https://github.blog/changelog/2026-06-18-safer-pull_request_target-defaults-for-github-actions-checkout/>\nfor more details about this breaking change\n\n**Full Changelog**:\n<https://github.com/actions/checkout/compare/v5.0.1...v5.1.0>\n\n###\n[`v5.0.1`](https://redirect.github.com/actions/checkout/blob/HEAD/CHANGELOG.md#v501)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v5...v5.0.1)\n\n- Port v6 cleanup to v5 by\n[@&#8203;ericsciple](https://redirect.github.com/ericsciple) in\n[#&#8203;2301](https://redirect.github.com/actions/checkout/pull/2301)\n\n###\n[`v5.0.0`](https://redirect.github.com/actions/checkout/blob/HEAD/CHANGELOG.md#v500)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v5...v5)\n\n- Update actions checkout to use node 24 by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;2226](https://redirect.github.com/actions/checkout/pull/2226)\n\n###\n[`v5`](https://redirect.github.com/actions/checkout/blob/HEAD/CHANGELOG.md#v501)\n\n[Compare\nSource](https://redirect.github.com/actions/checkout/compare/v4.4.0...v5)\n\n- Port v6 cleanup to v5 by\n[@&#8203;ericsciple](https://redirect.github.com/ericsciple) in\n[#&#8203;2301](https://redirect.github.com/actions/checkout/pull/2301)\n\n</details>\n\n<details>\n<summary>actions/github-script (actions/github-script)</summary>\n\n###\n[`v9.0.0`](https://redirect.github.com/actions/github-script/releases/tag/v9.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/github-script/compare/v9.0.0...v9.0.0)\n\n**New features:**\n\n- **`getOctokit` factory function** — Available directly in the script\ncontext. Create additional authenticated Octokit clients with different\ntokens for multi-token workflows, GitHub App tokens, and cross-org\naccess. See [Creating additional clients with\n`getOctokit`](https://redirect.github.com/actions/github-script#creating-additional-clients-with-getoctokit)\nfor details and examples.\n- **Orchestration ID in user-agent** — The `ACTIONS_ORCHESTRATION_ID`\nenvironment variable is automatically appended to the user-agent string\nfor request tracing.\n\n**Breaking changes:**\n\n- **`require('@&#8203;actions/github')` no longer works in scripts.**\nThe upgrade to `@actions/github` v9 (ESM-only) means\n`require('@&#8203;actions/github')` will fail at runtime. If you\npreviously used patterns like `const { getOctokit } =\nrequire('@&#8203;actions/github')` to create secondary clients, use the\nnew injected `getOctokit` function instead — it's available directly in\nthe script context with no imports needed.\n- `getOctokit` is now an injected function parameter. Scripts that\ndeclare `const getOctokit = ...` or `let getOctokit = ...` will get a\n`SyntaxError` because JavaScript does not allow `const`/`let`\nredeclaration of function parameters. Use the injected `getOctokit`\ndirectly, or use `var getOctokit = ...` if you need to redeclare it.\n- If your script accesses other `@actions/github` internals beyond the\nstandard `github`/`octokit` client, you may need to update those\nreferences for v9 compatibility.\n\n##### What's Changed\n\n- Add ACTIONS\\_ORCHESTRATION\\_ID to user-agent string by\n[@&#8203;Copilot](https://redirect.github.com/Copilot) in\n[#&#8203;695](https://redirect.github.com/actions/github-script/pull/695)\n- ci: use deployment: false for integration test environments by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;712](https://redirect.github.com/actions/github-script/pull/712)\n- feat!: add getOctokit to script context, upgrade\n[@&#8203;actions/github](https://redirect.github.com/actions/github) v9,\n[@&#8203;octokit/core](https://redirect.github.com/octokit/core) v7, and\nrelated packages by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;700](https://redirect.github.com/actions/github-script/pull/700)\n\n##### New Contributors\n\n- [@&#8203;Copilot](https://redirect.github.com/Copilot) made their\nfirst contribution in\n[#&#8203;695](https://redirect.github.com/actions/github-script/pull/695)\n\n**Full Changelog**:\n<https://github.com/actions/github-script/compare/v8.0.0...v9.0.0>\n\n###\n[`v9`](https://redirect.github.com/actions/github-script/compare/v8.0.0...v9.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/github-script/compare/v8.0.0...v9.0.0)\n\n###\n[`v8.0.0`](https://redirect.github.com/actions/github-script/compare/v8.0.0...v8.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/github-script/compare/v8.0.0...v8.0.0)\n\n###\n[`v8`](https://redirect.github.com/actions/github-script/releases/tag/v8):\n.0.0\n\n[Compare\nSource](https://redirect.github.com/actions/github-script/compare/v7.1.0...v8.0.0)\n\n##### What's Changed\n\n- Update Node.js version support to 24.x by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;637](https://redirect.github.com/actions/github-script/pull/637)\n- README for updating actions/github-script from v7 to v8 by\n[@&#8203;sneha-krip](https://redirect.github.com/sneha-krip) in\n[#&#8203;653](https://redirect.github.com/actions/github-script/pull/653)\n\n##### ⚠️ Minimum Compatible Runner Version\n\n**v2.327.1**\\\n[Release\nNotes](https://redirect.github.com/actions/runner/releases/tag/v2.327.1)\n\nMake sure your runner is updated to this version or newer to use this\nrelease.\n\n##### New Contributors\n\n- [@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) made their\nfirst contribution in\n[#&#8203;637](https://redirect.github.com/actions/github-script/pull/637)\n- [@&#8203;sneha-krip](https://redirect.github.com/sneha-krip) made\ntheir first contribution in\n[#&#8203;653](https://redirect.github.com/actions/github-script/pull/653)\n\n**Full Changelog**:\n<https://github.com/actions/github-script/compare/v7.1.0...v8.0.0>\n\n</details>\n\n<details>\n<summary>actions/labeler (actions/labeler)</summary>\n\n###\n[`v7.0.0`](https://redirect.github.com/actions/labeler/releases/tag/v7.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/labeler/compare/v7.0.0...v7.0.0)\n\n#### What's Changed\n\n##### Enhancements:\n\n- Migrate to ESM and update dependencies by\n[@&#8203;chiranjib-swain](https://redirect.github.com/chiranjib-swain)\nin [#&#8203;949](https://redirect.github.com/actions/labeler/pull/949)\n\n**Full Changelog**:\n<https://github.com/actions/labeler/compare/v6...v7.0.0>\n\n###\n[`v7`](https://redirect.github.com/actions/labeler/compare/v6.2.0...v7.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/labeler/compare/v6.2.0...v7.0.0)\n\n###\n[`v6.2.0`](https://redirect.github.com/actions/labeler/releases/tag/v6.2.0)\n\n[Compare\nSource](https://redirect.github.com/actions/labeler/compare/v6.1.0...v6.2.0)\n\n#### What's Changed\n\n##### Bug Fix\n\n- Improve PR number validation and warning messages in input handling by\n[@&#8203;chiranjib-swain](https://redirect.github.com/chiranjib-swain)\nin [#&#8203;939](https://redirect.github.com/actions/labeler/pull/939)\n\n##### Dependency Updates\n\n- Bump js-yaml to 4.2.0, apply npm audit fix, and add undici override by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;943](https://redirect.github.com/actions/labeler/pull/943)\n- Bump\n[@&#8203;typescript-eslint/eslint-plugin](https://redirect.github.com/typescript-eslint/eslint-plugin)\nfrom 8.59.1 to 8.61.1 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;942](https://redirect.github.com/actions/labeler/pull/942)\n\n**Full Changelog**:\n<https://github.com/actions/labeler/compare/v6.1.0...v6.2.0>\n\n###\n[`v6.1.0`](https://redirect.github.com/actions/labeler/releases/tag/v6.1.0)\n\n[Compare\nSource](https://redirect.github.com/actions/labeler/compare/v6.0.1...v6.1.0)\n\n#### Enhancements\n\n- Add changed-files-labels-limit and max-files-changed configuration\noptions to cap the number of labels added by\n[@&#8203;bluca](https://redirect.github.com/bluca) in\n[#&#8203;923](https://redirect.github.com/actions/labeler/pull/923)\n\n#### Bug Fixes\n\n- Improve Labeler Action documentation and permission error handling by\n[@&#8203;chiranjib-swain](https://redirect.github.com/chiranjib-swain)\nin [#&#8203;897](https://redirect.github.com/actions/labeler/pull/897)\n- Preserve manually added labels during workflow runs and refine label\nsynchronization logic by\n[@&#8203;chiranjib-swain](https://redirect.github.com/chiranjib-swain)\nin [#&#8203;917](https://redirect.github.com/actions/labeler/pull/917)\n\n#### Dependency Updates\n\n- Upgrade brace-expansion from 1.1.11 to 1.1.12 and document breaking\nchanges in v6 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;877](https://redirect.github.com/actions/labeler/pull/877)\n- Upgrade minimatch from 10.0.1 to 10.2.3 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;926](https://redirect.github.com/actions/labeler/pull/926)\n- Upgrade dependencies\n([@&#8203;actions/core](https://redirect.github.com/actions/core),\n[@&#8203;actions/github](https://redirect.github.com/actions/github),\njs-yaml, minimatch,\n[@&#8203;typescript-eslint](https://redirect.github.com/typescript-eslint))\nby [@&#8203;Copilot](https://redirect.github.com/Copilot) in\n[#&#8203;934](https://redirect.github.com/actions/labeler/pull/934)\n\n#### New Contributors\n\n- [@&#8203;chiranjib-swain](https://redirect.github.com/chiranjib-swain)\nmade their first contribution in\n[#&#8203;897](https://redirect.github.com/actions/labeler/pull/897)\n- [@&#8203;bluca](https://redirect.github.com/bluca) made their first\ncontribution in\n[#&#8203;923](https://redirect.github.com/actions/labeler/pull/923)\n- [@&#8203;Copilot](https://redirect.github.com/Copilot) made their\nfirst contribution in\n[#&#8203;934](https://redirect.github.com/actions/labeler/pull/934)\n\n**Full Changelog**:\n<https://github.com/actions/labeler/compare/v6...v6.1.0>\n\n###\n[`v6.0.1`](https://redirect.github.com/actions/labeler/releases/tag/v6.0.1)\n\n[Compare\nSource](https://redirect.github.com/actions/labeler/compare/v6...v6.0.1)\n\n#### What's Changed\n\n- Upgrade publish-action from 0.2.2 to 0.4.0 by\n[@&#8203;aparnajyothi-y](https://redirect.github.com/aparnajyothi-y) in\n[#&#8203;901](https://redirect.github.com/actions/labeler/pull/901)\n\n#### New Contributors\n\n- [@&#8203;aparnajyothi-y](https://redirect.github.com/aparnajyothi-y)\nmade their first contribution in\n[#&#8203;901](https://redirect.github.com/actions/labeler/pull/901)\n\n**Full Changelog**:\n<https://github.com/actions/labeler/compare/v6.0.0...v6.0.1>\n\n###\n[`v6.0.0`](https://redirect.github.com/actions/labeler/releases/tag/v6.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/labeler/compare/v6...v6)\n\n#### What's Changed\n\n- Add workflow file for publishing releases to immutable action package\nby [@&#8203;jcambass](https://redirect.github.com/jcambass) in\n[#&#8203;802](https://redirect.github.com/actions/labeler/pull/802)\n\n##### Breaking Changes\n\n- Upgrade Node.js version to 24 in action and dependencies\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;891](https://redirect.github.com/actions/labeler/pull/891)\nMake sure your runner is on version v2.327.1 or later to ensure\ncompatibility with this release. [Release\nNotes](https://redirect.github.com/actions/runner/releases/tag/v2.327.1)\n\n##### Dependency Upgrades\n\n- Upgrade eslint-config-prettier from 9.0.0 to 9.1.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;711](https://redirect.github.com/actions/labeler/pull/711)\n- Upgrade eslint from 8.52.0 to 8.55.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;720](https://redirect.github.com/actions/labeler/pull/720)\n- Upgrade [@&#8203;types/jest](https://redirect.github.com/types/jest)\nfrom 29.5.6 to 29.5.11 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;719](https://redirect.github.com/actions/labeler/pull/719)\n- Upgrade\n[@&#8203;types/js-yaml](https://redirect.github.com/types/js-yaml) from\n4.0.8 to 4.0.9 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;718](https://redirect.github.com/actions/labeler/pull/718)\n- Upgrade\n[@&#8203;typescript-eslint/parser](https://redirect.github.com/typescript-eslint/parser)\nfrom 6.9.0 to 6.14.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;717](https://redirect.github.com/actions/labeler/pull/717)\n- Upgrade prettier from 3.0.3 to 3.1.1 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;726](https://redirect.github.com/actions/labeler/pull/726)\n- Upgrade eslint from 8.55.0 to 8.56.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;725](https://redirect.github.com/actions/labeler/pull/725)\n- Upgrade\n[@&#8203;typescript-eslint/parser](https://redirect.github.com/typescript-eslint/parser)\nfrom 6.14.0 to 6.19.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;745](https://redirect.github.com/actions/labeler/pull/745)\n- Upgrade eslint-plugin-jest from 27.4.3 to 27.6.3 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;744](https://redirect.github.com/actions/labeler/pull/744)\n- Upgrade\n[@&#8203;typescript-eslint/eslint-plugin](https://redirect.github.com/typescript-eslint/eslint-plugin)\nfrom 6.9.0 to 6.20.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;750](https://redirect.github.com/actions/labeler/pull/750)\n- Upgrade prettier from 3.1.1 to 3.2.5 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;752](https://redirect.github.com/actions/labeler/pull/752)\n- Upgrade undici from 5.26.5 to 5.28.3 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;757](https://redirect.github.com/actions/labeler/pull/757)\n- Upgrade braces from 3.0.2 to 3.0.3 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;789](https://redirect.github.com/actions/labeler/pull/789)\n- Upgrade minimatch from 9.0.3 to 10.0.1 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;805](https://redirect.github.com/actions/labeler/pull/805)\n- Upgrade\n[@&#8203;actions/core](https://redirect.github.com/actions/core) from\n1.10.1 to 1.11.1 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;811](https://redirect.github.com/actions/labeler/pull/811)\n- Upgrade typescript from 5.4.3 to 5.7.2 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;819](https://redirect.github.com/actions/labeler/pull/819)\n- Upgrade\n[@&#8203;typescript-eslint/parser](https://redirect.github.com/typescript-eslint/parser)\nfrom 7.3.1 to 8.17.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;824](https://redirect.github.com/actions/labeler/pull/824)\n- Upgrade prettier from 3.2.5 to 3.4.2 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;825](https://redirect.github.com/actions/labeler/pull/825)\n- Upgrade [@&#8203;types/jest](https://redirect.github.com/types/jest)\nfrom 29.5.12 to 29.5.14 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;827](https://redirect.github.com/actions/labeler/pull/827)\n- Upgrade eslint-plugin-jest from 27.9.0 to 28.9.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;832](https://redirect.github.com/actions/labeler/pull/832)\n- Upgrade ts-jest from 29.1.2 to 29.2.5 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;831](https://redirect.github.com/actions/labeler/pull/831)\n- Upgrade [@&#8203;vercel/ncc](https://redirect.github.com/vercel/ncc)\nfrom 0.38.1 to 0.38.3 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;830](https://redirect.github.com/actions/labeler/pull/830)\n- Upgrade typescript from 5.7.2 to 5.7.3 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;835](https://redirect.github.com/actions/labeler/pull/835)\n- Upgrade eslint-plugin-jest from 28.9.0 to 28.11.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;839](https://redirect.github.com/actions/labeler/pull/839)\n- Upgrade undici from 5.28.4 to 5.28.5 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;842](https://redirect.github.com/actions/labeler/pull/842)\n- Upgrade\n[@&#8203;octokit/request-error](https://redirect.github.com/octokit/request-error)\nfrom 5.0.1 to 5.1.1 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;846](https://redirect.github.com/actions/labeler/pull/846)\n\n##### Documentation changes\n\n- Add note regarding `pull_request_target` to README.md by\n[@&#8203;silverwind](https://redirect.github.com/silverwind) in\n[#&#8203;669](https://redirect.github.com/actions/labeler/pull/669)\n- Update readme with additional examples and important note about\n`pull_request_target` event by\n[@&#8203;IvanZosimov](https://redirect.github.com/IvanZosimov) in\n[#&#8203;721](https://redirect.github.com/actions/labeler/pull/721)\n- Document update - permission section by\n[@&#8203;harithavattikuti](https://redirect.github.com/harithavattikuti)\nin [#&#8203;840](https://redirect.github.com/actions/labeler/pull/840)\n- Improvement in documentation for pull\\_request\\_target event usage in\nREADME by\n[@&#8203;suyashgaonkar](https://redirect.github.com/suyashgaonkar) in\n[#&#8203;871](https://redirect.github.com/actions/labeler/pull/871)\n- Fix broken links in documentation by\n[@&#8203;suyashgaonkar](https://redirect.github.com/suyashgaonkar) in\n[#&#8203;822](https://redirect.github.com/actions/labeler/pull/822)\n\n#### New Contributors\n\n- [@&#8203;silverwind](https://redirect.github.com/silverwind) made\ntheir first contribution in\n[#&#8203;669](https://redirect.github.com/actions/labeler/pull/669)\n- [@&#8203;Jcambass](https://redirect.github.com/Jcambass) made their\nfirst contribution in\n[#&#8203;802](https://redirect.github.com/actions/labeler/pull/802)\n- [@&#8203;suyashgaonkar](https://redirect.github.com/suyashgaonkar)\nmade their first contribution in\n[#&#8203;822](https://redirect.github.com/actions/labeler/pull/822)\n-\n[@&#8203;HarithaVattikuti](https://redirect.github.com/HarithaVattikuti)\nmade their first contribution in\n[#&#8203;840](https://redirect.github.com/actions/labeler/pull/840)\n- [@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) made their\nfirst contribution in\n[#&#8203;891](https://redirect.github.com/actions/labeler/pull/891)\n\n**Full Changelog**:\n<https://github.com/actions/labeler/compare/v5...v6.0.0>\n\n###\n[`v6`](https://redirect.github.com/actions/labeler/compare/v5.0.0...v6)\n\n[Compare\nSource](https://redirect.github.com/actions/labeler/compare/v5.0.0...v6)\n\n</details>\n\n<details>\n<summary>actions/setup-node (actions/setup-node)</summary>\n\n###\n[`v7.0.0`](https://redirect.github.com/actions/setup-node/releases/tag/v7.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-node/compare/v7.0.0...v7.0.0)\n\n##### What's Changed\n\n##### Enhancements:\n\n- Add cache-primary-key and cache-matched-key as outputs by\n[@&#8203;gowridurgad](https://redirect.github.com/gowridurgad) in\n[#&#8203;1577](https://redirect.github.com/actions/setup-node/pull/1577)\n- Migrate to ESM and upgrade dependencies by\n[@&#8203;gowridurgad](https://redirect.github.com/gowridurgad) in\n[#&#8203;1574](https://redirect.github.com/actions/setup-node/pull/1574)\n\n##### Bug fixes:\n\n- Remove dummy NODE\\_AUTH\\_TOKEN export by\n[@&#8203;gowridurgad](https://redirect.github.com/gowridurgad) in\n[#&#8203;1558](https://redirect.github.com/actions/setup-node/pull/1558)\n- Only use `mirrorToken` in `getManifest` if it's provided by\n[@&#8203;deiga](https://redirect.github.com/deiga) in\n[#&#8203;1548](https://redirect.github.com/actions/setup-node/pull/1548)\n\n##### Documentation updates:\n\n- Add documentation for publishing to npm with Trusted Publisher (OIDC)\nby\n[@&#8203;chiranjib-swain](https://redirect.github.com/chiranjib-swain)\nin\n[#&#8203;1536](https://redirect.github.com/actions/setup-node/pull/1536)\n- docs: Update restore-only cache documentation by\n[@&#8203;priya-kinthali](https://redirect.github.com/priya-kinthali) in\n[#&#8203;1550](https://redirect.github.com/actions/setup-node/pull/1550)\n- docs: Update caching recommendations to mitigate cache poisoning risks\nby\n[@&#8203;chiranjib-swain](https://redirect.github.com/chiranjib-swain)\nin\n[#&#8203;1567](https://redirect.github.com/actions/setup-node/pull/1567)\n\n##### Dependency update:\n\n- Upgrade\n[@&#8203;actions/cache](https://redirect.github.com/actions/cache) to\n5.1.0, log cache write denied by\n[@&#8203;jasongin](https://redirect.github.com/jasongin) in\n[#&#8203;1569](https://redirect.github.com/actions/setup-node/pull/1569)\n\n##### New Contributors\n\n- [@&#8203;chiranjib-swain](https://redirect.github.com/chiranjib-swain)\nmade their first contribution in\n[#&#8203;1536](https://redirect.github.com/actions/setup-node/pull/1536)\n- [@&#8203;deiga](https://redirect.github.com/deiga) made their first\ncontribution in\n[#&#8203;1548](https://redirect.github.com/actions/setup-node/pull/1548)\n- [@&#8203;jasongin](https://redirect.github.com/jasongin) made their\nfirst contribution in\n[#&#8203;1569](https://redirect.github.com/actions/setup-node/pull/1569)\n\n**Full Changelog**:\n<https://github.com/actions/setup-node/compare/v6...v7.0.0>\n\n###\n[`v7`](https://redirect.github.com/actions/setup-node/compare/v6.5.0...v7.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-node/compare/v6.5.0...v7.0.0)\n\n###\n[`v6.5.0`](https://redirect.github.com/actions/setup-node/releases/tag/v6.5.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-node/compare/v6.4.0...v6.5.0)\n\n##### What's Changed\n\n- Update\n[@&#8203;actions/cache](https://redirect.github.com/actions/cache) to\n5.1.0 and add security overrides for undici and fast-xml-parser by\n[@&#8203;HarithaVattikuti](https://redirect.github.com/HarithaVattikuti)\nin\n[#&#8203;1579](https://redirect.github.com/actions/setup-node/pull/1579)\n\n**Full Changelog**:\n<https://github.com/actions/setup-node/compare/v6.4.0...v6.5.0>\n\n###\n[`v6.4.0`](https://redirect.github.com/actions/setup-node/releases/tag/v6.4.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-node/compare/v6.3.0...v6.4.0)\n\n##### What's Changed\n\n##### Dependency updates:\n\n- Upgrade [@&#8203;actions](https://redirect.github.com/actions)\ndependencies by [@&#8203;Copilot](https://redirect.github.com/Copilot)\nin\n[#&#8203;1525](https://redirect.github.com/actions/setup-node/pull/1525)\n- Update Node.js versions in versions.yml and bump package to v6.4.0 by\n[@&#8203;priya-kinthali](https://redirect.github.com/priya-kinthali) in\n[#&#8203;1533](https://redirect.github.com/actions/setup-node/pull/1533)\n\n##### New Contributors\n\n- [@&#8203;Copilot](https://redirect.github.com/Copilot) made their\nfirst contribution in\n[#&#8203;1525](https://redirect.github.com/actions/setup-node/pull/1525)\n\n**Full Changelog**:\n<https://github.com/actions/setup-node/compare/v6...v6.4.0>\n\n###\n[`v6.3.0`](https://redirect.github.com/actions/setup-node/releases/tag/v6.3.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-node/compare/v6.2.0...v6.3.0)\n\n##### What's Changed\n\n##### Enhancements:\n\n- Support parsing `devEngines` field by\n[@&#8203;susnux](https://redirect.github.com/susnux) in\n[#&#8203;1283](https://redirect.github.com/actions/setup-node/pull/1283)\n\n> When using node-version-file: package.json, setup-node now\nprefers devEngines.runtime over engines.node.\n\n##### Dependency updates:\n\n- Fix npm audit issues by\n[@&#8203;gowridurgad](https://redirect.github.com/gowridurgad) in\n[#&#8203;1491](https://redirect.github.com/actions/setup-node/pull/1491)\n- Replace uuid with crypto.randomUUID() by\n[@&#8203;trivikr](https://redirect.github.com/trivikr) in\n[#&#8203;1378](https://redirect.github.com/actions/setup-node/pull/1378)\n- Upgrade minimatch from 3.1.2 to 3.1.5 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1498](https://redirect.github.com/actions/setup-node/pull/1498)\n\n##### Bug fixes:\n\n- Remove hardcoded bearer for mirror-url\n[@&#8203;marco-ippolito](https://redirect.github.com/marco-ippolito) in\n[#&#8203;1467](https://redirect.github.com/actions/setup-node/pull/1467)\n- Scope test lockfiles by package manager and update cache tests by\n[@&#8203;gowridurgad](https://redirect.github.com/gowridurgad) in\n[#&#8203;1495](https://redirect.github.com/actions/setup-node/pull/1495)\n\n##### New Contributors\n\n- [@&#8203;susnux](https://redirect.github.com/susnux) made their first\ncontribution in\n[#&#8203;1283](https://redirect.github.com/actions/setup-node/pull/1283)\n\n**Full Changelog**:\n<https://github.com/actions/setup-node/compare/v6...v6.3.0>\n\n###\n[`v6.2.0`](https://redirect.github.com/actions/setup-node/releases/tag/v6.2.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-node/compare/v6.1.0...v6.2.0)\n\n##### What's Changed\n\n##### Documentation\n\n- Documentation update related to absence of Lockfile by\n[@&#8203;mahabaleshwars](https://redirect.github.com/mahabaleshwars) in\n[#&#8203;1454](https://redirect.github.com/actions/setup-node/pull/1454)\n- Correct mirror option typos by\n[@&#8203;MikeMcC399](https://redirect.github.com/MikeMcC399) in\n[#&#8203;1442](https://redirect.github.com/actions/setup-node/pull/1442)\n- Readme update on checkout version v6 by\n[@&#8203;deining](https://redirect.github.com/deining) in\n[#&#8203;1446](https://redirect.github.com/actions/setup-node/pull/1446)\n- Readme typo fixes\n[@&#8203;munyari](https://redirect.github.com/munyari) in\n[#&#8203;1226](https://redirect.github.com/actions/setup-node/pull/1226)\n- Advanced document update on checkout version v6 by\n[@&#8203;aparnajyothi-y](https://redirect.github.com/aparnajyothi-y) in\n[#&#8203;1468](https://redirect.github.com/actions/setup-node/pull/1468)\n\n##### Dependency updates:\n\n- Upgrade\n[@&#8203;actions/cache](https://redirect.github.com/actions/cache) to\nv5.0.1 by [@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;1449](https://redirect.github.com/actions/setup-node/pull/1449)\n\n##### New Contributors\n\n- [@&#8203;mahabaleshwars](https://redirect.github.com/mahabaleshwars)\nmade their first contribution in\n[#&#8203;1454](https://redirect.github.com/actions/setup-node/pull/1454)\n- [@&#8203;MikeMcC399](https://redirect.github.com/MikeMcC399) made\ntheir first contribution in\n[#&#8203;1442](https://redirect.github.com/actions/setup-node/pull/1442)\n- [@&#8203;deining](https://redirect.github.com/deining) made their\nfirst contribution in\n[#&#8203;1446](https://redirect.github.com/actions/setup-node/pull/1446)\n- [@&#8203;munyari](https://redirect.github.com/munyari) made their\nfirst contribution in\n[#&#8203;1226](https://redirect.github.com/actions/setup-node/pull/1226)\n\n**Full Changelog**:\n<https://github.com/actions/setup-node/compare/v6...v6.2.0>\n\n###\n[`v6.1.0`](https://redirect.github.com/actions/setup-node/releases/tag/v6.1.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-node/compare/v6...v6.1.0)\n\n##### What's Changed\n\n##### Enhancement:\n\n- Remove always-auth configuration handling by\n[@&#8203;priyagupta108](https://redirect.github.com/priyagupta108) in\n[#&#8203;1436](https://redirect.github.com/actions/setup-node/pull/1436)\n\n##### Dependency updates:\n\n- Upgrade\n[@&#8203;actions/cache](https://redirect.github.com/actions/cache) from\n4.0.3 to 4.1.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;1384](https://redirect.github.com/actions/setup-node/pull/1384)\n- Upgrade actions/checkout from 5 to 6 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;1439](https://redirect.github.com/actions/setup-node/pull/1439)\n- Upgrade js-yaml from 3.14.1 to 3.14.2 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;1435](https://redirect.github.com/actions/setup-node/pull/1435)\n\n##### Documentation update:\n\n- Add example for restore-only cache in documentation by\n[@&#8203;aparnajyothi-y](https://redirect.github.com/aparnajyothi-y) in\n[#&#8203;1419](https://redirect.github.com/actions/setup-node/pull/1419)\n\n**Full Changelog**:\n<https://github.com/actions/setup-node/compare/v6...v6.1.0>\n\n###\n[`v6.0.0`](https://redirect.github.com/actions/setup-node/releases/tag/v6.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-node/compare/v6...v6)\n\n##### What's Changed\n\n**Breaking Changes**\n\n- Limit automatic caching to npm, update workflows and documentation by\n[@&#8203;priyagupta108](https://redirect.github.com/priyagupta108) in\n[#&#8203;1374](https://redirect.github.com/actions/setup-node/pull/1374)\n\n**Dependency Upgrades**\n\n- Upgrade ts-jest from 29.1.2 to 29.4.1 and document breaking changes in\nv5 by [@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot]\nin\n[#&#8203;1336](https://redirect.github.com/actions/setup-node/pull/1336)\n- Upgrade prettier from 2.8.8 to 3.6.2 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;1334](https://redirect.github.com/actions/setup-node/pull/1334)\n- Upgrade actions/publish-action from 0.3.0 to 0.4.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;1362](https://redirect.github.com/actions/setup-node/pull/1362)\n\n**Full Changelog**:\n<https://github.com/actions/setup-node/compare/v5...v6.0.0>\n\n###\n[`v6`](https://redirect.github.com/actions/setup-node/compare/v5.0.0...v6)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-node/compare/v5.0.0...v6)\n\n###\n[`v5.0.0`](https://redirect.github.com/actions/setup-node/releases/tag/v5.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-node/compare/v5.0.0...v5.0.0)\n\n##### What's Changed\n\n##### Breaking Changes\n\n- Enhance caching in setup-node with automatic package manager detection\nby [@&#8203;priya-kinthali](https://redirect.github.com/priya-kinthali)\nin\n[#&#8203;1348](https://redirect.github.com/actions/setup-node/pull/1348)\n\nThis update, introduces automatic caching when a valid `packageManager`\nfield is present in your `package.json`. This aims to improve workflow\nperformance and make dependency management more seamless.\nTo disable this automatic caching, set `package-manager-cache: false`\n\n```yaml\nsteps:\n- uses: actions/checkout@v5\n- uses: actions/setup-node@v5\n  with:\n    package-manager-cache: false\n```\n\n- Upgrade action to use node24 by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;1325](https://redirect.github.com/actions/setup-node/pull/1325)\n\nMake sure your runner is on version v2.327.1 or later to ensure\ncompatibility with this release. [See Release\nNotes](https://redirect.github.com/actions/runner/releases/tag/v2.327.1)\n\n##### Dependency Upgrades\n\n- Upgrade\n[@&#8203;octokit/request-error](https://redirect.github.com/octokit/request-error)\nand [@&#8203;actions/github](https://redirect.github.com/actions/github)\nby [@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;1227](https://redirect.github.com/actions/setup-node/pull/1227)\n- Upgrade uuid from 9.0.1 to 11.1.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;1273](https://redirect.github.com/actions/setup-node/pull/1273)\n- Upgrade undici from 5.28.5 to 5.29.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;1295](https://redirect.github.com/actions/setup-node/pull/1295)\n- Upgrade form-data to bring in fix for critical vulnerability by\n[@&#8203;gowridurgad](https://redirect.github.com/gowridurgad) in\n[#&#8203;1332](https://redirect.github.com/actions/setup-node/pull/1332)\n- Upgrade actions/checkout from 4 to 5 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;1345](https://redirect.github.com/actions/setup-node/pull/1345)\n\n##### New Contributors\n\n- [@&#8203;priya-kinthali](https://redirect.github.com/priya-kinthali)\nmade their first contribution in\n[#&#8203;1348](https://redirect.github.com/actions/setup-node/pull/1348)\n- [@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) made their\nfirst contribution in\n[#&#8203;1325](https://redirect.github.com/actions/setup-node/pull/1325)\n\n**Full Changelog**:\n<https://github.com/actions/setup-node/compare/v4...v5.0.0>\n\n###\n[`v5`](https://redirect.github.com/actions/setup-node/compare/v4.4.0...v5.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-node/compare/v4.4.0...v5.0.0)\n\n</details>\n\n<details>\n<summary>actions/setup-python (actions/setup-python)</summary>\n\n###\n[`v7.0.0`](https://redirect.github.com/actions/setup-python/releases/tag/v7.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-python/compare/v7.0.0...v7.0.0)\n\n#### What's Changed\n\n##### Enhancements\n\n- Migrate to ESM and upgrade dependencies by\n[@&#8203;priyagupta108](https://redirect.github.com/priyagupta108) in\n[#&#8203;1330](https://redirect.github.com/actions/setup-python/pull/1330)\n- Pin SHA commits and update docs with latest versions by\n[@&#8203;HarithaVattikuti](https://redirect.github.com/HarithaVattikuti)\nin\n[#&#8203;1338](https://redirect.github.com/actions/setup-python/pull/1338)\n- Remove the pip-install input by\n[@&#8203;gowridurgad](https://redirect.github.com/gowridurgad) in\n[#&#8203;1336](https://redirect.github.com/actions/setup-python/pull/1336)\n\n##### Bug Fix\n\n- Fix to Classify stderr warning messages as warnings instead of errors\nin annotations by\n[@&#8203;lmvysakh](https://redirect.github.com/lmvysakh) in\n[#&#8203;1335](https://redirect.github.com/actions/setup-python/pull/1335)\n- Validate and retry manifest fetch to prevent silent failures by\n[@&#8203;priyagupta108](https://redirect.github.com/priyagupta108) in\n[#&#8203;1332](https://redirect.github.com/actions/setup-python/pull/1332)\n\n##### Dependency Upgrade\n\n- Bump certifi from 2020.6.20 to 2024.7.4 in /**tests**/data by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1328](https://redirect.github.com/actions/setup-python/pull/1328)\n- Remove EOL Python versions and Bumps numpy text fixture by\n[@&#8203;priya-kinthali](https://redirect.github.com/priya-kinthali) in\n[#&#8203;1333](https://redirect.github.com/actions/setup-python/pull/1333)\n- Upgrade\n[@&#8203;actions/cache](https://redirect.github.com/actions/cache) to\n6.2.0 by [@&#8203;philip-gai](https://redirect.github.com/philip-gai) in\n[#&#8203;1337](https://redirect.github.com/actions/setup-python/pull/1337)\n\n#### New Contributors\n\n- [@&#8203;lmvysakh](https://redirect.github.com/lmvysakh) made their\nfirst contribution in\n[#&#8203;1335](https://redirect.github.com/actions/setup-python/pull/1335)\n- [@&#8203;philip-gai](https://redirect.github.com/philip-gai) made\ntheir first contribution in\n[#&#8203;1337](https://redirect.github.com/actions/setup-python/pull/1337)\n\n**Full Changelog**:\n<https://github.com/actions/setup-python/compare/v6...v7.0.0>\n\n###\n[`v7`](https://redirect.github.com/actions/setup-python/compare/v6.3.0...v7.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-python/compare/v6.3.0...v7.0.0)\n\n###\n[`v6.3.0`](https://redirect.github.com/actions/setup-python/releases/tag/v6.3.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-python/compare/v6.2.0...v6.3.0)\n\n#### What's Changed\n\n##### Enhancement\n\n- Add RHEL support and include Linux distro in cache keys by\n[@&#8203;priyagupta108](https://redirect.github.com/priyagupta108) in\n[#&#8203;1323](https://redirect.github.com/actions/setup-python/pull/1323)\n- Fix pip cache error handling on Windows by\n[@&#8203;priyagupta108](https://redirect.github.com/priyagupta108) in\n[#&#8203;1040](https://redirect.github.com/actions/setup-python/pull/1040)\n\n##### Dependency update\n\n- Upgrade minimatch from 3.1.2 to 3.1.5 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1281](https://redirect.github.com/actions/setup-python/pull/1281)\n- Upgrade actions dependencies by\n[@&#8203;gowridurgad](https://redirect.github.com/gowridurgad) with\n[@&#8203;Copilot](https://redirect.github.com/Copilot) in\n[#&#8203;1303](https://redirect.github.com/actions/setup-python/pull/1303)\n- Upgrade\n[@&#8203;actions/cache](https://redirect.github.com/actions/cache) to\n5.1.0, log cache write denied by\n[@&#8203;jasongin](https://redirect.github.com/jasongin) in\n[#&#8203;1324](https://redirect.github.com/actions/setup-python/pull/1324)\n- Upgrade dependency versions and test workflow configuration by\n[@&#8203;HarithaVattikuti](https://redirect.github.com/HarithaVattikuti)\nin\n[#&#8203;1322](https://redirect.github.com/actions/setup-python/pull/1322)\n\n##### Documentation\n\n- Update advanced-usage.md by\n[@&#8203;Dunky-Z](https://redirect.github.com/Dunky-Z) in\n[#&#8203;811](https://redirect.github.com/actions/setup-python/pull/811)\n\n#### New Contributors\n\n- [@&#8203;gowridurgad](https://redirect.github.com/gowridurgad) with\n[@&#8203;Copilot](https://redirect.github.com/Copilot) made their first\ncontribution in\n[#&#8203;1303](https://redirect.github.com/actions/setup-python/pull/1303)\n- [@&#8203;jasongin](https://redirect.github.com/jasongin) made their\nfirst contribution in\n[#&#8203;1324](https://redirect.github.com/actions/setup-python/pull/1324)\n- [@&#8203;Dunky-Z](https://redirect.github.com/Dunky-Z) made their\nfirst contribution in\n[#&#8203;811](https://redirect.github.com/actions/setup-python/pull/811)\n\n**Full Changelog**:\n<https://github.com/actions/setup-python/compare/v6.2.0...v6.3.0>\n\n###\n[`v6.2.0`](https://redirect.github.com/actions/setup-python/releases/tag/v6.2.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-python/compare/v6.1.0...v6.2.0)\n\n#### What's Changed\n\n##### Dependency Upgrades\n\n- Upgrade dependencies to Node 24 compatible versions by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;1259](https://redirect.github.com/actions/setup-python/pull/1259)\n- Upgrade urllib3 from 2.5.0 to 2.6.3 in `/__tests__/data` by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1253](https://redirect.github.com/actions/setup-python/pull/1253)\nand\n[#&#8203;1264](https://redirect.github.com/actions/setup-python/pull/1264)\n\n**Full Changelog**:\n<https://github.com/actions/setup-python/compare/v6...v6.2.0>\n\n###\n[`v6.1.0`](https://redirect.github.com/actions/setup-python/releases/tag/v6.1.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-python/compare/v6...v6.1.0)\n\n#### What's Changed\n\n##### Enhancements:\n\n- Add support for `pip-install` input by\n[@&#8203;gowridurgad](https://redirect.github.com/gowridurgad) in\n[#&#8203;1201](https://redirect.github.com/actions/setup-python/pull/1201)\n- Add graalpy early-access and windows builds by\n[@&#8203;timfel](https://redirect.github.com/timfel) in\n[#&#8203;880](https://redirect.github.com/actions/setup-python/pull/880)\n\n##### Dependency and Documentation updates:\n\n- Enhanced wording and updated example usage for `allow-prereleases` by\n[@&#8203;yarikoptic](https://redirect.github.com/yarikoptic) in\n[#&#8203;979](https://redirect.github.com/actions/setup-python/pull/979)\n- Upgrade urllib3 from 1.26.19 to 2.5.0 and document breaking changes in\nv6 by [@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1139](https://redirect.github.com/actions/setup-python/pull/1139)\n- Upgrade typescript from 5.4.2 to 5.9.3 and Documentation update by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1094](https://redirect.github.com/actions/setup-python/pull/1094)\n- Upgrade actions/publish-action from 0.3.0 to 0.4.0 & Documentation\nupdate for pip-install input by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1199](https://redirect.github.com/actions/setup-python/pull/1199)\n- Upgrade requests from 2.32.2 to 2.32.4 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1130](https://redirect.github.com/actions/setup-python/pull/1130)\n- Upgrade prettier from 3.5.3 to 3.6.2 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1234](https://redirect.github.com/actions/setup-python/pull/1234)\n- Upgrade [@&#8203;types/node](https://redirect.github.com/types/node)\nfrom 24.1.0 to 24.9.1 and update macos-13 to macos-15-intel by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1235](https://redirect.github.com/actions/setup-python/pull/1235)\n\n#### New Contributors\n\n- [@&#8203;yarikoptic](https://redirect.github.com/yarikoptic) made\ntheir first contribution in\n[#&#8203;979](https://redirect.github.com/actions/setup-python/pull/979)\n\n**Full Changelog**:\n<https://github.com/actions/setup-python/compare/v6...v6.1.0>\n\n###\n[`v6.0.0`](https://redirect.github.com/actions/setup-python/releases/tag/v6.0.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-python/compare/v6...v6)\n\n#### What's Changed\n\n##### Breaking Changes\n\n- Upgrade to node 24 by\n[@&#8203;salmanmkc](https://redirect.github.com/salmanmkc) in\n[#&#8203;1164](https://redirect.github.com/actions/setup-python/pull/1164)\n\nMake sure your runner is on version v2.327.1 or later to ensure\ncompatibility with this release. [See Release\nNotes](https://redirect.github.com/actions/runner/releases/tag/v2.327.1)\n\n##### Enhancements:\n\n- Add support for `pip-version` by\n[@&#8203;priyagupta108](https://redirect.github.com/priyagupta108) in\n[#&#8203;1129](https://redirect.github.com/actions/setup-python/pull/1129)\n- Enhance reading from .python-version by\n[@&#8203;krystof-k](https://redirect.github.com/krystof-k) in\n[#&#8203;787](https://redirect.github.com/actions/setup-python/pull/787)\n- Add version parsing from Pipfile by\n[@&#8203;aradkdj](https://redirect.github.com/aradkdj) in\n[#&#8203;1067](https://redirect.github.com/actions/setup-python/pull/1067)\n\n##### Bug fixes:\n\n- Clarify pythonLocation behaviour for PyPy and GraalPy in environment\nvariables by\n[@&#8203;aparnajyothi-y](https://redirect.github.com/aparnajyothi-y) in\n[#&#8203;1183](https://redirect.github.com/actions/setup-python/pull/1183)\n- Change missing cache directory error to warning by\n[@&#8203;aparnajyothi-y](https://redirect.github.com/aparnajyothi-y) in\n[#&#8203;1182](https://redirect.github.com/actions/setup-python/pull/1182)\n- Add Architecture-Specific PATH Management for Python with --user Flag\non Windows by\n[@&#8203;aparnajyothi-y](https://redirect.github.com/aparnajyothi-y) in\n[#&#8203;1122](https://redirect.github.com/actions/setup-python/pull/1122)\n- Include python version in PyPy python-version output by\n[@&#8203;cdce8p](https://redirect.github.com/cdce8p) in\n[#&#8203;1110](https://redirect.github.com/actions/setup-python/pull/1110)\n- Update docs: clarification on pip authentication with setup-python by\n[@&#8203;priya-kinthali](https://redirect.github.com/priya-kinthali) in\n[#&#8203;1156](https://redirect.github.com/actions/setup-python/pull/1156)\n\n##### Dependency updates:\n\n- Upgrade idna from 2.9 to 3.7 in /**tests**/data by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;843](https://redirect.github.com/actions/setup-python/pull/843)\n- Upgrade form-data to fix critical vulnerabilities\n[#&#8203;182](https://redirect.github.com/actions/setup-python/issues/182)\n&\n[#&#8203;183](https://redirect.github.com/actions/setup-python/issues/183)\nby [@&#8203;aparnajyothi-y](https://redirect.github.com/aparnajyothi-y)\nin\n[#&#8203;1163](https://redirect.github.com/actions/setup-python/pull/1163)\n- Upgrade setuptools to 78.1.1 to fix path traversal vulnerability in\nPackageIndex.download by\n[@&#8203;aparnajyothi-y](https://redirect.github.com/aparnajyothi-y) in\n[#&#8203;1165](https://redirect.github.com/actions/setup-python/pull/1165)\n- Upgrade actions/checkout from 4 to 5 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;1181](https://redirect.github.com/actions/setup-python/pull/1181)\n- Upgrade\n[@&#8203;actions/tool-cache](https://redirect.github.com/actions/tool-cache)\nfrom 2.0.1 to 2.0.2 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;1095](https://redirect.github.com/actions/setup-python/pull/1095)\n\n#### New Contributors\n\n- [@&#8203;krystof-k\n\n> ✂ **Note**\n> \n> PR body was truncated to here.\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-09-25T17:29:23+03:00",
          "tree_id": "9a86546ca8e93da029f62ea70905d617b03514d8",
          "url": "https://github.com/laurigates/dotfiles/commit/631791eac6c438b7d92854073e0bc69caa6cddac"
        },
        "date": 1790346601768,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.01046013368666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015840160000000002,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012671882,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.01152479386,
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
          "id": "75a2747d3e9b667e4ae356d0e321d834bde1b358",
          "message": "fix(mise): approve low-download npm:ocx so mise upgrade stops failing (#457)\n\nmise refuses to install npm packages with fewer than 1000 weekly\ndownloads unless they are approved explicitly. `ocx` has 487 per week,\nso `mise upgrade` exited 1. That aborted the `01-update-packages.sh`\nrun_onchange script, and `chezmoi apply` stopped partway.\n\nThis PR sets `allow_low_downloads = true` on `npm:ocx` in\n`private_dot_config/mise/config.toml.tmpl`. The version stays pinned at\n2.0.14.\n\nVerification:\n- `mise install npm:ocx` using the new entry installed 2.0.14, and `ocx\n--version` printed `2.0.14`.\n- The rendered template parses as TOML and resolves to `{version =\n\"2.0.14\", allow_low_downloads = true}`.\n- Pre-commit hooks passed.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nCo-authored-by: Claude Opus 5.5 (1M context) <noreply@anthropic.com>",
          "timestamp": "2026-09-25T17:29:37+03:00",
          "tree_id": "50e3295db69bcf2dd275a46114fd8884012fd62e",
          "url": "https://github.com/laurigates/dotfiles/commit/75a2747d3e9b667e4ae356d0e321d834bde1b358"
        },
        "date": 1790346640760,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.010351790346666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0012134417200000002,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.00104965792,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.00965613812,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "444a04d962093bd700f1e330e9991c1f4dd09b77",
          "message": "chore(deps): update anthropics/claude-code-action action to v1.0.233 (#458)\n\nThis PR contains the following updates:\n\n| Package | Type | Update | Change | Pending |\n|---|---|---|---|---|\n|\n[anthropics/claude-code-action](https://redirect.github.com/anthropics/claude-code-action)\n| action | patch | `v1.0.232` → `v1.0.233` | `v1.0.235` (+1) |\n\n---\n\n> [!WARNING]\n> Some dependencies could not be looked up. Check the [Dependency\nDashboard](../issues/379) for more information.\n\n---\n\n### Release Notes\n\n<details>\n<summary>anthropics/claude-code-action\n(anthropics/claude-code-action)</summary>\n\n###\n[`v1.0.233`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.233)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.232...v1.0.233)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.232...v1.0.233>\n\n</details>\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-09-27T18:21:54Z",
          "tree_id": "f26cdad0cadae24a41e78449bafdfb4f1c5904a3",
          "url": "https://github.com/laurigates/dotfiles/commit/444a04d962093bd700f1e330e9991c1f4dd09b77"
        },
        "date": 1790533350583,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.007907382333333336,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0013040071400000001,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0010405385400000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.009444356880000001,
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
          "id": "e3879db9e0e66ea51a41fe3eb7fff2f0033cab8f",
          "message": "chore(claude): context diet wave 3 — promote, consolidate, and lean always-loaded rules (#459)\n\n## What\n\nContext diet, wave 3 (`meta-context-diet` audit). Cuts ~24.1k chars\n(~6.0k tokens) from the every-turn context: ~21.5k from `~/.claude`\nrules (applies in every project) and ~2.6k from this repo's own\n`CLAUDE.md` and `.claude/rules/`.\n\n**Global rules (`exact_dot_claude/rules/`)**\n- Promoted to skills, rule left as a pointer stub:\n`verify-license-position-before-declaring-blocked` →\n`code-quality-plugin:code-license-position`; `workflow-agent-scale` →\n`workflow-orchestration-plugin:workflow-scale-budget`\n- Consolidated and deleted: `mise-stale-tool-copies` (now in\n`configure-mise` REFERENCE), `orbstack-gui-quit-orphans-helper`\n(`macos-performance-triage`)\n- Leaned, invariant wording kept: `communication`,\n`offload-to-deterministic-substrate`, `skill-and-agent-catalog-check`,\n`agent-and-tool-selection`, `front-load-executive-decisions`,\n`copy-paste-commands`, `dependency-management`. The three-tics and\nend-on-the-fact sections of `communication.md` are unchanged because\n`prose-plugin:prose-check` names that file as canonical.\n- Path-scoped: `local-ci-parity` (CI workflows, justfiles, pre-commit,\nmise, Makefile)\n\n**Project context**\n- `CLAUDE.md` § Linting points at `.claude/rules/testing.md` (which\ngains the `lint:docs` and gitleaks rows); § Tools dropped; § Blueprint\ncut to one line\n- `development.md` trimmed to the commit type/scope list; its bare\n`chezmoi apply` advice contradicted the worktree guidance\n- `document-management.md` deleted\n(`blueprint-plugin:document-detection` covers it)\n\n## Depends on\n\nlaurigates/claude-plugins#2860 — the new skills and the consolidation\ntargets. Merge that first.\n\n## After merge\n\n`just apply`: `exact_dot_claude/` removes the two deleted rules from\n`~/.claude/rules/`.\n\n## Checks\n\nPre-commit passed on both commits (context-budget and doc-reference\nhooks included). `mise run lint` passes except `lint:lua`, which fails\nlocally because luacheck 1.2.0 crashes on Lua 5.5\n(lunarmodules/luacheck#147); no Lua files changed.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01Juiaf9kfaYKgrm7gYYCNk4\n\n---------\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-09-29T10:41:02+03:00",
          "tree_id": "52594e7fe13a2641e188c175ec788445e2963860",
          "url": "https://github.com/laurigates/dotfiles/commit/e3879db9e0e66ea51a41fe3eb7fff2f0033cab8f"
        },
        "date": 1790667723963,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.010745521786666665,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0017590429400000003,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012938193400000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.011584583240000002,
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
          "id": "a60a24f477780d72b1031d79785dbf20225b0625",
          "message": "fix(zsh): make ccd cd in the current shell instead of spawning a subshell (#460)\n\n`ccd` was `chezmoi cd`, which starts a child `$SHELL` in the source\ndirectory because a subprocess cannot change its parent shell's working\ndirectory. Each use stacked a nested shell that had to be left with\n`exit`.\n\nThe alias now resolves the path with `chezmoi source-path` and runs a\nplain `cd`, so it moves the current shell and `cd -` returns to the\nprevious directory.\n\nThe alias no longer accepts a target-path argument (`chezmoi cd\n<target>`); `ccd` always goes to the source root.\n\nVerified: `cd \"$(chezmoi source-path)\" && pwd` prints\n`/Users/lgates/.local/share/chezmoi`; `mise run lint:shell` exits 0.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01LGcuLvq4b6uf6X5oMQBSiU\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-09-29T12:58:14+03:00",
          "tree_id": "ee07a6f4329c187d3c3053d6bb885b4273b28a1d",
          "url": "https://github.com/laurigates/dotfiles/commit/a60a24f477780d72b1031d79785dbf20225b0625"
        },
        "date": 1790675947598,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.00948788622,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015233585200000004,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012602765200000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.01085487962,
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
          "id": "6ef9020eb550b16353cdc107841a27c4d752bd5b",
          "message": "chore(claude): enable documentation-plugin at user scope (#461)\n\nChanges `documentation-plugin@laurigates-claude-plugins` from `false` to\n`true` in the `enabledPlugins` overlay of\n`exact_dot_claude/modify_settings.json`.\n\nThree always-loaded global rules point at skills in this plugin:\n`documentation-authoring.md`,\n`verify-machine-facts-before-publishing.md` and `tool-use-patterns.md`.\nThey name `docs-single-source`, `docs-verify-machine-facts` and\n`docs-fetch-fallbacks`. `public-export-sanitization` also moved into\nthis plugin in laurigates/claude-plugins#2810. While the plugin is\ndisabled, none of those pointers resolve outside thelma, which enables\nthe plugin itself.\n\nVerified by piping the live `~/.claude/settings.json` through the modify\nscript: the rendered\n`enabledPlugins[\"documentation-plugin@laurigates-claude-plugins\"]` is\n`true`.\n\nTakes effect after `chezmoi apply` and a new session.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_018X1UhPee6LFXJK7L5Awinj\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-09-29T14:01:42+03:00",
          "tree_id": "00b96bfb4cfaa8e12f4796fa5a983e13f55f2e47",
          "url": "https://github.com/laurigates/dotfiles/commit/6ef9020eb550b16353cdc107841a27c4d752bd5b"
        },
        "date": 1790679757503,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.009653642873333335,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015067633599999998,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012568655600000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0114310703,
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
          "id": "1b7ea784ae5294c639a9686a72f673033a5a3bf3",
          "message": "docs(claude): replace the Opus-only subagent floor with per-task model selection (#462)\n\n## What\n\nReplaces the \"Opus is the floor\" section of\n`agent-and-tool-selection.md` with per-task model selection, and records\nthe evidence behind it.\n\nThe Opus-only rule came from one comparison: Opus 4.8 at low effort beat\nSonnet 4.6 at high effort (#237). The rule text dropped the model\nversions, so it read as a permanent law, and it kept ruling Sonnet out\nafter Sonnet 5.5 shipped.\n\nNew section:\n- **Opus stays the default** for delegates that edit, verify facts, or\nreturn analysis the main loop builds on, and **stays the choice for\nopen-ended review and audit**.\n- **Sonnet 5.5 is allowed** for well-specified work (a bounded\ndiagnosis, an implementation against an explicit brief) when an\nindependent check stands behind it: a mechanical gate, or an Opus re-run\nof its claims. It is also allowed whenever Lauri asks for it.\n- \"Remove Sonnet suggestions on sight\" becomes \"don't hard-code a\ncheaper model as a blanket cost default; choose per task\".\n- **Sonnet 5.5 specifics** from the\n[announcement](https://www.anthropic.com/claude-sonnet-5-5): set effort\nexplicitly where it can be set (Claude Code defaults Sonnet to Medium);\ncap it at `high`/`xhigh` for scoped edits, never `max`; send security\nreview to Opus; re-run the comparison for the Haiku cold-read exception\nwhen Haiku 5.5 ships.\n- The Haiku cold-read exception, `inherit`, effort as a cost lever, and\nthe `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` note are unchanged in substance.\n\n`multi-model-delegation.md` pointed at the rule as \"(always Opus)\" and\nnow says \"(model selection)\".\n\n## Evidence\n\nA comparison ran on 2026-09-30 in the FVH `infrastructure` repo. Both\nmodels got identical read-only briefs against a frozen snapshot\n(`3c8767ba`), at the same default effort, and were graded against\ndefects verified before the runs:\n\n| Task | Sonnet 5.5 | Opus 5.5 | Tokens (S / O) |\n|---|---|---|---|\n| Diagnosis: why a classifier resolves nothing (4 known causes) | 4/4 |\n4/4 | 178k / 180k |\n| Review of three justfile recipes (12 known defects) | 10/12 | 12/12 |\n156k / 161k |\n\nEach model's unique claims were checked against the repo and live data,\nand neither run made a false claim. Separately, a Sonnet 5.5\nimplementation task (infrastructure #2517–#2519) held on every claim\nre-run against the pushed branches.\n\nThe Sonnet 5.5 specifics come from the announcement rather than these\nruns. On FrontierCode, Sonnet 5.5 at Max scored below Xhigh because it\nran the code-review skill's subagents more often, which led to timeouts\nand out-of-scope edits. Higher-risk cyber tasks fall back to Sonnet 5,\nwhich is why security review stays on Opus.\n\n**Limits:** four graded runs, scored by an Opus session, at default\neffort only. The Agent tool can't set effort per call, so this doesn't\nretest the old low-vs-high pairing. The rule says to re-run the\ncomparison when either model changes.\n\n## Not in this PR\n\n`laurigates/claude-plugins` may still restate the Opus-only standard,\nfor example `agents-plugin:agents-analyze` (\"auditing agents against the\nalways-Opus standard\"). Aligning it is a separate change in that repo.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01RWYU5hjKTtT37CkLELMimM\n\n---------\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-01T14:13:11+03:00",
          "tree_id": "44d9ecc040edb7f1d7a9e51f8f2f74ccb7a1dc7e",
          "url": "https://github.com/laurigates/dotfiles/commit/1b7ea784ae5294c639a9686a72f673033a5a3bf3"
        },
        "date": 1790853260458,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.010832734886666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015265302000000002,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.001260196,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.01209552702,
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
          "id": "1bc53527ca99d5278e719171361b5f2e5aded91b",
          "message": "feat(pi): local web search for local models via SearXNG, pi-lean-search, pi-smart-fetch, ketch (#463)\n\n## Summary\n\nKeyless, self-hosted web search for pi when running local models.\nReplaces the need for Ollama's hosted web search (account + API key).\n\n| Layer | Component | Config |\n|---|---|---|\n| Backend | SearXNG (Docker, loopback only) |\n`~/.config/searxng/{compose.yaml,settings.yml,.env}` |\n| pi search tool | `pi-lean-search@0.6.0` (`web-search`) | `searxng.url`\nin `~/.pi/agent/settings.json` |\n| pi fetch tools | `pi-smart-fetch@0.3.17` (`web_fetch`,\n`batch_web_fetch`) | `smartFetchDefaultMaxChars: 12000` |\n| CLI | `ketch` 0.18.1 | `KETCH_BACKEND=searxng`, `KETCH_SEARXNG_URL` in\nmise env |\n\n## Changes\n\n- **mise**: `@earendil-works/pi-coding-agent` 0.84.1 → 0.99.2 (breaking\nchanges in between are SDK/extension-API only);\n`github:1broseidon/ketch` = 0.18.1; ketch env pinned to SearXNG so\n`auto` never falls back to hosted providers.\n- **SearXNG**: derived from the [official compose\nfile](https://docs.searxng.org/admin/installation-docker.html), with\nthese deviations:\n  - published on `127.0.0.1` only;\n  - limiter and valkey dropped;\n- `search.formats: [html, json]`\n([settings_search](https://docs.searxng.org/admin/settings/settings_search.html));\n  - image tag pinned;\n- `settings.yml` mounted read-only as a single file, because the\nentrypoint `chown -R`s a mounted config dir;\n- `GRANIAN_HOST=0.0.0.0`, because the image's `::` default aborts when\nDocker IPv6 is off.\n- `SEARXNG_SECRET`\n([settings_server](https://docs.searxng.org/admin/settings/settings_server.html))\nis generated once by a chezmoi `create_` template and never committed.\n- **pi**: `private_dot_pi/agent/modify_settings.json.tmpl` deep-merges\nan overlay\n([settings](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/settings.md),\n[packages](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/packages.md)):\n- pi-owned runtime keys (`defaultModel`, `lastChangelogVersion`, …) pass\nthrough unchanged;\n- `packages` is unioned by package identity, so packages added with `pi\ninstall` survive;\n  - pi installs declared or re-pinned packages on its next start.\n- **just**: `searxng-up`, `searxng-down`, `searxng-check` in\n`maint.just`. The port is read from the running container.\n- **Single source of truth**: port and image tag in `.chezmoidata.toml`\n`[searxng]`.\n\n## Testing\n\n- `tests/test-pi-settings-modify.sh` (`mise run test:pi-settings`, added\nto `mise run test`): 9/9 pass. Covers an empty target, pass-through of\npi-owned keys, replacing a stale pin, keeping unmanaged and object-form\npackages, and idempotence.\n- `chezmoi apply` into a scratch `$HOME`, then `docker compose up`:\n  - `/healthz` returns 200;\n  - `format=json` returns 200;\n  - `format=csv` returns 403, which confirms the settings are applied;\n  - no secret error;\n  - host file ownership is unchanged;\n  - a second `chezmoi status` is clean and the secret stays stable.\n- pi 0.99.2 with the rendered settings: both packages installed on\nstartup, `/searxng-status` reports \"search pipeline is working\", and\n`web_fetch`/`batch_web_fetch` are registered.\n- `mise install github:1broseidon/ketch@0.18.1` resolves the release\nasset. `ketch config` shows `backend=searxng` coming from the env.\n- Other checks pass: shellcheck (tracked scripts plus the rendered\n`modify_`), `check-doc-references --strict`, `test-ci-pins`,\n`test-mise-tasks` (21 pass, 3 skip for missing luacheck/actionlint), and\ngitleaks.\n\n## Notes\n\n- `pi-smart-fetch@0.3.17` triggers a pi warning: it lists\n`@earendil-works/pi-tui` and `@sinclair/typebox` under `dependencies`\ninstead of `peerDependencies`. This is an upstream packaging issue and\ndoes not stop it loading.\n- SearXNG upstream engines can rate-limit or CAPTCHA a single IP.\nEnabling several engines is the mitigation.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01LhfqduwVxbM2KoJJM9nG8i\n\n---\n_Generated by [Claude\nCode](https://claude.ai/code/session_01LhfqduwVxbM2KoJJM9nG8i)_\n\nCo-authored-by: Claude <noreply@anthropic.com>",
          "timestamp": "2026-10-01T17:29:19+03:00",
          "tree_id": "77965266645227c9f1fdd514e7c81fa85b56a124",
          "url": "https://github.com/laurigates/dotfiles/commit/1bc53527ca99d5278e719171361b5f2e5aded91b"
        },
        "date": 1790865023252,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.009560469786666666,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015169339000000001,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012531407,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.01146814996,
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
          "id": "7634207217411f43b0745f75dfd3e8e703069cb4",
          "message": "chore: lazy-lock refresh, atuin history filters, pi superseded-package prune (#464)\n\n## Summary\n\nThree independent tidying changes bundled as one PR:\n\n1. **`lazy-lock.json` refresh** — routine plugin pin bump across 11\nplugins (blink-ripgrep, fzf-lua, gitsigns, kitty-scrollback, kulala,\nmini, neoconf, nvim-treesitter, opencode, render-markdown, schemastore).\n\n2. **atuin history filters** — extend `history_filter` for commands\ntouching `/mnt/sabrent` (external SSD with models), `.safetensors` paths\n(large model files), and piped `gcloud secrets` output.\n\n3. **pi `modify_settings` pruning** — the `modify_settings` overlay that\npins `pi-lean-search`/`pi-smart-fetch` now also removes\n`npm:@ollama/pi-web-search` when present in the live file, so the two\ndon't fight over `web_fetch`. Adds `is_pruned` to the jq filter with a\ncomment naming the supersession, and a test case asserting survival of\nunmanaged entries.\n\n## Testing\n- `bash tests/test-pi-settings-modify.sh` — 10/10 pass (includes the new\n`@ollama/pi-web-search` prune assertion).\n- `just status` confirms the only remaining local drift is\n`.config/mise/config.toml` and `.pi/agent/settings.json` (already\ncovered by earlier issues #448/#447 family).\n- `just lint` advisory flagged the \"safetensors → safe tensor\" typo\nsuggestion as info-level; cosmetic only and pre-committed as-is.\n- Pre-commit hooks pass on all three commits.",
          "timestamp": "2026-10-02T14:32:12+03:00",
          "tree_id": "ada536898fd3ef4443a0b497af749464eee4c205",
          "url": "https://github.com/laurigates/dotfiles/commit/7634207217411f43b0745f75dfd3e8e703069cb4"
        },
        "date": 1790940786271,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.008983698533333334,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0010900858000000002,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0008606170000000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.007818286800000001,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "911ef2270ed500fb0ebc319acc98d5a818683789",
          "message": "chore(deps): update GitHub Actions (#465)\n\nThis PR contains the following updates:\n\n| Package | Type | Update | Change | Pending |\n|---|---|---|---|---|\n|\n[anthropics/claude-code-action](https://redirect.github.com/anthropics/claude-code-action)\n| action | patch | `v1.0.233` → `v1.0.237` | `v1.0.240` (+2) |\n|\n[codelytv/pr-size-labeler](https://redirect.github.com/codelytv/pr-size-labeler)\n| action | minor | `v1.10.4` → `v1.11.1` | `v1.12.0` |\n\n---\n\n> [!WARNING]\n> Some dependencies could not be looked up. Check the [Dependency\nDashboard](../issues/379) for more information.\n\n---\n\n### Release Notes\n\n<details>\n<summary>anthropics/claude-code-action\n(anthropics/claude-code-action)</summary>\n\n###\n[`v1.0.237`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.237)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.236...v1.0.237)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.236...v1.0.237>\n\n###\n[`v1.0.236`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.236)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.235...v1.0.236)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.235...v1.0.236>\n\n###\n[`v1.0.235`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.235)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.234...v1.0.235)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.234...v1.0.235>\n\n###\n[`v1.0.234`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.234)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.233...v1.0.234)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.233...v1.0.234>\n\n</details>\n\n<details>\n<summary>codelytv/pr-size-labeler (codelytv/pr-size-labeler)</summary>\n\n###\n[`v1.11.1`](https://redirect.github.com/CodelyTV/pr-size-labeler/releases/tag/v1.11.1)\n\n[Compare\nSource](https://redirect.github.com/codelytv/pr-size-labeler/compare/v1.11.0...v1.11.1)\n\n#### What's Changed\n\n- fix: preserve labels added by other automations by\n[@&#8203;JavierCane](https://redirect.github.com/JavierCane) in\n[CodelyTV#110](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/110)\n\n**Full Changelog**:\n<https://github.com/CodelyTV/pr-size-labeler/compare/v1.11.0...v1.11.1>\n\n###\n[`v1.11.0`](https://redirect.github.com/CodelyTV/pr-size-labeler/releases/tag/v1.11.0)\n\n[Compare\nSource](https://redirect.github.com/codelytv/pr-size-labeler/compare/v1.10.5...v1.11.0)\n\n#### What's Changed\n\n- docs: clarify `files_to_ignore` path matching by\n[@&#8203;JavierCane](https://redirect.github.com/JavierCane) in\n[CodelyTV#108](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/108)\n- feat: improve DX when required permissions are missing and reduce the\nnumber of required permissions by\n[@&#8203;JavierCane](https://redirect.github.com/JavierCane) in\n[CodelyTV#109](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/109)\n\n**Full Changelog**:\n<https://github.com/CodelyTV/pr-size-labeler/compare/v1.10.5...v1.11.0>\n\n###\n[`v1.10.5`](https://redirect.github.com/CodelyTV/pr-size-labeler/releases/tag/v1.10.5)\n\n[Compare\nSource](https://redirect.github.com/codelytv/pr-size-labeler/compare/v1.10.4...v1.10.5)\n\n#### What's Changed\n\n- ci: pin checkout action to v7.0.1 by\n[@&#8203;JavierCane](https://redirect.github.com/JavierCane) in\n[CodelyTV#104](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/104)\n- fix(ci): use current bashunit installer by\n[@&#8203;JavierCane](https://redirect.github.com/JavierCane) in\n[CodelyTV#105](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/105)\n- build(deps): upgrade bashunit to 0.51.0 by\n[@&#8203;JavierCane](https://redirect.github.com/JavierCane) in\n[CodelyTV#106](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/106)\n- ci: configure Dependabot for GitHub Actions by\n[@&#8203;JavierCane](https://redirect.github.com/JavierCane) in\n[CodelyTV#107](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/107)\n- fix: paginate PR files when counting changes by\n[@&#8203;caugner](https://redirect.github.com/caugner) in\n[CodelyTV#102](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/102)\n- fix(labeler): generate comment after XL label is added by\n[@&#8203;scastd](https://redirect.github.com/scastd) in\n[CodelyTV#99](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/99)\n\n#### New Contributors\n\n- [@&#8203;caugner](https://redirect.github.com/caugner) made their\nfirst contribution in\n[CodelyTV#102](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/102)\n- [@&#8203;scastd](https://redirect.github.com/scastd) made their first\ncontribution in\n[CodelyTV#99](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/99)\n\n**Full Changelog**:\n<https://github.com/CodelyTV/pr-size-labeler/compare/v1.10.4...v1.10.5>\n\n</details>\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-10-03T17:57:04Z",
          "tree_id": "2e95a5a5185db272c9e5a72857a014d8c874fc0e",
          "url": "https://github.com/laurigates/dotfiles/commit/911ef2270ed500fb0ebc319acc98d5a818683789"
        },
        "date": 1791050294520,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.01061858542,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00153047124,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.00123500844,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.011110848,
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
          "id": "df3d35d60d00f899cd2cd61ae34f236fcbf66ce7",
          "message": "docs(macos): point to macos-sudo-touchid-context for sudo Touch ID (#468)\n\nAdds a short **Touch ID for sudo** note to `docs/platform_specific.md`,\npointing to\n[laurigates/macos-sudo-touchid-context](https://github.com/laurigates/macos-sudo-touchid-context).\nThat's the PAM module this machine uses instead of Apple's `pam_tid.so`,\nso the Touch ID dialog names the command and the requesting process.\n\n`sudo_local` is root-owned under `/etc`, so chezmoi doesn't manage it.\nThe note records the manual install and the lockout caveat.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_014K1A7GNV5GDcQyJdbazbG7\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-05T14:01:53+03:00",
          "tree_id": "e5bb1c373a5c23cb53c0f1d231798be58ff452fd",
          "url": "https://github.com/laurigates/dotfiles/commit/df3d35d60d00f899cd2cd61ae34f236fcbf66ce7"
        },
        "date": 1791198170360,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.00889988454,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0014963980199999998,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012505486199999999,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.011078179440000002,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "c6e04ab6de653db651cc7680d4fe6c38453f792b",
          "message": "chore(deps): update GitHub Actions (#467)\n\nThis PR contains the following updates:\n\n| Package | Type | Update | Change | Pending |\n|---|---|---|---|---|\n| [anchore/sbom-action](https://redirect.github.com/anchore/sbom-action)\n| action | patch | `v0.24.2` → `v0.24.3` | |\n|\n[anthropics/claude-code-action](https://redirect.github.com/anthropics/claude-code-action)\n| action | patch | `v1.0.237` → `v1.0.240` | `v1.0.241` |\n|\n[codelytv/pr-size-labeler](https://redirect.github.com/codelytv/pr-size-labeler)\n| action | minor | `v1.11.1` → `v1.12.0` | |\n| [laurigates/.github](https://redirect.github.com/laurigates/.github)\n([changelog](https://redirect.github.com/laurigates/.github/compare/308861c8c7ab920bd60c05d7f562960c3a6dd02d..6b009f6e3a319852d3efcb4794bdaaa3c5a6772c))\n| action | digest | `308861c` → `6b009f6` | |\n\n---\n\n> [!WARNING]\n> Some dependencies could not be looked up. Check the [Dependency\nDashboard](../issues/379) for more information.\n\n---\n\n### Release Notes\n\n<details>\n<summary>anchore/sbom-action (anchore/sbom-action)</summary>\n\n###\n[`v0.24.3`](https://redirect.github.com/anchore/sbom-action/releases/tag/v0.24.3)\n\n[Compare\nSource](https://redirect.github.com/anchore/sbom-action/compare/v0.24.2...v0.24.3)\n\n##### Added Features\n\n- bump type-fest from 5.9.0 to 5.10.0 \\[PR\n[#&#8203;742](https://redirect.github.com/anchore/sbom-action/pull/742)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump [@&#8203;types/node](https://redirect.github.com/types/node) from\n26.5.1 to 26.6.1 \\[PR\n[#&#8203;741](https://redirect.github.com/anchore/sbom-action/pull/741)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump [@&#8203;types/node](https://redirect.github.com/types/node) from\n26.4.1 to 26.5.1 \\[PR\n[#&#8203;737](https://redirect.github.com/anchore/sbom-action/pull/737)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump typescript-eslint from 8.69.0 to 8.70.0 \\[PR\n[#&#8203;736](https://redirect.github.com/anchore/sbom-action/pull/736)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump type-fest from 5.8.0 to 5.9.0 \\[PR\n[#&#8203;732](https://redirect.github.com/anchore/sbom-action/pull/732)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump eslint from 10.9.1 to 10.10.0 \\[PR\n[#&#8203;733](https://redirect.github.com/anchore/sbom-action/pull/733)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump typescript-eslint from 8.68.0 to 8.69.0 \\[PR\n[#&#8203;730](https://redirect.github.com/anchore/sbom-action/pull/730)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump [@&#8203;types/node](https://redirect.github.com/types/node) from\n26.2.0 to 26.4.0 \\[PR\n[#&#8203;727](https://redirect.github.com/anchore/sbom-action/pull/727)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump typescript-eslint from 8.67.0 to 8.68.0 \\[PR\n[#&#8203;726](https://redirect.github.com/anchore/sbom-action/pull/726)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n\n##### Bug Fixes\n\n- bump github.com/anchore/go-make from 0.8.0 to 0.8.1 in /.make \\[PR\n[#&#8203;738](https://redirect.github.com/anchore/sbom-action/pull/738)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump anchore/go-make/.github/actions/setup from 0.8.0 to 0.8.1 in\n/.github/actions/bootstrap \\[PR\n[#&#8203;740](https://redirect.github.com/anchore/sbom-action/pull/740)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump zizmorcore/zizmor-action from 0.6.3 to 0.6.4 \\[PR\n[#&#8203;739](https://redirect.github.com/anchore/sbom-action/pull/739)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump zizmorcore/zizmor-action from 0.6.2 to 0.6.3 \\[PR\n[#&#8203;734](https://redirect.github.com/anchore/sbom-action/pull/734)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump [@&#8203;types/node](https://redirect.github.com/types/node) from\n26.4.0 to 26.4.1 \\[PR\n[#&#8203;731](https://redirect.github.com/anchore/sbom-action/pull/731)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump tsx from 4.23.12 to 4.23.13 \\[PR\n[#&#8203;729](https://redirect.github.com/anchore/sbom-action/pull/729)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump eslint from 10.9.0 to 10.9.1 \\[PR\n[#&#8203;728](https://redirect.github.com/anchore/sbom-action/pull/728)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n- bump [@&#8203;humanfs/node](https://redirect.github.com/humanfs/node)\nfrom 0.16.7 to 0.16.8 \\[PR\n[#&#8203;725](https://redirect.github.com/anchore/sbom-action/pull/725)\n[@&#8203;dependabot](https://redirect.github.com/dependabot)]\n\n**[(Full\nChangelog)](https://redirect.github.com/anchore/sbom-action/compare/v0.24.2...v0.24.3)**\n\n</details>\n\n<details>\n<summary>anthropics/claude-code-action\n(anthropics/claude-code-action)</summary>\n\n###\n[`v1.0.240`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.240)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.239...v1.0.240)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.239...v1.0.240>\n\n###\n[`v1.0.239`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.239)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.238...v1.0.239)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.238...v1.0.239>\n\n###\n[`v1.0.238`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.238)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.237...v1.0.238)\n\n##### What's Changed\n\n- ci: security hardening for GitHub Actions workflows that call Claude\nby [@&#8203;qing-ant](https://redirect.github.com/qing-ant) in\n[#&#8203;1867](https://redirect.github.com/anthropics/claude-code-action/pull/1867)\n\n##### New Contributors\n\n- [@&#8203;qing-ant](https://redirect.github.com/qing-ant) made their\nfirst contribution in\n[#&#8203;1867](https://redirect.github.com/anthropics/claude-code-action/pull/1867)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.237...v1.0.238>\n\n</details>\n\n<details>\n<summary>codelytv/pr-size-labeler (codelytv/pr-size-labeler)</summary>\n\n###\n[`v1.12.0`](https://redirect.github.com/CodelyTV/pr-size-labeler/releases/tag/v1.12.0)\n\n[Compare\nSource](https://redirect.github.com/codelytv/pr-size-labeler/compare/v1.11.1...v1.12.0)\n\n#### What's Changed\n\n- perf: stop fetching PR files at XL threshold by\n[@&#8203;caugner](https://redirect.github.com/caugner) in\n[CodelyTV#111](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/111)\n- fix: label pull requests from forks with a writable token by\n[@&#8203;JavierCane](https://redirect.github.com/JavierCane) in\n[CodelyTV#112](https://redirect.github.com/CodelyTV/pr-size-labeler/pull/112)\n\n**Full Changelog**:\n<https://github.com/CodelyTV/pr-size-labeler/compare/v1.11.1...v1.12.0>\n\n</details>\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-10-05T21:29:32Z",
          "tree_id": "6edf37c91fd1060b01bea501a0ff0273d42f09a3",
          "url": "https://github.com/laurigates/dotfiles/commit/c6e04ab6de653db651cc7680d4fe6c38453f792b"
        },
        "date": 1791235844025,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.009811647533333334,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00123403902,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.00116886582,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.009741851800000001,
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
          "id": "ac8c2981ce8f7d9601d854a65887a288272df570",
          "message": "chore(mise): capture pin bumps from the live global config (#469)\n\nPorts pins that were bumped in place in `~/.config/mise/config.toml`\nback into `private_dot_config/mise/config.toml.tmpl`, so the next\n`chezmoi apply` keeps them instead of downgrading them.\n\n| Tool | Old | New |\n|---|---|---|\n| go | 1.23 | 1.27 |\n| opentofu | 1.11.2 | 1.13.0 |\n| @gradient-tools/surface | 0.8.0 | 0.9.0 |\n| @dotenvx/dotenvx | 2.21.0 | 2.32.3 |\n| @google/gemini-cli | 0.55.1 | 0.62.0 |\n| @mermaid-js/mermaid-cli | 11.16.0 | 12.0.0 |\n| @playwright/test | 1.62.1 | 1.63.0 |\n| ocx | 2.0.14 | 2.0.15 |\n| opencode-ai | 1.17.16 | 1.18.34 |\n| vitest | 4.1.10 | 5.0.3 |\n| chezmoi (repo `.mise.toml`, read by the template) | 2.72.2 | 2.73.0 |\n\nThe in-place bump wrote ocx's `allow_low_downloads` as the string\n`\"true\"`. The template keeps the boolean.\n\nVerified: `chezmoi --source <worktree> diff ~/.config/mise/config.toml`\nnow shows only the chezmoi pin, comment alignment, and the ocx boolean.\n`tests/test-ci-pins.sh` passes.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01HHJxZ7gHUWusPaUpZ81xXn\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-06T08:29:57+03:00",
          "tree_id": "9d662587f786f3f6b54950788603bbd2dfb3359b",
          "url": "https://github.com/laurigates/dotfiles/commit/ac8c2981ce8f7d9601d854a65887a288272df570"
        },
        "date": 1791264654768,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.00805416902,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0013448087400000004,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0010613497400000001,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.00954113302,
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
          "id": "ec3ed89c5fc6f19eda430491a42b6f98869d1687",
          "message": "docs(claude): route code-triggered follow-ups to a tripwire test (#470)\n\nAdds an exception to the Git Workflow rule in\n`exact_dot_claude/CLAUDE.md`. A post-merge follow-up that waits on a\ncondition visible in the source (a list outgrowing a limit, an enum\ngaining a member, a version bump) goes in the same PR as a tripwire\ntest, not as a GitHub issue.\n\nWithout it, the global rule keeps sending those follow-ups to issues and\noverrides the skill routing added in laurigates/claude-plugins#2911\n(`testing-plugin:test-tripwire`, plus the `session-wrap`, `git-issue`\nand `git-triage` rows).\n\nThe pre-commit suite passes, including the global context budget check.\nThe change adds one line.\n\nAfter merge, `chezmoi apply ~/.claude/CLAUDE.md` installs it.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01CpsxEu51MKyvB5otaHs1mr\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-06T12:55:27+03:00",
          "tree_id": "4c0e63204ac7feab2e1406355fb794678fccbeda",
          "url": "https://github.com/laurigates/dotfiles/commit/ec3ed89c5fc6f19eda430491a42b6f98869d1687"
        },
        "date": 1791280571821,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.007331854233333334,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.00118312152,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.00093359392,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.009208145380000001,
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
          "id": "8aad5eb7913b51a8b63b21bdee15a62eeabb70b4",
          "message": "docs(claude): reduce promoted-rule stubs to their triggers (#471)\n\nReduces 21 `exact_dot_claude/rules/*.md` \"Promoted to a skill\" stubs to\nthe skill name and when to invoke it.\n\n## Why\n\nEach stub carried a hand-written list of what its skill contains (\"it\ncarries the …\", \"it diagnoses the three …\"), and nothing kept those\nlists in step with the skills. The `pr-merge-hazards.md` list had\nalready drifted. It never mentioned the skill's §4 or §5, and it missed\n§6 (serial merge chains, laurigates/claude-plugins#2957) the day that\nsection was added. Two other stubs stated counts (\"four categories\",\n\"three silent layers\") that would drift the same way. The skills' own\nheadings are now the only list of their contents.\n\n## Kept on purpose\n\n- **`pr-merge-hazards.md`:** the two inline gates (merged-ness authority\norder, merge over red). You read them while making the merge decision,\nand the skill notes the two copies must be edited together.\n- **`taskwarrior-tracking.md`:** the `project:` prefix-match fact. You\nneed it at the moment of filing, so it stays inline as its own sentence;\nonly the inventory around it went.\n- **`multi-model-delegation.md`:** \"it sets `user-invocable: false`\",\nwhich explains how the skill loads.\n- **`zsh-gotchas.md`:** the symptom table, which is how you know to\nreach for the skill. Only its lead-in lost the \"all four mechanisms\"\ncount.\n- **`tool-use-patterns.md`:** maps moments to skills, which is trigger\nrouting.\n- **`tui-markdown-rendering.md`:** \"it carries two behaviors\" is\nordinary prose, not a skill inventory. Unchanged.\n\n## Checks\n\n| Test | Result |\n|---|---|\n| `bash tests/test-claude-context-budget.sh` | `PASS=4 FAIL=0\nSTATUS=PASS` |\n| `bash tests/test-claude-plugin-references.sh` | all plugin-reference\nchecks passed |\n| `bash tests/test-claude-runtime-ignored.sh` | PASS |\n\n- No `it carries` / `carries the` skill inventory remains under\n`exact_dot_claude/rules/`.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01EdVb2NcqENVQXagb1qBNjE\n\n---------\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-08T13:05:06+03:00",
          "tree_id": "96897c9cbc4c49b691261eab929e2c917f3f8d66",
          "url": "https://github.com/laurigates/dotfiles/commit/8aad5eb7913b51a8b63b21bdee15a62eeabb70b4"
        },
        "date": 1791453972018,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0,
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
          "id": "da882153c4812171bbe32d31bcc2126dc286422d",
          "message": "feat(zsh): add completion for ImageMagick's magick command (#472)\n\nAdds `dot_zfunc/_magick`, a zsh completer for ImageMagick 7's `magick`.\n\nImageMagick has no completion generator, so this can't be a line in\n`.chezmoidata/completions.toml`. zsh's bundled `_imagemagick` predates\nIM7: it registers `convert`, `identify` and the other standalone tools,\nbut not `magick`. The registry now has a comment pointing to the\nhand-written file, as it does for `just`.\n\nThe completer reads the installed binary:\n\n- **Option names, descriptions and argument names:** parsed from `magick\n-help`, or from `magick <tool> -help` after a tool word (`identify`,\n`mogrify`, …). The result is cached for the rest of the shell session.\n- **Argument values:** come from `magick -list <type>` at TAB time. That\ncovers colorspace, filter, gravity, compose, colour names, `-limit`\nresources, `-ordered-dither` threshold maps, and so on.\n- **Not covered:** `+option` forms, since `-help` doesn't list them.\n\nChanging `completions.toml` (a comment only) changes the hash\n`run_onchange_02-generate-completions` watches, so the next full apply\nregenerates all completions once.\n\n## Testing\n\nA zpty harness (kept out of the commit) drove an interactive `zsh -f`\nwith this file on `fpath` and pressed TAB on 12 cases, with `echo $HOM`\nas a control.\n\n- **Results:** the control and all 11 `magick` cases complete correctly.\nThat includes `-colorspace sR` → `sRGB`, `-fill AliceB` → `AliceBlue`,\n`-limit me` → `memory`, `-ordered-dither o2` → `o2x2`, `magick identify\n-verb` → `-verbose`, and `magick mogrify -filter Lanc` → `Lanczos`.\n- **Lint:** `mise run lint` passes except `lint:lua`, which fails\nbecause the local luacheck 1.2.0 crashes on Lua 5.5. That's unrelated to\nthis change. gitleaks finds no leaks.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01E9JvWFK9DB8B1G3ubHrqrq\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-09T07:54:41+03:00",
          "tree_id": "a1c4a404477ab371534f35b830bbcc5dc84f26c7",
          "url": "https://github.com/laurigates/dotfiles/commit/da882153c4812171bbe32d31bcc2126dc286422d"
        },
        "date": 1791521746768,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0,
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
          "id": "32424172c925267c00b28bfe220fdc4f48379497",
          "message": "fix(zsh): pull the base branch after ghsq/ghrb merges a PR into it (#473)\n\n## What\n\n`ghsq`/`ghrb` now `git pull --ff-only` when you run them from the base\nbranch of a PR they just merged, e.g. merging from the main checkout on\n`main` while the PR's branch lives in a worktree.\n\n## Why\n\nThe post-merge step `_gh_home_if_merged` only acted when the *current*\nbranch had a merged PR. On `main`, `gh pr view` reports `no pull\nrequests found for branch \"main\"`, so the helper returned before pulling\nand `main` stayed behind origin (observed after merging #472).\n\n## How\n\n`_gh_home_if_merged` falls back to a new `_gh_pull_if_base_of_merged`\nwhen the current branch has no merged PR. It checks each PR number the\nrun acted on (`gh pr view <n> --json state,baseRefName`) and pulls if\none is `MERGED` into the current branch, printing the same what/why\nlines as the existing go-home path. Selected-but-skipped PRs are still\nopen, so they never trigger a pull. The help text for `ghsq` and the\ncomment above it describe the new case.\n\n## Verification\n\n- Scratch test (not committed): the two helpers extracted from the\nsource with `sed`, `gh` stubbed, run in a temp repo whose `main` is one\ncommit behind origin. Acted PR not merged: stays behind=1. PR merged\ninto `main`: fast-forwards to behind=0 with the what/why output.\n- `zsh -n` on the rendered template: exit 0.\n- `mise run lint`: shell, actions and docs tasks pass; `lint:lua` fails\non a local luacheck 1.2.0 / Lua 5.5 crash unrelated to this change.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01TGefgXKy2wVF1V5jdSxBGk\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-09T10:30:14+03:00",
          "tree_id": "0dec20795fab09001ad73cfdb843d06c2498f904",
          "url": "https://github.com/laurigates/dotfiles/commit/32424172c925267c00b28bfe220fdc4f48379497"
        },
        "date": 1791531073108,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0,
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
          "id": "9c12ee731cbe9b4523eb17723a45e9e9086be7fc",
          "message": "feat(just): add worktree-audit recipe for stray and merged worktrees (#475)\n\nAdds `worktree-audit` to `git.just`, next to `branch-audit`, so `just -g\nworktree-audit [root]` lists which linked worktrees can be removed. With\nno argument it audits the current repo; with a directory it audits every\nrepo up to three levels below it.\n\nIt is read-only, like `branch-audit`: it prints `git worktree remove` /\n`git worktree prune` commands and runs nothing.\n\n**Columns**\n- `LOC=stray`: the worktree is outside `<repo>/.claude/worktrees/`. This\nis the `git worktree add ../<name>` pattern that left 41 worktrees next\nto their repos under `~/repos`.\n- `VERDICT`, first match wins:\n  - `PRUNE`: the directory is gone.\n  - `IN-USE`: a running process has its cwd inside it (`lsof`).\n  - `DIRTY`: uncommitted or untracked files.\n- `MERGED`: one of `branch-audit`'s signals, or a commit-to-PR lookup\n(`repos/{nwo}/commits/{sha}/pulls`) that finds the PR for a detached\nworkflow or agent worktree.\n- `REVIEW`: none of the above. This includes a merged PR whose worktree\nhas local commits past the PR head.\n\n**Tested** on `just -g worktree-audit ~/repos`, exit 0: 184 MERGED, 7\nDIRTY, 2 IN-USE, 4 REVIEW, 6 PRUNE. Spot-checked against `gh` while\nbuilding it:\n- `claude-plugins-lean-reader` and `-sedview` show as MERGED; #3047 and\n#3072 merged in the last hour.\n- Three detached mcu-tinkering-lab worktrees that previously showed as\nREVIEW resolve to merged PRs #630, #672 and #620.\n\nThe recipe body passes `shellcheck`. Pre-commit passes, including the\njustfile parse check and the context-budget check.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01SRgcMKH9btxScDXZPxczY1\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-13T10:38:02+03:00",
          "tree_id": "46218f4d96abf04b446f43b5f802cc392077619d",
          "url": "https://github.com/laurigates/dotfiles/commit/9c12ee731cbe9b4523eb17723a45e9e9086be7fc"
        },
        "date": 1791877139352,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "028c1356fb75229b277b46de6992c9db496fded6",
          "message": "chore(deps): update GitHub Actions (#474)\n\nThis PR contains the following updates:\n\n| Package | Type | Update | Change |\n|---|---|---|---|\n| [actions/setup-node](https://redirect.github.com/actions/setup-node) |\naction | minor | `v7.0.0` → `v7.1.0` |\n|\n[actions/upload-artifact](https://redirect.github.com/actions/upload-artifact)\n| action | patch | `v7.0.1` → `v7.0.2` |\n|\n[anthropics/claude-code-action](https://redirect.github.com/anthropics/claude-code-action)\n| action | patch | `v1.0.240` → `v1.0.248` |\n| [laurigates/.github](https://redirect.github.com/laurigates/.github)\n([changelog](https://redirect.github.com/laurigates/.github/compare/6b009f6e3a319852d3efcb4794bdaaa3c5a6772c..aad403be1e3d72f68f6536f212ed3a0339263d22))\n| action | digest | `6b009f6` → `aad403b` |\n\n---\n\n> [!WARNING]\n> Some dependencies could not be looked up. Check the [Dependency\nDashboard](../issues/379) for more information.\n\n---\n\n### Release Notes\n\n<details>\n<summary>actions/setup-node (actions/setup-node)</summary>\n\n###\n[`v7.1.0`](https://redirect.github.com/actions/setup-node/releases/tag/v7.1.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-node/compare/v7...v7.1.0)\n\n##### What's Changed\n\n##### Enhancements:\n\n- Add support for mise.toml file by\n[@&#8203;gperdomor](https://redirect.github.com/gperdomor) in\n[#&#8203;1421](https://redirect.github.com/actions/setup-node/pull/1421)\n- Support absolute paths in node-version-file by\n[@&#8203;v-mahabaleshwars](https://redirect.github.com/v-mahabaleshwars)\nin\n[#&#8203;1633](https://redirect.github.com/actions/setup-node/pull/1633)\n\n##### Bug fixes:\n\n- Add Node version validation and manifest fetch retry by\n[@&#8203;v-jitenderpalsingh](https://redirect.github.com/v-jitenderpalsingh)\nin\n[#&#8203;1580](https://redirect.github.com/actions/setup-node/pull/1580)\n\n##### Documentation updates:\n\n- README.md: bump actions/checkout to latest version 7 by\n[@&#8203;deining](https://redirect.github.com/deining) in\n[#&#8203;1578](https://redirect.github.com/actions/setup-node/pull/1578)\n- docs: add V7 ESM migration and NODE\\_AUTH\\_TOKEN behavior change by\n[@&#8203;v-gowridurgad](https://redirect.github.com/v-gowridurgad) in\n[#&#8203;1593](https://redirect.github.com/actions/setup-node/pull/1593)\n- Fixed cache recommendation syntax by\n[@&#8203;SubJunk](https://redirect.github.com/SubJunk) in\n[#&#8203;1603](https://redirect.github.com/actions/setup-node/pull/1603)\n\n##### Dependency updates:\n\n- Update workflow pins and migrate Node matrices to modern versions by\n[@&#8203;v-HarithaVattikuti](https://redirect.github.com/v-HarithaVattikuti)\nin\n[#&#8203;1583](https://redirect.github.com/actions/setup-node/pull/1583)\n- Upgrade\n[@&#8203;actions/cache](https://redirect.github.com/actions/cache) to\n6.2.0 by [@&#8203;philip-gai](https://redirect.github.com/philip-gai) in\n[#&#8203;1584](https://redirect.github.com/actions/setup-node/pull/1584)\n- Pin [@&#8203;types/node](https://redirect.github.com/types/node) to\nv24 by\n[@&#8203;v-priyagupta108](https://redirect.github.com/v-priyagupta108)\nin\n[#&#8203;1585](https://redirect.github.com/actions/setup-node/pull/1585)\n- Override brace-expansion to 5.0.8 by\n[@&#8203;v-priyagupta108](https://redirect.github.com/v-priyagupta108)\nwith [@&#8203;Copilot](https://redirect.github.com/Copilot) in\n[#&#8203;1599](https://redirect.github.com/actions/setup-node/pull/1599)\n- Upgrade actions/checkout from 7.0.0 to 7.0.1 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1598](https://redirect.github.com/actions/setup-node/pull/1598)\n- Upgrade prettier from 3.8.4 to 3.9.6 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1590](https://redirect.github.com/actions/setup-node/pull/1590)\n- Upgrade [@&#8203;vercel/ncc](https://redirect.github.com/vercel/ncc)\nfrom 0.44.0 to 0.45.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1610](https://redirect.github.com/actions/setup-node/pull/1610)\n- Upgrade pnpm/action-setup from 6.0.9 to 6.0.10 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1602](https://redirect.github.com/actions/setup-node/pull/1602)\n- Upgrade baseline-browser-mapping from 2.10.38 to 2.11.22 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1629](https://redirect.github.com/actions/setup-node/pull/1629)\n- Upgrade\n[@&#8203;types/semver](https://redirect.github.com/types/semver) from\n7.7.1 to 7.8.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1616](https://redirect.github.com/actions/setup-node/pull/1616)\n- Upgrade\n[@&#8203;typescript-eslint/parser](https://redirect.github.com/typescript-eslint/parser)\nfrom 8.62.0 to 8.70.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1615](https://redirect.github.com/actions/setup-node/pull/1615)\n- Upgrade pnpm/action-setup from 6.0.10 to 6.1.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1631](https://redirect.github.com/actions/setup-node/pull/1631)\n- Upgrade jest-each from 30.4.1 to 30.5.2 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1636](https://redirect.github.com/actions/setup-node/pull/1636)\n- Upgrade eslint-plugin-n from 18.1.0 to 18.3.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1638](https://redirect.github.com/actions/setup-node/pull/1638)\n- Update dependencies and add license files by\n[@&#8203;v-HarithaVattikuti](https://redirect.github.com/v-HarithaVattikuti)\nin\n[#&#8203;1642](https://redirect.github.com/actions/setup-node/pull/1642)\n- Upgrade eslint from 10.5.0 to 10.11.0 and package.json from 7.0.0 to\n7.1.0 by [@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1635](https://redirect.github.com/actions/setup-node/pull/1635)\n\n##### New Contributors\n\n-\n[@&#8203;v-jitenderpalsingh](https://redirect.github.com/v-jitenderpalsingh)\nmade their first contribution in\n[#&#8203;1580](https://redirect.github.com/actions/setup-node/pull/1580)\n- [@&#8203;philip-gai](https://redirect.github.com/philip-gai) made\ntheir first contribution in\n[#&#8203;1584](https://redirect.github.com/actions/setup-node/pull/1584)\n- [@&#8203;gperdomor](https://redirect.github.com/gperdomor) made their\nfirst contribution in\n[#&#8203;1421](https://redirect.github.com/actions/setup-node/pull/1421)\n- [@&#8203;SubJunk](https://redirect.github.com/SubJunk) made their\nfirst contribution in\n[#&#8203;1603](https://redirect.github.com/actions/setup-node/pull/1603)\n\n**Full Changelog**:\n<https://github.com/actions/setup-node/compare/v7.0.0...v7.1.0>\n\n</details>\n\n<details>\n<summary>actions/upload-artifact (actions/upload-artifact)</summary>\n\n###\n[`v7.0.2`](https://redirect.github.com/actions/upload-artifact/releases/tag/v7.0.2)\n\n[Compare\nSource](https://redirect.github.com/actions/upload-artifact/compare/v7.0.1...v7.0.2)\n\n##### What's Changed\n\n- Improves artifact download retries when the service returns HTTP 429\n(rate limiting), including honoring valid Retry-After headers.\n- Updates\n[@&#8203;actions/artifact](https://redirect.github.com/actions/artifact)\nto v6.3.1.\n\n##### New Contributors\n\n- [@&#8203;tunc-d](https://redirect.github.com/tunc-d) made their first\ncontribution in\n[#&#8203;821](https://redirect.github.com/actions/upload-artifact/pull/821)\n\n**Full Changelog**:\n<https://github.com/actions/upload-artifact/compare/v7.0.1...v7.0.2>\n\n</details>\n\n<details>\n<summary>anthropics/claude-code-action\n(anthropics/claude-code-action)</summary>\n\n###\n[`v1.0.248`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.248)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.247...v1.0.248)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.247...v1.0.248>\n\n###\n[`v1.0.247`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.247)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.246...v1.0.247)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.246...v1.0.247>\n\n###\n[`v1.0.246`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.246)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.245...v1.0.246)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.245...v1.0.246>\n\n###\n[`v1.0.245`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.245)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.244...v1.0.245)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.244...v1.0.245>\n\n###\n[`v1.0.244`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.244)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.243...v1.0.244)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.243...v1.0.244>\n\n###\n[`v1.0.243`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.243)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.242...v1.0.243)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.242...v1.0.243>\n\n###\n[`v1.0.242`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.242)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.241...v1.0.242)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.241...v1.0.242>\n\n###\n[`v1.0.241`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.241)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.240...v1.0.241)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.240...v1.0.241>\n\n</details>\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-10-13T09:25:38Z",
          "tree_id": "84201cc2a90a8bff4735e734459092fbff949f13",
          "url": "https://github.com/laurigates/dotfiles/commit/028c1356fb75229b277b46de6992c9db496fded6"
        },
        "date": 1791883598067,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0,
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
          "id": "ac14a33a9b3aefc2bf8711ea36e83fc285de93b9",
          "message": "fix(just): worktree-audit read gh's error body as a merged PR number (#476)\n\nFollow-up to #475. `worktree-audit` reported two worktrees as MERGED\nthat aren't: `claude-plugins-model-map` (open PR #3064, 1 commit not\npushed) and `pal-mcp-server/.claude/worktrees/dogfood`. When the\ncommit-to-PR lookup fails with HTTP 422 (the commit was never pushed),\n`gh api` exits 1 but still prints the JSON error body to stdout. The\nrecipe's `|| true` kept that body, and the non-empty check took it as a\nPR number.\n\nThe fix clears the variable when the call fails and accepts only a bare\nPR number.\n\n**Verified:** both worktrees now show as REVIEW. A control call on the\nmodel-map HEAD reproduces the 422 body on stdout with exit 1. The recipe\nbody passes shellcheck.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01SRgcMKH9btxScDXZPxczY1\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-13T16:26:51+03:00",
          "tree_id": "9805919320586ab423c8a75cb790e1f1fb0656ff",
          "url": "https://github.com/laurigates/dotfiles/commit/ac14a33a9b3aefc2bf8711ea36e83fc285de93b9"
        },
        "date": 1791898066562,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0,
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
          "id": "f4a9976fdf4dcdac6955e124718ad85b64e1d2dd",
          "message": "docs(claude): list the disk-reclaim recipes among the just -g examples (#478)\n\n## What\n\nAdds `reclaim-dry`/`reclaim` and `ollama-idle`/`ollama-prune` to the\nexample list in the global `CLAUDE.md` paragraph that points agents at\n`just -g` recipes.\n\n## Why\n\nIn a disk-full session the agent followed the public `macos-disk-usage`\nskill and hand-rolled cache, worktree and model cleanup; the existing\nrecipes were never consulted because the example list named no disk\nrecipes. The skill lives in the public claude-plugins marketplace and\ncannot reference these personal recipes, so the pointer belongs here.\nCompanion to #477, which fixes the uv and bun purges inside\n`reclaim.sh`.\n\nOne line in an always-loaded file; the global context budget pre-commit\ncheck passes.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01QrFmip3RSwzwi61bhj5Pdz\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-13T16:27:12+03:00",
          "tree_id": "d3ffada25330259ef13501939facc0b08f753c31",
          "url": "https://github.com/laurigates/dotfiles/commit/f4a9976fdf4dcdac6955e124718ad85b64e1d2dd"
        },
        "date": 1791898129381,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0,
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
          "id": "eb4d38f5087987c1d79ed116d9ac00ec21741157",
          "message": "feat(zsh): update and re-test PRs mid-batch in ghsq/ghrb/ghrp (#480)\n\n## What\n\nThe shared batch-merge engine behind `ghsq`, `ghrb` and `ghrp` does two\nnew things:\n\n- **Update and re-test.** If the batch has already merged into a PR's\nbase this run, the engine runs `gh pr update-branch` on the PR\n(`--rebase` for `ghrb`) and waits for CI on the new head with `gh pr\nchecks --watch --fail-fast`. It then merges with `--match-head-commit`\nset to the head that passed. If CI fails, the PR is left open.\n- **Hand conflicts to Claude.** CONFLICTING PRs are collected and left\nopen. After the batch ends, the engine asks about each one in turn and,\non `y`, starts `claude --worktree` with a prompt to resolve it, run lint\nand tests, and push without merging. The handoff only runs once every\nmerge is done, so Claude resolves against the final base. PRs from a\nrepo other than the current checkout get a note instead of a handoff.\n\n## Why\n\nBefore a batch, each PR's green CI ran against the base as it was then.\nOnce an earlier PR in the batch merges, a later PR can still merge\ncleanly and break the base. Updating the branch and re-running CI\ncatches that. Each PR updated this way costs one CI wait.\n\n`gh pr update-branch` can't resolve a real conflict: gh refuses when\nGitHub reports CONFLICTING (`update_branch.go`). Those PRs need someone\nto resolve them, so they go to Claude instead of being skipped.\n\n## Notes\n\n- Only PRs whose base took a merge **in this run** are updated. A PR\nthat was already behind its base before the run merges as before.\n- `gh pr checks --watch` exits at once if no check is registered yet\n(`checks.go`: \"no checks reported\"). The engine therefore waits up to\n60s for the first check to appear. If none does, it merges without\nwaiting.\n- Tested against a stubbed `gh` in a pty: squash and rebase paths, the\nCI-failure path, and the conflict handoff with both `y` and `n`. It has\nnot yet been run against real PRs.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_014VQuCxyigibinKgmfkBfv2\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-17T08:19:52+03:00",
          "tree_id": "48ae91ba71ee99697116cb109b856bb1638dafaf",
          "url": "https://github.com/laurigates/dotfiles/commit/eb4d38f5087987c1d79ed116d9ac00ec21741157"
        },
        "date": 1792214448456,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0,
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
          "id": "7dee23bbbaab8743a92d935510b965f8861c0f93",
          "message": "docs(claude): record a Sonnet implement-and-verify run in model-selection evidence (#479)\n\nAdds one evidence entry to\n`exact_dot_claude/rules/agent-and-tool-selection.md` (Model Selection →\nEvidence).\n\nThe existing Sonnet evidence ends on a task that held on every claim. In\nlaurigates/claude-plugins#3088–#3090, three Sonnet 5.5 implementers at\n`high` effort were each followed by a fresh Sonnet verifier. A verifier\ncaught a new helper that reported an unrunnable gate (exit 127) as a\ncaught mutation. One implementer follow-up put a hook's timeout headroom\nat about 1 s, when the worst case overran the 5 s budget by about 3 s;\nthe main loop found it while checking before filing\n(laurigates/claude-plugins#3093). The run had no Opus arm and was not\ngraded.\n\nThe always-loaded total is 50,986 bytes against a 78,400-byte budget\n(`tests/test-claude-context-budget.sh`).\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01CmJH662ikgdowBiW8126A4\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-17T16:45:55+03:00",
          "tree_id": "2034603bb7cddf89ca192d766394f1d6125495f0",
          "url": "https://github.com/laurigates/dotfiles/commit/7dee23bbbaab8743a92d935510b965f8861c0f93"
        },
        "date": 1792244805200,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "e4e80f9e4dfe92e609dd93e57141d3a279edb721",
          "message": "chore(deps): update chezmoi to v2.73.1 (#482)\n\nThis PR contains the following updates:\n\n| Package | Type | Update | Change |\n|---|---|---|---|\n| [chezmoi](https://redirect.github.com/twpayne/chezmoi) | tools | patch\n| `2.73.0` → `2.73.1` |\n\n---\n\n> [!WARNING]\n> Some dependencies could not be looked up. Check the [Dependency\nDashboard](../issues/379) for more information.\n\n---\n\n### Release Notes\n\n<details>\n<summary>twpayne/chezmoi (chezmoi)</summary>\n\n###\n[`v2.73.1`](https://redirect.github.com/twpayne/chezmoi/releases/tag/v2.73.1)\n\n[Compare\nSource](https://redirect.github.com/twpayne/chezmoi/compare/v2.73.0...v2.73.1)\n\n#### Changelog\n\n##### Fixes\n\n-\n[`41a618c`](https://redirect.github.com/twpayne/chezmoi/commit/41a618c046fc5f7bb47cfebcd485d022c9ed5eb8)\nfix: Don't double backslashes in shellQuote\n-\n[`c6778d6`](https://redirect.github.com/twpayne/chezmoi/commit/c6778d6771766daba702848b5a0f9b31bbbafa82)\nfix: Pass /dev/null to diff command for missing files in apply\n--interactive\n-\n[`6933f78`](https://redirect.github.com/twpayne/chezmoi/commit/6933f7858b0855f997d8b0c9d5c5218d44ea7911)\nfix: Fix panic in add when adding file in external\\_ explicit dir\n-\n[`2abb5f7`](https://redirect.github.com/twpayne/chezmoi/commit/2abb5f7d684166ec7110ca944aa2f0acb32b860e)\nfix: Fix panic in re-add with exact\\_ dirs with implicit parents\n-\n[`3cd47c5`](https://redirect.github.com/twpayne/chezmoi/commit/3cd47c524444ffa16038f18a7190b781f29ca5e6)\nfix: Fix panic in re-add with externals with implicit parents\n-\n[`56ef8a3`](https://redirect.github.com/twpayne/chezmoi/commit/56ef8a372e53e5cf5832ed8e867798fd3b7758b9)\nfix: Report correct line number for secrets found by add\n\n##### Documentation\n\n-\n[`7cd56b9`](https://redirect.github.com/twpayne/chezmoi/commit/7cd56b9caf96cd1606e860532a692ea0dbf10924)\ndocs: State that re-add command does not cover externals\n-\n[`544cb5b`](https://redirect.github.com/twpayne/chezmoi/commit/544cb5b4ef63080980c411191214e21161e2265d)\ndocs: Add link to article\n\n</details>\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-10-17T16:46:23+03:00",
          "tree_id": "1b4d8bfe0abd611a18cbeedcf47eaf4fd0a18d7b",
          "url": "https://github.com/laurigates/dotfiles/commit/e4e80f9e4dfe92e609dd93e57141d3a279edb721"
        },
        "date": 1792244855684,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "noreply@anthropic.com",
            "name": "Claude",
            "username": "claude"
          },
          "committer": {
            "email": "lauri.gates@gmail.com",
            "name": "Lauri Gates",
            "username": "laurigates"
          },
          "distinct": true,
          "id": "a2924a5a1e43d7cff4cfa2ae41b8ff7a64e4e0c4",
          "message": "test(mise): run the root-meta and organize-stars tests in `mise run test`\n\n#442 and #443 added test:chezmoi-root-meta and test:organize-stars but left\n[tasks.test].depends to the #439 change, whose wiring check in\ntests/test-mise-tasks.sh fails for a test:* task missing from it. Add both to\ndepends and to REPO_TASKS, and bring the test:ci-pins description and the\nci-pins hook comment up to the pins #440 added.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\nClaude-Session: https://claude.ai/code/session_0139fxxuAJxarrymWrUYf4QL",
          "timestamp": "2026-10-17T20:23:52+03:00",
          "tree_id": "7c5b7e59c2f28f2875c2bdacb7ca6f19645e7d9a",
          "url": "https://github.com/laurigates/dotfiles/commit/a2924a5a1e43d7cff4cfa2ae41b8ff7a64e4e0c4"
        },
        "date": 1792257885506,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.12026963966666666,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015925016,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013253684000000003,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0113076956,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "b85ea3802eaae26c3bbdaf9850447d492352fdac",
          "message": "chore(deps): update pre-commit hook JohnnyMorganz/StyLua to v2.6.0 (#484)\n\nThis PR contains the following updates:\n\n| Package | Type | Update | Change |\n|---|---|---|---|\n|\n[JohnnyMorganz/StyLua](https://redirect.github.com/JohnnyMorganz/StyLua)\n| repository | minor | `v2.5.2` → `v2.6.0` |\n\nNote: The `pre-commit` manager in Renovate is not supported by the\n`pre-commit` maintainers or community. Please do not report any problems\nthere, instead [create a Discussion in the Renovate\nrepository](https://redirect.github.com/renovatebot/renovate/discussions/new)\nif you have any questions.\n\n---\n\n### Release Notes\n\n<details>\n<summary>JohnnyMorganz/StyLua (JohnnyMorganz/StyLua)</summary>\n\n###\n[`v2.6.0`](https://redirect.github.com/JohnnyMorganz/StyLua/releases/tag/v2.6.0)\n\n[Compare\nSource](https://redirect.github.com/JohnnyMorganz/StyLua/compare/v2.5.2-input.2...v2.6.0)\n\n#### \\[2.6.0] - 2026-10-10\n\n##### Added\n\n- Luau: Added support for `if local` / `if const` condition bindings in\nboth `if` statements and `if` expressions (e.g. `if local x = getValue()\nthen ... end`)\n- Added `Input` mode for `collapse_simple_statement`, preserving whether\nsimple statements are single-line or multi-line in the input while still\nformatting their contents\n([#&#8203;1112](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1112))\n\n##### Fixed\n\n- Fixed range formatting indenting statements one level too shallow when\nnested inside a function expression within a table constructor\n([#&#8203;1145](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1145))\n- Fixed `-- stylua: ignore start`/`end` ranges inside multiline tables\nreformatting the ignored fields\n([#&#8203;1134](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1134))\n- When using range formatting, semicolons outside of the provided range\nare no longer incorrectly formatted\n([#&#8203;1147](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1147))\n- Luau: Fixed sort requires not recognizing imports declared with\n`const`, e.g. `const Foo = require(path)`\n- Luau: Fixed the `read`/`write` access modifier merging into the\nelement type in array type shorthand, changing the meaning of the code\n(`{ read Foo }` was formatted as `{ readFoo }`)\n([#&#8203;1126](https://redirect.github.com/JohnnyMorganz/StyLua/issues/1126))\n- Fixed single-line comments in CRLF files gaining an extra carriage\nreturn (`\\r\\r\\n`) on every format when `line_endings = \"Windows\"`, and\nkeeping their original `\\r\\n` when formatting to Unix line endings\n([#&#8203;1167](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1167))\n\n***\n\n#### External Contributions\n\n- Mention conform.nvim as a Neovim formatter plugin that supports stylua\nby [@&#8203;alerque](https://redirect.github.com/alerque) in\n[#&#8203;1124](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1124)\n- Clarify the syntax for command-line formatting configuration by\n[@&#8203;kormide](https://redirect.github.com/kormide) in\n[#&#8203;1132](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1132)\n- Fix sort\\_requires not recognizing `const` imports in luau by\n[@&#8203;ddashdev](https://redirect.github.com/ddashdev) in\n[#&#8203;1123](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1123)\n- Fix Luau array access modifier formatting by\n[@&#8203;Companion](https://redirect.github.com/Companion) in\n[#&#8203;1148](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1148)\n- Keep out-of-range semicolons when formatting a range by\n[@&#8203;GhostCoder6969](https://redirect.github.com/GhostCoder6969) in\n[#&#8203;1158](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1158)\n- support if-local and if-const by\n[@&#8203;annieetang](https://redirect.github.com/annieetang) in\n[#&#8203;1160](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1160)\n- Add Input mode for collapse\\_simple\\_statement by\n[@&#8203;ddashdev](https://redirect.github.com/ddashdev) in\n[#&#8203;1112](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1112)\n\n#### New Contributors\n\n- [@&#8203;kormide](https://redirect.github.com/kormide) made their\nfirst contribution in\n[#&#8203;1132](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1132)\n- [@&#8203;ddashdev](https://redirect.github.com/ddashdev) made their\nfirst contribution in\n[#&#8203;1123](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1123)\n- [@&#8203;Companion](https://redirect.github.com/Companion) made their\nfirst contribution in\n[#&#8203;1148](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1148)\n- [@&#8203;GhostCoder6969](https://redirect.github.com/GhostCoder6969)\nmade their first contribution in\n[#&#8203;1158](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1158)\n- [@&#8203;annieetang](https://redirect.github.com/annieetang) made\ntheir first contribution in\n[#&#8203;1160](https://redirect.github.com/JohnnyMorganz/StyLua/pull/1160)\n\n**Full Changelog**:\n<https://github.com/JohnnyMorganz/StyLua/compare/v2.5.2...v2.6.0>\n\n</details>\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-10-18T17:21:17Z",
          "tree_id": "8465edd0c7038c37055e4bf92dbc53a91c9f44f7",
          "url": "https://github.com/laurigates/dotfiles/commit/b85ea3802eaae26c3bbdaf9850447d492352fdac"
        },
        "date": 1792344132112,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.11300049066666668,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015482812,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012897768000000001,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0129148814,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "252d497889864231e5184a86a65b67364a723cec",
          "message": "chore(deps): update GitHub Actions (#485)\n\nThis PR contains the following updates:\n\n| Package | Type | Update | Change | Pending |\n|---|---|---|---|---|\n| [Homebrew/actions](https://redirect.github.com/Homebrew/actions) | |\nminor | `2026.09.21.1` → `2026.10.12.1` | |\n|\n[anthropics/claude-code-action](https://redirect.github.com/anthropics/claude-code-action)\n| action | patch | `v1.0.249` → `v1.0.250` | `v1.0.252` (+1) |\n\n---\n\n### Release Notes\n\n<details>\n<summary>Homebrew/actions (Homebrew/actions)</summary>\n\n###\n[`v2026.10.12.1`](https://redirect.github.com/Homebrew/actions/releases/tag/2026.10.12.1)\n\n[Compare\nSource](https://redirect.github.com/Homebrew/actions/compare/2026.09.28.1...2026.10.12.1)\n\n##### What's Changed\n\n- build(deps): bump the github-actions group across 1 directory with 2\nupdates by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;944](https://redirect.github.com/Homebrew/actions/pull/944)\n- build(deps-dev): bump\n[@&#8203;types/node](https://redirect.github.com/types/node) from\n24.13.5 to 24.13.6 in the npm group by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;943](https://redirect.github.com/Homebrew/actions/pull/943)\n- setup-ruby: drop `brew ruby` from input description by\n[@&#8203;p-linnane](https://redirect.github.com/p-linnane) in\n[#&#8203;945](https://redirect.github.com/Homebrew/actions/pull/945)\n- Synchronize shared configuration by\n[@&#8203;BrewTestBot](https://redirect.github.com/BrewTestBot) in\n[#&#8203;946](https://redirect.github.com/Homebrew/actions/pull/946)\n- build(deps): bump the npm group with 3 updates by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;947](https://redirect.github.com/Homebrew/actions/pull/947)\n- Suppress developer mode warnings by\n[@&#8203;p-linnane](https://redirect.github.com/p-linnane) in\n[#&#8203;948](https://redirect.github.com/Homebrew/actions/pull/948)\n\n**Full Changelog**:\n<https://github.com/Homebrew/actions/compare/2026.09.28.1...2026.10.12.1>\n\n###\n[`v2026.09.28.1`](https://redirect.github.com/Homebrew/actions/releases/tag/2026.09.28.1)\n\n[Compare\nSource](https://redirect.github.com/Homebrew/actions/compare/2026.09.21.1...2026.09.28.1)\n\n##### What's Changed\n\n- build(deps): bump the npm group with 3 updates by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;940](https://redirect.github.com/Homebrew/actions/pull/940)\n- build(deps): bump the github-actions group across 1 directory with 3\nupdates by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;941](https://redirect.github.com/Homebrew/actions/pull/941)\n\n**Full Changelog**:\n<https://github.com/Homebrew/actions/compare/2026.09.21.1...2026.09.28.1>\n\n</details>\n\n<details>\n<summary>anthropics/claude-code-action\n(anthropics/claude-code-action)</summary>\n\n###\n[`v1.0.250`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.250)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.249...v1.0.250)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.249...v1.0.250>\n\n</details>\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-10-18T17:22:04Z",
          "tree_id": "b856acf4a3348e7a704e23982538bb40a19fdc42",
          "url": "https://github.com/laurigates/dotfiles/commit/252d497889864231e5184a86a65b67364a723cec"
        },
        "date": 1792344193537,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.11591618933333335,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015257726000000003,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012988898000000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0109039432,
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
          "id": "4312b06efa8215d45b2458089e7f1d16545cea9a",
          "message": "docs(claude): align Haiku guidance with Haiku 5.5 and claude-plugins tiers (#487)\n\n## What\n\nUpdates `exact_dot_claude/rules/agent-and-tool-selection.md` § Model\nSelection:\n\n- The Haiku bullet now lists the shapes claude-plugins sanctions: the\ncold-read reader, a lean read-only agent file (`omitClaudeMd: true`,\nRead/Grep/Glob only, explicit `effort:`), a mechanical workflow\n`agent()` stage with explicit effort whose output a stronger stage or\nscript checks (omission included), and `.github/workflows` use per\nworkflow after a replay. The rule that a Haiku reader's judgments are\nnever built on unchecked stays.\n- The \"When Haiku 5.5 ships\" bullet is replaced by a pointer to\nlaurigates/claude-plugins#3116 as the next re-run.\n- § Evidence gains the 2026-10-10 Haiku 5.5 audit result.\n\nThe Sonnet bullets and the cold-read exception section are unchanged.\n\n## Why\n\nHaiku 5.5 shipped on 2026-10-07 and is the `haiku` alias since Claude\nCode 2.1.293. The rule still waited for it and was narrower than\nlaurigates/claude-plugins#3117 (merged 2026-10-18), which states the\ntiers in `.claude/rules/agent-development.md` § Model Selection for\nAgents and enforces them in `scripts/check-agent-model.sh` and\n`scripts/check-workflow-js-model.sh`.\n\n## How the claims were checked\n\nEach claim in #486 was read against its source with `gh api` / `gh`:\n\n- `docs/audits/haiku-5.5-reevaluation-2026-10-10.md`: 16 Haiku 5.5\nclassifiers at `medium`; Opus confirmed 93 of 204 non-`keep` verdicts\n(46%), adjusted 38, rejected 73; all 49 control `keep` verdicts held.\nMatches.\n- One correction: #486 says the 16 classifiers were \"each checked by an\nOpus verifier\". The audit used 6 Opus 5.5 verifiers at `high`, one per\ngroup of batches. The Evidence entry follows the audit.\n- `agent-development.md` § Model Selection for Agents, the lean-reader\nshape in `check-agent-model.sh` (`lean_haiku_problems`), the haiku-stage\nrule in `check-workflow-js-model.sh`,\n`agents-plugin/agents/lean-reader.md`, and #3116 (open, Tier 2\nopus/sonnet/haiku matrix) all match the issue.\n\nFixes #486\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_018btNDJn8QVSHUwDLLkaaGK\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-19T10:27:19+03:00",
          "tree_id": "2e6749e35f7eb26f8fd8554b14ac423b8b9db7b6",
          "url": "https://github.com/laurigates/dotfiles/commit/4312b06efa8215d45b2458089e7f1d16545cea9a"
        },
        "date": 1792394888877,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.07988838433333334,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0013270472,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0010518883999999999,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.009513590800000003,
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
          "id": "68ccc36f40531d3dd08f96b22b47bc13a4d9122c",
          "message": "chore(zsh): regenerate claude CLI completion (#491)\n\n## What\nRegenerated `dot_zfunc/_claude` from the installed claude CLI.\n\n## Why\nThe CLI replaced the `project` subcommand with `purge` and extended the\n`attach` help text, so the shipped completion offered a subcommand that\nno longer exists.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_018btNDJn8QVSHUwDLLkaaGK\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-19T10:27:47+03:00",
          "tree_id": "1b16658ac1936c67689c1a523cebfe05920fcac1",
          "url": "https://github.com/laurigates/dotfiles/commit/68ccc36f40531d3dd08f96b22b47bc13a4d9122c"
        },
        "date": 1792394938315,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.077699019,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0009488798000000002,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0008544310000000001,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0072320272,
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
          "id": "7b597bbdf882ca88c1eb9cce31bf2edb0f8331f1",
          "message": "chore(claude): stop tracking ~/repos rules that repos-claude-config owns (#492)\n\n## What\nRemoves `private_repos/private_dot_claude/rules/` (four files) from the\nchezmoi source.\n\n## Why\n`ci-cd-multirepo.md`, `github-metadata-hygiene.md`, `justfile.md` and\n`tool-migration-cutover.md` were tracked byte-identically here and in\nlaurigates/repos-claude-config, which already owns the other 24 files in\n`~/repos/.claude/rules/`. With two owners, every edit had to land twice.\nSame split as #444/#490, where dotfiles kept `~/repos/CLAUDE.md`.\n\n## How\n`private_repos/` and `private_dot_claude/` are not `exact_` dirs, so\ndropping the source stops chezmoi from managing the files without\ndeleting the targets. `chezmoi status --source <worktree> ~/repos`\nreports nothing, and `chezmoi managed` now lists only `repos/CLAUDE.md`\nunder `~/repos`. No other file in this repo references the removed path\n(`git grep`). The rules are no longer published in this public repo.\n\nNo post-merge step: the targets stay on disk, owned by the\nrepos-claude-config checkout.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_018btNDJn8QVSHUwDLLkaaGK\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-19T12:40:39+03:00",
          "tree_id": "b115d4e22b32a89475736f92f166ac0b7eb968b8",
          "url": "https://github.com/laurigates/dotfiles/commit/7b597bbdf882ca88c1eb9cce31bf2edb0f8331f1"
        },
        "date": 1792402888384,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.07268001733333333,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0012412752,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0009977506,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0081966716,
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
          "id": "19516e83c7182c42b9757d7245004f90196543b4",
          "message": "chore(mise): capture pin bumps made on the target with mise upgrade --bump (#493)\n\n## What\nBumps eight exact pins in `private_dot_config/mise/config.toml.tmpl` to\nthe versions installed on one machine: opentofu 1.13.1, ketch 0.19.0,\ndotenvx 2.38.0, pi-coding-agent 1.3.0, gemini-cli 0.64.0,\n@playwright/test 1.64.1, opencode-ai 1.19.3, vitest 5.0.5.\n\n## Why\nThe bumps were made in `~/.config/mise/config.toml` with `mise upgrade\n--bump` and never reached the source. A forced `chezmoi apply` for #448\nreverted them. `mise where` confirms each of the eight versions is\ninstalled.\n\n## How\nLeft out on purpose:\n- chezmoi: rendered from `.mise.toml` (#418), so the target-side 2.73.2\nwould not hold.\n- `pi`, `ollama`, `opencode = \"latest\"`: these install second copies of\ntools the source already provides\n(`npm:@earendil-works/pi-coding-agent`, Homebrew `ollama`,\n`npm:opencode-ai`).\n\nThe rendered config parses as TOML (`tomllib`).\n\nRefs #448\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_018btNDJn8QVSHUwDLLkaaGK\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-19T12:52:21+03:00",
          "tree_id": "d488b62ff0d1dc9f75322aefa3ec03ac70b9b171",
          "url": "https://github.com/laurigates/dotfiles/commit/19516e83c7182c42b9757d7245004f90196543b4"
        },
        "date": 1792403597877,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.115671076,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015385226000000003,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013126944000000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0110896278,
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
          "id": "0e648e3a97a66cf04be719a062c18ceeb01c1bbb",
          "message": "fix(mise): track latest stable python for pipx tools (#494)\n\n`python = [\"3.11\", \"3.13\"]` made 3.11 the interpreter for every `pipx:`\ntool. mise runs `uv tool install --python\n~/.local/share/mise/installs/python/3.11/bin/python` (seen with\n`MISE_VERBOSE=1 mise install pipx:ansible@14.5.0`). ansible 14 requires\nPython >= 3.12, so `mise upgrade --global --bump` failed on\n`pipx:ansible@14.5.0`.\n\nThis replaces the list with `python = \"latest\"` (currently 3.15.0 per\n`mise latest python`). Nothing in the repo depends on 3.11.\n\nVerified: all 17 `pipx:` tools in the config install into throwaway\nPython 3.15.0 venvs. Ten resolve from wheels alone; ansible, pre-commit,\nesptool, ranger-fm, mlx-lm, jinjanator and yamllint need at least one\nsdist, which builds.\n\nAfter merge: `chezmoi apply ~/.config/mise/config.toml && mise install`.\nmise then rebuilds the pipx tools on 3.15.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01MTzgWGbUpTi14YdCkV6kas\n\n---------\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-19T15:31:27+03:00",
          "tree_id": "4a77891c80ac69cf81b5e48d2e76c6a39c70506c",
          "url": "https://github.com/laurigates/dotfiles/commit/0e648e3a97a66cf04be719a062c18ceeb01c1bbb"
        },
        "date": 1792413134628,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.084882332,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0012282626000000001,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0010106212,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0082371048,
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
          "id": "666ddb8bd153284b21e25ef830e15a695d67e4c7",
          "message": "docs(mise): note how pipx tools pick their python and survive a prune (#495)\n\nAdds a short section to `docs/mise-quick-reference.md`. mise passes the\nfirst global `python` to `uv tool install --python` for every `pipx:`\ntool, and pruning an interpreter breaks the venvs built on it. Includes\nthe check-and-rebuild commands used before `mise prune python` in #494's\nfollow-up.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01MTzgWGbUpTi14YdCkV6kas\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-21T12:51:26+03:00",
          "tree_id": "ca27061466cf17e453b1f7f1fc93741d74164439",
          "url": "https://github.com/laurigates/dotfiles/commit/666ddb8bd153284b21e25ef830e15a695d67e4c7"
        },
        "date": 1792576346051,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.12048102500000002,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015835122,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013402794000000001,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0113766284,
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
          "id": "715d700935aca11d22cf1bbb62fb5b78791766d8",
          "message": "feat(claude): read AGENTS.md alongside CLAUDE.md (#496)\n\n## What\n\nSets Claude Code's **Project instructions** to `claude-md-and-agents-md`\nvia `pluginConfigs.\"cc-plugin-agents-md@builtin\"` in the\n`~/.claude/settings.json` overlay.\n\n## Why\n\nThe default mode (`claude-md-or-agents-md`) reads `AGENTS.md` only when\nno `CLAUDE.md` exists in the working directory or above it\n([docs](https://code.claude.com/docs/en/memory#choose-which-instruction-files-load)).\n`~/repos/CLAUDE.md` sits above every repo, so no `AGENTS.md` under\n`~/repos` loaded. 10 such files were being skipped, including skullcaps,\nComfyUI, ComfyUI_frontend and surface. Claude Code ignores this key in\nproject and local settings, so it has to be set user-wide.\n\nSide effect: 6 repos with both files that are not linked (FVH\ninfrastructure, pal-mcp-server, ollama, local-ai-testing, …) now load\n`AGENTS.md` after `CLAUDE.md`. Repos whose `CLAUDE.md` imports or\nsymlinks `AGENTS.md` are not double-loaded.\n\n## Verification\n\n- `chezmoi apply ~/.claude/settings.json`: the diff adds only\n`pluginConfigs`.\n- A fresh `claude -p` in `skullcaps-workbench` reported both the repo\nand workspace `AGENTS.md` as loaded, quoting the first lines correctly.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01TeZMmjPozaeAwz99UpohiH\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-21T12:53:33+03:00",
          "tree_id": "9960884c27b38d22baf913b90e71afbbcdfe4b3f",
          "url": "https://github.com/laurigates/dotfiles/commit/715d700935aca11d22cf1bbb62fb5b78791766d8"
        },
        "date": 1792576465501,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.12308686366666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015972512000000001,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013484112000000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0112019324,
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
          "id": "599c0075384366a4cc4e755ba044eecb3d656037",
          "message": "docs(claude): correct enabledPlugins resolution to per-plugin (#497)\n\n## What\n\n`claude-plugins-freshness.md` said a project's `enabledPlugins` map\nreplaces the global one wholesale, so any globally enabled plugin the\nproject map omits would be disabled. The [`enabledPlugins` settings\nreference](https://code.claude.com/docs/en/settings-reference#enabledplugins)\nsays each `plugin@marketplace` key resolves on its own, highest scope\nfirst, and falls back to the manifest `defaultEnabled` when no scope\nsets it. Its example is a project `true` overriding a user `false`, with\n`.claude/settings.local.json` as the per-machine opt-out.\n\n## Changes\n\n- The rule section now states per-plugin resolution, plus a note\nrecording the earlier claim so an audit doesn't reintroduce it.\n- The consequence for exhaustive pins is kept, with the reason it\nactually holds: web and remote sessions have no user scope, so only the\nproject map applies there.\n- Two comments in `private_dot_config/just/plugins.just`\n(`plugins-reconcile-keys`, `plugins-audit`) repeated the claim and are\nreworded. Recipe code is unchanged.\n\n## How it surfaced\n\nWhile enabling 13 plugins in ForumViriumHelsinki/fvh-data-pipe#78, the\nrule implied that commit would switch off 31 other globally enabled\nplugins in that repo. The settings reference contradicts it.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01WDfr3HpmhC7t7hK32XNH5M\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-21T12:55:30+03:00",
          "tree_id": "79fce8b79f17df41c91df634d2927b6900cc6ada",
          "url": "https://github.com/laurigates/dotfiles/commit/599c0075384366a4cc4e755ba044eecb3d656037"
        },
        "date": 1792576588625,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.11914731299999999,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.001553947,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013081770000000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0106630068,
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
          "id": "3984bbcae93dbb6652c5a345379a1f205b36c350",
          "message": "docs(claude): require a source command for numbers in PRs and summaries (#498)\n\n## What\n\nAdds one sentence to the \"Status Claims Point at Evidence\" section of\n`exact_dot_claude/rules/communication.md`: a number in a PR, issue,\ncommit, or summary names the command that produced it, or is labelled as\nan estimate.\n\n## Why\n\nThe usage report of 2026-10-14 found a PR table carrying an uncomputed\nhole count (397; the computed value was 422) and a time estimate given\nwithout a measurement. The section already covered ran/passed/pushed\nclaims but not numbers. Unverified negatives (\"no other instances\") stay\nwith `tool-use-patterns.md` § \"Control-test negatives\".\n\n## Checks\n\n- `mise run lint:shell`, `lint:actions`, `lint:docs`: exit 0. `mise run\nlint` exits 1 only on `lint:lua`, because Homebrew luacheck 1.2.0\ncrashes on Lua 5.5 on this machine. That is a local environment problem,\nand this PR touches no Lua.\n- `gitleaks dir . --config .gitleaks.toml`: exit 0, no leaks.\n- Pre-commit hooks passed on commit.\n\nAfter merge, run `chezmoi apply ~/.claude` to sync the rule.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01GhhDWA39zgDrq12SM1Nenv\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-21T12:57:50+03:00",
          "tree_id": "abd01b47361ca54268edbe76c346a5bdc0e7daa6",
          "url": "https://github.com/laurigates/dotfiles/commit/3984bbcae93dbb6652c5a345379a1f205b36c350"
        },
        "date": 1792576731311,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.13054931400000003,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0017654418000000002,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0014857334,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.012253960400000003,
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
          "id": "16c86a79ffe18eb7a3d9df6f6eeed2caaa018bf0",
          "message": "docs(claude): tighten communication rules, generalize actor labels (#499)\n\n## What\n\nRevises `exact_dot_claude/rules/communication.md`. It merges the\nimprovements from a proposed rewrite and keeps the parts of the current\nrule that the rewrite dropped.\n\nTaken from the proposal:\n- The duplicate \"ask clarifying questions\" bullet is gone from Proactive\nEngagement. Opening now asks only when no conventional default applies,\nwhich matches `decision-defaults.md`.\n- Actor labels cover any offered choice, not only `AskUserQuestion`, and\nadd a split-actor example (`Claude runs migrations; Lauri updates DNS`).\nThe heading is now \"Actor Labels in Options\", so the \"actor-label\nconvention\" reference in `front-load-executive-decisions.md` still\nmatches.\n- A check that was not run is marked as pending verification.\n- The footer label is `TL;DR:` instead of `TL;DR (ELI5):`.\n- Claude states its delegation rationale only when delegation was a\nplausible option.\n\nKept from the current rule:\n- the table of three closing-flourish forms, with their real examples\n- the \"position plus shape\" test, the Don't/Do pair, and \"never a\nmirrored or generalizing\" clause\n- \"chat responses\" in the End-on-the-Fact scope\n- \"don't also fix them unless asked\"\n- the TL;DR skip conditions and the one-per-turn limit\n- the number-sourcing sentence from #498\n\nMost of the size reduction comes from trimming rationale prose around\nthe table and folding bullets together.\n\n## Checks\n\n- `bash tests/test-claude-context-budget.sh`: PASS=4 FAIL=0.\nAlways-loaded total is 52,331 bytes against a budget of 78,400.\n- `python3 scripts/check-doc-references.py --strict`: DANGLING_COUNT=0,\nexit 0.\n- `wc -c exact_dot_claude/rules/communication.md`: 5,355 bytes before,\n4,665 bytes after.\n- `gitleaks` and `mise` are not installed in this session, so the\ngitleaks scan and `mise run lint` have not been run yet.\n\nAfter merge, run `chezmoi apply ~/.claude` to sync the rule.\n\n---\n_Generated by [Claude\nCode](https://claude.ai/code/session_01NBZbuTNv3DpqmNFiDqM2Jb)_\n\nCo-authored-by: Claude <noreply@anthropic.com>",
          "timestamp": "2026-10-21T19:13:32+03:00",
          "tree_id": "570a4a850c18ffe7b00b62913edc6eabbb9bb6ab",
          "url": "https://github.com/laurigates/dotfiles/commit/16c86a79ffe18eb7a3d9df6f6eeed2caaa018bf0"
        },
        "date": 1792599268233,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.09591190666666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0013512416000000002,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0011416294,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.009381918600000002,
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
          "id": "ff72db2ab291d45562c39a9101f558ecded9d0cf",
          "message": "feat(macos): add noTunes to stop media keys launching Apple Music (#500)\n\nHeadphone play/pause launches Apple Music when no other app holds Now\nPlaying. This adds the \\`notunes\\` cask to the \\`gui\\` profile and a\n\\`com.lgates.notunes\\` RunAtLoad LaunchAgent so it starts at login.\n\nVerified locally: \\`launchctl print\\` shows last exit code 0, \\`pgrep -x\nnoTunes\\` finds it running, and Music started with \\`open -a Music\\` is\nno longer running 3 s later.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01SG98vnBanHD77dEZ8p8CNt\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-22T10:43:22+03:00",
          "tree_id": "2df0395afdd42263f9545afec9e2c6b70257f7aa",
          "url": "https://github.com/laurigates/dotfiles/commit/ff72db2ab291d45562c39a9101f558ecded9d0cf"
        },
        "date": 1792655051790,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.07045232133333335,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0011881912000000002,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0009682315999999999,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0080149508,
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
          "id": "fca6429ca55c6063bb4ead10d2e5786f1c67f90e",
          "message": "docs(zsh): explain cb alias vs pbcopy and xsel (#501)\n\nAdds a comment above the `cb` alias in `aliases.zsh` comparing it with\n`pbcopy` and `xsel -ib`. `pbcopy` and `xsel` write the clipboard of the\nhost they run on. `cb` (`kitty +kitten clipboard`) sends the text to\nkitty through the TTY, so it reaches the local clipboard from inside\nSSH, but it only works under kitty.\n\nComment only, no behaviour change. `zsh -n aliases.zsh` passes.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01VvQAs2GdfoPMhDrC9ChpvD\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-22T16:49:22+03:00",
          "tree_id": "56e1a2167643b94e58d708ad721f96a10fab9a93",
          "url": "https://github.com/laurigates/dotfiles/commit/fca6429ca55c6063bb4ead10d2e5786f1c67f90e"
        },
        "date": 1792677021995,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.12789155966666668,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0016373952000000003,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013835342000000001,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0125084064,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "f9f4cd872ded846fb4a9d45bda84869ae42e1a30",
          "message": "chore(deps): update @anthropic-ai/claude-code to v2.1.306 (#506)\n\nThis PR contains the following updates:\n\n| Package | Change |\n[Age](https://docs.renovatebot.com/merge-confidence/) |\n[Confidence](https://docs.renovatebot.com/merge-confidence/) |\n|---|---|---|---|\n|\n[@anthropic-ai/claude-code](https://redirect.github.com/anthropics/claude-code)\n| `2.1.302` → `2.1.306` |\n![age](https://developer.mend.io/api/mc/badges/age/npm/@anthropic-ai%2fclaude-code/2.1.306?slim=true)\n|\n![confidence](https://developer.mend.io/api/mc/badges/confidence/npm/@anthropic-ai%2fclaude-code/2.1.302/2.1.306?slim=true)\n|\n\n---\n\n### Release Notes\n\n<details>\n<summary>anthropics/claude-code\n(@&#8203;anthropic-ai/claude-code)</summary>\n\n###\n[`v2.1.306`](https://redirect.github.com/anthropics/claude-code/blob/HEAD/CHANGELOG.md#21306)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code/compare/v2.1.305...v2.1.306)\n\n- Fixed `claude -p` inside cloud sessions reporting \"Not logged in\" when\nstarted without the session's environment variables\n- Fixed an API error being replaced by \"prompt is too long\", and an\nunneeded compaction, in sessions with many MCP tools\n\n###\n[`v2.1.305`](https://redirect.github.com/anthropics/claude-code/blob/HEAD/CHANGELOG.md#21305)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code/compare/v2.1.304...v2.1.305)\n\n- Added `sandbox.allowNestedUserNamespaces` so sandboxed commands on\nLinux can create user namespaces (Chromium, rootless podman); this lets\nthem get around the sandbox's file protections\n- Added `CLAUDE_CODE_RETRY_WATCHDOG_USAGE_LIMIT_RECHECK_MS` so\nunattended retry mode (`CLAUDE_CODE_RETRY_WATCHDOG`) notices a usage\nlimit that was lifted before its reset\n- Fixed every request failing on Vertex, Bedrock and other providers\nwhen the endpoint or a gateway rejects tool search, and behind gateways\nwith ToolSearch disallowed or left out of `--tools` (a 2.1.304\nregression): Claude Code now retries without it\n- Fixed `/effort` and `/autocompact` settings not applying when the\nmodel name differed from a `modelOverrides` value by letter case or a\n`[1m]` tag\n- Fixed new worktrees in a bare repository sometimes starting from local\nHEAD instead of the default branch, and unchanged subagent worktrees\nsometimes not being cleaned up\n- Fixed Bash commands on a full disk failing with a raw `ENOSPC` file\npath: the error now says the disk is full and that nothing ran\n- Fixed an MCP server passed by a cloud session or by the SDK's\n`setMcpServers` being replaced later in the session by a same-named\nserver from your own settings\n- Fixed Claude naming the wrong model for a subagent's work after the\nsubagent switched to a fallback model\n- Fixed cloud sessions and teammates not telling Claude when a\ncompaction had to leave the oldest messages out of its summary to fit\n- Fixed more cases of scheduled Cowork cloud sessions waiting five\nminutes for each subagent whose WebFetch needed a URL approval that\nnobody was there to give\n- Fixed Workflow resume re-running already-completed `pipeline()` and\n`parallel()` agents instead of serving them from the run's journal\n- Fixed Remote Control leaving empty \"(session)\" entries in `/resume`\nafter switching conversations with `/resume`\n- Fixed `/usage` rows being cut off in narrow terminals\n- Fixed startup warnings printing as raw text above the logo: they now\ngo to the debug log, and permission rules that restrict nothing show as\nwarning rows under the banner\n- Fixed screen reader mode: search boxes now say \"Search:\" instead of a\nsymbol VoiceOver read as \"telephone recorder\", and highlighted prompt\ntext, such as Ctrl+R search matches and \"ultrathink\", no longer has\nspaces inside words\n- Self-hosted runner: Fixed a start script that shares only its stdout\nwith the runner or orchestrator failing with `Resource temporarily\nunavailable` when `TERM` is set (a 2.1.300 regression)\n- Self-hosted runner: Fixed repository access failing since 2.1.296 when\na git credential helper or askpass program reads its settings through\n`GIT_CONFIG`\n- Self-hosted runner: Fixed the orchestrator reporting a spawn-runner\nhook as timed out when a runner it started in the background kept its\noutput open\n- Improved `/usage`: each warning is now a one-line fix that names its\nsource, and `f` applies the fixes; the same fixes appear in VS Code and\n`/doctor`\n- Improved MCP consent dialogs so an Enter meant for the prompt is less\nlikely to be taken as Accept\n- Improved a mod's `Image` to draw its picture in iTerm2 3.5 and later\nwith fullscreen rendering, where it showed only its `alt` text\n- Remote Control: Improved the spawn-mode messages: pressing `w` now\nsays the new mode is saved for the folder, and a later `claude\nremote-control` start that uses the saved mode says where it came from\n- Changed `allowedMcpServers` to stop filtering `managed-mcp.json` stdio\nservers that use `${VAR}` only in `env`: one your allowlist left out now\nloads on upgrade; use `deniedMcpServers` to keep it off\n- Changed plugins that Claude Desktop mounts by path to no longer keep\ntheir `allowed-tools` when your organization's managed settings set\n`allowManagedPermissionRulesOnly`\n- Changed the `/artifacts` delete confirmation to take 1 or Enter to\nkeep, 2 to delete, and Esc to cancel; `y` and `n` no longer answer it\n- Changed a mod's docked pane to stay within 45% of the terminal's\nwidth, including a width kept from a wider terminal\n- \\[VSCode] Added a \"Running start-up hooks\" spinner status, with a\nscreen reader announcement, while SessionStart or Setup hooks run\n- \\[VSCode] Fixed the spinner cutting off \"Compacting...\" when your\n`spinnerVerbs` setting replaces the built-in verbs with short ones\n- \\[VSCode] Changed the message shown when a session does not start in\ntime and no hook is running: it now leads with the output logs and lists\ncauses instead of pointing to sign-in and network first\n- \\[Cloud sessions] Fixed the Cloud environments admin page wrongly\nrefusing to save an existing environment with an \"installs packages\"\nerror\n- \\[Cloud sessions] Improved deleting a self-hosted environment so the\ndialog and error messages say what blocks the delete and what it will\naffect\n- \\[Claude Tag] Added public Slack channels Claude hasn't joined to the\nClaude Tag admin Add place search, so admins can set one up from there\n- \\[Claude Tag] Fixed Claude Tag access bundles so a repository that\nmoved to another GitHub account can be added again\n- \\[Claude Tag] Fixed a routine set up in a Slack DM thread no longer\nposting after another routine in that thread restarted the conversation;\nboth now keep posting there\n- \\[Claude Tag] Fixed routines set up in a Slack thread reporting\nsuccess without posting after the conversation ended; those runs are now\nskipped and the creator is told\n- \\[Claude Tag] Improved Claude Tag admin pages in large organizations\nso plugin, skill and bundle edits work while the channel list is still\nloading\n- \\[Code Review] Fixed Code Review sometimes not reviewing the newest\ncommit when several pushes landed on a pull request during a review\n- \\[Code Review] Changed Code Review re-reviews so they no longer open\nwith LGTM while earlier blocking findings are still open\n\n###\n[`v2.1.304`](https://redirect.github.com/anthropics/claude-code/blob/HEAD/CHANGELOG.md#21304)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code/compare/v2.1.303...v2.1.304)\n\n- Added a transcript line when a plugin that runs first skips one of\nyour mod's hooks, naming the event and the plugin\n- Added `decider: \"person\"` to a mod's `tool.check` answer: only the\npermission dialog or a host's callback can approve the ask, and it is\nrefused with the mod's reason where nobody can be asked\n- Added `e.isReadOnly` to a mod's `tool.check` event, set when the tool\ncall is read-only\n- Added `/auto-mode-setup`: a guided setup that reads your project and\nrecent sessions to teach auto mode about your environment, now also\navailable on Bedrock, Vertex, Foundry, Claude apps gateway and\ntelemetry-disabled sessions\n- Added `/claude-api managed-agents-secure`, which compares a Managed\nAgents agent's settings with Anthropic's published security guide,\nwithout changing anything\n- Added the names of the tools called earlier to the compaction summary\nin the transcript view (Ctrl+O)\n- Added a warning on Pro and Max plans when resuming an inactive\nconversation would use a noticeable share of your 5-hour usage limit:\nresume anyway, or start a new conversation and Claude can look up the\nprevious one if you refer to it\n- Fixed the organization policy not refreshing until the hourly check\nafter approving an `ANTHROPIC_API_KEY` at startup or switching \"Use\ncustom API key\" in `/config`\n- Fixed sandboxed commands failing to start on Linux when a\n`sandbox.filesystem.denyRead` glob contains brackets that are not a\ncharacter class, such as a `[user-id]` route folder\n- Fixed `rm -r` of a mounted drive or a folder at its top level\n(`/Volumes`, `/media`, WSL's `/mnt/c`) not getting the safety prompt\nthat `rm -rf /Applications` gets\n- Fixed `CLAUDE_CODE_TRANSCRIPT_LOCAL_GC` dropping messages from the\nsaved transcript when the disk filled up while the file was being\ntrimmed\n- Fixed a plugin keeping a headless run going past `--max-turns`, Stop,\nor ended input by spawning subagents or re-running a finished one\n- Fixed a failed mod reload removing the tools and commands of the\nversion that stays loaded, and its messages being wrong or silent about\nwhether the previous version is still loaded\n- Fixed a click on a mod's button being lost when buttons with the same\nlabel and no `key` were redrawn unchanged\n- Fixed mod sharing in the built-in `plugin-authoring` skill stopping at\nthe secret scan on machines with managed settings and on Team and\nEnterprise plans\n- Fixed scheduled Cowork cloud sessions waiting five minutes again for\neach subagent whose WebFetch needed a URL approval that nobody was there\nto give\n- Fixed Write results and rejected edits showing a file outside the\nworking directory as `../../…`; they now show `~/…` or the full path\n- Fixed a claude.ai Directory plugin's skills not running as commands\nwhen picked from the \"/\" menu in Cowork cloud sessions\n- Fixed Remote Control permanently withholding a desktop conversation's\nhistory when a different account was signed in to the terminal\n- Fixed Remote Control failing to start from Claude Desktop when\nDISABLE\\_TELEMETRY or DO\\_NOT\\_TRACK is set on a paid plan\n- Fixed model switches, messages and interrupts waiting behind a context\nusage check in SDK and desktop sessions\n- Fixed `context_management: Extra inputs are not permitted` errors\nbehind LLM gateways; Claude Code now resends the request without that\nfield\n- Fixed OpenTelemetry settings delivered through server-managed settings\nbeing ignored for the whole session after signing in during first-run\nsetup or the first start after /logout\n- Fixed unsandboxed Bash commands in Claude Desktop Code tab sessions on\nmacOS and Linux not seeing environment variables exported in shell\nstartup files such as \\~/.zshrc\n- Fixed the Consumer Terms notice being skipped for a day or longer\nafter a server error\n- Fixed `/privacy-settings` offering choices that may not apply to you\nafter a network or server error\n- Fixed a \"Context limit reached\" or \"Prompt is too long\" error after\nstopping a turn while Claude Code was compacting a conversation the API\nhad rejected as too long\n- Fixed subagents sometimes forgetting their most recent work when they\nwere messaged or resumed right after finishing\n- Fixed `claude --help` text for `--tools`, `--resume`, `--debug`,\n`--json-schema`, `--disable-slash-commands`, `--system-prompt-snapshot`\nand `claude update` to match actual behavior\n- Fixed `claude --worktree` removing the worktree and its branch without\nasking at exit when HEAD was detached or on another branch, which could\nlose commits\n- Fixed resumed and cloud sessions sending Claude the whole skill list\nagain each time plugins reloaded at startup\n- Fixed an interrupt not ending a Read that waits on an idle pipe or\ndevice named like an image\n- Fixed `/effort status`, `/effort ultracode` and the prompt's effort\nindicator showing a guessed effort level when `CLAUDE_CODE_EFFORT_LEVEL`\nis `auto` or `unset` and no level is sent\n- Fixed a PreToolUse hook's deny reason being replaced by a timeout\nerror when an Agent SDK callback hook on the same tool call timed out\n- Fixed Bash and PowerShell deleting a large command's output file when\nit could not be copied to the session's tool-results folder, unless the\ndisk is full\n- Fixed notes typed into a multiple-choice question with previews being\ncut off with \"…\" in terminals under about 100 columns, hiding what was\ntyped\n([#&#8203;82768](https://redirect.github.com/anthropics/claude-code/issues/82768))\n- Fixed self-paced `/loop` wakeups scheduled at the 1-hour maximum\nfiring just after the 1-hour prompt cache expired, so those wakeups no\nlonger re-read the conversation uncached\n- Fixed agent teams: approving a shutdown request from the main session\nno longer exits the whole CLI\n- Fixed a skill's `once` hook also removing another skill's identical\nhook after it ran\n- Fixed transcript mode's `{` and `}` landing the prompt on an\ninconsistent row, or off screen, instead of the transcript's first row\n- Fixed `CLAUDE_CODE_AUTO_COMPACT_WINDOW=200k` silently setting a 100K\nwindow: the variable now accepts `k` and `M` suffixes like\n`--autocompact`, and warns when a value is out of range or ignored\n- Fixed Ctrl+C in the agents view clearing a text selection without\ncopying it when pressed before the mouse button was released\n- Improved `/usage` to say when a rate limit on usage data ends instead\nof \"try again in a moment\"\n- Improved the lines shown when a mod written in the session loads,\nreloads or fails to load\n- Improved artifacts with several views: when you ask for links to them,\nClaude now writes out each view's link and explains that the address bar\nstays the same as you switch views\n- Improved cloud sessions: a new conversation's first turn no longer\nwaits for the local (stdio) MCP servers of plugins synced from\nclaude.ai, unless a server sets `alwaysLoad: true`\n- Improved how a remote session recovers its status when the server\nrefuses a status update that carried other session data\n- Improved session file size in auto mode: the safety classifier's\ncontext is no longer stored with every request\n- Improved the `claude -p` invalid-settings warning: a file that did not\nload lists only what stopped it, and long lists are capped per file\n- Improved resume of large compacted sessions in SDK and headless mode:\nthe first request after resuming is sent sooner\n- Improved responsiveness and throughput when many subagents are running\nat the same time\n- Improved memory use when sending requests in long or resumed\nconversations\n- Self-hosted runner: Improved the error shown when the git host answers\n\"not found\" for a session's repository: it now names the repository and\nwhom to ask\n- Windows: Improved git command start-up with a standard Git for Windows\ninstall by running its git.exe directly instead of through its cmd\nlauncher\n- Changed mods' `settings.read` hooks to receive each settings layer and\nrewrite the merged settings, so a managed mod can make an organization's\nsetting a ceiling, including the `cleanupPeriodDays` the retention sweep\nuses\n- Changed the `/artifacts` delete confirmation to show numbered choices:\n1 or Enter keeps the artifact, 2 deletes it, and y, n and Esc still work\n- Changed the question that turns on the mods Claude writes in a session\nto plain text with no link or session id; it stays up when a new turn\nstarts, and Claude tells you what loaded when you turn them on\n- Changed tool search to be on by default behind a custom\n`ANTHROPIC_BASE_URL`; a 400 or 422 from the gateway is retried without\nit\n- Changed compaction to send Claude the skill list again afterwards;\n`/reload-skills` now sends only new or changed skills\n- Changed skill hooks: the skills of one source (a repo, your own\nfolder, or a plugin) can register at most 1,024 hooks and 16,384 matcher\ncharacters per session\n- Changed skills under a policy that allows hooks from plugins only: a\nskill used in the main conversation whose hooks are kept out no longer\ngets its `allowed-tools`\n- Updated the /claude-api skill to use the `ant` CLI on Claude Platform\non AWS instead of falling back to the SDK or curl\n- Removed the notes from `claude plugin validate` that predicted where a\nmod's hooks would run\n- Removed the \"(research preview)\" label from the `/fast` dialog title\non Opus 5.5\n- \\[VSCode] Added mod drawing in the chat panel for sessions on Amazon\nBedrock, Google Vertex AI and Microsoft Foundry, behind an LLM gateway,\nor with telemetry turned off\n- \\[VSCode] Fixed one cause of sessions failing to start with\n\"Subprocess initialization did not complete within 60000ms\": time a\nSessionStart command hook spends running no longer counts toward the\nlimit, up to 10 minutes in total\n- \\[VSCode] Fixed a session closed while it was starting keeping its\nClaude Code process running until the start ended\n- \\[VSCode] Fixed a mod's drawings disappearing from a long-open panel\nuntil the next turn on machines that also run an older Claude Code\n- \\[VSCode] Fixed Past conversations hiding sessions when\n`claudeCode.claudeProcessWrapper` is set\n- \\[VSCode] Changed background sub-agents to show as one status line\nunder their Agent card instead of streaming every step into the chat;\nthe full transcript stays in /tasks\n- \\[Cloud sessions] Fixed folders in the composer's @&#8203; list\nshowing no name in cloud sessions, where picking one added only a space\ninstead of a mention\n- \\[Claude Tag] Fixed Claude going silent in a thread when its channel\nbecomes shared across Enterprise Grid workspaces mid-task; it now posts\na one-time note to @&#8203;-mention it in a new thread\n- \\[Claude Tag] Fixed `@Claude !fork` typed outside a thread getting no\nvisible reply; Claude now shows you a private note saying to run it from\ninside a thread\n- \\[Code Review] Added review levels to Code Review: Owners choose\nQuick, Standard (the default), or Deep for the organization, and can\ngive individual repositories their own level\n- \\[Code Review] Added an option in Code Review admin settings to review\nevery repository in a GitHub organization, including ones added later,\nwithout selecting them one by one\n- \\[Code Review] Fixed pull requests opened within a minute or two of an\nadmin turning on Code Review being silently skipped; they are now\nretried and reviewed\n\n###\n[`v2.1.303`](https://redirect.github.com/anthropics/claude-code/blob/HEAD/CHANGELOG.md#21303)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code/compare/v2.1.302...v2.1.303)\n\n- Bug fixes and reliability improvements\n\n</details>\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-10-24T17:26:00Z",
          "tree_id": "2985bf75d91698e75fc99696cfc7c330139f914e",
          "url": "https://github.com/laurigates/dotfiles/commit/f9f4cd872ded846fb4a9d45bda84869ae42e1a30"
        },
        "date": 1792862819808,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.11816288233333334,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015258318000000001,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012906202000000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0109565388,
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
          "id": "a9be74d27dbef9279d658e1354cce4eb4daa1ff5",
          "message": "feat(zshenv): keep Apptainer cache and temp on popos's data disk (#502)\n\nAdds a block to `dot_zshenv.tmpl` that, on hostname `pop-os` only, sets\n`APPTAINER_CACHEDIR` and `APPTAINER_TMPDIR` under\n`/mnt/sabrent/apptainer/` and creates the directories.\n\npopos's `/` has about 6 GB free. Apptainer's defaults\n(`~/.apptainer/cache` for image layers, `/tmp` for SIF assembly) would\nput a 3.4 GB CUDA image pull plus its 3.2 GB SIF on root. The background\nis in laurigates/claude-plugins#3182 (the new `tools-plugin:apptainer`\nskill).\n\nRendered with `chezmoi execute-template`: the block is present on popos\nand absent on the Mac (0 matching lines).\n\nPost-merge step tracked in laurigates/dotfiles#503.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01MSZ9jyVNVN8Xt7jjpUS8aB\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-24T22:45:28+03:00",
          "tree_id": "fdd116c239456694d8bf11eb11208650ca2a9150",
          "url": "https://github.com/laurigates/dotfiles/commit/a9be74d27dbef9279d658e1354cce4eb4daa1ff5"
        },
        "date": 1792871194034,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.11508377033333335,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015581984000000001,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012939516000000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.011622439600000003,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "17a5093f6483d1733d5241a93988ae0e7e4ecec2",
          "message": "chore(deps): update GitHub Actions (#508)\n\nThis PR contains the following updates:\n\n| Package | Type | Update | Change | Pending |\n|---|---|---|---|---|\n| [Homebrew/actions](https://redirect.github.com/Homebrew/actions) | |\npatch | `2026.10.12.1` → `2026.10.19.1` | |\n|\n[anthropics/claude-code-action](https://redirect.github.com/anthropics/claude-code-action)\n| action | patch | `v1.0.250` → `v1.0.256` | `v1.0.261` (+4) |\n| [laurigates/.github](https://redirect.github.com/laurigates/.github)\n([changelog](https://redirect.github.com/laurigates/.github/compare/aad403be1e3d72f68f6536f212ed3a0339263d22..bbb33382f63e21fd7ef903ebf85883b2a82cda01))\n| action | digest | `aad403b` → `bbb3338` | |\n\n---\n\n### Release Notes\n\n<details>\n<summary>Homebrew/actions (Homebrew/actions)</summary>\n\n###\n[`v2026.10.19.1`](https://redirect.github.com/Homebrew/actions/releases/tag/2026.10.19.1)\n\n[Compare\nSource](https://redirect.github.com/Homebrew/actions/compare/2026.10.12.1...2026.10.19.1)\n\n##### What's Changed\n\n- git-try-push: only force push after a successful pull by\n[@&#8203;p-linnane](https://redirect.github.com/p-linnane) in\n[#&#8203;949](https://redirect.github.com/Homebrew/actions/pull/949)\n- Synchronize shared configuration by\n[@&#8203;BrewTestBot](https://redirect.github.com/BrewTestBot) in\n[#&#8203;950](https://redirect.github.com/Homebrew/actions/pull/950)\n- build(deps): bump the github-actions group across 3 directories with 5\nupdates by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;952](https://redirect.github.com/Homebrew/actions/pull/952)\n- build(deps): bump js-yaml from 5.4.2 to 5.4.3 in the npm group by\n[@&#8203;dependabot](https://redirect.github.com/dependabot)\\[bot] in\n[#&#8203;951](https://redirect.github.com/Homebrew/actions/pull/951)\n\n**Full Changelog**:\n<https://github.com/Homebrew/actions/compare/2026.10.12.1...2026.10.19.1>\n\n</details>\n\n<details>\n<summary>anthropics/claude-code-action\n(anthropics/claude-code-action)</summary>\n\n###\n[`v1.0.256`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.256)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.255...v1.0.256)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.255...v1.0.256>\n\n###\n[`v1.0.255`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.255)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.254...v1.0.255)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.254...v1.0.255>\n\n###\n[`v1.0.254`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.254)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.253...v1.0.254)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.253...v1.0.254>\n\n###\n[`v1.0.253`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.253)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.252...v1.0.253)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.252...v1.0.253>\n\n###\n[`v1.0.252`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.252)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.251...v1.0.252)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.251...v1.0.252>\n\n###\n[`v1.0.251`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.251)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.250...v1.0.251)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.250...v1.0.251>\n\n</details>\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-10-24T22:46:18+03:00",
          "tree_id": "e27badb9d3ae527a9cbebc51af7bffb4a48c1e29",
          "url": "https://github.com/laurigates/dotfiles/commit/17a5093f6483d1733d5241a93988ae0e7e4ecec2"
        },
        "date": 1792871258304,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.121013624,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0016136294000000002,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013334126,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0117313316,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "f20ecf35fb0fa67494464e05b7c5dddeb65bec72",
          "message": "chore(deps): update @anthropic-ai/claude-code to v2.1.308 (#515)\n\nThis PR contains the following updates:\n\n| Package | Change |\n[Age](https://docs.renovatebot.com/merge-confidence/) |\n[Confidence](https://docs.renovatebot.com/merge-confidence/) |\n|---|---|---|---|\n|\n[@anthropic-ai/claude-code](https://redirect.github.com/anthropics/claude-code)\n| `2.1.306` → `2.1.308` |\n![age](https://developer.mend.io/api/mc/badges/age/npm/@anthropic-ai%2fclaude-code/2.1.308?slim=true)\n|\n![confidence](https://developer.mend.io/api/mc/badges/confidence/npm/@anthropic-ai%2fclaude-code/2.1.306/2.1.308?slim=true)\n|\n\n---\n\n### Release Notes\n\n<details>\n<summary>anthropics/claude-code\n(@&#8203;anthropic-ai/claude-code)</summary>\n\n###\n[`v2.1.308`](https://redirect.github.com/anthropics/claude-code/blob/HEAD/CHANGELOG.md#21308)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code/compare/v2.1.307...v2.1.308)\n\n- Bug fixes and reliability improvements\n\n###\n[`v2.1.307`](https://redirect.github.com/anthropics/claude-code/blob/HEAD/CHANGELOG.md#21307)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code/compare/v2.1.306...v2.1.307)\n\n- Added `/claude-api api-version` to move Claude API code to API version\n`2026-10-21`\n- Added the `claude_code.safety_event` OpenTelemetry event for each tool\ncall a permission rule, auto mode, a safety check, a hook or the sandbox\nstopped, prompted or sent back\n- Fixed requests failing with a model-not-found error when\n`CLAUDE_CODE_DISABLE_1M_CONTEXT` is set and the model is an alias with\nthe `[1m]` suffix, such as `opus[1m]`\n- Fixed the `prompt-caching-scope` beta header being sent behind custom\n`ANTHROPIC_BASE_URL` gateways and on Foundry, where it has no effect\n- Fixed MCP servers showing \"needs authentication\" in `claude -p` on\nmacOS while the login keychain was locked; they now say why, and the\nnext run after an unlock connects without a new sign-in\n- Fixed MCP servers being reported as timed out, and staying failed in\nheadless runs, when a macOS or Linux computer went to sleep while they\nwere connecting\n- Fixed HTTP MCP tool calls being sent twice when the connection closed\nmid-call; only read-only or idempotent tools are now retried\n- Fixed a turn sometimes starting without an SDK MCP server's latest\ntools when a background task was running\n- Fixed some \"Autocompact is thrashing\" errors in turns that read many\nPDF pages, images or other large tool results\n- Fixed `/autocompact` in cloud sessions going back to the default\nwindow after the session restarted\n- Fixed a conversation cleared with `/clear` sometimes coming back when\na cloud or self-hosted runner session restarted\n- Fixed `CLAUDE_STREAM_FIRST_BYTE_TIMEOUT_MS` being ignored in Claude\napps gateway sessions\n- Fixed telemetry from Claude Desktop sessions behind a Claude apps\ngateway being rejected when `OTEL_EXPORTER_OTLP_HEADERS` is set\n- Fixed `/permissions` > Recently denied not showing the denied shell\ncommand, and auto mode's local classifier ignoring an approval from\nthere when it checks a retried command; approving a row now names the\ncommand, not its description\n- Fixed `/help` and the `/` command menu showing long model-facing\ndescriptions for bundled skills such as `/claude-api` instead of their\nshort descriptions\n- Fixed subagent transcripts recording placeholder token usage and an\nempty stop reason for streamed responses\n- Fixed model switches through the Agent SDK's `setModel()`, and apps\nbuilt on it, being refused when the API took more than 5 seconds to\nconfirm the model; Claude Code now waits up to 15 seconds\n- Fixed a background command stopped through a connected app (such as\nthe desktop app archiving an idle session) being reported to Claude as\nstopped by the user; the notice now names its output file\n- Fixed WebFetch in Cowork cloud sessions reporting a tool error when a\nsite answered with a 4xx status or a robots.txt refusal; it is now a\nnormal result, as in local sessions\n- Fixed write tools on a directly configured GitHub MCP server showing a\nform that closed without creating anything in the desktop app's Code tab\n- Fixed Artifact tool reads failing with a connection reset when the\nserver had closed a reused connection\n- Self-hosted runner: Fixed sessions with `--use-anthropic-git-proxy`\ncommitting a `.claude/settings.local.json` left in the clone by an\nearlier session\n- Self-hosted runner: Fixed archiving or requeueing a session, or\nstopping the runner, during its checkout hook leaving the hook's\nprocesses running and the runner's slot held\n- Improved recovery from unparseable tool calls: Claude Code now retries\nthe call up to twice before ending the turn with an error\n- Improved fork subagents launched together: each is now told which\nlaunch is its own, so forks are much less likely to try to start each\nother's work\n- Improved browser sign-in: the success page now appears as soon as\nsign-in completes, without waiting for your account profile to load\n- Improved web search errors in cloud and self-hosted runner sessions: a\nsearch refused with a 403 that gives a reason now shows that reason\ninstead of a generic \"Authentication error\"\n- Improved the time to the first reply in cloud sessions when one of the\ndesktop app's MCP servers can't connect\n- Improved Remote Control connect time for sessions whose transcript\ncontains large pasted images or PDF reads\n- Changed the notice Claude gets when the WebSearch budget is used up to\nalso tell it not to query search engines in a browser or through\ncomputer use\n- Changed the `axScreenReader` setting and `CLAUDE_AX_SCREEN_READER` in\na settings `env` block to apply only from user, managed or `--settings`\nsettings (since 2.1.305)\n- Self-hosted runner: Changed checkout hooks to be stopped after 30\nminutes by default, failing the session's setup; if yours needs longer,\nraise `--checkout-hook-timeout-min` or set it to `0`\n- Self-hosted runner: Changed the certificate file built for\nAnthropic-managed git to filter its trusted certificates as the CLI\ndoes; a `[runner:warn]` line gives the number left out\n- \\[VSCode] Added a notice on the microphone button when voice dictation\nstops by itself (15 seconds without recognized speech, or the 2-minute\nlimit), saying why and that the text so far is kept\n- \\[VSCode] Fixed a long prompt expanded with Show more covering the\nwhole chat panel: a pinned prompt is now capped at 40% of the panel and\nscrolls\n- \\[VSCode] Fixed part of a list item or table cell with LaTeX math\npasting as a new list or table in rich text editors\n- \\[VSCode] Fixed dictation failing behind a TLS-inspecting proxy when\n`NODE_EXTRA_CA_CERTS` is set only in `~/.claude/settings.json`; it now\nalso follows `CLAUDE_CODE_CERT_STORE`\n- \\[VSCode] Changed the \"still open somewhere else\" notice to also cover\na Claude process left over from an extension restart, which usually ends\non its own within about 10 minutes\n- \\[VSCode] Changed voice dictation to filter its trusted certificates\nas the CLI does\n- \\[VSCode] Changed the extension's own requests to filter their trusted\ncertificates as the CLI does, and to trust the `NODE_EXTRA_CA_CERTS`\nfile named in the environment or in user settings\n- \\[Cloud sessions] Fixed the repository picker saying \"No repositories\nmatch\" while a search was still running; it now shows \"Searching…\" until\nthe results arrive\n- \\[Cloud sessions] Fixed the \"Waiting for a runner\" status on\nself-hosted environments being cut off; with on-demand runners it now\ncounts up from your last message and shows failed attempts\n- \\[Code Review] Added `@claude review stop` (also `off` and `pause`) to\nCode Review, ending an `@claude review always` subscription on a pull\nrequest without starting a new review\n\n</details>\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-10-25T17:38:56Z",
          "tree_id": "cb894c9c7be594c765fa403f7ea528cf3a44d613",
          "url": "https://github.com/laurigates/dotfiles/commit/f20ecf35fb0fa67494464e05b7c5dddeb65bec72"
        },
        "date": 1792949990160,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.09391455066666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0011463140000000003,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0009925712,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0082105066,
            "unit": "s"
          }
        ]
      },
      {
        "commit": {
          "author": {
            "email": "293328251+laurigates-renovate[bot]@users.noreply.github.com",
            "name": "laurigates-renovate[bot]",
            "username": "laurigates-renovate[bot]"
          },
          "committer": {
            "email": "noreply@github.com",
            "name": "GitHub",
            "username": "web-flow"
          },
          "distinct": true,
          "id": "c4258a6446bff54c161f89c2aab2f3315897fa54",
          "message": "chore(deps): update GitHub Actions (#516)\n\nThis PR contains the following updates:\n\n| Package | Type | Update | Change | Pending |\n[Age](https://docs.renovatebot.com/merge-confidence/) |\n[Confidence](https://docs.renovatebot.com/merge-confidence/) |\n|---|---|---|---|---|---|---|\n|\n[actions/setup-python](https://redirect.github.com/actions/setup-python)\n| action | minor | `v7.0.0` → `v7.1.0` | |\n![age](https://developer.mend.io/api/mc/badges/age/github-tags/actions%2fsetup-python/v7.1.0?slim=true)\n|\n![confidence](https://developer.mend.io/api/mc/badges/confidence/github-tags/actions%2fsetup-python/v7.0.0/v7.1.0?slim=true)\n|\n|\n[anthropics/claude-code-action](https://redirect.github.com/anthropics/claude-code-action)\n| action | patch | `v1.0.256` → `v1.0.258` | `v1.0.262` (+3) |\n![age](https://developer.mend.io/api/mc/badges/age/github-tags/anthropics%2fclaude-code-action/v1.0.258?slim=true)\n|\n![confidence](https://developer.mend.io/api/mc/badges/confidence/github-tags/anthropics%2fclaude-code-action/v1.0.256/v1.0.258?slim=true)\n|\n| [bun](https://bun.com)\n([source](https://redirect.github.com/oven-sh/bun)) | uses-with | patch\n| `1.4.3` → `1.4.4` | |\n![age](https://developer.mend.io/api/mc/badges/age/npm/bun/1.4.4?slim=true)\n|\n![confidence](https://developer.mend.io/api/mc/badges/confidence/npm/bun/1.4.3/1.4.4?slim=true)\n|\n| [laurigates/.github](https://redirect.github.com/laurigates/.github)\n([changelog](https://redirect.github.com/laurigates/.github/compare/bbb33382f63e21fd7ef903ebf85883b2a82cda01..1ecad76523a79f59001c3cb2aff584de262c8fde))\n| action | digest | `bbb3338` → `1ecad76` | | | |\n\n---\n\n### Release Notes\n\n<details>\n<summary>actions/setup-python (actions/setup-python)</summary>\n\n###\n[`v7.1.0`](https://redirect.github.com/actions/setup-python/releases/tag/v7.1.0)\n\n[Compare\nSource](https://redirect.github.com/actions/setup-python/compare/v7...v7.1.0)\n\n#### What's Changed\n\n##### Enhancements\n\n- Add `mirror` and `mirror-token` inputs for custom Python distribution\nsources by [@&#8203;luhenry](https://redirect.github.com/luhenry) in\n[#&#8203;1302](https://redirect.github.com/actions/setup-python/pull/1302)\n- Improve error message clarity by\n[@&#8203;v-lmvysakh](https://redirect.github.com/v-lmvysakh) in\n[#&#8203;1351](https://redirect.github.com/actions/setup-python/pull/1351)\n\n##### Dependency Upgrade\n\n- Upgrade browserslist from 4.28.2 to 4.28.9 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1353](https://redirect.github.com/actions/setup-python/pull/1353)\n- Upgrade\n[@&#8203;typescript-eslint/parser](https://redirect.github.com/typescript-eslint/parser)\nfrom 8.62.0 to 8.70.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1343](https://redirect.github.com/actions/setup-python/pull/1343)\n- Upgrade eslint-plugin-jest from 29.15.2 to 29.16.6 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1342](https://redirect.github.com/actions/setup-python/pull/1342)\n- Upgrade [@&#8203;vercel/ncc](https://redirect.github.com/vercel/ncc)\nfrom 0.44.0 to 0.45.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1357](https://redirect.github.com/actions/setup-python/pull/1357)\n- Upgrade\n[@&#8203;types/semver](https://redirect.github.com/types/semver) from\n7.7.1 to 7.8.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1359](https://redirect.github.com/actions/setup-python/pull/1359)\n- Upgrade undici from 6.28.0 to 6.29.0 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1364](https://redirect.github.com/actions/setup-python/pull/1364)\n- Upgrade ts-jest from 29.4.11 to 29.4.14 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1361](https://redirect.github.com/actions/setup-python/pull/1361)\n- Upgrade brace-expansion from 5.0.9 to 5.0.12 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1365](https://redirect.github.com/actions/setup-python/pull/1365)\n- Upgrade prettier from 3.8.4 to 3.9.9 and package.json from 7.0.0 to\n7.1.0 by [@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1363](https://redirect.github.com/actions/setup-python/pull/1363)\n- Upgrade\n[@&#8203;typescript-eslint/eslint-plugin](https://redirect.github.com/typescript-eslint/eslint-plugin)\nfrom 8.62.0 to 8.71.1 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1369](https://redirect.github.com/actions/setup-python/pull/1369)\n- Upgrade actions/checkout from 7.0.0 to 7.0.1 by\n[@&#8203;dependabot](https://redirect.github.com/dependabot) in\n[#&#8203;1345](https://redirect.github.com/actions/setup-python/pull/1345)\n- Upgrade cache to 6.3.0 by\n[@&#8203;v-HarithaVattikuti](https://redirect.github.com/v-HarithaVattikuti)\nin\n[#&#8203;1370](https://redirect.github.com/actions/setup-python/pull/1370)\n- Resolve Basic Validation audit failures by\n[@&#8203;v-HarithaVattikuti](https://redirect.github.com/v-HarithaVattikuti)\nin\n[#&#8203;1347](https://redirect.github.com/actions/setup-python/pull/1347)\n- Resolve npm audit failures by\n[@&#8203;v-HarithaVattikuti](https://redirect.github.com/v-HarithaVattikuti)\nin\n[#&#8203;1350](https://redirect.github.com/actions/setup-python/pull/1350)\n\n#### New Contributors\n\n- [@&#8203;luhenry](https://redirect.github.com/luhenry) made their\nfirst contribution in\n[#&#8203;1302](https://redirect.github.com/actions/setup-python/pull/1302)\n\n**Full Changelog**:\n<https://github.com/actions/setup-python/compare/v7.0.0...v7.1.0>\n\n</details>\n\n<details>\n<summary>anthropics/claude-code-action\n(anthropics/claude-code-action)</summary>\n\n###\n[`v1.0.258`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.258)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.257...v1.0.258)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.257...v1.0.258>\n\n###\n[`v1.0.257`](https://redirect.github.com/anthropics/claude-code-action/releases/tag/v1.0.257)\n\n[Compare\nSource](https://redirect.github.com/anthropics/claude-code-action/compare/v1.0.256...v1.0.257)\n\n**Full Changelog**:\n<https://github.com/anthropics/claude-code-action/compare/v1.0.256...v1.0.257>\n\n</details>\n\n<details>\n<summary>oven-sh/bun (bun)</summary>\n\n###\n[`v1.4.4`](https://redirect.github.com/oven-sh/bun/releases/tag/bun-v1.4.4):\nBun v1.4.4\n\n[Compare\nSource](https://redirect.github.com/oven-sh/bun/compare/bun-v1.4.3...bun-v1.4.4)\n\nTo install Bun v1.4.4\n\n```bash\ncurl -fsSL https://bun.com/install | bash\n\n# or you can use npm\n# npm install -g bun\n```\n\nWindows:\n\n```bash\npowershell -c \"irm bun.com/install.ps1|iex\"\n```\n\nTo upgrade to Bun v1.4.4:\n\n```bash\nbun upgrade\n```\n\n##### [Read Bun v1.4.4's release notes on Bun's\nblog](https://bun.com/blog/bun-v1.4.4)\n\n##### Thanks to 39 contributors!\n\n- [@&#8203;0xh3x](https://redirect.github.com/0xh3x)\n- [@&#8203;1cedsoda](https://redirect.github.com/1cedsoda)\n- [@&#8203;alex-mextner](https://redirect.github.com/alex-mextner)\n- [@&#8203;alii](https://redirect.github.com/alii)\n- [@&#8203;Artoria2e5](https://redirect.github.com/Artoria2e5)\n- [@&#8203;bompus](https://redirect.github.com/bompus)\n- [@&#8203;C0casio45](https://redirect.github.com/C0casio45)\n- [@&#8203;cirospaciari](https://redirect.github.com/cirospaciari)\n- [@&#8203;davidhevn](https://redirect.github.com/davidhevn)\n- [@&#8203;deepshekhardas](https://redirect.github.com/deepshekhardas)\n- [@&#8203;Dex4Sure](https://redirect.github.com/Dex4Sure)\n- [@&#8203;dylan-conway](https://redirect.github.com/dylan-conway)\n-\n[@&#8203;EffortlessSteven](https://redirect.github.com/EffortlessSteven)\n- [@&#8203;eriklangille](https://redirect.github.com/eriklangille)\n- [@&#8203;filipesarturi](https://redirect.github.com/filipesarturi)\n- [@&#8203;fredluz](https://redirect.github.com/fredluz)\n- [@&#8203;gerardp](https://redirect.github.com/gerardp)\n- [@&#8203;gohryt](https://redirect.github.com/gohryt)\n- [@&#8203;himself65](https://redirect.github.com/himself65)\n- [@&#8203;hughescr](https://redirect.github.com/hughescr)\n- [@&#8203;Jarred-Sumner](https://redirect.github.com/Jarred-Sumner)\n- [@&#8203;jdjkelly](https://redirect.github.com/jdjkelly)\n- [@&#8203;jecquas](https://redirect.github.com/jecquas)\n- [@&#8203;jobansd](https://redirect.github.com/jobansd)\n- [@&#8203;kernoeb](https://redirect.github.com/kernoeb)\n- [@&#8203;KilianB](https://redirect.github.com/KilianB)\n- [@&#8203;MarshallOfSound](https://redirect.github.com/MarshallOfSound)\n- [@&#8203;Neekoras](https://redirect.github.com/Neekoras)\n- [@&#8203;nikeee](https://redirect.github.com/nikeee)\n- [@&#8203;nikelborm](https://redirect.github.com/nikelborm)\n- [@&#8203;ousamabenyounes](https://redirect.github.com/ousamabenyounes)\n- [@&#8203;pjb3](https://redirect.github.com/pjb3)\n- [@&#8203;RajeshKumar11](https://redirect.github.com/RajeshKumar11)\n- [@&#8203;ralyodio](https://redirect.github.com/ralyodio)\n- [@&#8203;robobun](https://redirect.github.com/robobun)\n- [@&#8203;RubenPari](https://redirect.github.com/RubenPari)\n- [@&#8203;sosukesuzuki](https://redirect.github.com/sosukesuzuki)\n- [@&#8203;steipete](https://redirect.github.com/steipete)\n- [@&#8203;SyMind](https://redirect.github.com/SyMind)\n\n</details>\n\n---\n\n- [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check\nthis box\n\n---\n\nThis PR has been generated by [Mend\nRenovate](https://redirect.github.com/renovatebot/renovate).\n\n<!--renovate-debug:eyJjcmVhdGVkSW5WZXIiOiI0My4yODguMCIsInVwZGF0ZWRJblZlciI6IjQzLjI4OC4wIiwidGFyZ2V0QnJhbmNoIjoibWFpbiIsImxhYmVscyI6WyJkZXBlbmRlbmNpZXMiLCJyZW5vdmF0ZSJdfQ==-->\n\nCo-authored-by: laurigates-renovate[bot] <293328251+laurigates-renovate[bot]@users.noreply.github.com>",
          "timestamp": "2026-10-25T17:39:33Z",
          "tree_id": "83d8966b26c34d7aff0cb16ffca5a9db1b559205",
          "url": "https://github.com/laurigates/dotfiles/commit/c4258a6446bff54c161f89c2aab2f3315897fa54"
        },
        "date": 1792950051200,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.12054954766666666,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015737666,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013647438000000001,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.011995565400000002,
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
          "id": "9329946ddf5e31aed70712a342c2ef5f0f44c160",
          "message": "fix(zsh): update BEHIND PRs in ghsq and stop the Claude handoff crash (#520)\n\n## What\n\nTwo `ghsq`/`ghrb` failures seen on laurigates/gitops#277–#281:\n\n1. **BEHIND PRs refused.** `_gh_poll_merge` ran `gh pr update-branch`\nonly when the PR's base took a merge earlier in the same run. gitops now\nrequires up-to-date branches (`strict_required_status_checks_policy =\ntrue`), so the four PRs that were already `BEHIND` went straight to `gh\npr merge` and were refused with \"the head branch is not up to date with\nthe base branch\". `mergeStateStatus == BEHIND` now also triggers the\nupdate-and-wait-for-CI path. GitHub reports `BEHIND` only under that\nrule, so unprotected bases behave as before.\n2. **Claude handoff crash.** `claude --worktree … </dev/tty` died with\n`EINVAL: invalid argument, kqueue` (Bun v1.4.4). macOS kqueue rejects\nthe `/dev/tty` alias. The handoff loop now reads its list from fd 3, so\nstdin stays the real terminal device for both `read -k` and `claude`.\n\n## Verification\n\n- Pty repro (python `pty.fork`, Bun stdin reader standing in for\n`claude`): `</dev/tty` crashes with the same stack, `<$TTY` and\ninherited stdin print `OK no crash`.\n- Old vs new `_gh_conflict_handoff` in the same pty harness with `y`\ntyped: old crashes, new prompts and runs the child cleanly.\n- `chezmoi execute-template | zsh -n` passes;\n`tests/test-gh-completion.sh` 18/18.\n- Not exercised end to end: the BEHIND branch of `_gh_poll_merge`\nagainst a live merge run. The `mergeStateStatus` field it reads returned\n`BEHIND` for gitops#278–#281 via `gh pr list`.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01QTsvFFgo5mhLhLaQxW63Nn\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-26T12:10:19+02:00",
          "tree_id": "4b9c30df101d27d197f6b396045c4dec8842d054",
          "url": "https://github.com/laurigates/dotfiles/commit/9329946ddf5e31aed70712a342c2ef5f0f44c160"
        },
        "date": 1793009481296,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.12374868300000001,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0017152340000000002,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013677750000000003,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.012395869200000003,
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
          "id": "8cf9a8c819435219a6af71166fd5e2a8c767a5ae",
          "message": "feat(zsh): add ghrr to tick Renovate rebase boxes from the terminal (#521)\n\n## What\n\n`ghrr` ticks Renovate's `<!-- rebase-check -->` box (\"If you want to\nrebase/retry this PR, check this box\") through `gh pr edit`, so mass\nrebase requests no longer need the browser.\n\n- `ghrr`: fzf multi-select of this repo's open PRs that still carry an\nunticked box (`^a` = all).\n- `ghrr 277 278`: those PRs directly; a PR without the box (not\nRenovate, or already ticked) is skipped with a note.\n- `ghrr -r`: also `gh workflow run renovate.yml` on\n`$GH_RENOVATE_RUNNER` (default `laurigates/gitops`). Without it, the box\nacts on the next scheduled run. That run covers every repo (~20 min,\nbilled), so it is opt-in.\n\nRegistered in the wrapper help tables, PR-number completion, and fzf-tab\npreview alongside the other `gh*` wrappers.\n\n## Verification\n\n- Live on laurigates/gitops: `ghrr 277` ticked the box (body now `- [x]\n<!-- rebase-check -->`); a rerun and a non-Renovate PR (#162) were\nskipped.\n- The picker's list query returned #278–#281 and excluded #277 (ticked)\nand #162. The fzf UI itself was not exercised (no TTY in the session).\n- `chezmoi execute-template | zsh -n` passes;\n`tests/test-gh-completion.sh` 18/18.\n\nIndependent of the ghsq fix PR; the two touch adjacent lines in the\nwrapper doc table, so the second to merge may need a trivial rebase.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01QTsvFFgo5mhLhLaQxW63Nn\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-26T10:15:06Z",
          "tree_id": "b4242be16f220ea4d042c2a423ec4c161955a11c",
          "url": "https://github.com/laurigates/dotfiles/commit/8cf9a8c819435219a6af71166fd5e2a8c767a5ae"
        },
        "date": 1793009766720,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.11661961400000002,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015488960000000001,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013090524,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0116757164,
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
          "id": "e0ae003c1f73058e1f2912df25edaba7cd3736b3",
          "message": "chore(renovate): drop group:allNonMajor from the repo extends (#509)\n\n## What\n\nRemoves `group:allNonMajor` from `extends` in `renovate.json5`.\n\n## Why\n\nThe account-wide Renovate config in laurigates/gitops already applies\n`group:allNonMajor`. laurigates/gitops#298 moves the global presets to\n`globalExtends` and adds a rule that takes 0.x minor bumps out of\n`renovate/all-minor-patch` into their own approval-gated branch. A\nrepo's own `extends` resolves after the global packageRules, so the\n`group:allNonMajor` listed here would put those 0.x minors back into\n`all-minor-patch`. In scansift the same grouping bundled a breaking\nsharp 0.33 to 0.35 bump into its non-major PR (laurigates/scansift#72).\n\n## How\n\nOne line removed, plus a comment in its place saying why it stays out.\nThe preset still applies through the global config, both before and\nafter laurigates/gitops#298. Under the current gitops main config,\nglobal `extends` presets are prepended to this repo's `extends`. Under\n#298 they resolve into the global config.\n\nRenovate's resolved package rules, applied to synthetic updates\n(Renovate 43.288.0, the production runner's version):\n\n| Update | gitops#298, before this PR | gitops#298, after this PR |\n|---|---|---|\n| `shellcheck` 0.11.0 to 0.12.0 (mise), minor | `all-minor-patch`,\napproval true | its own `<upstream>-0.x` group, approval true |\n| `shellcheck` 0.11.0 to 0.11.1, patch | `all-minor-patch` |\n`all-minor-patch` |\n| `@anthropic-ai/claude-code` 2.1.306 to 2.2.0, minor |\n`all-minor-patch` | `all-minor-patch` |\n\nUnder the current gitops main config, all three rows read\n`all-minor-patch` with no approval, both before and after this PR.\n\nThis repo's own \"Automerge patch and minor updates\" rule still sets\n`automerge: true` on a 0.x minor. Once Lauri ticks it on the Dependency\nDashboard, the PR automerges when its checks pass.\n\n## Gates\n\n- `renovate-config-validator --strict` in repo mode: \"Config validated\nsuccessfully\". Control: an unknown key (`packageRulez`) gives \"Invalid\nconfiguration option\" and exit 1.\n- `renovate --platform=local --dry-run=lookup` before and after this\nchange, under both the gitops main config and the #298 config: the\nupdate and branch lists are identical in all four runs, 13 updates each.\nNothing currently pending is a 0.x minor, so the dry run shows only that\nnothing else moves. The table above comes from `applyPackageRules` on\nthe merged config, not from a live run.\n- Not run: a dry run with dashboard approval or branch creation. A\n`--dry-run=lookup` does not exercise either.\n\n## Merge notes\n\nCan merge before or after laurigates/gitops#298. Before #298 it changes\nnothing, as the identical dry runs above show.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-26T10:32:41Z",
          "tree_id": "0e5d4cb63aaa4f51713fad317fe44783ea3bf6bb",
          "url": "https://github.com/laurigates/dotfiles/commit/e0ae003c1f73058e1f2912df25edaba7cd3736b3"
        },
        "date": 1793010812009,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.07083623566666668,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0011677712,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0009820071999999999,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.008049283,
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
          "id": "2610c09b72e9fa6eb1b7214b614bc795e6c0551d",
          "message": "ci: skip organize-stars while GH_STAR_TOKEN is missing and stop masking shellcheck in coverage (#510)\n\n## What\n\n- `organize-stars.yml` starts with a step that checks `GH_STAR_TOKEN`.\nWhen the secret is empty, the step emits a `::warning::` naming it and\nevery later step is skipped. Provisioning is tracked in #512.\n- `coverage.yml`'s \"Analyze shell scripts\" step now fails when\nshellcheck fails on any script. It previously reported every script as\npassing.\n\n## Why\n\n**organize-stars**: `GH_STAR_TOKEN` has never been created, so `gh api\nuser/starred` exits 4 and the weekly run on main is red\n(https://github.com/laurigates/dotfiles/actions/runs/39282372383).\nBefore #483 the same run was green with \"Found 0 repos to process\".\n\n**coverage**: the step tested `if shellcheck -f gcc \"$script\" 2>&1 | tee\nshellcheck.log`. The step shell is `bash -e` without pipefail, so the\n`if` saw tee's exit status.\nhttps://github.com/laurigates/dotfiles/actions/runs/39790279959 printed\n`./aliases.zsh:106:7: error: ... [SC2142]` and `./aliases.zsh:194:19:\nerror: ... [SC2068]`, then `Coverage: 100% (Color: brightgreen)`. 115\nruns in the audit window, 0 failures.\n\n## How\n\n- organize-stars: the guard writes `present=true|false` to\n`$GITHUB_OUTPUT`, and checkout, the organizer, the state commit and the\nlog upload all check it. Once the secret exists, the workflow runs as\nbefore.\n- coverage, for the case this change turns the job red:\n- Redirect instead of `| tee`, so the `if` tests shellcheck's own exit\nstatus.\n- Drop `*.zsh` from the `find`. shellcheck does not support zsh, and\n`aliases.zsh` was the only `.zsh` file in the set and the only failing\nfile.\n- End the step with `exit 1` and an `::error::` when `FAILED > 0`, and\nprint each failing script's shellcheck output.\n- Count every diagnostic level (`error|warning|note`) and replace `||\necho \"0\"`, which printed a second `0` when grep found nothing. That\nbranch was unreachable before this change.\n- The 42 remaining scripts are all in `lint:shell`'s set (`git ls-files\n'*.sh'`, 48 files), which the smoke Linters job already gates. Deleting\n`coverage.yml` would also remove the duplicate. This PR keeps the\nworkflow and fixes it; deletion is Lauri's call.\n\n## Gates\n\n- `actionlint` on both files: exit 0. Pre-commit hooks on commit,\nincluding `check CI GitHub API consumers are authenticated` and `Lint\nGitHub Actions workflow files`: passed.\n- `tests/test-organize-stars.sh` (42 checks),\n`tests/test-ci-github-api-auth.py` and `tests/test-ci-pins.sh`: PASS.\n- Coverage step, extracted from the workflow and run from the repo root\nwith shellcheck 0.11.0:\n  - New step on this tree: exit 0. All 42 `.sh` files pass.\n- New step with a planted script carrying SC2086 and SC2035 findings:\nexit 1, `::error::shellcheck failed on 1 of 43 script(s)`.\n  - Old step with the same planted script: exit 0.\n- Guard step, extracted from the workflow: `shellcheck -s bash` exit 0.\nRun under `bash -e`, it writes `present=false` and the warning when the\nsecret is empty, and `present=true` when it is set.\n\nRefs #512\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\n---------\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-26T10:48:48Z",
          "tree_id": "3a5a8f947ff3af490d3520a26ed83a85b0c3bcef",
          "url": "https://github.com/laurigates/dotfiles/commit/2610c09b72e9fa6eb1b7214b614bc795e6c0551d"
        },
        "date": 1793011780579,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.12120738866666668,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015911378000000003,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0012956252000000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.010992083,
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
          "id": "9520ed2c9a9bd0188f36e59d0cb825ef82b0ed80",
          "message": "ci: review pull requests with the OpenCode reusable workflow (pilot) (#514)\n\n## What\n\nAdds `.github/workflows/opencode-review.yml`, a caller of\n`laurigates/.github`'s `reusable-opencode-review.yml@main`\n(laurigates/.github#99) on `pull_request` types `opened`, `synchronize`,\n`reopened` and `ready_for_review`. It passes `secrets: OPENCODE_API_KEY`\nand uses every input default, so the model is the reusable workflow's\ndefault free one.\n\nThis repo's default workflow permissions are `write`; the job grants\n`contents: read` and `pull-requests: write` explicitly anyway, so the\nscopes do not depend on that setting.\n\n## Why\n\nThis repo and loractl are the pilot for automatic PR review on a free\nOpenCode model. The rollout to the other repos waits for the first\nreview posted here or in loractl.\n\nIt replaces `claude-code-review.yml`, which is `disabled_manually` here\n(`gh api repos/laurigates/dotfiles/actions/workflows --paginate`), so\nthe two never review side by side. #511 deletes that file.\n\nWhat a PR here gets: a draft, a bot-authored PR, a bot push, a fork PR,\na PR whose every file is docs or a lockfile, and a diff over 2000\nchanged lines all skip with a notice. A missing or rejected\n`OPENCODE_API_KEY`, or a model OpenCode no longer lists, fails the check\nred. Otherwise one review is posted, with an inline comment per finding\non a diff line. Under this repo's default-branch ruleset\n(`required_review_thread_resolution: true`), each inline comment must be\nresolved before the PR can merge, auto-merge included.\n\n## Merge order\n\n1. laurigates/.github#99 merges first.\n2. laurigates/gitops#316 merges and is released, and the release's `tofu\napply` pushes `OPENCODE_API_KEY` to this repo.\n3. Then this PR.\n\nUntil step 1, this PR's `opencode-review.yml` run fails at startup\nbecause `reusable-opencode-review.yml` is not on `main` yet (run\n40171164536). A startup failure creates no check run, so the PR shows no\nred `opencode-review` check and its merge state is not blocked; the\nfailure is visible only in the Actions tab. Between steps 1 and 2 the\njob starts and fails red on the missing key.\n\n**Cutover signal:** the first OpenCode review (a `github-actions[bot]`\nreview whose body starts **OpenCode review** and ends with an\n`opencode-review:reviewed=` marker) posted on a human-authored PR that\nchanges more than workflow files, here or in loractl. That is the\ntrigger for laurigates/.github#100, the rollout to the other repos.\n\n## Verification\n\n- `actionlint` 1.7.12 on the new file: clean.\n- `git merge-tree` against every open PR in this repo: clean.\n- Startup run 40171164536: failure, as expected while the reusable is\nnot on `main`.\n- Not run: a review. It cannot run until the reusable is on `main` and\nthe key is applied.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-26T11:06:38Z",
          "tree_id": "91c061ea27b8998a509bf3bd5f7ce3d6687dddbd",
          "url": "https://github.com/laurigates/dotfiles/commit/9520ed2c9a9bd0188f36e59d0cb825ef82b0ed80"
        },
        "date": 1793012853456,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.11616017533333334,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015503578,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013089199999999999,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0113331304,
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
          "id": "ea995f92c6027f2c9f433a88985bdccd11648931",
          "message": "ci(claude): gate auto-fix on human actors and delete the disabled review workflow (#511)\n\n## What\n\n- `auto-fix-ci-failures.yml` skips Smoke failures started by a bot other\nthan `claude[bot]`/`claude`, and stops triggering on `main` completions.\n- `claude-code-review.yml` is deleted (separate commit).\n\n## Why\n\n**auto-fix**: the caller's `if:` checked only the failure and a PR. When\nSmoke failed on a Renovate PR, the reusable ran, and claude-code-action\nrefused the actor: `Workflow initiated by non-human actor:\nlaurigates-renovate (type: Bot)`\n(https://github.com/laurigates/dotfiles/actions/runs/35833478228). At\nthe pinned SHA, the reusable sets `allowed_bots: \"claude[bot],claude\"`.\nOf the 115 skipped runs in the audit window, 46 came from main pushes,\nwhich `pull_requests[0]` always skips.\n\n**claude-code-review**: `disabled_manually` since its last run on\n2026-04-12. It was later migrated to a `reusable-claude-review.yml`\ncaller that Renovate keeps bumping (#451, #467, #474) but that has never\nrun. It declares `pull_request: [opened, synchronize]` with no bot gate,\nand no issue tracks it. `@claude` mentions keep working through\n`claude.yml`.\n\n## How\n\n- The job condition gains the actor clause from\n`reusable-auto-fix.yml`'s example caller: `actor.type != 'Bot' ||\nactor.login == 'claude[bot]' || actor.login == 'claude'`. The existing\n`conclusion` and `pull_requests[0]` checks stay.\n- `on.workflow_run.branches-ignore: [main]` filters on the triggering\nrun's head branch, so main completions no longer create a run.\n- `private_dot_config/just/plugins.just` still lists\n`claude-code-review.yml` among the filenames its recipes scan in other\nrepos. That is unaffected.\n\n## Gates\n\n- `actionlint .github/workflows/auto-fix-ci-failures.yml`: exit 0.\nPre-commit hooks on commit: passed.\n- The auto-fix caller runs only on `workflow_run`, so no check on this\nPR exercises it. The first Smoke failure on a human PR after merge will.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\n---------\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-26T11:09:58Z",
          "tree_id": "66c36c872d86fc3964256fbeab11b36e72f1a1d5",
          "url": "https://github.com/laurigates/dotfiles/commit/ea995f92c6027f2c9f433a88985bdccd11648931"
        },
        "date": 1793013056370,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.10339471833333334,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0011999146,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0010428262,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.009287508000000002,
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
          "id": "3528a682d2df134e275c0870029884fbf4dd7c0b",
          "message": "fix(chezmoi): capture target-side drift from Claude Code and mise (#522)\n\nResolves the drift prompts from `chezmoi apply`:\n\n- `exact_dot_claude/.chezmoiignore`: ignore new Claude Code runtime\nstate `daemon-auth-cooldown`, `daemon-auth-status.json`, `dev-mods/`.\n- `private_dot_config/git/ignore`: add `**/.claude/.cc-writes/`, which\nwas present on the target only.\n- `private_dot_config/mise/config.toml.tmpl`: replace `npm:opencode-ai`\n1.19.3 with `npm:@opencode/cli` 2.1.4 (`opencode-ai` latest is 1.19.4;\nthe `opencode` registry entry resolves to `npm:@opencode/cli`).\n\nVerified with `chezmoi --source <worktree> status`: the three `.claude`\nentries and `.config/git/ignore` no longer appear.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01K89idRM2Bc7R3oiaz3Mf8a\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-26T11:17:16Z",
          "tree_id": "e1af68f9f6739a433c1758fe8016b2844b1da666",
          "url": "https://github.com/laurigates/dotfiles/commit/3528a682d2df134e275c0870029884fbf4dd7c0b"
        },
        "date": 1793013506894,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.12857740666666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015971576,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013920294000000003,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0123518036,
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
            "email": "lauri.gates@gmail.com",
            "name": "Lauri Gates",
            "username": "laurigates"
          },
          "distinct": true,
          "id": "31ad45501a6a07559e1fa4be6e45334932b80a8e",
          "message": "feat(just): add merge-method-rollout to add the caller to active repos\n\nDry run by default: lists every non-archived source repo of the owner with a\nPR merged in the last 90 days that lacks .github/workflows/merge-method.yml.\napply=true commits the caller to a ci/merge-method branch through the\ncontents API and opens a PR, skipping repos where that branch exists so a\nre-run resumes. Repo merge settings and the merge:* labels are gitops state\nand are deliberately not touched.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\nClaude-Session: https://claude.ai/code/session_019HRyi88qtUmT7BH6rKwUSb",
          "timestamp": "2026-10-26T15:16:53+02:00",
          "tree_id": "e97be2182f1ff5976c1a2def1edb7521b65cb14d",
          "url": "https://github.com/laurigates/dotfiles/commit/31ad45501a6a07559e1fa4be6e45334932b80a8e"
        },
        "date": 1793020677113,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.11954031966666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015617806000000002,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013214698,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.011260122200000002,
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
            "email": "lauri.gates@gmail.com",
            "name": "Lauri Gates",
            "username": "laurigates"
          },
          "distinct": true,
          "id": "fe01ae7e853246dc5626497c6e04ae0843ff6b84",
          "message": "fix(zsh): enable bare glob qualifiers in _gh_merge_method\n\nClaude Code's shell, which also runs `!` commands, sets nobareglobqual, so\nthe (Nn) qualifier on the pr-merge-method.py glob was read as literal text.\nThe glob failed with \"no matches found\", and ghsq / ghrb / ghm fell back to\nthe merge:* label. Set bare_glob_qual function-locally.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\nClaude-Session: https://claude.ai/code/session_01JkCD9CRWh2L98RviTXbaVw",
          "timestamp": "2026-10-27T10:06:04+02:00",
          "tree_id": "1417b769bb72f168e5211b11c9d4f8489ed04c51",
          "url": "https://github.com/laurigates/dotfiles/commit/fe01ae7e853246dc5626497c6e04ae0843ff6b84"
        },
        "date": 1793088428137,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.11917704433333336,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015384542,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013026534,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.010819605,
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
          "id": "055f18eafddfb679a87681bb13fef2867320b78a",
          "message": "docs(claude): rebuild after restoring a mutated file, not just after mutating it (#526)\n\nAdds a bullet to `validate-adversarial-constructions.md`. A `cp` restore\nusually lands in the same second as the mutant build, and make/CMake\ncompare one-second mtimes, so the object built from the mutant still\ncounts as current. The next run then reports the mutant's failure\nagainst restored source. The fix is to `touch` the restored file (or\nforce the target) before rebuilding.\n\nObserved three times in skullcaps-native on 2026-10-22. The edit was\nleft uncommitted in the main checkout by an earlier session and is moved\nhere unchanged.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01JkCD99DhhasECZzSq8UdGn\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-27T12:34:26+02:00",
          "tree_id": "28fa1198f6588ea5cf3fb366f9d74e42fb937ed9",
          "url": "https://github.com/laurigates/dotfiles/commit/055f18eafddfb679a87681bb13fef2867320b78a"
        },
        "date": 1793097309671,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.08287851133333334,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0010478146,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0009108572,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.007945628400000002,
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
            "email": "lauri.gates@gmail.com",
            "name": "Lauri Gates",
            "username": "laurigates"
          },
          "distinct": true,
          "id": "66fc53d12077ab77557d565dbdbfcf17a084101f",
          "message": "chore(nvim): update lazy-lock plugin pins\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\nClaude-Session: https://claude.ai/code/session_01JkCD99DhhasECZzSq8UdGn",
          "timestamp": "2026-10-27T12:36:43+02:00",
          "tree_id": "3b8a59377fc731560d5b60e995c703eb9788573a",
          "url": "https://github.com/laurigates/dotfiles/commit/66fc53d12077ab77557d565dbdbfcf17a084101f"
        },
        "date": 1793097446666,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.09406817566666666,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.001239611,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0009856346000000002,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.011009608,
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
          "id": "7f11ca9d1023cc2b3963081a827622a0aaf486f3",
          "message": "fix(chezmoi): ignore four new Claude Code runtime dirs under ~/.claude (#528)\n\n`chezmoi status` listed `.cc-writes/`, `bridge-spawn/`, `seed-admin/`\nand `ssh/` as pending deletions. `~/.claude` is an `exact_` dir and none\nof them were in `exact_dot_claude/.chezmoiignore`. #522 added\n`.cc-writes` to the git ignore only. All four are empty directories\ncreated this morning.\n\n`bridge-spawn`, `seed-admin` and `.cc-writes` appear as strings in the\nClaude Code 2.1.311 binary. `ssh` is too generic a string to find there;\nthe comment marks its writer as inferred from its creation alongside\n`seed-admin/`.\n\nVerified with `chezmoi --source <worktree> status`: none of the four\nentries remain.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01JkCD99DhhasECZzSq8UdGn\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-27T12:39:07+02:00",
          "tree_id": "f84b4385e0e44262e267d986926ba700557ce053",
          "url": "https://github.com/laurigates/dotfiles/commit/7f11ca9d1023cc2b3963081a827622a0aaf486f3"
        },
        "date": 1793097594522,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.07259661866666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0012915214,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0010043898000000001,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0102660952,
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
          "id": "713a6c78c9074a83a20f88aacb26d0de391d3b4c",
          "message": "fix(zsh): dispatch ghrr -r to the repo owner's Renovate runner (#534)\n\n`ghrr -r` always dispatched `laurigates/gitops` `renovate.yml`. Run in a\n`ForumViriumHelsinki` repo, it ticked the rebase box there and then\nstarted a full gitops run, which never scans FVH repos. Those PRs come\nfrom `fvh-renovate-bot`, run by `ForumViriumHelsinki/infrastructure`\n`renovate.yml`.\n\nThe runner is now picked from the current repo's owner:\n\n| Owner | Runner |\n|---|---|\n| `laurigates` | `laurigates/gitops` |\n| `ForumViriumHelsinki` | `ForumViriumHelsinki/infrastructure` |\n| anything else | no dispatch, message to set `GH_RENOVATE_RUNNER` |\n\n`GH_RENOVATE_RUNNER` still overrides the mapping.\n\nVerified by sourcing the rendered `ghrr` with a stubbed `gh` for all\nfour cases: each mapped owner dispatched to its runner, the unknown\nowner dispatched nothing, and the override won. `zsh -n` passes on the\nrendered `~/.zshrc`.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01JkCD9BXzMhX3oFG15DVshf\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-29T13:46:50+02:00",
          "tree_id": "de6a0d9a224c129711ffa26d36c8bc3840321290",
          "url": "https://github.com/laurigates/dotfiles/commit/713a6c78c9074a83a20f88aacb26d0de391d3b4c"
        },
        "date": 1793274472038,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.12668014733333333,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0015908604000000003,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0013363794,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.011397827199999998,
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
          "id": "bac1b870ebb5913c77e8772d4c816b8660888d94",
          "message": "docs(claude): a time-series level names its aligner and resolution (#533)\n\nAdds one sentence to `communication.md` § Status Claims Point at\nEvidence: a level read off a time series names its aligner and\nresolution, because the max over a coarse bucket is a peak, not a level.\n\nThe case: in an fvh-data-pipe incident session, DB CPU from 3 h\n`ALIGN_MAX` buckets was reported as \"staying at ~65%\" after a deploy.\n15-minute `ALIGN_MEAN` showed it flat at 20–21% throughout, and the\nclaim was retracted before any issue was filed on it.\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)\n\nhttps://claude.ai/code/session_01JkCD9BHmbLzDhJ7J2WivHW\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>",
          "timestamp": "2026-10-29T13:49:42+02:00",
          "tree_id": "9331185084925fb293f63ac7eb1198e046f52def",
          "url": "https://github.com/laurigates/dotfiles/commit/bac1b870ebb5913c77e8772d4c816b8660888d94"
        },
        "date": 1793274633557,
        "tool": "customSmallerIsBetter",
        "benches": [
          {
            "name": "chezmoi apply --dry-run",
            "value": 0.07141294066666667,
            "unit": "s"
          },
          {
            "name": "zsh startup",
            "value": 0.0011646084,
            "unit": "s"
          },
          {
            "name": "bash startup",
            "value": 0.0009806344000000001,
            "unit": "s"
          },
          {
            "name": "nvim startup",
            "value": 0.0083569378,
            "unit": "s"
          }
        ]
      }
    ]
  }
}