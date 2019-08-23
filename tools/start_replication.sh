#!/usr/bin/env bash

projectdir=$1
builddir=$2

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 projectdir builddir" >&2
    exit 1
fi

scriptsdir="$projectdir/mysql_scripts"
srcdir="$projectdir/mysql-5.6"

cd $builddir

cnf="$scriptsdir/tools/slave.cnf"

echo "start slave;" | ./bin/mysql --defaults-file=$cnf

cd -
      
