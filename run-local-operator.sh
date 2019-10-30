#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# This script executes telepresence against an operator deployment.
#
# Invoke in the directory of the binary to debug
# (e.g. my-operator/cmd/my-operator-command) and provide the path to
# the operator's deployment manifest:
#
# KUBECONFIG=... run-local-operator.sh ../../manifests/05_deploy.yaml
#
# Dependencies:
#
# - KUBECONFIG needs to be set
# - oc
# - yq (pip install yq)
# - jq (dnf install jq)
# - telepresence (https://www.telepresence.io/reference/install)
# - delve (https://github.com/go-delve/delve)

KUBECONFIG="${KUBECONFIG:-}"
if [[ "${KUBECONFIG}" == "" ]]; then
  >&2 echo "KUBECONFIG is not set"
  exit 1
fi

DEPLOYMENT_YAML="${1-}"
if [[ ! "${DEPLOYMENT_YAML}" ]]; then
  >&2 echo "usage: $0 </path/to/operator/deployment.yaml>"
  exit 1
fi

YQ_ARGS="${DEPLOYMENT_YAML} -r"
RUN_CMD="${2-}"
DEBUG=

NAMESPACE="$(yq '.metadata.namespace' ${YQ_ARGS})"
NAME="$(yq '.metadata.name' ${YQ_ARGS})"

if [ "${RUN_CMD}" ]; then
  # Delete the leader election lock to ensure that the local process
  # becomes the leader as quickly as possible.
  LOCK_CONFIGMAP="${NAME}-lock"
  oc delete configmap "${LOCK_CONFIGMAP}" --namespace "${NAMESPACE}" --ignore-not-found=true

  CMD="$(yq '.spec.template.spec.containers[0].command[1:] | join(" ")' ${YQ_ARGS})"
  ARGS="$(yq '.spec.template.spec.containers[0].args | join(" ")' ${YQ_ARGS})"

  if [[ "${DEBUG}" ]]; then
    dlv debug -- ${CMD} ${ARGS}
  else
    go run ${CMD} ${ARGS}
  fi
else
  # Add an entry in /etc/hosts for the api endpoint in the configured
  # KUBECONFIG (which is assumed to have at most one server).
  #
  # This supports using telepresence with kube clusters running in
  # aws. telepresence will proxy dns requests to the cluster and will
  # return an internal aws address for the api endpoint otherwise.
  SERVER_HOST="$(grep server "${KUBECONFIG}" | sed -e 's+    server: https://\(.*\):.*+\1+')"
  SERVER_IP="$(dig "${SERVER_HOST}" +short | head -n 1)"
  ENTRY="${SERVER_IP} ${SERVER_HOST}"
  if ! grep "${ENTRY}" /etc/hosts > /dev/null; then
    grep -q "${SERVER_HOST}" /etc/hosts && \
      (cp -f /etc/hosts /tmp/etc-hosts && \
         sed -i 's+.*'"${SERVER_HOST}"'$+'"${ENTRY}"'+' /tmp/etc-hosts && \
         sudo cp /tmp/etc-hosts /etc/hosts)\
        || echo "${ENTRY}" | sudo tee -a /etc/hosts
  fi

  KIND="$(yq '.kind' ${YQ_ARGS})"
  GROUP="$(yq '.apiVersion' ${YQ_ARGS})"

  # Ensure the operator is not managed by CVO
  oc patch clusterversion/version --type='merge' -p "$(cat <<- EOF
spec:
  overrides:
  - group: ${GROUP}
    kind: ${KIND}
    name: ${NAME}
    namespace: ${NAMESPACE}
    unmanaged: true
EOF
)"

  # Ensure the operator is managed again on shutdown
  function cleanup {
    oc patch clusterversion/version --type='merge' -p "$(cat <<- EOF
spec:
  overrides:
  - group: ${GROUP}
    kind: ${KIND}
    name: ${NAME}
    namespace: ${NAMESPACE}
    unmanaged: false
EOF
)"
  }
  trap cleanup EXIT

  telepresence --namespace="${NAMESPACE}" --swap-deployment "${NAME}"\
               --mount=/tmp/tel_root --run run-local-operator.sh\
               "${DEPLOYMENT_YAML}" y
fi
