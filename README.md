# My Dotfiles

## Installation

[dotbot](https://github.com/anishathalye/dotbot) is used to handle installation of my dotfiles.

```
git clone --recurse-submodules git@github.com:laurigates/dotfiles
```

Basic workstation installation:

```
./install workstation
```

Install a specific configuration:

```
./install rust
```

List available configs:
```
./install --list
```

## macOS quirks

### Jumping between words

You have to disable system level shortcuts for ctrl+left arrow and ctrl+right
arrow to be able to use those shortcuts in zsh.

![MacOS ctrl+arrow shortcuts that have to be disabled](images/macos_ctrlarrow.png)

## Container testing

Build the container image using docker or podman:

```shell
docker build . -t laurigates/dotfiles
podman build . -t laurigates/dotfiles --format docker
```

Run the image:

```shell
docker run --rm -it laurigates/dotfiles:latest
podman run --rm -it laurigates/dotfiles:latest
```

## Debugging PATH

Display everything that happens when starting the shell, run a simple command and filter the output.

```shell
zsh -x -c 'printenv PATH' 2>&1 | rg PATH
```
