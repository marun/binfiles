#!/usr/bin/env bash

# Need to symlink volume mounts, e.g.
#  sudo ln -s /tmp/tel_root/var/run/configmaps /var/run/configmaps
#  sudo ln -s /tmp/tel_root/var/run/secrets /var/run/secrets

# If the cluster is running in aws, add an entry in /etc/hosts for the
# api endpoint. This is necessary because telepresence will proxy dns
# requests to the cluster and will return an internal aws address for
# the api endpoint.

TARGET="${1}"
DEBUG="${2}"

KUBECONFIG=/opt/src/os-installer/auth/kubeconfig telepresence --namespace="${TARGET}" --swap-deployment "${TARGET}" --mount=/tmp/tel_root --run run-cmd.sh "${TARGET}" "${DEBUG}"
