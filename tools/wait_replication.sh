#/usr/bin/env bash

projectdir=$1
builddir=$2
cnf=$3
mastercommits=$4

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 projectdir builddir cnf mastercommits" >&2
    exit 1
fi

scriptsdir="$projectdir/mysql_scripts"

cd $builddir

read_ncommits() {
    nc=$($scriptsdir/tools/read_ncommits.sh $builddir $cnf)
}

read_ncommits
while [[ $nc -ne $mastercommits ]]; do
    sleep 0.2 
    read_ncommits
done
