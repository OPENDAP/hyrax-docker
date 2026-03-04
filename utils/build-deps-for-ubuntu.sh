#!/bin/bash

HR="#######################################################################"
###########################################################################
# loggy()
function loggy(){
    echo  "$@" | awk '{ print "# "$0;}'  >&2
}
loggy "$HR"
loggy "$0 - BEGIN"
loggy ""
loggy "       prefix: $prefix"

extra_targets="${extra_targets:-"aws_s2n_tls"}"
loggy "extra_targets: $extra_targets"
loggy ""

make_target="${make_target:-"for-travis"}"
loggy "  make_target: $make_target"
loggy ""
repo_dir="/root/hyrax-dependencies"
loggy "     repo_dir: $repo_dir"
loggy "Changing to repo_dir: $repo_dir"
cd "$repo_dir" || exit $?
loggy ""

loggy ""
loggy "Running make $make_target"
loggy ""
make -j16 for-travis 2>&1 | tee "$prefix/build.log";

loggy "$0 - END"
loggy "$HR"
