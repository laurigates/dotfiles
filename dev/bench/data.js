window.BENCHMARK_DATA = {
  "lastUpdate": 1790146984467,
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
      }
    ]
  }
}