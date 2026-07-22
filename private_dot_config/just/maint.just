# maint.just — local machine maintenance recipes (imported by the global justfile).

# Deterministic $HOME top-level hygiene sweep: report new / known-junk entries
# since the last run. Never deletes — triage the delta yourself. Backs the
# quarterly reminder (taskwarrior project:home-cleanup); full report lives in
# ~/Documents/home-cleanup-2026-07/.
home-audit:
    bash "$HOME/scripts/home-audit.sh"
