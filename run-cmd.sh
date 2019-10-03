#!/usr/bin/env bash

TARGET="${1}"

# Delete the leader election lock to ensure that the local process
# becomes the leader as quickly as possible.
oc delete configmap "${TARGET}-lock" --namespace "${TARGET}"

cd "/opt/src/oso/src/github.com/openshift/cluster-${TARGET}/cmd/cluster-${TARGET}"

#go run main.go operator --config=/var/run/configmaps/config/config.yaml
dlv debug -- operator --config=/var/run/configmaps/config/config.yaml
