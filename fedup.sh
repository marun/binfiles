#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Delete clusters (delete-clusters.sh script kills my machine)
kind get clusters | xargs -I {} kind delete cluster --name {}

## Deploy with image in local insecure registry
#CONTAINER_REGISTRY_HOST=172.17.0.3:5000 OVERWRITE_KUBECONFIG=y ./scripts/create-clusters.sh
#./scripts/deploy-federation.sh 172.17.0.3:5000/federation-v2:test cluster2

# Deploy with image in docker hub
KIND_TAG="v1.14.0" OVERWRITE_KUBECONFIG=y ./scripts/create-clusters.sh
./scripts/deploy-federation.sh docker.io/maru/kubefed:test cluster2
