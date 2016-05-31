#!/bin/bash

set -ex

TARGET_PATH=$1

if [ -z "${TARGET_PATH}" ]; then
    >&2 echo "Usage: $0 {target_path}"
    exit 1
fi

find "${TARGET_PATH}" -type d -exec sudo chmod g+s {} \;
sudo chmod -R g+w "${TARGET_PATH}"
