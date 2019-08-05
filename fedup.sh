#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Delete clusters (delete-clusters.sh script kills my machine)
kind get clusters | xargs -I {} kind delete cluster --name {}

# Deploy with image in docker hub
KIND_TAG=v1.14.2 CONFIGURE_INSECURE_REGISTRY_CLUSTER= OVERWRITE_KUBECONFIG=y ./scripts/create-clusters.sh
./scripts/deploy-kubefed.sh docker.io/maru/kubefed:test cluster2
