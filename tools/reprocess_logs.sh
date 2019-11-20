#!/usr/bin/env bash

benchmark=""
config=""
logsdir=""

print_usage() {
    echo "Usage: $0 -c config -i logsdir -b benchmark"
    exit 1
}

while getopts 'c:i:b:' flag; do
    case "${flag}" in
	b) benchmark="${OPTARG}" ;;
	c) config="${OPTARG}" ;;
	i) logsdir="${OPTARG}" ;;
	*) print_usage ;;
    esac
done

if [[ -z $benchmark || -z $config || -z $logsdir ]]; then
    print_usage
    exit 1
fi

config=$(realpath $config)
logsdir=$(realpath $logsdir)

projectdir=$(awk -F' ' '/projectdir/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
scriptsdir="$projectdir/mysql_scripts"
configsdir="$scriptsdir/tools"

for dir in $(find $logsdir -maxdepth 1 -mindepth 0 -type d); do
    outdir=$(realpath $dir)

    bench_config="$outdir/$benchmark.xml"
    duration=$(sed -n "s!\s*<time>\([0-9]\+\)</time>\s*!\1!p" $bench_config)
    
    if [[ -e $outdir/monitor.primary.csv ]]; then
	$scriptsdir/tools/process_monitor_log.py -s primary -d $duration -i $outdir/monitor.primary.csv -o $outdir
    fi
    if [[ -e $outdir/monitor.backup.csv ]]; then
	$scriptsdir/tools/process_monitor_log.py -s backup -d $duration -i $outdir/monitor.backup.csv -o $outdir
    fi
done
