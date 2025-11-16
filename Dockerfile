# Dotfiles testing container with chezmoi
# Based on: https://www.jamesridgway.co.uk/blog/dotfiles-with-github-travis-ci-and-docker
FROM alpine:3

# Install base dependencies
RUN apk add --no-cache \
    bash \
    fish \
    git \
    curl \
    shadow \
    age

# Install chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# Create test user with fish as default shell
RUN adduser -D -s /bin/fish tester

# Switch to test user
USER tester
ENV HOME /home/tester
WORKDIR /home/tester

# Initialize chezmoi with the dotfiles
COPY --chown=tester:tester . /tmp/dotfiles
RUN chezmoi init --source=/tmp/dotfiles

# Apply dotfiles (with verbose output for debugging)
RUN chezmoi apply -v

# Verify installation
RUN chezmoi verify || true

# Set working directory to home
WORKDIR /home/tester

CMD ["/bin/fish"]
