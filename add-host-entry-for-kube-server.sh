#!/usr/bin/env bash

# Add an entry in /etc/hosts for the api endpoint in the configured
# KUBECONFIG (which is assumed to have at most one server).
#
# This supports using telepresence with kube clusters running in
# aws. telepresence will proxy dns requests to the cluster and will
# return an internal aws address for the api endpoint otherwise.

set -o errexit
set -o nounset
set -o pipefail

if [[ "${KUBECONFIG}" == "" ]]; then
  >&2 echo "KUBECONFIG is not set"
  exit 1
fi

SERVER_HOST="$(grep server "${KUBECONFIG}" | sed -e 's+    server: https://\(.*\):6443+\1+')"
SERVER_IP="$(dig "${SERVER_HOST}" +short | head -n 1)"
ENTRY="${SERVER_IP} ${SERVER_HOST}"
if ! grep "${ENTRY}" /etc/hosts > /dev/null; then
  grep -q "${SERVER_HOST}" /etc/hosts && \
    (cp -f /etc/hosts /tmp/etc-hosts && \
    sed -i 's+.*'"${SERVER_HOST}"'$+'"${ENTRY}"'+' /tmp/etc-hosts && \
    sudo cp /tmp/etc-hosts /etc/hosts)\
      || echo "${ENTRY}" | sudo tee -a /etc/hosts
fi
