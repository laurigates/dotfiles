# https://www.jamesridgway.co.uk/blog/dotfiles-with-github-travis-ci-and-docker
# https://github.com/jamesridgway/dotfiles
FROM alpine:3

RUN apk add zsh git python3

# Create test user and add to sudoers
RUN adduser -D -s /bin/zsh tester

# Add dotfiles and chown
COPY --chown=tester:tester . /home/tester/dotfiles

# Switch testuser
USER tester
ENV HOME /home/tester

# Change working directory
WORKDIR /home/tester/dotfiles
SHELL ["/bin/zsh", "-c"]

# dotbot requires pyyaml
RUN ./install-profile workstation

CMD ["/bin/zsh"]
