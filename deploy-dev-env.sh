#!/usr/bin/env bash

# Deploys dev env to fedora 31 host.

set -o errexit
set -o nounset
set -o pipefail

# Enable password-less sudo
echo 'maru ALL=(ALL) NOPASSWD: ALL' >> ./maru
sudo chown root:root ./maru
sudo mv ./maru /etc/sudoers.d/

# Configure env forwarding for ssh connections
sudo tee -a /etc/ssh/sshd_config > /dev/null << EOL
AcceptEnv GIT_AUTHOR_*
AcceptEnv GIT_COMMITTER_*
AcceptEnv TZ
EOL

# Disable password-based logins
sudo sed -i 's/^PasswordAuthentication yes$/PasswordAuthentication no/' /etc/ssh/sshd_config

# Install packages
sudo dnf -y update
sudo dnf -y install\
 ack\
 aspell-en\
 aspell\
 autoconf\
 bash-completion\
 bc\
 bind-utils\
 conntrack\
 dnf-plugins-core\
 docker\
 findutils\
 fpaste\
 fuse\
 gcc-c++\
 gcc\
 git\
 gnutls-devel\
 grubby\
 htop\
 iptables\
 jq\
 libxml2-devel\
 libxslt-devel\
 links\
 make\
 man\
 man-pages\
 ncurses-devel\
 procps\
 python-devel\
 python-pip\
 rsync\
 screen\
 sshfs\
 stow\
 sysstat\
 texinfo\
 vim-enhanced

# Deploy dotfiles and apply with stow
mkdir ~/src
git clone https://github.com/marun/dotfiles.git ~/src/dotfiles/
~/src/dotfiles/apply.sh

# Deploy binfiles
git clone https://github.com/marun/binfiles.git ~/bin

# Install gimme to simplify consumption of golang
curl -sL -o ~/bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
chmod +x ~/bin/gimme

# Install and configure emacs
git clone https://github.com/marun/dotemacs.git ~/.emacs.d
pushd .emacs.d > /dev/null
  ./install.sh
popd > /dev/null

# Install docker ce (kind not yet compatible with podman)

# Clear out incompatible dependencies
sudo dnf remove -y docker\
  docker-client\
  docker-client-latest\
  docker-common\
  docker-latest\
  docker-latest-logrotate\
  docker-logrotate\
  docker-selinux\
  docker-engine-selinux\
  docker-engine

# Configure docker repo
sudo dnf config-manager\
  --add-repo\
  https://download.docker.com/linux/fedora/docker-ce.repo

# Install docker packages
sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Ensure non-privileged access
sudo usermod -aG docker maru

# Enable cgroups compatibility with docker
sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0"

# Enable but do not start the docker service. A reboot is necessary before the service will be able to start
sudo systemctl enable docker

# Install kind
curl -Lo ~/bin/kind https://github.com/kubernetes-sigs/kind/releases/download/v0.7.0/kind-linux-amd64
chmod +x ~/bin/kind

mkdir ~/install
pushd ~/install > /dev/null
  # Install oc
  curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp-dev-preview/latest-4.4/openshift-client-linux.tar.gz
  tar xf openshift-client-linux.tar.gz
  mv kubectl oc ~/bin
  # Install glide
  curl -LO https://github.com/Masterminds/glide/releases/download/v0.13.3/glide-v0.13.3-linux-amd64.tar.gz
  tar xf glide-v0.13.3-linux-amd64.tar.gz
  mv linux-amd64/glide ~/bin
popd > /dev/null

echo "Reboot now to ensure a docker-compatible kernel configuration!"
