# My Dotfiles

## Overview

This repository contains my personal dotfiles and configurations for setting up a development environment. It leverages [dotbot](https://github.com/anishathalye/dotbot) for installation and management.

## Installation

Clone the repository with submodules:

```bash
git clone --recurse-submodules git@github.com:laurigates/dotfiles
```

### Basic Installation

To install the default workstation configuration:

```bash
./install workstation
```

### Specific Configurations

To install a specific configuration, such as `rust`:

```bash
./install rust
```

### List Available Configurations

To see all available configurations:

```bash
./install --list
```

## zkbd Configuration

Run `zkbd` to configure your keyboard settings.

## macOS Specific Notes

### Key Bindings

To enable moving focus to the next window, configure macOS key bindings accordingly.

### Jumping Between Words

Disable system-level shortcuts for `ctrl+left arrow` and `ctrl+right arrow` to use these shortcuts in `zsh`.

![MacOS ctrl+arrow shortcuts that have to be disabled](images/macos_ctrlarrow.png)

## Container Testing

### Build the Container

Use Docker or Podman to build the container image:

```bash
docker build . -t laurigates/dotfiles
podman build . -t laurigates/dotfiles --format docker
```

### Run the Container

Run the container image:

```bash
docker run --rm -it laurigates/dotfiles:latest
podman run --rm -it laurigates/dotfiles:latest
```

## Debugging

### Debugging PATH

To debug the `PATH` variable, display everything that happens when starting the shell, run a simple command, and filter the output:

```bash
zsh -x -c 'printenv PATH' 2>&1 | rg PATH
```

### Debugging Neovim Configuration

Start Neovim in a clean state:

```bash
nvim --clean -u init.lua
```

Use the following commands to debug Neovim's LSP configuration:

```
:Neoconf lsp
:Neoconf show
```

### Debugging Zsh Completions

To reset and reinitialize Zsh completions:

```bash
rm -f ~/.zcompdump; compinit
```

## Testing

### Verifying Zsh Environment

Ensure the following features work as expected:

- `git <tab>`: Produces colorful FZF completions provided by `fzf-tab`.
- `kubectl <tab>`: Produces monochrome completions.
- `ctrl+r`: Opens FZF history search.
- `alt/option+c`: Opens FZF directory search.
- `ctrl+t`: Opens FZF file search.
- `fzf`: Displays syntax-highlighted previews provided by `bat`.
- `stty -a`: Displays terminal settings.
