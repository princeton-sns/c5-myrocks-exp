#!/usr/bin/env bash


projectdir=$1
builddir=$2
cnf=$3
benchmark=$4

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 projectdir builddir cnf benchmark" >&2
    exit 1
fi

scriptsdir="$projectdir/mysql_scripts"
spdir="$scriptsdir/storedproc/$benchmark"

if [[ -e $spdir ]]; then
    cd $builddir

    for sp in $spdir/*.sql; do
        ./bin/mysql --defaults-file=$cnf < $sp
    done

    cd -
fi
