#!/bin/bash

set -e  # Exit on error

echo "Starting Git configuration..."

# Set pull to always rebase instead of merge
git config --global pull.rebase true

# Set the default branch for new repositories to 'main'
git config --global init.defaultBranch main

# Configure LFS filter for cleaning files
git config --global filter.lfs.clean 'git-lfs clean -- %f'

# Configure LFS filter for smudging files
git config --global filter.lfs.smudge 'git-lfs smudge -- %f'

# Configure LFS filter for processing files
git config --global filter.lfs.process 'git-lfs filter-process'

# Make LFS filter required for the repository
git config --global filter.lfs.required true

# Automatically stash changes before rebasing
git config --global rebase.autoStash true

# Automatically squash commits during rebase
git config --global rebase.autosquash true

# Use 'delta' as the pager for viewing diffs and logs
git config --global core.pager delta

# Use 'delta' to filter diffs in interactive mode
git config --global interactive.diffFilter 'delta --color-only'

# Enable navigation between diff sections in 'delta'
git config --global delta.navigate true

# Set 'delta' to use dark theme (suitable for light terminal backgrounds)
git config --global delta.light false

# Use diff3 conflict style for merges
git config --global merge.conflictstyle diff3

# Only allow fast-forward merges
git config --global merge.ff only

# Use zebra coloring for moved code in diffs
git config --global diff.colorMoved zebra

# Use histogram diff algorithm
git config --global diff.algorithm histogram

# Enable reuse recorded resolution of conflicted merges
git config --global rerere.enabled true

# Automatically update rerere database
git config --global rerere.autoupdate true

# Push the current branch by default
git config --global push.default current

# Automatically set up remote for new branches
git config --global push.autoSetupRemote true

# Enable colored output
git config --global color.ui auto

# Use ISO 8601 date format for logs
git config --global log.date iso

# Enable autocorrection for Git commands
git config --global help.autocorrect 20

echo "Git configuration completed successfully!"
