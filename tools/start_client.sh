#!/usr/bin/env bash

projectdir=$1
outdir=$2
benchmark=$3
i=$4

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 projectdir outdir benchmark i" >&2
    exit 1
fi

scriptsdir="$projectdir/mysql_scripts"
oltpbenchdir="$scriptsdir/oltpbench"
configsdir="$scriptsdir/tools"

cd $oltpbenchdir

ant execute -Dbenchmark=$benchmark -Dconfig=$configsdir/$benchmark.xml \
    -Dexecute=true \
    -Dextra="--directory $outdir --output results.$i \
    --output-raw=true output-samples=true -s 1 -ss" \
    > $outdir/client.$i.log 2>&1 &

cd -
      
