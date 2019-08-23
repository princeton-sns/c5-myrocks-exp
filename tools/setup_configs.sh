#!/usr/bin/env bash

projectdir=$1
config=$2
benchmark=$3
outdir=$4

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 projectdir config benchmark outdir" >&2
    exit 1
fi

scriptsdir="$projectdir/mysql_scripts"
srcdir="$projectdir/mysql-5.6"

# Copy config files to outdir
cp $config $outdir
cp $scriptsdir/tools/$benchmark.xml $outdir
cp $scriptsdir/tools/master.cnf $outdir
cp $scriptsdir/tools/slave.cnf $outdir

scriptscommit=$(cd $scriptsdir && git rev-parse --verify HEAD)
mysqlcommit=$(cd $srcdir && git rev-parse --verify HEAD)
cat > $outdir/gitcommits.txt << EOF
scripts: $scriptscommit
mysql: $mysqlcommit
EOF
