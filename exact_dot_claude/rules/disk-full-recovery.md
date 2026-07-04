# Disk-Full Recovery — When Bash Stops Working

When root (`/`) fills up, the harness can't write Bash output files: **every**
Bash call fails instantly with
`ENOSPC: no space left on device, open '/tmp/claude-.../tasks/<id>.output'`
— regardless of the command. This is a hard stop the agent cannot fix itself.

**The invariants:**

1. Recognize the signature (ENOSPC on the harness's own output path, every
   call) — do **not** retry Bash commands; they fail identically until space
   is freed.
2. Hand the user recovery commands with the `! <cmd>` prefix so output lands
   in the conversation: start with `! df -h /` and
   `! du -shx ~/.cache/* 2>/dev/null | sort -h | tail -10`.
3. Prefer tools' own cleanup commands over `rm -rf` (`uv cache clean`,
   `pip cache purge`, `brew cleanup -s`, `go clean -cache`,
   `docker system prune -a`, `journalctl --vacuum-size=1G`). A typical
   uv/pip/HF session frees 30–50 GB.
4. Fix the cause, not the symptom: redirect caches on small-root machines
   (`HF_HOME` — see `huggingface-downloads.md`; `UV_CACHE_DIR`,
   `PIP_CACHE_DIR`, `HOMEBREW_CACHE`), persisted in `.zshrc`/`~/.api_tokens`.

For the full space-hunt playbook (APFS snapshots, OrbStack images, offender
tables), use the `macos-plugin:macos-disk-usage` skill.
