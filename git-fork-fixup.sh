#!/bin/bash

repo_name=$(basename $(pwd))

git remote rename origin upstream
git remote add origin https://github.com/marun/${repo_name}
git remote set-url --push origin git@github.com:marun/${repo_name}.git
