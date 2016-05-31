#!/bin/bash

neutron security-group-rule-create \
        --direction ingress \
        --ethertype IPv4 \
        --protocol icmp \
        default
neutron security-group-rule-create \
        --direction ingress \
        --ethertype IPv4 \
        --port-range-min 22 \
        --port-range-max 22 \
        --protocol tcp \
        default
