#!/bin/bash

go test -race -args -kubeconfig=/home/dev/.kube/config -v=4 -test.v -ginkgo.noColor -in-memory-controllers=true -ginkgo.skip='IngressDNS|Scheduling'
