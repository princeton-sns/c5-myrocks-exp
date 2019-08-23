#!/usr/bin/env bash

builddir=$1
cnf=$2
masterslave=$3

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 builddir cnf masterslave" >&2
    exit 1
fi

cd $builddir

echo "show $masterslave status;" | ./bin/mysql --defaults-file=$cnf

cd - > /dev/null
      
