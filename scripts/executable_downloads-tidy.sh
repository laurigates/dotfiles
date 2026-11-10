#!/usr/bin/env bash
# downloads-tidy.sh — deterministic ~/Downloads cleanup that never prints file content.
#
# Every top-level entry gets exactly one bucket, decided by the first rule that
# matches. Rules escalate through content-free inspection tiers and stop at the
# first tier that decides:
#
#   T0 name/extension/size   *.private-key.pem, *.dmg, "X (1).pdf", zero bytes
#   T1 PEM header labels     "PRIVATE KEY" vs "CERTIFICATE" (label only)
#   T2 archive member names  zip of certs, zip holding an .app, already-extracted
#   T3 gitleaks              --redact=100, JSON report to a temp file, only the
#                            finding's top-level path is read back, report deleted
#
# Buckets, in precedence order:
#
#   secret          key/p12/recovery-code by name, or a PEM private-key label
#                   -> rm (never Trash), outside working hours, >= 2 h old
#   cert            .crt/.cer/.der, cert-only PEM, zip of only certs
#                   -> Trash, outside working hours, >= 2 h old
#   secret-suspect  gitleaks hit on anything not decided above (a doc quoting a
#                   key, a project dir) -> report only; a false positive here
#                   must never hard-delete a document
#   installer       .dmg/.pkg/.mcpb/..., .app bundles, zips holding an .app/.exe
#   redundant       "X (N).ext" byte-identical to X; an archive whose every
#                   member already exists extracted next to it
#   junk            zero-byte files, stale partial downloads
#   route           first matching glob in routes.tsv -> mv to its directory;
#                   destination `keep` leaves it in place, out of the report
#                   (the only route that applies to directories)
#   unrouted        everything else -> report only
#
# installer/redundant/junk -> Trash once >= 24 h old, any time of day.
#
# Age is Spotlight's kMDItemDateAdded (when the file arrived in this folder),
# falling back to birth time. mtime is useless here: browsers keep the server's
# Last-Modified, so a fresh download can carry a 10-year-old mtime.
#
# DRY-RUN BY DEFAULT. --apply acts. Emits `TIDY …` lines and a KEY=VALUE rollup;
# with --apply each action is appended to $XDG_STATE_HOME/downloads-tidy/log.tsv.
#
# Backs `just -g downloads-tidy-dry` / `downloads-tidy` and the
# com.lgates.downloads-tidy LaunchAgent. Sibling of reclaim.sh / home-audit.sh
# (home-audit excludes Downloads as its own scope; this is that scope).
#
# Test seams (tests/test-downloads-tidy.sh): TIDY_HOUR, TIDY_DOW (1=Mon..7=Sun)
# fake the clock; TIDY_TRASH_DIR replaces /usr/bin/trash with a mv.
set -euo pipefail

root="$HOME/Downloads"
apply=0
ignore_window=0
notify=0
routes="${XDG_CONFIG_HOME:-$HOME/.config}/downloads-tidy/routes.tsv"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/downloads-tidy"

SECRET_MIN_AGE_H="${TIDY_SECRET_MIN_AGE_H:-2}"
OTHER_MIN_AGE_H="${TIDY_MIN_AGE_H:-24}"
WORK_START="${TIDY_WORK_START:-8}"
WORK_END="${TIDY_WORK_END:-18}"

usage() {
    echo "usage: downloads-tidy.sh [--apply] [--root DIR] [--routes FILE] [--ignore-window] [--notify]"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --apply) apply=1; shift ;;
        --root) root="$2"; shift 2 ;;
        --routes) routes="$2"; shift 2 ;;
        --ignore-window) ignore_window=1; shift ;;
        --notify) notify=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "downloads-tidy.sh: unknown arg: $1" >&2; usage >&2; exit 2 ;;
    esac
done

