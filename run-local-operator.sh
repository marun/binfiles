#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# This script executes telepresence against an operator deployment.
#
# KUBECONFIG=... DEPLOYMENT_YAML=... TARGET_PATH=... run-local-operator.sh
#
# Dependencies:
#
# - oc
# - yq (pip install yq)
# - jq (fedora: dnf install jq; macos: brew install jq)
# - telepresence
#    - fedora:
#      - curl -s https://packagecloud.io/install/repositories/datawireio/telepresence/script.rpm.sh | sudo bash
#      - sudo dnf install telepresence
#    - macos:
#      - brew cask install osxfuse # reboot required
#      - brew install datawire/blackbird/telepresence
#    - Current release (0.104) not compatible with ocp.
#      - Workaround: Install dependencies via package but telepresence from source
#        - git clone https://github.com/telepresenceio/telepresence
#        - cd telepresence
#        - git remote add marun https://github.com/marun/telepresence
#        - git fetch marun
#        - git checkout -t marun/ocp-compatible
#        - make virtualenv
#        - . virtualenv/bin/activate
# - delve (go get github.com/go-delve/delve/cmd/dlv)

KUBECONFIG="${KUBECONFIG:-}"
if [[ "${KUBECONFIG}" == "" ]]; then
  >&2 echo "KUBECONFIG is not set"
  exit 1
fi

# The yaml defining the operator's deployment resource. Will be parsed
# for configuration like resource name, namespace, and command.
DEPLOYMENT_YAML="${DEPLOYMENT_YAML:-}"
if [[ ! "${DEPLOYMENT_YAML}" ]]; then
  >&2 echo "DEPLOYMENT_YAML is not set"
  exit 1
fi

# The path to the golang package to run or debug
# (e.g. `/my/project/cmd/operator`)
TARGET_PATH="${TARGET_PATH:-}"
if [[ ! "${TARGET_PATH}" ]]; then
  >&2 echo "TARGET_PATH is not set"
  exit 1
fi

# By default the operator will be run via 'go run'. Providing DEBUG=y
# will run `dlv debug` instead.
DEBUG="${DEBUG:-}"

# Whether to add an entry in /etc/hosts for the api server host. This
# is necessary if targeting a cluster deployed in aws.
ADD_AWS_HOST_ENTRY="${ADD_AWS_HOST_ENTRY:-y}"

# The target cmd will be parsed from the deployment by default, but
# can be overridden by setting this var.
TARGET_CMD="${TARGET_CMD:-}"

# The target args will be parsed from the deployment by default, but
# can be overridden by setting this var.
TARGET_ARGS="${TARGET_ARGS:-}"

# The command telepresence should run in the local deployment
# environment. By default it will run or debug the operator but it can
# be useful to run a shell (e.g. `bash`) for troubleshooting.
RUN_CMD="${RUN_CMD:-run-local-operator.sh}"

# Whether this script should run telepresence or is being run by
# telepresence. Used as an internal control var, not necessary to set
# manually.
_INTERNAL_RUN="${_INTERNAL_RUN:-}"

# Some operators (e.g. auth operator) specify build flags to generate
# different binaries for ocp or okd.
BUILD_FLAGS="${BUILD_FLAGS:-}"

YQ_ARGS="${DEPLOYMENT_YAML} -r"

NAMESPACE="$(yq '.metadata.namespace' ${YQ_ARGS})"
NAME="$(yq '.metadata.name' ${YQ_ARGS})"

# If not provided, the lock configmap will be defaulted to the name of
# the deployment suffixed by `-lock`.
LOCK_CONFIGMAP="${LOCK_CONFIGMAP:-${NAME}-lock}"

if [ "${_INTERNAL_RUN}" ]; then
  # Delete the leader election lock to ensure that the local process
  # becomes the leader as quickly as possible.
  oc delete configmap "${LOCK_CONFIGMAP}" --namespace "${NAMESPACE}" --ignore-not-found=true

  if [[ ! "${TARGET_CMD}" ]]; then
    # Parse the command from the deployment
    TARGET_CMD="$(yq '.spec.template.spec.containers[0].command[1:] | join(" ")' ${YQ_ARGS})"
  fi

  if [[ ! "${TARGET_ARGS}" ]]; then
    # Parse the args from the deployment
    TARGET_ARGS="$(yq '.spec.template.spec.containers[0].args | join(" ")' ${YQ_ARGS})"
  fi

  pushd "${TARGET_PATH}" > /dev/null
    if [[ "${DEBUG}" ]]; then
      if [[ "${BUILD_FLAGS}" ]]; then
        BUILD_FLAGS="--build-flags=${BUILD_FLAGS}"
      fi
      dlv debug ${BUILD_FLAGS} -- ${TARGET_CMD} ${TARGET_ARGS}
    else
      go run ${BUILD_FLAGS} . ${TARGET_CMD} ${TARGET_ARGS}
    fi
  popd > /dev/null
else
  if [[ "${ADD_AWS_HOST_ENTRY}" ]]; then
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
      >&2 echo "Attempting to add '${ENTRY}' to /etc/hosts to ensure access to an aws cluster. This requires sudo."
      >&2 echo "If this cluster is not in aws, specify ADD_AWS_HOST_ENTRY="
      grep -q "${SERVER_HOST}" /etc/hosts && \
        (cp -f /etc/hosts /tmp/etc-hosts && \
           sed -i 's+.*'"${SERVER_HOST}"'$+'"${ENTRY}"'+' /tmp/etc-hosts && \
           sudo cp /tmp/etc-hosts /etc/hosts)\
          || echo "${ENTRY}" | sudo tee -a /etc/hosts
    fi
  fi

  # Ensure pod volumes are symlinked to the expected location
  if [[ ! -L '/var/run/configmaps' ]]; then
     >&2 echo "Attempting to symlink /tmp/tel_root/var/run/configmaps to /var/run/configmaps. This requires sudo."
     sudo ln -s /tmp/tel_root/var/run/configmaps /var/run/configmaps
  fi
  if [[ ! -L '/var/run/secrets' ]]; then
    >&2 echo "Attempting to symlink /tmp/tel_root/var/run/secrets to /var/run/secrets. This requires sudo."
    sudo ln -s /tmp/tel_root/var/run/secrets /var/run/secrets
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

  # Ensure that traffic for all machines in the cluster is also
  # proxied so that the local operator will be able to access them.
  ALSO_PROXY="$(oc get machines -A -o json | jq -jr '.items[] | .status.addresses[0].address | @text "--also-proxy=\(.) "')"

  TELEPRESENCE_OCP_USE_DEFAULT_IMAGE=y _INTERNAL_RUN=y telepresence --namespace="${NAMESPACE}"\
    --swap-deployment "${NAME}" ${ALSO_PROXY} --mount=/tmp/tel_root --run "${RUN_CMD}"
fi
