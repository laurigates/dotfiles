# https://www.jamesridgway.co.uk/blog/dotfiles-with-github-travis-ci-and-docker
# https://github.com/jamesridgway/dotfiles
FROM ubuntu:latest

# OS updates and install
RUN apt-get update -qq && apt-get install -y -qq \
sudo \
language-pack-en \
zsh wget git \
python3 python3-pip \
# ruby build dependencies
libssl-dev libreadline-dev \
&& update-locale

# Could possibly pipe wget to tar instead of saving it to a file
RUN wget https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz && \
tar xaf nvim-linux64.tar.gz --strip-components=1 -C /usr/local

# Create test user and add to sudoers
RUN useradd -m -s /bin/zsh tester && \
usermod -aG sudo tester && \
echo "tester   ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers

# Add dotfiles and chown
COPY --chown=tester:tester . /home/tester/dotfiles

# Switch testuser
USER tester
ENV HOME /home/tester

# Change working directory
WORKDIR /home/tester/dotfiles
SHELL ["/bin/zsh", "-c"]

# dotbot requires pyyaml
RUN pip3 install pyyaml
RUN ./install-profile workstation

CMD ["/bin/zsh"]
