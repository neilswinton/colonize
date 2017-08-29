#!/bin/bash

here=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if ! salt-call --version &>/dev/null; then
    tempdir=$(mktemp -d)
    trap "{ rm -rf $tempdir; }" EXIT

    cd $tempdir
    git clone https://github.com/saltstack/salt-bootstrap.git
    cd salt-bootstrap
    ./bootstrap-salt.sh
fi

cd $here
salt-call --no-color --local  --file-root=./salt/roots/salt --pillar-root ./salt/roots/pillar state.highstate
