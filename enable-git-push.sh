#!/usr/bin/env bash

# Set an ssh push url for a personal github repo

set -o errexit
set -o nounset
set -o pipefail


REPO_URL="$(git remote -v  | grep origin | grep push | awk '{print $2}')"
if [[ "${REPO_URL}" = git* ]]; then
  >&2 echo "origin remote is already set to an ssh push url"
  exit 1
fi

REPO="$(echo "${REPO_URL}" | sed -e 's+https://github.com/++')"
git remote set-url --push origin "git@github.com:${REPO}"
