# https://www.jamesridgway.co.uk/blog/dotfiles-with-github-travis-ci-and-docker
FROM debian:latest
MAINTAINER Lauri Gates

# OS updates and install
RUN apt-get update -qq
RUN apt-get install -qq -y git sudo zsh python

# Create test user and add to sudoers
RUN useradd -m -s /bin/zsh tester
RUN usermod -aG sudo tester
RUN echo "tester   ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers

# Add dotfiles and chown
COPY . /home/tester/dotfiles
RUN chown -R tester:tester /home/tester

# Switch testuser
USER tester
ENV HOME /home/tester

# Change working directory
WORKDIR /home/tester/dotfiles

# Run setup
RUN ./install

CMD ["/bin/bash"]
