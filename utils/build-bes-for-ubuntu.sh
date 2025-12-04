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

export PATH="$prefix/bin:$prefix/deps/bin:$PATH";
loggy "PATH:$PATH"

export CPPFLAGS="${CPPFLAGS:-""} -I$prefix/include ";
loggy "CPPFLAGS:$CPPFLAGS"

proj_prefix="$prefix/deps/proj/"
export LDFLAGS="${LDFLAGS:-""} -L$prefix/lib -lpthread -lm ";
export proj_libdir="$proj_prefix/lib64" ;
export deps_libdir="$prefix/deps/lib64";
if ! test -d "$proj_libdir"
then
    proj_libdir="$proj_prefix/lib"
fi
LDFLAGS="${LDFLAGS:-""} -L$proj_libdir "

if ! test -d "$deps_libdir"
then
    export deps_libdir="$prefix/deps/lib"
fi
LDFLAGS="${LDFLAGS:-""} -L$deps_libdir "
loggy "LDFLAGS: $LDFLAGS"

ln -s /root/bes /root/travis

repo_dir="/root/bes"
loggy "     repo_dir: $repo_dir"
loggy "Changing to repo_dir: $repo_dir"
cd "$repo_dir" || exit $?
loggy ""

autoreconf  --force --install --verbose
./configure --disable-dependency-tracking --prefix=$prefix --with-dependencies=$prefix/deps --without-gdal --enable-developer

make -j16  \
    && make install \
    && echo "BES.User=root" > $prefix/etc/bes/site.conf \
    && echo "BES.Group=root" > $prefix/etc/bes/site.conf \
    && besctl start \
    && make check -j16 \
    && besctl stop

loggy "$0 - END"
loggy "$HR"
