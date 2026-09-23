# Smoke test container matching CI environment
# Reproduces .github/workflows/smoke.yml locally for faster iteration
#
# Usage:
#   make smoke-build   # Build and run full smoke test
#   make smoke-lint    # Run linting only
#   make smoke-shell   # Interactive shell for debugging
#
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    file \
    git \
    locales \
    procps \
    sudo \
    unzip \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Set up locale (required for some tools)
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Create test user with sudo access (matches CI runner user setup)
RUN useradd -m -s /bin/zsh -G sudo tester && \
    echo "tester ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to test user for Homebrew installation
USER tester
ENV HOME=/home/tester
WORKDIR /home/tester

# Install Homebrew (Linux)
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH (must match installer output)
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
RUN brew --version
ENV HOMEBREW_NO_AUTO_UPDATE=1
ENV HOMEBREW_NO_ANALYTICS=1

# Install core tools via Homebrew (matching CI)
RUN brew install neovim

# Install mise at the release the CI workflows pin with jdx/mise-action
# `version:` (tests/test-ci-pins.sh check D); mise.run otherwise installs the
# newest release.
RUN curl https://mise.run | MISE_VERSION=v2026.9.12 sh
ENV PATH="/home/tester/.local/bin:${PATH}"

# chezmoi comes from the .mise.toml pin, as in CI (#418); the shims resolve
# `chezmoi` to the pinned version. The tools-only .mise.toml needs no trust.
# MISE_TRUSTED_CONFIG_PATHS mirrors the environment jdx/mise-action sets for
# the CI workspace.
ENV MISE_TRUSTED_CONFIG_PATHS=/tmp/dotfiles
ENV PATH="/home/tester/.local/share/mise/shims:${PATH}"
COPY --chown=tester:tester .mise.toml /tmp/dotfiles/.mise.toml
RUN mise --cd /tmp/dotfiles install chezmoi

# Install pre-commit for linting stage
RUN brew install pre-commit

# Copy dotfiles source
COPY --chown=tester:tester . /tmp/dotfiles
WORKDIR /tmp/dotfiles

# Default: run full smoke test (lint + build)
CMD ["/tmp/dotfiles/scripts/smoke-test-docker.sh"]
