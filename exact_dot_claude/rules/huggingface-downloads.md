# Hugging Face Downloads

Redirect HF caches to the same disk as the destination. `--local-dir` only
covers the **final** file; HF still writes intermediate transfer state to
`~/.cache/huggingface/{hub,xet}` regardless. For multi-GB downloads, that
intermediate state is on the order of the file size — easily fills root.

## The trap

```sh
hf download <repo> <file> --local-dir /big/disk/staging
```

Final file lands on `/big/disk/`. Hub manifest and **xet transfer chunks**
land in `~/.cache/huggingface/xet/`. Xet is HF's newer transfer protocol —
it stages compressed blocks under `~/.cache` while reconstructing the file,
and the staged blocks are roughly file-sized. Symptom on a small root:

```
OSError: I/O error: IO Error: No space left on device (os error 28)
```

## Fix

`HF_HOME` is the umbrella. Setting it relocates both `HF_HUB_CACHE`
(`$HF_HOME/hub`) and `HF_XET_CACHE` (`$HF_HOME/xet`) automatically:

```sh
HF_HOME=/big/disk/hf-cache hf download <repo> <file> --local-dir /big/disk/staging
```

Persist for a session by exporting in `.zshrc`, `~/.api_tokens` (mise
auto-sources), or a per-project `.envrc` (direnv). Project-specific override
in CLAUDE.md when one machine has a small root and a big data disk:

```sh
# Pop!_OS / Ubuntu, root on a small SSD:
export HF_HOME=/mnt/big-disk/hf-cache
```

## Two-stage download pattern

```sh
mkdir -p /big/disk/staging /big/disk/hf-cache
HF_HOME=/big/disk/hf-cache hf download <repo> <path/in/repo> \
  --local-dir /big/disk/staging
mv /big/disk/staging/<path/in/repo> /destination/
rm -rf /big/disk/staging
```

The staging step avoids HF replicating the repo's directory structure under
the final destination — `hf download` preserves repo paths under
`--local-dir`, which is rarely what you want.

## Don't stage on /tmp

`/tmp` is sometimes tmpfs (RAM-backed) and on Linux installs that put `/`
on a small SSD it's a fast way to fill root. Always stage on a disk you've
verified with `df -h`. The Claude Code harness writes Bash output files to
`/tmp/claude-<uid>/`, so a full `/tmp` stops Bash entirely (see
`disk-full-recovery.md`).

## Pre-download size check

For very large files, HEAD-check the download URL before committing:

```sh
.venv/bin/python -c "
from huggingface_hub import hf_hub_url
import urllib.request
url = hf_hub_url('<repo>', '<file>')
with urllib.request.urlopen(urllib.request.Request(url, method='HEAD')) as r:
    print(f'{int(r.headers.get(\"Content-Length\", 0))/1e9:.2f} GB')
"
```

Then check the destination disk's free space matches at least 2× that
(staging + final), or 1× if `HF_HOME` is on the destination disk itself.

## Background downloads

Multi-GB downloads should run via Bash `run_in_background: true`. The
harness will notify on completion; do not poll. After completion, the agent
moves staged files into place, removes the staging dir, and verifies sizes
with `stat -c '%s'` against the HEAD-reported `Content-Length`.

`hf download` exit code 1 with the actual `.safetensors` files at full size
on disk usually means the **post-download cache cleanup** ran out of root
disk, not that the transfer itself failed. Verify file sizes before
re-downloading.
