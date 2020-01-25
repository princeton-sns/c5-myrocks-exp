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
done

# Wait for all python processes to finish
wait
