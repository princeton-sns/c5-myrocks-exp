#!/usr/bin/env bash

debug="false"
clean="false"
config=""

print_usage() {
    echo "Usage: $0 [-d] [-l] -c config"
    exit 1
}

while getopts 'dlc:' flag; do
    case "${flag}" in
	d) debug="true" ;;
	l) clean="true" ;;
	c) config="${OPTARG}" ;;
	*) print_usage ;;
    esac
done

if [[ -z $config ]]; then
    print_usage
fi

projectdir=$(awk -F' ' '/projectdir/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
builddir=$(awk -F' ' '/builddir/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
clients=$(awk -F' ' '/clients/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
primary=$(awk -F' ' '/primary/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
backup=$(awk -F' ' '/backup/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)

scriptsdir="$projectdir/mysql_scripts"

ssh="ssh -o StrictHostKeyChecking=no"

echo "Building mysql"
$ssh $primary "$scriptsdir/tools/build_mysql.sh $projectdir $builddir $clean $debug" &
pids[0]=$!
if [[ $primary != $backup ]]; then
    $ssh $backup "$scriptsdir/tools/build_mysql.sh $projectdir $builddir $clean $debug" &
    pids[1]=$!
fi

for pid in ${pids[@]}; do
    wait $pid
done

echo "Building oltpbench"
for c in ${clients[@]}; do
    $ssh $c "$scriptsdir/tools/build_oltpbench.sh $projectdir"
done

