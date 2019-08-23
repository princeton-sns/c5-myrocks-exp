#!/usr/bin/env bash

builddir=$1

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 builddir" >&2
    exit 1
fi

killall -9 mysqld

rm -rf $builddir/data/mysqld.1
