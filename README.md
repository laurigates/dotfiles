# My Dotfiles

## Overview

This repository contains my personal dotfiles, managed using [chezmoi](https://www.chezmoi.io/). It sets up my development environment, including configurations for Zsh, Neovim, Git, and various development tools. Tool versions are managed using [mise-en-place](https://mise.jdx.dev/).

## Installation

1.  **Install chezmoi:** Follow the instructions on the [chezmoi installation guide](https://www.chezmoi.io/install/).
2.  **Initialize chezmoi with this repository:**
    ```bash
    chezmoi init https://github.com/laurigates/dotfiles.git
    ```
3.  **Review the changes:** Check which files chezmoi plans to create or modify.
    ```bash
    chezmoi diff
    ```
4.  **Apply the changes:**
    ```bash
    chezmoi apply -v
    ```

## Tool Management with mise-en-place

This setup uses [mise-en-place](https://mise.jdx.dev/) (formerly `rtx`) to manage development tool versions (like Node.js, Python, Go, etc.).

-   Tool versions are defined in the `.config/mise/config.toml` file (managed by chezmoi).
-   After cloning or updating the dotfiles, run `mise install` in your shell to install the specified tool versions.
-   `mise` automatically activates the correct tool versions when you enter a directory containing a `mise.toml` or `.tool-versions` file.

## Further Documentation

## Components Overview

For a detailed breakdown of the tools and components managed by these dotfiles (like chezmoi, mise, Zsh plugins, Neovim setup, etc.), see:

-   [Components and Workflow Tools](./docs/components.md)

## Further Documentation

For more specific guides, see the following documents:

-   [Platform Specific Notes](./docs/platform_specific.md)
-   [Container Testing](./docs/container_testing.md)
-   [Debugging Guide](./docs/debugging.md)
-   [Verifying Environment Setup](./docs/verifying_environment.md)
