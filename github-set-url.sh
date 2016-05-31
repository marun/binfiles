#!/bin/bash

repo_name=$(basename $(pwd))

git remote set-url --push origin git@github.com:marun/${repo_name}.git
