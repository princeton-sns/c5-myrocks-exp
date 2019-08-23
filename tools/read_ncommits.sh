#!/usr/bin/env bash

builddir=$1
cnf=$2

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 builddir cnf" >&2
    exit 1
fi

cd $builddir

./bin/mysqladmin --defaults-file=$cnf extended-status | grep Com_commit | awk -F' ' '{ print $4 }'

cd - > /dev/null
      
