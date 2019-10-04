#!/usr/bin/env bash

builddir=$1
outdir=$2

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 builddir outdir" >&2
    exit 1
fi

file=$builddir/data/mysqld.1/mysql_error.log
[[ -e $file ]] && cp $file $outdir/mysql_error.primary.log

file=$builddir/data/mysqld.2/mysql_error.log
[[ -e $file ]] && cp $file $outdir/mysql_error.backup.log
