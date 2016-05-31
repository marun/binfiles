#!/bin/bash

zone=$1
interface=$2

if [[ -z "${zone}" ]]; then
  >&2 echo "Usage: $0 zone [interface]"
  exit 1
fi

if [[ -z "${interface}" ]]; then
  firewall-cmd --zone "${zone}" --change-interface "${interface}"
fi

firewall-cmd --permanent --zone "${zone}" --add-service nfs
firewall-cmd --permanent --zone "${zone}" --add-service rpc-bind
firewall-cmd --permanent --zone "${zone}" --add-service mountd
firewall-cmd --permanent --zone "${zone}" --add-port 2049/udp
firewall-cmd --reload
