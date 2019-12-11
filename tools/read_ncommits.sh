#!/usr/bin/env bash

builddir=$1
cnf=$2

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 builddir cnf" >&2
    exit 1
fi

cd $builddir

./bin/mysqladmin --defaults-file=$cnf extended-status \
    | awk -F'[ \t\n_-]+' '/histogram_binlog_group_commit/{ sum += ($6 * $9) } END { print sum }'

cd - > /dev/null
      
