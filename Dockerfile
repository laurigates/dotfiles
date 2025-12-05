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
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
ENV HOMEBREW_NO_AUTO_UPDATE=1
ENV HOMEBREW_NO_ANALYTICS=1

# Install core tools via Homebrew (matching CI)
RUN brew install chezmoi neovim

# Install mise
RUN curl https://mise.run | sh
ENV PATH="/home/tester/.local/bin:${PATH}"

# Install Python and pre-commit for linting stage
RUN brew install python@3.12
RUN pip3 install --user pre-commit

# Copy dotfiles source
COPY --chown=tester:tester . /tmp/dotfiles
WORKDIR /tmp/dotfiles

# Default: run full smoke test (lint + build)
CMD ["/tmp/dotfiles/scripts/smoke-test-docker.sh"]
