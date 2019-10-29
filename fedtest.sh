#!/bin/bash

go test -race -args -kubeconfig=/home/dev/.kube/config -v=4 -test.v -ginkgo.noColor -in-memory-controllers=true -ginkgo.skip='IngressDNS|Scheduling'

#KUBECONFIG=/opt/src/os-installer/auth/cb-kubeconfig openshift-tests run openshift/conformance --run="let the deployment config with a"

#dlv test -- -ginkgo.noColor -ginkgo.v

#cd /opt/src/kk/src/k8s.io/kubernetes/vendor/k8s.io/client-go/ && go test ./tools/cache

# dlv test -- -kubeconfig=/home/dev/.kube/config -v=4 -test.v -ginkgo.noColor -ginkgo.v  -ginkgo.focus=Scale -in-memory-controllers=true -limited-scope=true -kubefed-namespace=scal\
e2

# dlv debug -- crd paths=/opt/src/controller-tools/pkg/crd/testdata -output:dir=/opt/src/controlle-tools/pkg/crd/testdata

# go test -args -kubeconfig=/home/dev/.kube/config -v=4 -test.v -ginkgo.noColor -in-memory-controllers=true -ginkgo.focus=secrets -ginkgo.dryRun
