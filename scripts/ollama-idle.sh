#!/usr/bin/env bash
# ollama-idle.sh — report (and optionally prune) ollama models by LAST READ.
#
# `ollama list`'s MODIFIED column is the *pull* time, which says nothing about
# whether you actually use a model — a model pulled yesterday and never run
# looks fresher than one pulled last year and used daily. This reads the atime
# of each model's blobs instead, which is the honest "last actually loaded"
# signal. (Verified: neither / nor /System/Volumes/Data mounts noatime, so APFS
# tracks access times here.)
#
# DRY-RUN BY DEFAULT. Pass --apply to `ollama rm` everything past the threshold.
# Deliberately NOT wired into the weekly reclaim job — re-pulling a 25 GB model
# over a home connection is a real cost, so this one stays a human decision.
#
# Backs `just -g ollama-idle` / `just -g ollama-prune`.
set -euo pipefail

days=45
apply=0

while [ $# -gt 0 ]; do
    case "$1" in
        --apply) apply=1; shift ;;
        --days) days="$2"; shift 2 ;;
        -h|--help) echo "usage: ollama-idle.sh [--apply] [--days N]"; exit 0 ;;
        *) echo "ollama-idle.sh: unknown arg: $1" >&2; exit 2 ;;
    esac
done

command -v ollama >/dev/null 2>&1 || { echo "ollama-idle.sh: ollama not installed" >&2; exit 1; }

idle_file="$(mktemp)"
trap 'rm -f "$idle_file"' EXIT

MODELS_DIR="${OLLAMA_MODELS:-$HOME/.ollama/models}" \
IDLE_DAYS="$days" IDLE_FILE="$idle_file" python3 - <<'PY'
import json, os, pathlib, time

root = pathlib.Path(os.environ["MODELS_DIR"])
threshold = int(os.environ["IDLE_DAYS"])
now = time.time()
rows = []

for mf in (root / "manifests").rglob("*"):
    if not mf.is_file():
        continue
    try:
        m = json.loads(mf.read_text())
    except Exception:
        continue
    # manifests/<registry>/<namespace...>/<model>/<tag>; drop the registry host.
    parts = mf.relative_to(root / "manifests").parts
    ns = "/".join(parts[1:-1])
    # `library/` is ollama's default namespace and is elided in `ollama rm`.
    name = f"{ns.removeprefix('library/')}:{parts[-1]}"
    digests = [layer["digest"] for layer in m.get("layers", [])]
    if m.get("config", {}).get("digest"):
        digests.append(m["config"]["digest"])
    size = atime = 0
    for d in digests:
        blob = root / "blobs" / d.replace(":", "-")
        if blob.exists():
            st = blob.stat()
            size += st.st_size
            atime = max(atime, st.st_atime)
    if size:
        rows.append((atime, size, name))

rows.sort()
print(f"{'LAST READ':<12} {'IDLE':>6} {'SIZE':>8}  MODEL")
idle_total = idle_names = 0
with open(os.environ["IDLE_FILE"], "w") as fh:
    for atime, size, name in rows:
        age = int((now - atime) // 86400)
        mark = "  IDLE" if age >= threshold else ""
        print(f"{time.strftime('%Y-%m-%d', time.localtime(atime))}   {age:>4}d {size/1e9:>7.1f}G  {name}{mark}")
        if age >= threshold:
            fh.write(name + "\n")
            idle_total += size
            idle_names += 1

print()
print(f"IDLE_THRESHOLD_DAYS={threshold}")
print(f"IDLE_MODELS={idle_names}")
print(f"IDLE_RECLAIMABLE_GB={idle_total/1e9:.1f}")
PY

if [ "$apply" -eq 1 ]; then
    echo "=== PRUNING ==="
    while IFS= read -r model; do
        [ -n "$model" ] || continue
        printf '%-32s ' "$model"
        ollama rm "$model" >/dev/null 2>&1 && echo removed || echo FAILED
    done < "$idle_file"
    printf 'STATUS=applied\n'
    printf 'DISK_AVAIL=%s\n' "$(df -h / | awk 'NR==2{print $4}')"
else
    printf 'STATUS=dry-run  (pass --apply to remove the IDLE models)\n'
fi
