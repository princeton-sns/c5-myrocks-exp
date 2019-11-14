#!/usr/bin/env bash

projectdir=$1
builddir=$2
cnf=$3
logfile=$4
logpos=$5

if [[ $# -ne 5 ]]; then
    echo "Usage: $0 projectdir builddir cnf logfile logpos" >&2
    exit 1
fi

scriptsdir="$projectdir/mysql_scripts"

read_log_pos() {
    out=$($scriptsdir/tools/read_status.sh $builddir $cnf slave)
    lf=$(echo "$out" | tr "\n" "\t" | cut -f65)
    lp=$(echo "$out" | tr "\n" "\t" | cut -f66)
}

cd $builddir

echo "start slave io_thread;" | ./bin/mysql --defaults-file=$cnf

cd -

read_log_pos
while [ "$lf" != "$logfile" ] || [ "$lp" != "$logpos" ]; do
    sleep 0.2
    read_log_pos
done

