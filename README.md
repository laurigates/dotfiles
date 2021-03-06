# My Dotfiles

## Installation

I use [dotbot](https://github.com/anishathalye/dotbot) to handle installation of my dotfiles.
I have configured the more advanced setup described on the
[Tips and Tricks](https://github.com/anishathalye/dotbot/wiki/Tips-and-Tricks#more-advanced-setup)
page in the dotbot wiki.

For a basic workstation installation

```
./install-profile workstation
```

To install a specific configuration

```
./install-standalone rust
```

## Node & Ruby executables

Remember to run `rbenv rehash` and `nodenv rehash` after installing packages in
either environment. Otherwise the shell and vim won't find the new binaries.

## Docker testing

Build a docker image to test installation of the dotfiles

```shell
docker build -t laurigates/dotfiles .
```

Run the docker image

```shell
docker run --rm -it laurigates/dotfiles:latest
```
