#!/bin/bash

repo_name=$(basename $(pwd))

# Fix repos previously configured to name the personal fork origin
if git remote | grep -q upstream; then
  git remote rename origin marun
  git remote rename upstream origin
else
  git remote add marun https://github.com/marun/${repo_name}
  git remote set-url --push marun git@github.com:marun/${repo_name}.git
fi
