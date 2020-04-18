#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Rewrite the origin fetch url for ssh push

PUSH_URL="$(git remote -v | grep fetch | awk '{print $2}' | sed -e 's+https://github.com/+git@github.com:+')"
git remote set-url --push origin "${PUSH_URL}"
