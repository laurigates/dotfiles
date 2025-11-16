# Docker Testing Environment

This directory contains a Docker-based testing environment for validating chezmoi dotfiles installation in a clean Alpine Linux container.

## Quick Start

```bash
# Build and run interactive shell
./docker-test.sh run

# Quick verification test
./docker-test.sh test

# Clean up everything
./docker-test.sh clean
```

## Manual Docker Commands

```bash
# Build the container
docker compose build

# Run interactive shell
docker compose run --rm dotfiles

# Run specific command
docker compose run --rm dotfiles fish -c "chezmoi verify"

# Clean up
docker compose down --rmi all
```

## Container Details

- **Base Image**: Alpine Linux 3
- **Shell**: Fish (with bash also available)
- **User**: `tester` (non-root)
- **Chezmoi**: Latest version from get.chezmoi.io
- **Working Directory**: `/home/tester`

## What Gets Tested

The Dockerfile performs these steps:

1. Installs fish, git, curl, and age
2. Installs latest chezmoi
3. Creates a test user with fish as default shell
4. Initializes chezmoi from the dotfiles source
5. Applies all dotfiles with `chezmoi apply -v`
6. Verifies installation with `chezmoi verify`

## Troubleshooting

### Build fails during chezmoi apply

Check the verbose output to see which file is causing issues. Common problems:

- **Templates requiring data**: Ensure `.chezmoidata.toml` has all required values
- **Platform-specific files**: Check `.chezmoiignore` excludes unsupported files
- **External dependencies**: Some configs may require tools not installed in Alpine

### Shell doesn't start

The container defaults to fish shell. If fish installation fails, you can temporarily change `CMD ["/bin/fish"]` to `CMD ["/bin/bash"]` in the Dockerfile.

### Missing tools

The container includes minimal tools. Add additional packages to the `apk add` line in the Dockerfile:

```dockerfile
RUN apk add --no-cache \
    bash \
    fish \
    git \
    curl \
    shadow \
    age \
    # Add more tools here
    neovim \
    tmux
```

## CI Integration

This Docker setup can be integrated into CI/CD pipelines:

```yaml
# .github/workflows/test-dotfiles.yml
name: Test Dotfiles

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build and test dotfiles
        run: docker compose run --rm dotfiles fish -c "chezmoi verify"
```

## Advanced Usage

### Persistent Testing

Uncomment the volume section in `docker-compose.yml` to persist the home directory between runs:

```yaml
volumes:
  - dotfiles-test-home:/home/tester
```

### Multi-Platform Testing

Test on different architectures:

```bash
# Build for ARM64 (e.g., Apple Silicon)
docker buildx build --platform linux/arm64 -t dotfiles-arm64 .

# Build for AMD64
docker buildx build --platform linux/amd64 -t dotfiles-amd64 .
```

### Interactive Development

Start a container and keep it running for iterative testing:

```bash
docker compose up -d
docker compose exec dotfiles fish
# Make changes, test, repeat
docker compose down
```

## Limitations

- **Alpine-specific**: Uses Alpine Linux, which may behave differently than Ubuntu/macOS
- **Minimal tools**: Only essential tools installed by default
- **No systemd**: Services that require systemd won't work
- **Templates**: Platform-specific templates may not render correctly on Alpine

## See Also

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Alpine Linux Package Search](https://pkgs.alpinelinux.org/)
- Main dotfiles README: `README.md`
