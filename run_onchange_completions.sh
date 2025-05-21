#!/bin/bash

# Script to generate ZSH completions for various CLI tools
# Places all completion files in ~/.zfunc directory

# Create completion directory if it doesn't exist
mkdir -p ~/.zfunc

# Generate completions for various tools if they are installed
if command -v pipx >/dev/null 2>&1; then
  pipx install argcomplete >/dev/null 2>&1 && register-python-argcomplete pipx > ~/.zfunc/_pipx
fi

if command -v rustup >/dev/null 2>&1; then
  rustup completions zsh cargo > ~/.zfunc/_cargo
  rustup completions zsh > ~/.zfunc/_rustup
fi

if command -v pip >/dev/null 2>&1; then
  pip completion --zsh > ~/.zfunc/_pip
fi

if command -v oc >/dev/null 2>&1; then
  oc completion zsh > ~/.zfunc/_oc
fi

if command -v docker >/dev/null 2>&1; then
  docker completion zsh > ~/.zfunc/_docker
fi

if command -v podman >/dev/null 2>&1; then
  podman completion -f ~/.zfunc/_podman zsh
fi

if command -v rpk >/dev/null 2>&1; then
  rpk generate shell-completion zsh > ~/.zfunc/_rpk
fi

if command -v kubectl >/dev/null 2>&1; then
  kubectl completion zsh > ~/.zfunc/_kubectl
fi

if command -v pdm >/dev/null 2>&1; then
  pdm completion zsh > ~/.zfunc/_pdm
fi

if command -v npm >/dev/null 2>&1; then
  npm completion zsh > ~/.zfunc/_npm
fi

if command -v luarocks >/dev/null 2>&1; then
  luarocks completion zsh > ~/.zfunc/_luarocks
fi

if command -v minikube >/dev/null 2>&1; then
  minikube completion zsh > ~/.zfunc/_minikube
fi

if command -v atuin >/dev/null 2>&1; then
  atuin gen-completions --shell zsh --out-dir ~/.zfunc
fi

if command -v k3d >/dev/null 2>&1; then
  k3d completion zsh > ~/.zfunc/_k3d
fi

if command -v gh >/dev/null 2>&1; then
  gh completion -s zsh > ~/.zfunc/_gh
fi

if command -v argocd >/dev/null 2>&1; then
  argocd completion zsh > ~/.zfunc/_argocd
fi

if command -v rg >/dev/null 2>&1; then
  rg --generate=complete-zsh > ~/.zfunc/_rg
fi

if command -v helm >/dev/null 2>&1; then
  helm completion zsh > ~/.zfunc/_helm
fi

if command -v mise >/dev/null 2>&1; then
  mise completion zsh > ~/.zfunc/_mise
fi

if command -v arduino-cli >/dev/null 2>&1; then
  arduino-cli completion zsh > ~/.zfunc/_arduino-cli
fi

if command -v orbctl >/dev/null 2>&1; then
  orbctl completion zsh > ~/.zfunc/_orbctl
fi

if command -v orb >/dev/null 2>&1; then
  orb completion zsh > ~/.zfunc/_orb
fi

if command -v fd >/dev/null 2>&1; then
  fd --gen-completions > ~/.zfunc/_fd
fi

if command -v aider >/dev/null 2>&1; then
  aider --shell-completions zsh > ~/.zfunc/_aider
fi

echo "ZSH completions have been generated in ~/.zfunc"
