#!/usr/bin/env bash

declare -A IMPL_NAMES
IMPL_NAMES["fdr"]="CopyCat"
IMPL_NAMES["fdr+fro"]="CopyCat"
IMPL_NAMES["fdr+kro"]="CopyCat"
IMPL_NAMES["fdr+co"]="CopyCat"
IMPL_NAMES["kuafu"]="KuaFu"
IMPL_NAMES["kuafu+kro"]="KuaFu"
IMPL_NAMES["kuafu+co"]="KuaFu"

declare -A ROIMPL_NAMES
ROIMPL_NAMES["none"]=""
ROIMPL_NAMES["fro"]="+cRO"
ROIMPL_NAMES["kro"]="+kRO"
ROIMPL_NAMES["co"]="+CO"
ROIMPL_NAMES["kro"]="+kRO"

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

echo "impl,n_clients,n_workers,use_upsert,server,total_time_ms,n_commits,commit_rate_tps,relative_commit_rate" > $outfile

for dir in $(find $logsdir -maxdepth 1 -mindepth 1 -type d -printf '%f\n'); do
    impl=$(echo "$dir" | sed -e 's/\([^_]\+\)_.*/\1/g')
    roimpl=$(echo "$dir" | sed -e 's/[^_]\+_\([^_]\+\)_.*/\1/g')
    nclients=$(echo "$dir" | sed -e 's/\([^_]\+_\)\+\([0-9]\+\)c_.*/\2/g')
    nworkers=$(echo "$dir" | sed -e 's/\([^_]\+_\)\+\([0-9]\+\)w_.*/\2/g')
    upsert=$(echo "$dir" | sed -e 's/\([^_]\+_\)\+\([^_]\+\)u_.*/\2/g')

    if [[ -v "IMPL_NAMES[$impl]" ]]; then
	      impl=${IMPL_NAMES[$impl]}
    fi

    if [[ -v "ROIMPL_NAMES[$roimpl]" ]]; then
	      roimpl=${ROIMPL_NAMES[$roimpl]}
    fi

    if [[ $upsert == "t" ]]; then
        upsert="true"
    else
        upsert="false"
    fi

    primary_csv=$(cat $logsdir/$dir/commit_rate.primary.csv)
    primary_cr=$(echo "$primary_csv" | awk -F',' '/primary/{ gsub("\r", "", $4); print $4 }')
    primary_rcr=$(echo "$primary_cr / $primary_cr" | bc -l)

    echo "$primary_csv" | \
	      sed -e '/server/d' \
	          -e 's/\r//' \
	          -e "s/^primary/${impl}${roimpl},$nclients,$nworkers,$upsert,Primary/" \
	          -e "s/$/,${primary_rcr}/" \
	          >> $outfile

    if [[ -e "$logsdir/$dir/commit_rate.backup.csv" ]]; then
        backup_csv=$(cat $logsdir/$dir/commit_rate.backup.csv)
        backup_cr=$(echo "$backup_csv" | awk -F',' '/backup/{ gsub("\r", "", $4); print $4 }')
        backup_rcr=$(echo "$backup_cr / $primary_cr" | bc -l)

        echo "$backup_csv" | \
	          sed -e '/server/d' \
	              -e 's/\r//' \
	              -e "s/^backup/${impl}${roimpl},$nclients,$nworkers,$upsert,$impl${roimpl}/" \
	              -e "s/$/,${backup_rcr}/" \
	              >> $outfile
    fi
done
