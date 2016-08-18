#!/bin/bash

# Run tests in aws with vagrant-openshift

vagrant origin-init --stage os --os rhel7 --instance-type m4.large maru-dev
vagrant up --provider aws
vagrant build-origin-base
vagrant clone-upstream-repos --clean
vagrant checkout-repos
vagrant test-origin --extended networking -d --skip-check --skip-image-cleanup
