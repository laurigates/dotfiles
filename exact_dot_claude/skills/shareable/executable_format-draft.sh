#!/usr/bin/env bash
#
# format-draft.sh — extract one topic+register block from the shareables
# queue note, convert it to Google Chat syntax via google-chat-format, and
# copy the result to the clipboard, ready to paste.
#
# Usage:
#   format-draft.sh REGISTER [TOPIC_SUBSTRING]
#
#   REGISTER         one of: layman | technical | one-liner | takeaway
#   TOPIC_SUBSTRING  optional, case-insensitive match against the H2 title.
#                    If omitted, the FIRST pending ([ ]) block for REGISTER
#                    (in file order) is used.
#
# Env:
#   SHAREABLES   path to the queue note
#                (default: ~/Documents/LakuVault/FVH/shareables.md)
#
# Prints the converted message to stdout (for review) and copies it to the
# clipboard. Does NOT flip [ ]→[x]; that stays a deliberate, post-confirmation
# step (done by the skill or by hand).

set -euo pipefail

REGISTER="${1:-layman}"
TOPIC="${2:-}"
SHAREABLES="${SHAREABLES:-$HOME/Documents/LakuVault/FVH/shareables.md}"

if [[ ! -f "$SHAREABLES" ]]; then
    echo "Error: queue note not found: $SHAREABLES" >&2
    exit 1
fi

# Extract the raw markdown body for the requested topic+register block.
body="$(SHAREABLES="$SHAREABLES" REGISTER="$REGISTER" TOPIC="$TOPIC" python3 - <<'PY'
import os, re, sys

path = os.environ["SHAREABLES"]
register = os.environ["REGISTER"].strip().lower()
topic_q = os.environ.get("TOPIC", "").strip().lower()

lines = open(path, encoding="utf-8").read().splitlines()

# Split into topics: an H2 (## , not ###) starts a new topic.
topics = []  # list of (title, [body_lines])
cur = None
for ln in lines:
    if re.match(r"^##\s+(?!#)", ln):
        cur = {"title": ln[2:].strip(), "lines": []}
        topics.append(cur)
    elif cur is not None:
        cur["lines"].append(ln)

def blocks(topic):
    """Yield (status, register_name, [text_lines]) for each H3 register block."""
    tl = topic["lines"]
    i = 0
    while i < len(tl):
        m = re.match(r"^###\s+\[([ xX])\]\s+([A-Za-z-]+)", tl[i])
        if not m:
            i += 1
            continue
        status, name = m.group(1).lower(), m.group(2).strip().lower()
        # find the opening fence
        j = i + 1
        while j < len(tl) and not re.match(r"^```", tl[j]):
            # stop if we hit the next H3 / H2 before any fence
            if re.match(r"^###?\s", tl[j]):
                break
            j += 1
        text = []
        if j < len(tl) and re.match(r"^```", tl[j]):
            j += 1
            while j < len(tl) and not re.match(r"^```", tl[j]):
                text.append(tl[j])
                j += 1
        yield status, name, text
        i = j + 1

# Candidate topics: filter by substring if a query was given.
candidates = topics
if topic_q:
    candidates = [t for t in topics if topic_q in t["title"].lower()]
    if not candidates:
        sys.stderr.write(f"No topic matching '{topic_q}'.\n")
        sys.exit(3)

# When a topic was named, take that register regardless of status.
# When no topic was named, take the first PENDING block for the register.
for t in candidates:
    for status, name, text in blocks(t):
        if name != register:
            continue
        if not topic_q and status != " ":
            continue
        sys.stderr.write(f"→ {t['title']} :: {register}\n")
        sys.stdout.write("\n".join(text).strip() + "\n")
        sys.exit(0)

if topic_q:
    sys.stderr.write(f"Topic matched but no '{register}' block found.\n")
else:
    sys.stderr.write(f"No pending '{register}' block left.\n")
sys.exit(4)
PY
)"

# Convert to Google Chat syntax and copy to clipboard.
converted="$(printf '%s\n' "$body" | google-chat-format 2>/dev/null)"

if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$converted" | pbcopy
elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$converted" | xclip -selection clipboard
elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "$converted" | xsel --clipboard --input
else
    echo "Warning: no clipboard tool (pbcopy/xclip/xsel); printing only." >&2
fi

echo "--- copied to clipboard, ready to paste ---"
printf '%s\n' "$converted"
