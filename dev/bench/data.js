window.BENCHMARK_DATA = {
  "lastUpdate": 1790147863406,
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
      }
    ]
  }
}