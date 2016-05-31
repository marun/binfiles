#!/bin/bash

cid=$1
mirror_addr=$2

if [[ -z "${cid}" ]] || [[ -z "${mirror_addr}" ]]; then
    >&2 echo "Usage: $0 [container id] [mirror address]"
    exit 1
fi

docker cp ~/bin/set-fedora-mirror.sh ${cid}:/tmp
docker exec -t ${cid} /tmp/set-fedora-mirror.sh "${mirror_addr}"
