# maint.just — local machine maintenance recipes (imported by the global justfile).

# Deterministic $HOME top-level hygiene sweep: report new / known-junk entries
# since the last run. Never deletes — triage the delta yourself. Backs the
# quarterly reminder (taskwarrior project:home-cleanup); full report lives in
# ~/Documents/home-cleanup-2026-07/.
home-audit:
    bash "$HOME/scripts/home-audit.sh"

# Stale target/ node_modules/ .venv/ (dir mtime older than `days`) are whole-dir
# removals; still-active Rust targets get `cargo sweep --time days` instead, so
# recent builds stay warm. Rationale and the structured output format are
# documented in the script header.
# Preview reclaimable build artifacts + package caches (never deletes)
reclaim-dry days="30":
    bash "$HOME/scripts/reclaim.sh" --days {{ days }}

# Everything this removes is regenerable. Also runs weekly, unattended, via the
# com.lgates.reclaim launchd agent (Sundays 09:23, log in ~/Library/Logs/
# reclaim.run.log) — run it by hand when you need the space sooner.
# Delete stale build artifacts and prune package caches
reclaim days="30":
    bash "$HOME/scripts/reclaim.sh" --days {{ days }} --apply

# Uses blob atime, not `ollama list`'s MODIFIED column — that shows when a model
# was PULLED, which says nothing about whether you ever ran it.
# Report ollama models by last actual use
ollama-idle days="45":
    bash "$HOME/scripts/ollama-idle.sh" --days {{ days }}

# Deliberately NOT part of the weekly job — re-pulling a 25 GB model is slow
# enough that it stays a deliberate choice.
# Remove ollama models idle `days`+ (re-pullable)
ollama-prune days="45":
    bash "$HOME/scripts/ollama-idle.sh" --days {{ days }} --apply
