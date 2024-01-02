# My Dotfiles

## Installation

I use [dotbot](https://github.com/anishathalye/dotbot) to handle installation of my dotfiles.
I have configured the more advanced setup described on the
[Tips and Tricks](https://github.com/anishathalye/dotbot/wiki/Tips-and-Tricks#more-advanced-setup)
page in the dotbot wiki.

```
git clone --recurse-submodules git@github.com:laurigates/dotfiles
```

For a basic workstation installation

```
./install-profile workstation
```

To install a specific configuration

```
./install-standalone rust
```

## macOS quirks

### Jumping between words

You have to disable system level shortcuts for ctrl+left arrow and ctrl+right
arrow to be able to use those shortcuts in zsh.

![MacOS ctrl+arrow shortcuts that have to be disabled](images/macos_ctrlarrow.png)

## Docker testing

Build a docker image to test installation of the dotfiles

```shell
docker build -t laurigates/dotfiles .
```

Run the docker image

```shell
docker run --rm -it laurigates/dotfiles:latest
```

## Debugging PATH

Display everything that happens when starting the shell, run a simple command and filter the output.

```shell
zsh -x -c 'printenv PATH' 2>&1 | rg PATH
```