# mdls, /usr/bin/trash, BSD stat and bsdtar are macOS-only.
[ "$(uname -s)" = Darwin ] || { echo "downloads-tidy.sh: macOS only, refusing" >&2; exit 1; }
[ -d "$root" ] || { echo "downloads-tidy.sh: no such dir: $root" >&2; exit 1; }
for t in gitleaks jq unzip tar cmp mdls; do
    command -v "$t" >/dev/null 2>&1 || { echo "downloads-tidy.sh: missing tool: $t" >&2; exit 1; }
done

shopt -s nocasematch

now=$(date +%s)
hour=$((10#${TIDY_HOUR:-$(date +%H)}))
dow="${TIDY_DOW:-$(date +%u)}"
offhours=0
if [ "$dow" -ge 6 ] || [ "$hour" -lt "$WORK_START" ] || [ "$hour" -ge "$WORK_END" ]; then
    offhours=1
fi
[ "$ignore_window" -eq 1 ] && offhours=1

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# --- T3: gitleaks, content never leaves the temp report ----------------------
# --exit-code 3 separates "leaks found" from errors, which also exit 1.
gl_rc=0
gitleaks dir --no-banner --redact=100 --max-target-megabytes 20 --max-archive-depth 3 \
    --exit-code 3 -l error -f json -r "$tmp/gl.json" "$root" >/dev/null 2>&1 || gl_rc=$?
if [ "$gl_rc" -ne 0 ] && [ "$gl_rc" -ne 3 ]; then
    echo "downloads-tidy.sh: gitleaks failed (exit $gl_rc)" >&2; exit 1
fi
jq -e 'type == "array"' "$tmp/gl.json" >/dev/null || { echo "downloads-tidy.sh: unreadable gitleaks report" >&2; exit 1; }
# Top-level entry of each finding. Archive members are reported as "a.zip!member".
jq -r '.[].File' "$tmp/gl.json" | while IFS= read -r f; do
    rel="${f#"$root"/}"; rel="${rel%%/*}"; echo "${rel%%!*}"
done | sort -u > "$tmp/gl_hits"
rm -f "$tmp/gl.json"

gl_hit() { grep -Fxq -- "$1" "$tmp/gl_hits"; }

# --- helpers -----------------------------------------------------------------
age_h() {
    local p="$1" added ts=""
    added=$(mdls -raw -name kMDItemDateAdded "$p" 2>/dev/null || true)
    if [ -n "$added" ] && [ "$added" != "(null)" ]; then
        ts=$(date -j -f '%Y-%m-%d %H:%M:%S %z' "$added" +%s 2>/dev/null || true)
    fi
    [ -n "$ts" ] || ts=$(stat -f %B "$p")
    echo $(( (now - ts) / 3600 ))
}

has_private_key_label() { grep -aqE '^-----BEGIN ([A-Z0-9]+ )*PRIVATE KEY-----' "$1"; }
has_cert_label() { grep -aqE '^-----BEGIN CERTIFICATE-----' "$1"; }

# Member names only; directories, AppleDouble and __MACOSX noise dropped.
members() {
    case "$1" in
        *.zip) unzip -Z1 "$1" 2>/dev/null ;;
        *.tar|*.tar.gz|*.tgz) tar -tf "$1" 2>/dev/null ;;
    esac | grep -vE '(/$|^__MACOSX/|(^|/)\._)' || true
}

crypto_re='\.(pem|crt|cer|der|key|p12|pfx|p7b)$'
key_member_re='(\.(key|p12|pfx)|private-key\.pem)$'
installer_member_re='(\.app/|\.(exe|msi|pkg|mpkg|dmg)$)'

# PEM label of .pem/.key members, piped straight into grep and never printed.
# Catches privkey.pem / server.pem, which no member-name rule recognises. The
# `|| true` keeps unzip's SIGPIPE (grep -q exits early) from failing pipefail.
zip_has_private_key() {
    { unzip -C -p "$1" '*.pem' '*.key' 2>/dev/null || true; } |
        grep -aqE '^-----BEGIN ([A-Z0-9]+ )*PRIVATE KEY-----'
}

