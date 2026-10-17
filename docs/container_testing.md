# Container Testing

The `Dockerfile` builds an Ubuntu 24.04 image that mirrors the CI runner:
Homebrew, mise, the `chezmoi` version pinned in `.mise.toml`, `jq` (needed by
`exact_dot_claude/modify_settings.json`) and `pre-commit`. The dotfiles are
copied to `/tmp/dotfiles` and the container's default command,
`scripts/smoke-test-docker.sh`, runs the same lint and `chezmoi apply` stages as
`.github/workflows/smoke.yml`.

## Run the Smoke Test

`docker-compose.yml` defines the services and the `justfile` wraps them:

```bash
just smoke         # Build the image and run lint + build stages
just smoke-lint    # Lint stage only
just smoke-build   # Build stage only (chezmoi apply and zsh startup)
just smoke-shell   # Interactive zsh in the image, for debugging a failure
just smoke-clean   # Remove the containers and image
```

`mise run docker` is equivalent to `just smoke`. Both exit non-zero when the
smoke test fails, so they can gate a commit or a CI step.

The image can also be built and run without Compose (Docker or Podman):

```bash
docker build . -t laurigates/dotfiles
docker run --rm -it laurigates/dotfiles:latest
```

## Limitations

- The apply runs with `--exclude=scripts`, as in CI: the `run_once_` and
  `run_onchange_` scripts install packages and are skipped.
- The container is Linux only. macOS is covered by the `Build (macOS)` job in
  `smoke.yml`.
