#!/usr/bin/env bash

TARGET="${1}"
DEBUG="${2}"

# Delete the leader election lock to ensure that the local process
# becomes the leader as quickly as possible.
oc delete configmap "${TARGET}-lock" --namespace "${TARGET}" --ignore-not-found=true

cd "/opt/src/os/src/github.com/openshift/cluster-${TARGET}/cmd/cluster-${TARGET}"

if [[ "${DEBUG}" ]]; then
  dlv debug -- operator --config=/var/run/configmaps/config/config.yaml
else
  go run main.go operator --config=/var/run/configmaps/config/config.yaml
fi
