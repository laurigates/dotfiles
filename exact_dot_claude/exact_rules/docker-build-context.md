---
paths:
  - "**/Dockerfile*"
  - "**/*.dockerignore"
  - "**/.dockerignore"
  - "**/docker-compose*.yml"
---

# Docker Build Context & `.dockerignore` Location

A bare `.dockerignore` placed **inside a subdirectory** is never read by
the builder. This silently ships the entire build context (the `.git`
dir, `docs/`, test fixtures, `node_modules/`, large binaries) on every
build — slow uploads, fat layers, and occasionally secrets that should
never have entered the image. The failure is invisible: the build
succeeds, just with a bloated context.

## The rule

For `docker build -f <subdir>/Dockerfile <context>`, BuildKit consults
**exactly two** locations for the ignore file, in this precedence:

1. **`<subdir>/Dockerfile.dockerignore`** — the *per-Dockerfile* form:
   same directory as the Dockerfile, prefixed with the Dockerfile's
   name. Takes precedence when present.
2. **`<context>/.dockerignore`** — a `.dockerignore` at the **root of
   the build context** (usually the repo root, i.e. the `.` argument).

A `.dockerignore` sitting next to the Dockerfile *without* the
Dockerfile-name prefix (e.g. `screenshots/.dockerignore`) is **not**
one of those locations — it is dead.

| You have… | Build is `-f sub/Dockerfile .` | Consulted? |
|---|---|---|
| `.dockerignore` (repo root) | yes | ✅ context-root fallback |
| `sub/Dockerfile.dockerignore` | yes | ✅ per-Dockerfile, wins over root |
| `sub/.dockerignore` (bare, in subdir) | yes | ❌ **never read** |

## Fix

When the Dockerfile lives in a subdirectory and you want a co-located
ignore file, name it `<Dockerfile-name>.dockerignore`:

```
git mv sub/.dockerignore sub/Dockerfile.dockerignore
```

If the Dockerfile is custom-named (`build.Dockerfile`), the ignore file
is `build.Dockerfile.dockerignore`.

Verify it took effect — the context transfer size drops:

```
docker build -f sub/Dockerfile -t img . 2>&1 | grep "transferring context"
```

## When this bites

- A screenshot / CI / tooling image whose Dockerfile lives under
  `screenshots/`, `docker/`, `.ci/`, etc. with a sibling `.dockerignore`.
- Porting a Docker setup between repos by copying the directory verbatim
  — the bare `.dockerignore` rides along and stays dead in the new repo.

## Ref

<https://docs.docker.com/build/concepts/context/> — "A Dockerfile-specific
ignore-file takes precedence over the `.dockerignore` file at the root of
the build context if both exist."
