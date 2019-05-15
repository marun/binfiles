#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

id="${1:-}"
remote="${2:-upstream}"

if [[ -z "${id}" ]]; then
  >&2 echo "Usage: $0 pr_id [remote]"
  exit 1
fi

branch="pr/${id}"

git fetch "${remote}" "pull/${id}/head:${branch}"
git checkout "${branch}"
