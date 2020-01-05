#!/usr/bin/env bash

projectdir=$1
outdir=$2
benchmark=$3
config=$4
i=$5

if [[ $# -ne 5 ]]; then
    echo "Usage: $0 projectdir outdir benchmark config i" >&2
    exit 1
fi

scriptsdir="$projectdir/mysql_scripts"
oltpbenchdir="$scriptsdir/oltpbench"
configsdir="$scriptsdir/tools"

cd $oltpbenchdir

ant execute -Dbenchmark=$benchmark -Dconfig=$configsdir/$config.xml \
    -Dexecute=true \
    -Dextra="--histograms --directory $outdir --output results.$i \
    --output-raw=true output-samples=true -s 1 -ss" \
    > $outdir/client.$i.log 2>&1 &

cd -
      
