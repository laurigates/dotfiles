# Disk-Full Recovery — When Bash Stops Working

When the root partition (`/`) fills up, the Claude Code harness can no
longer write Bash tool output files (which live under
`/tmp/claude-<uid>/`). Every Bash invocation fails immediately with:

```
ENOSPC: no space left on device, open '/tmp/claude-.../tasks/<id>.output'
```

This is a **hard stop**. The error fires before the command runs, so even
`df -h` and `du` cannot be issued via the Bash tool. The agent cannot
recover by itself — the user must free space first.

## What the agent can do

1. Recognize the symptom: `ENOSPC: no space left on device, open
   '/tmp/claude-.../tasks/...'` on every Bash call regardless of the
   command's content.
2. Tell the user the harness is locked and surface the exact recovery
   commands for them to run with the `! <cmd>` prefix in Claude Code so
   output lands in the conversation.
3. Do **not** re-attempt the same Bash command — it will fail again with
   the same error until root has free space.
4. Do **not** try to write via `Write` / `Edit` — those write to the
   session's cwd which is usually fine, but the agent still can't run any
   verifying command, so silent failure modes are likely.

## What the user runs

```sh
! df -h /
! du -shx ~/.cache/* 2>/dev/null | sort -h | tail -10
```

The standard offenders, in order of typical size:

| Cache | Reclaim with | Auto-rebuilds |
|---|---|---|
| `~/.cache/uv` | `uv cache clean` | yes, on next `uv add` / `uv sync` |
| `~/.cache/pip` | `pip cache purge` | yes, on next `pip install` |
| `~/.cache/huggingface/{hub,xet}` | `huggingface-cli delete-cache` (interactive) or remove a specific repo's subdir | yes |
| `~/.cache/Homebrew` | `brew cleanup -s` | partial — most of `~/.cache/Homebrew` is installed bottle archives, not stale cache; `brew cleanup -s` only frees ~10–50 MB on a typical setup |
| `~/.cache/pre-commit` | `pre-commit gc` (conservative — keeps active envs) or `pre-commit clean` (wipes all hook envs, slow rebuild on next run) | yes |
| `~/.cache/mozilla` | clear from Firefox UI, or `rm -rf ~/.cache/mozilla/firefox/*/cache2/` | yes |
| `~/.cache/go-build` | `go clean -cache` | yes |

Prefer the tools' own cleanup commands over `rm -rf` — they preserve
active envs/locks and respect package-manager invariants. Most user-level
hooks block `rm -rf ~/.cache/...` anyway.

For one session of `uv` / `pip` work plus the `~/.cache/huggingface/xet`
state from a single multi-GB HF download, expect 30–50 GB recoverable
across the standard caches without affecting any installed software.

## Prevention

If the same root-disk fill keeps happening, the cause is usually a tool
that doesn't honor its primary cache-redirect flag:

- **Hugging Face**: `--local-dir` doesn't cover xet — see
  `huggingface-downloads.md` for the `HF_HOME` fix.
- **uv / pip**: `UV_CACHE_DIR` / `PIP_CACHE_DIR` redirect; set when root
  is small.
- **Homebrew**: `HOMEBREW_CACHE` redirects bottle downloads.
- **npm**: `npm config set cache /big/disk/.npm` redirects globally.

Persist these in `.zshrc` (or `~/.api_tokens` which mise auto-sources) on
machines with a small root partition. Re-running cleanup is a stopgap; the
real fix is the redirect.

## Quick survey

When investigating a full root, this catches the dominant offenders:

```sh
df -h /
du -shx ~/.cache/* 2>/dev/null | sort -h | tail -10
du -shx ~/.local/* 2>/dev/null | sort -h | tail -10
sudo -n du -shx /var/lib/docker /var/lib/snapd 2>/dev/null
journalctl --disk-usage
```

Common surprises:

- `/var/lib/docker` if Docker is installed and not in use, after a few
  builds (`docker system prune -a` reclaims).
- `journalctl --disk-usage` over a few GB (`sudo journalctl --vacuum-size=1G`).
- `~/.local/share/Trash/` after a UI delete of large files.
