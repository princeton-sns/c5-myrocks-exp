#!/usr/bin/env bash

logsdir=""
outfile=""

print_usage() {
    echo "Usage: $0 -i logsdir -o outfile"
    exit 1
}

while getopts 'i:o:' flag; do
    case "${flag}" in
	i) logsdir="${OPTARG}" ;;
	o) outfile="${OPTARG}" ;;
	*) print_usage ;;
    esac
done

if [[ -z $logsdir || -z $outfile ]]; then
    print_usage
fi

logsdir=$(realpath $logsdir)
outfile=$(realpath $outfile)

echo "impl,n_clients,n_inserts,server,total_time_ms,n_commits,commit_rate_tps" > $outfile

for dir in $(find $logsdir -maxdepth 1 -mindepth 1 -type d -printf '%f\n'); do
    impl=$(echo "$dir" | sed -e 's/\([^_]\+\)_.*/\1/g')
    nclients=$(echo "$dir" | sed -e 's/[^_]\+_\([0-9]\+\)c_.*/\1/g')
    ninserts=$(echo "$dir" | sed -e 's/[^_]\+_[^_]\+_\([0-9]\+\)i/\1/g')

    for server in "primary" "backup"; do
	cat $logsdir/$dir/commit_rate.$server.csv | sed -e '/server/d' -e "s/^/$impl,$nclients,$ninserts,/" >> $outfile
    done
done
