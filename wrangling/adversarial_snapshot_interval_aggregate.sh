#!/usr/bin/env bash

declare -A IMPL_NAMES
IMPL_NAMES["fdr_none"]="FDR"
IMPL_NAMES["fdr+fro_none"]="FDR"
IMPL_NAMES["fdr+kro_none"]="FDR"
IMPL_NAMES["fdr+co_none"]="FDR"
IMPL_NAMES["fdr+fro_fro"]="FDR+fRO"
IMPL_NAMES["fdr+kro_kro"]="FDR+kRO"
IMPL_NAMES["fdr+co_co"]="FDR+CO"
IMPL_NAMES["kuafu_none"]="KuaFu"
IMPL_NAMES["kuafu+kro_none"]="KuaFu"
IMPL_NAMES["kuafu+co_none"]="KuaFu"
IMPL_NAMES["kuafu+kro_kro"]="KuaFu+kRO"
IMPL_NAMES["kuafu+co_co"]="KuaFu+CO"

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

echo "impl,n_clients,n_workers,n_inserts,snap_interval,server,total_time_ms,n_commits,commit_rate_tps,relative_commit_rate" > $outfile

for dir in $(find $logsdir -maxdepth 1 -mindepth 1 -type d -printf '%f\n'); do
    impl=$(echo "$dir" | sed -e 's/\([^_]\+_[^_]\+\)_.*/\1/g')
    nclients=$(echo "$dir" | sed -e 's/\([^_]\+_\)\+\([0-9]\+\)c_.*/\2/g')
    nworkers=$(echo "$dir" | sed -e 's/\([^_]\+_\)\+\([0-9]\+\)w_.*/\2/g')
    ninserts=$(echo "$dir" | sed -e 's/\([^_]\+_\)\+\([0-9]\+\)i_.*/\2/g')

    nclients=$([[ "$nclients" != "$dir" ]] && echo "$nclients" || echo "")
    nworkers=$([[ "$nworkers" != "$dir" ]] && echo "$nworkers" || echo "")
    ninserts=$([[ "$ninserts" != "$dir" ]] && echo "$ninserts" || echo "")
    snapinterval=$(echo "$dir" | sed -e 's/\([^_]\+_\)\+\([0-9]\+\)s_.*/\2/g')

    if [[ -v "IMPL_NAMES[$impl]" ]]; then
	      impl=${IMPL_NAMES[$impl]}
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
	          -e "s/^primary/$impl,$nclients,$nworkers,$ninserts,$snapinterval,Primary/" \
	          -e "s/$/,${primary_rcr}/" \
	          >> $outfile

    echo "$backup_csv" | \
	      sed -e '/server/d' \
	          -e 's/\r//' \
	          -e "s/^backup/$impl,$nclients,$nworkers,$ninserts,$snapinterval,$impl/" \
	          -e "s/$/,${backup_rcr}/" \
	          >> $outfile
done
