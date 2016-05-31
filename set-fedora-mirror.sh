#!/bin/bash

mirror_host=$1
if [[ -z "${mirror_host}" ]]; then
  >&2 echo "Usage: $0 mirror_host"
  exit 1
fi

fedora_version=$(cat /etc/redhat-release | awk '{print $3}')
mirror_url="http://${mirror_host}/fedora${fedora_version}"

echo 'deltarpm=0' >> /etc/dnf/dnf.conf
sed -i -e 's+^metalink=+#metalink=+' /etc/yum.repos.d/fedora.repo
sed -i -e 's+#*baseurl=.*+baseurl='${mirror_url}'/fedora+' \
  /etc/yum.repos.d/fedora.repo
sed -i -e 's+^metalink=+#metalink=+' /etc/yum.repos.d/fedora-updates.repo
sed -i -e 's+#*baseurl=.*+baseurl='${mirror_url}'/updates+' \
  /etc/yum.repos.d/fedora-updates.repo

dnf clean all
