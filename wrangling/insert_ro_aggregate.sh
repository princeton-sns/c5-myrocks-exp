#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

declare -A IMPL_NAMES
IMPL_NAMES["fdr"]="FDR"
IMPL_NAMES["fdr+fro"]="FDR+fRO"
IMPL_NAMES["fdr+kro"]="FDR+kRO"
IMPL_NAMES["fdr+co"]="FDR+CO"
IMPL_NAMES["kuafu"]="KuaFu"
IMPL_NAMES["kuafu+kro"]="KuaFu+kRO"
IMPL_NAMES["kuafu+co"]="KuaFu+CO"

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

echo "impl,n_clients,n_workers,n_roclients,server,total_time_ms,n_commits,commit_rate_tps,relative_commit_rate,rw" > $outfile

i=0
for dir in $(find $logsdir -maxdepth 1 -mindepth 1 -type d -printf '%f\n'); do
    impl=$(echo "$dir" | sed -e 's/\([^_]\+\)_.*/\1/g')
    nclients=$(echo "$dir" | sed -e 's/\([^_]\+_\)\+\([0-9]\+\)c_.*/\2/g')
    nroclients=$(echo "$dir" | sed -e 's/\([^_]\+_\)\+\([0-9]\+\)r_.*/\2/g')
    nworkers=$(echo "$dir" | sed -e 's/\([^_]\+_\)\+\([0-9]\+\)w_.*/\2/g')

    if [[ -v "IMPL_NAMES[$impl]" ]]; then
	      impl=${IMPL_NAMES[$impl]}
    fi

    $SCRIPT_DIR/process_replag.py -i $logsdir/$dir/mysql_error.backup.log -o $logsdir/$dir -s $impl -c $nclients -r $nroclients -w $nworkers &
    i=$((i+1))

    # Process 3 at a time
    if [[ $i -eq 3 ]]; then
        wait
        i=0
    fi

    primary_csv=$(cat $logsdir/$dir/commit_rate.primary.csv)
    backup_csv=$(cat $logsdir/$dir/commit_rate.backup.csv)

    primary_cr=$(echo "$primary_csv" | awk -F',' '/primary/{ gsub("\r", "", $4); print $4 }')
    backup_cr=$(echo "$backup_csv" | awk -F',' '/backup/{ gsub("\r", "", $4); print $4 }')

    primary_rcr=$(echo "$primary_cr / $primary_cr" | bc -l)
    backup_rcr=$(echo "$backup_cr / $primary_cr" | bc -l)

    echo "$primary_csv" | \
	      sed -e '/server/d' \
	          -e 's/\r//' \
	          -e "s/^primary/$impl,$nclients,$nworkers,$nroclients,Primary/" \
	          -e "s/$/,${primary_rcr},w/" \
	          >> $outfile

    echo "$backup_csv" | \
	      sed -e '/server/d' \
	          -e 's/\r//' \
	          -e "s/^backup/$impl,$nclients,$nworkers,$nroclients,$impl/" \
	          -e "s/$/,${backup_rcr},w/" \
	          >> $outfile

    ro_reqs=$(cat $logsdir/$dir/ro/client.0.log | awk '/Rate limited reqs/{ print $10 }' | sed -e 's/[^0-9]//g')
    ro_nanos=$(cat $logsdir/$dir/ro/client.0.log | awk '/Rate limited reqs/{ print $9 }' | sed -e 's/[^0-9]//g')
    ro_ms=$(echo "$ro_nanos / 1000000" | bc -l)
    ro_tput=$(cat $logsdir/$dir/ro/client.0.log | awk '/Rate limited reqs/{ print $12 }')

    echo "$impl,$nclients,$nworkers,$nroclients,$impl,$ro_ms,$ro_reqs,$ro_tput,NA,r" >> $outfile
done

# Wait for all python processes to finish
wait
