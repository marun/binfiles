#!/bin/bash

# Update git repos from their remotes

set -e


while getopts ":f" opt; do
    case $opt in
        f)
            # Sync only neutron repos by default
            SYNC_ALL=1
            ;;
    esac

done


ASYNC=1
VERBOSE=0

GIT_MIRROR_PATH=${GIT_MIRROR_PATH:-/opt/data/git}

repos=(
    'openstack/neutron.git'
    'openstack/neutron-fwaas.git'
    'openstack/neutron-lbaas.git'
    'openstack/neutron-vpnaas.git'
    'openstack-dev/devstack.git'
    'openstack-dev/pbr.git'
    'openstack/cinder.git'
    'openstack/cliff.git'
    'openstack/glance.git'
    'openstack/glance_store.git'
    'openstack/heat.git'
    'openstack/horizon.git'
    'openstack/keystone.git'
    'openstack/keystonemiddleware.git'
    'openstack/nova.git'
    'openstack/oslo.concurrency.git'
    'openstack/oslo.config.git'
    'openstack/oslo.db.git'
    'openstack/oslo.i18n.git'
    'openstack/oslo.log.git'
    'openstack/oslo.messaging.git'
    'openstack/oslo.middleware.git'
    'openstack/oslo.rootwrap.git'
    'openstack/oslo.serialization.git'
    'openstack/oslo.utils.git'
    'openstack/oslo.vmware.git'
    'openstack/pycadf.git'
    'openstack/python-cinderclient.git'
    'openstack/python-glanceclient.git'
    'openstack/python-heatclient.git'
    'openstack/python-keystoneclient.git'
    'openstack/python-neutronclient.git'
    'openstack/python-novaclient.git'
    'openstack/python-openstackclient.git'
    'openstack/python-quantumclient.git'
    'openstack/python-swiftclient.git'
    'openstack/quantum.git'
    'openstack/requirements.git'
    'openstack/stevedore.git'
    'openstack/taskflow.git'
    'openstack/tempest.git'
    'openstack/tempest-lib.git'
    )
other_repos=(
    'http://anongit.freedesktop.org/git/spice/spice-html5.git'
    'https://github.com/osrg/ryu.git'
    'https://github.com/kanaka/noVNC.git'
    )

mirror_repo() {
    local source_url=$1
    local target_path=$2

    if [ "$SYNC_ALL" != "1" ] && [[ ! "$source_url" =~ neutron ]]; then
        continue
    fi

    if [ ! -d ${target_path} ]; then
       echo "Creating mirror of ${source_url} at ${target_path}"
       git clone ${source_url} ${target_path} --mirror --quiet
    else
       echo "Updating mirror for ${source_url}"
       cd ${target_path}
       if [ "$VERBOSE" -eq 1 ]; then
           git remote update
           git update-server-info
       else
           git remote update &> /dev/null
           git update-server-info &> /dev/null
       fi
    fi
    echo "Finished mirroring ${source_url}"
}

if [ -d ${GIT_MIRROR_PATH} ]; then
    for repo in ${repos[@]}; do
        repo_path="${GIT_MIRROR_PATH}/${repo}"
        cmd="mirror_repo https://github.com/${repo} ${repo_path}"
        if [ "$ASYNC" -eq 1 ]; then
            $cmd &
        else
            $cmd
        fi
    done

    for repo in ${other_repos[@]}; do
        repo_path="${GIT_MIRROR_PATH}/other/${repo##*/}"
        cmd="mirror_repo ${repo} ${repo_path}"
        if [ "$ASYNC" -eq 1 ]; then
            $cmd &
        else
            $cmd
        fi
    done

    if [ "$ASYNC" -eq 1 ]; then
        FAIL=0
        for job in `jobs -p`
        do
            wait $job || let "FAIL+=1"
        done

        if [ "$FAIL" != "0" ];
        then
            echo "An error occured."
        fi
    fi
else
    echo "$(basename $0): ${GIT_MIRROR_PATH} is not a directory."
fi
