#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="${1:-}"
CONFIG_TEMPLATE="${CONFIG_TEMPLATE:-install-config.yaml.libvirt}"
OPENSHIFT_INSTALL="${OPENSHIFT_INSTALL:-./openshift-install}"

if [ -z "${OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE}" ]; then
    >&2 echo "Usage: $0 release-image"
    exit 1
fi

# The config is removed by the installer so copying from a template
# avoids having to create one for every install.
cp "${CONFIG_TEMPLATE}" install-config.yaml

# Fix the ingress configuration by removing the cluster name.
# TODO(marun) Fix the installer to not require this for libvirt.
${OPENSHIFT_INSTALL} create manifests
CLUSTER_NAME="$(yq '.metadata.name' "${CONFIG_TEMPLATE}" -r)"
sed -i 's/'"${CLUSTER_NAME}"'.//' ./manifests/cluster-ingress-02-config.yml

${OPENSHIFT_INSTALL} create cluster
