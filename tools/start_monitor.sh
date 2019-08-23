#!/usr/bin/env bash

projectdir=$1
builddir=$2
outdir=$3
cnf=$4
i=$5

if [[ $# -ne 5 ]]; then
    echo "Usage: $0 projectdir builddir outdir cnf i" >&2
    exit 1
fi

scriptsdir="$projectdir/mysql_scripts"

cd $scriptsdir

./tools/monitor.sh $builddir $cnf > $outdir/monitor.$i.csv 2>&1 &

echo $!

cd - > /dev/null
      
