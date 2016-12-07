#!/bin/bash

set -e

OS_RELEASE=n hack/build-go.sh
cp _output/local/bin/linux/amd64/openshift images/origin/bin/
docker build -t openshift/origin images/origin
docker build -t openshift/origin-haproxy-router images/router/haproxy/
