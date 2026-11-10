#!/usr/bin/env bash
# Regression test: scripts/downloads-tidy.sh buckets ~/Downloads entries the way
# its header promises, and never prints file content.
#
# What is being protected
# ------------------------
# - Secrets are hard-deleted, never moved to Trash, and only outside working
#   hours: a key in the Trash is still a key on disk.
# - A key renamed to .txt is still caught (PEM label tier), and a document
#   that merely quotes a key (gitleaks tier) is reported, never deleted.
# - A young secret is left alone so a download mid-import is not yanked.
# - Output carries paths and buckets only, no key material.
#
# How
# ---
# A scratch Downloads under $TMPDIR (not Spotlight-indexed, so age falls back
# to birth time, which `touch -t` to an older date moves back too). Fixture
# keys are generated at run time, so the repo never holds one. The clock is
# faked with TIDY_HOUR/TIDY_DOW and Trash with TIDY_TRASH_DIR.
#
# Usage: tests/test-downloads-tidy.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
TIDY="$REPO_DIR/scripts/executable_downloads-tidy.sh"

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; NC=$'\033[0m'
failures=0
pass() { echo "${GREEN}✓${NC} $1"; }
fail() { echo "${RED}✗${NC} $1"; failures=$((failures + 1)); }

[ "$(uname -s)" = Darwin ] || { echo "skip: downloads-tidy is macOS-only"; exit 0; }
for t in gitleaks openssl jq; do
    command -v "$t" >/dev/null 2>&1 || { echo "skip: $t not installed"; exit 0; }
done
[ -f "$TIDY" ] || { fail "downloads-tidy.sh not found at $TIDY"; exit 1; }

fx=$(mktemp -d) || { echo 'mktemp failed' >&2; exit 1; }
if [ -z "$fx" ] || [ ! -d "$fx" ]; then echo 'bad sandbox dir' >&2; exit 1; fi
trap 'rm -rf "$fx"' EXIT

dl="$fx/Downloads"
mkdir -p "$dl" "$fx/state" "$fx/trash"

openssl genrsa -out "$dl/app.2026-01-01.private-key.pem" 2048 2>/dev/null
cp "$dl/app.2026-01-01.private-key.pem" "$dl/blob.txt"
{ echo "# setup notes"; echo; cat "$dl/app.2026-01-01.private-key.pem"; } > "$dl/notes.md"
openssl req -x509 -key "$dl/app.2026-01-01.private-key.pem" -subj /CN=t -days 1 -out "$dl/chain.pem" 2>/dev/null
openssl genrsa -out "$dl/fresh.private-key.pem" 2048 2>/dev/null
key_line=$(sed -n 2p "$dl/app.2026-01-01.private-key.pem")

cp "$dl/app.2026-01-01.private-key.pem" "$dl/tls.key"
# Keynote's .key is a zip package; it must never hit the rm'd secret bucket.
mkdir -p "$fx/kn" && echo slide > "$fx/kn/index.apxl" && (cd "$fx/kn" && zip -q "$dl/Deck.key" index.apxl)
# Let's Encrypt naming: no member name says "private key", only the PEM label does.
mkdir -p "$fx/le" && cp "$dl/app.2026-01-01.private-key.pem" "$fx/le/privkey.pem" && cp "$dl/chain.pem" "$fx/le/fullchain.pem"
(cd "$fx/le" && zip -q "$dl/le-bundle.zip" privkey.pem fullchain.pem)
(cd "$fx/le" && zip -q "$dl/certs-only.zip" fullchain.pem)

echo installer > "$dl/setup.dmg"
echo same > "$dl/report.md"; echo same > "$dl/report (1).md"
echo a > "$dl/other.md"; echo b > "$dl/other (1).md"
mkdir -p "$dl/bundle"; echo x > "$dl/bundle/a.txt"
(cd "$dl" && zip -qr bundle.zip bundle)
: > "$dl/empty.txt"
echo pdf > "$dl/Invoice-0001.pdf"
printf '# comment\nInvoice-*.pdf\t%s\n' "$fx/routed" > "$fx/routes.tsv"

# Everything but fresh.private-key.pem is three days old.
find "$dl" -mindepth 1 ! -name 'fresh.private-key.pem' -exec touch -t "$(date -v-3d +%Y%m%d%H%M)" {} +

run() { # $1 hour, rest: extra args
    local h="$1"; shift
    env XDG_STATE_HOME="$fx/state" TIDY_HOUR="$h" TIDY_DOW=3 TIDY_TRASH_DIR="$fx/trash" \
        bash "$TIDY" --root "$dl" --routes "$fx/routes.tsv" "$@" 2>&1
}
line() { grep "path=$dl/$2\( dest=.*\)\{0,1\}\$" <<<"$1"; }
expect() { # output name bucket status
    local l; l=$(line "$1" "$2")
    if grep -q "bucket=$3 .*status=$4 " <<<"$l"; then pass "$2 -> $3/$4"
    else fail "$2: want bucket=$3 status=$4, got: ${l:-nothing}"; fi
}

work=$(run 10)
expect "$work" "app.2026-01-01.private-key.pem" secret skipped:working-hours
expect "$work" "chain.pem" cert skipped:working-hours
expect "$work" "setup.dmg" installer planned

eve=$(run 20)
expect "$eve" "app.2026-01-01.private-key.pem" secret planned
expect "$eve" "blob.txt" secret planned
expect "$eve" "notes.md" secret-suspect report
expect "$eve" "chain.pem" cert planned
expect "$eve" "fresh.private-key.pem" secret skipped:too-young
expect "$eve" "report (1).md" redundant planned
expect "$eve" "other (1).md" unrouted report
expect "$eve" "bundle.zip" redundant planned
expect "$eve" "empty.txt" junk planned
expect "$eve" "Invoice-0001.pdf" route planned
expect "$eve" "tls.key" secret planned
expect "$eve" "Deck.key" unrouted report
expect "$eve" "le-bundle.zip" secret planned
expect "$eve" "certs-only.zip" cert planned

if grep -q -- '-----BEGIN' <<<"$eve$work" || grep -qF -- "$key_line" <<<"$eve$work"; then
    fail "output contains key material"
else
    pass "output contains no key material"
fi

applied=$(run 20 --apply)
rc=$?
if [ "$rc" -eq 0 ]; then pass "--apply exits 0"; else fail "--apply exited $rc: $(tail -n 3 <<<"$applied")"; fi
if [ ! -e "$dl/app.2026-01-01.private-key.pem" ] && [ ! -e "$fx/trash/app.2026-01-01.private-key.pem" ]; then
    pass "secret hard-deleted, not in Trash"
else
    fail "secret still on disk (Downloads or Trash)"
fi
if [ -e "$fx/trash/setup.dmg" ]; then pass "installer moved to Trash"; else fail "installer not in Trash"; fi
if [ -e "$dl/notes.md" ]; then pass "gitleaks-only hit left in place"; else fail "notes.md was removed"; fi
if [ -e "$dl/fresh.private-key.pem" ]; then pass "young secret left in place"; else fail "young secret removed"; fi
if [ -e "$dl/other (1).md" ]; then pass "differing (1) copy kept"; else fail "differing copy removed"; fi
if [ -e "$fx/routed/Invoice-0001.pdf" ]; then pass "route moved file"; else fail "route did not move file"; fi
if [ -s "$fx/state/downloads-tidy/log.tsv" ]; then pass "action log written"; else fail "no action log"; fi

[ "$failures" -eq 0 ] || { echo "${RED}$failures failure(s)${NC}"; exit 1; }
echo "${GREEN}all passed${NC}"