archive_all_extracted() {
    local a="$1" stem name m n=0
    name=$(basename "$a")
    stem="${name%.zip}"; stem="${stem%.tar.gz}"; stem="${stem%.tgz}"; stem="${stem%.tar}"
    while IFS= read -r m; do
        n=$((n + 1))
        [ -e "$root/$m" ] || [ -e "$root/$stem/$m" ] || return 1
    done < <(members "$a")
    [ "$n" -gt 0 ]
}

route_for() {
    local name="$1" glob dest
    [ -f "$routes" ] || return 1
    while IFS=$'\t' read -r glob dest; do
        case "$glob" in ''|\#*) continue ;; esac
        # shellcheck disable=SC2053  # unquoted on purpose: glob match
        if [[ "$name" == $glob ]]; then echo "${dest/#\~/$HOME}"; return 0; fi
    done < "$routes"
    return 1
}

# Sets bucket/action/window/min_age/dest for one top-level entry.
classify() {
    local name="$1" p="$root/$1" ext size m
    dest=""; window=any; min_age="$OTHER_MIN_AGE_H"

    if [ -d "$p" ]; then
        if [[ "$name" == *.app ]]; then bucket=installer; action=trash
        elif dest=$(route_for "$name") && [ "$dest" = keep ]; then dest=""; bucket=kept; action=keep
        elif gl_hit "$name"; then bucket=secret-suspect; action=report
        else bucket=unrouted; action=report; fi
        return
    fi

    ext=""; [[ "$name" == *.* ]] && ext="${name##*.}"
    size=$(stat -f %z "$p")

    # T0 secret by name
    case "$name" in
        *.private-key.pem|*.p12|*.pfx|*.jks|*.keystore|*.ppk|id_rsa*|id_ecdsa*|id_ed25519*|*recovery*code*|*backup*code*)
            bucket=secret; action="rm"; window=off; min_age="$SECRET_MIN_AGE_H"; return ;;
    esac
    # T1 PEM labels on small crypto-ish text files. .key is decided here, not by
    # name: it is also Apple Keynote's extension (a zip package, no PEM label).
    if [[ "$ext" =~ ^(pem|crt|cer|txt|key)$ ]] && [ "$size" -lt 1048576 ]; then
        if has_private_key_label "$p"; then
            bucket=secret; action="rm"; window=off; min_age="$SECRET_MIN_AGE_H"; return
        fi
        if [[ "$ext" == pem ]] && has_cert_label "$p"; then
            bucket=cert; action=trash; window=off; min_age="$SECRET_MIN_AGE_H"; return
        fi
    fi
    if [[ "$ext" =~ ^(crt|cer|der|p7b|p7c)$ ]]; then
        bucket=cert; action=trash; window=off; min_age="$SECRET_MIN_AGE_H"; return
    fi
    # T2 zip of nothing but certs/keys
    if [[ "$ext" == zip ]]; then
        m=$(members "$p")
        if [ -n "$m" ] && ! grep -viqE "$crypto_re" <<<"$m"; then
            if grep -iqE "$key_member_re" <<<"$m" || zip_has_private_key "$p"; then bucket=secret; action="rm"
            else bucket=cert; action=trash; fi
            window=off; min_age="$SECRET_MIN_AGE_H"; return
        fi
    fi
    # T3 gitleaks hit on anything else: report, never delete
    if gl_hit "$name"; then bucket=secret-suspect; action=report; return; fi

    # installers
    if [[ "$ext" =~ ^(dmg|pkg|mpkg|msi|exe|mcpb|appimage|deb|rpm)$ ]]; then
        bucket=installer; action=trash; return
    fi
    if [[ "$ext" == zip ]] && members "$p" | grep -iqE "$installer_member_re"; then
        bucket=installer; action=trash; return
    fi

    # redundant copies
    local dup_re='^(.*) \(([0-9]+)\)(\.[^.]+)?$'
    if [[ "$name" =~ $dup_re ]]; then
        local orig="${BASH_REMATCH[1]}${BASH_REMATCH[3]}"
        if [ -f "$root/$orig" ] && cmp -s "$p" "$root/$orig"; then
            bucket=redundant; action=trash; return
        fi
    fi
    if [[ "$name" =~ \.(zip|tar|tar\.gz|tgz)$ ]] && archive_all_extracted "$p"; then
        bucket=redundant; action=trash; return
    fi

    # junk
    if [ "$size" -eq 0 ] || [[ "$ext" =~ ^(crdownload|download|part|partial)$ ]]; then
        bucket=junk; action=trash; return
    fi

    if dest=$(route_for "$name"); then
        # Destination "keep": Lauri maintains it in place; not reported daily.
        if [ "$dest" = keep ]; then dest=""; bucket=kept; action=keep
        else bucket=route; action=move; fi
        return
    fi

    bucket=unrouted; action=report
}

