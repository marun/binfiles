#!/bin/bash

# Terminate the aws instance used to run tests with vagrant-openshift

vagrant modify-instance -r marun-dev_terminate -s && rm -rf .vagrant
