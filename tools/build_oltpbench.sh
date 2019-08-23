#!/usr/bin/env bash

projectdir=$1

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 projectdir" >&2
    exit 1
fi

scriptsdir="$projectdir/mysql_scripts"
oltpbenchdir="$scriptsdir/oltpbench"

cd $oltpbenchdir

ant build

cd -

