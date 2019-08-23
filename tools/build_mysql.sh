#!/usr/bin/env bash

projectdir=$1
builddir=$2
clean=$3
debug=$4

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 projectdir builddir clean debug" >&2
    exit 1
fi

scriptsdir="$projectdir/mysql_scripts"
srcdir="$projectdir/mysql-5.6"

if [[ $clean == "true" ]]; then
    test -e $builddir && rm -rf $builddir/*
fi

test -e $builddir || mkdir -p $builddir
test -e $builddir/data || mkdir -p $builddir/data

cd $builddir

if [[ $debug == "true" ]]; then
    cmake $srcdir -DCMAKE_BUILD_TYPE=Debug -DWITH_SSL=system \
	  -DMYSQL_MAINTAINER_MODE=1 -DENABLE_DTRACE=0 -DWITH_ZSTD=/usr \
	  -DCMAKE_INSTALL_PREFIX=$builddir
else
    cmake $srcdir -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_SSL=system -DWITH_ZLIB=bundled \
	  -DWITH_LZ4=/usr/lib/x86_64-linux-gnu -DWITH_ZSTD=system -DWITH_JEMALLOC=/usr/local/lib \
	  -DMYSQL_MAINTAINER_MODE=0 -DENABLED_LOCAL_INFILE=1 \
	  -DCMAKE_C_FLAGS="-DHAVE_JEMALLOC" -DCMAKE_CXX_FLAGS="-march=native -DHAVE_JEMALLOC" \
	  -DCMAKE_INSTALL_PREFIX=$builddir
fi

make -j`nproc` -Otarget
make install

cd -

