#!/bin/bash
#
# From bes/.travis.yml
#
# - autoreconf --force --install --verbose
# - ./configure --disable-dependency-tracking --prefix=$prefix --with-dependencies=$prefix/deps --enable-developer
# - export LD_LIBRARY_PATH="/home/travis/install/deps/lib:$LD_LIBRARY_PATH"
# - echo "LD_LIBRARY_PATH - $LD_LIBRARY_PATH" >&2
# - make -j16 && make install && besctl start && make check -j16 && besctl stop
# -
#
#
#
#
echo "LD_LIBRARY_PATH - $LD_LIBRARY_PATH" >&2

HR="#######################################################################"
###########################################################################
# loggy()
function loggy() {
    echo "$@" | awk '{ print "# "$0;}' >&2
}
loggy "$HR"
loggy "$0 - BEGIN"
loggy ""
loggy " prefix: $prefix"
loggy "    PWD: $PWD"
export LD_LIBRARY_PATH="$prefix/deps/lib:$LD_LIBRARY_PATH"
loggy "LD_LIBRARY_PATH:$LD_LIBRARY_PATH"

export PKG_CONFIG_PATH="$prefix/deps/lib/pkgconfig";
loggy "PKG_CONFIG_PATH:$PKG_CONFIG_PATH"

export PATH="$prefix/deps/bin:$PATH";
loggy "PATH:$PATH"

repo_dir="/root/bes"
loggy "     repo_dir: $repo_dir"
loggy "Changing to repo_dir: $repo_dir"
cd "$repo_dir" || exit $?
loggy ""

autoreconf  --force --install --verbose
./configure --disable-dependency-tracking --prefix=$prefix --with-dependencies=$prefix/deps --enable-developer

make -j16
make install
besctl start
make check -j16
besctl stop

loggy "$0 - END"
loggy "$HR"
