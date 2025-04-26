# Container Testing

You can test the dotfiles configuration within a container environment.

## Build the Container

Use Docker or Podman:

```bash
# Using Docker
docker build . -t laurigates/dotfiles

# Using Podman
podman build . -t laurigates/dotfiles --format docker
```

## Run the Container

```bash
# Using Docker
docker run --rm -it laurigates/dotfiles:latest

# Using Podman
podman run --rm -it laurigates/dotfiles:latest
```

Inside the container, the dotfiles should be applied, providing the configured Zsh and Neovim environment.