do_trash() {
    if [ -n "${TIDY_TRASH_DIR:-}" ]; then mkdir -p "$TIDY_TRASH_DIR" && mv "$1" "$TIDY_TRASH_DIR/"
    else /usr/bin/trash "$1"; fi
}

perform() {
    local p="$1"
    case "$action" in
        rm) rm -f -- "$p" ;;
        trash) do_trash "$p" ;;
        move)
            mkdir -p "$dest"
            [ ! -e "$dest/$(basename "$p")" ] || return 3
            mv -n -- "$p" "$dest/" ;;
    esac
}

# --- main loop ---------------------------------------------------------------
n_done=0 n_planned=0 n_skipped=0 n_report=0 n_failed=0 n_kept=0
[ "$apply" -eq 1 ] && mkdir -p "$state_dir"

while IFS= read -r -d '' p; do
    name="${p#"$root"/}"
    classify "$name"
    age=$(age_h "$p")
    if [ "$action" = keep ]; then
        n_kept=$((n_kept + 1)); continue
    elif [ "$action" = report ]; then
        status=report; n_report=$((n_report + 1))
    elif [ "$window" = off ] && [ "$offhours" -eq 0 ]; then
        status=skipped:working-hours; n_skipped=$((n_skipped + 1))
    elif [ "$age" -lt "$min_age" ]; then
        status=skipped:too-young; n_skipped=$((n_skipped + 1))
    elif [ "$apply" -eq 0 ]; then
        status=planned; n_planned=$((n_planned + 1))
    elif perform "$p"; then
        status="done"; n_done=$((n_done + 1))
    else
        rc=$?
        if [ "$rc" -eq 3 ]; then status=skipped:dest-exists; n_skipped=$((n_skipped + 1))
        else status=failed; n_failed=$((n_failed + 1)); fi
    fi
    printf 'TIDY bucket=%s action=%s status=%s age_h=%s path=%s%s\n' \
        "$bucket" "$action" "$status" "$age" "$p" "${dest:+ dest=$dest}"
    if [ "$apply" -eq 1 ] && [ "$action" != report ]; then
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$bucket" "$action" "$status" "$p" "$dest" \
            >> "$state_dir/log.tsv"
    fi
done < <(find "$root" -mindepth 1 -maxdepth 1 ! -name '.*' -print0 | sort -z)

echo "TIDY_APPLY=$apply"
echo "TIDY_OFFHOURS=$offhours"
echo "TIDY_DONE=$n_done"
echo "TIDY_PLANNED=$n_planned"
echo "TIDY_SKIPPED=$n_skipped"
echo "TIDY_REPORT=$n_report"
echo "TIDY_KEPT=$n_kept"
echo "TIDY_FAILED=$n_failed"

if [ "$notify" -eq 1 ]; then
    msg="$n_done handled, $n_report to review, $n_failed failed"
    # kitten notify is in-band (needs a kitty tty); launchd has none.
    if [ -t 1 ] && command -v kitten >/dev/null 2>&1; then
        kitten notify "Downloads tidy" "$msg" || true
    else
        osascript -e "display notification \"$msg\" with title \"Downloads tidy\"" || true
    fi
fi

[ "$n_failed" -eq 0 ]
