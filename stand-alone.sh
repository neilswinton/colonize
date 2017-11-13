#!/bin/bash

program="$0"

function fatal()
{
    if [ -n "$*" ] ; then
        echo >&2 "$*"
    fi

    echo >&2 "usage: $program [-l salt-log-level ] [-r ssh-host ]"
    exit 2
}
logging=""

while getopts "dl:r:?" o
do
    case "$o" in
        d) debug="-d"; set -x ;;                    # trace on
        l) logging="-l $OPTARG" ;;
        r) remote="$OPTARG" ;;
        ?) fatal ;;                     # usage
    esac
done
shift $((OPTIND - 1))

here=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [ -n "$remote" ]; then
    dir=$(ssh "$remote" mktemp -d) || fatal "Could not create a remote tempdir"
    echo $remote:$dir
    (cd $here && tar -cf - $(find . -name .git -prune -o -type f) ) | ssh "$remote" "cd $dir && tar -xf - && sudo bash ./stand-alone.sh $debug $logging "
    exit $?
fi

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
salt-call $logging --no-color --local  --file-root=./salt/roots/salt --pillar-root ./salt/roots/pillar state.highstate
