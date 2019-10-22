#!/usr/bin/env bash

IMPLS=("fdr" "fdr+fro" "fdr+kro" "fdr+co" "kuafu" "kuafu+kro" "kuafu+co") # impls correspond to git tags
NCLIENTS=(8)
NINSERTS=(1 2 4 8 16 32 64 128 256)
NSAMPLES=1

config=""
outdir=""

print_usage() {
    echo "Usage: $0 -c config -o outdir"
    exit 1
}

while getopts 'c:o:b:' flag; do
    case "${flag}" in
	c) config="${OPTARG}" ;;
	o) outdir="${OPTARG}" ;;
	*) print_usage ;;
    esac
done

if [[ -z $config || -z $outdir ]]; then
    print_usage
fi

benchmark="adversary"
config=$(realpath $config)
outdir=$(realpath $outdir)

projectdir=$(awk -F' ' '/projectdir/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)

scriptsdir="$projectdir/mysql_scripts"
srcdir="$projectdir/mysql-5.6"

ssh="ssh -o StrictHostKeyChecking=no"

echo "Starting experiments"

for impl in ${IMPLS[@]}; do
    echo "Building impl: $impl"
    cd $srcdir
    commitbefore=$(git rev-parse --verify HEAD)
    git checkout $impl
    commitafter=$(git rev-parse --verify HEAD)
    if [[ $commitbefore != $commitafter ]]; then
    	$scriptsdir/tools/build.sh -l -c $config
    fi
    cd -


    cfg=$scriptsdir/tools/$benchmark.xml
    ro=$(echo "$impl" | cut -d+ -f2 -)
    if [[ "$ro" == "$impl" ]]; then
	ro_flag=""
    else
	ro_flag="-r $ro"
    fi

    for nclients in ${NCLIENTS[@]}; do
	for ninserts in ${NINSERTS[@]}; do
	    nworkers="$nclients"

	    weights=""
	    for ni in 0 1 2 4 8 16 32 64 128 256; do
		[[ $ni -eq $ninserts ]] && weights="${weights}100," || weights="${weights}0,"
	    done
	    weights="${weights:0:-1}"

	    echo "Editing configs"
	    sed -i -e "s!\(<terminals>\)[0-9]\+\(</terminals>\)!\1${nclients}\2!g" $cfg
	    sed -i -e "s!\(<inserts>\)[0-9]\+\(</inserts>\)!\1${ninserts}\2!g" $cfg
	    sed -i -e "s!\(<weights>\)[0-9,]\+\(</weights>\)!\1${weights}\2!g" $cfg
	    sed -i -e "s!\(nworkers\)\s\+[0-9]\+!\1 $nworkers!g"  $config

	    for ((s=0;s<NSAMPLES;s++)); do
		echo "Starting experiment: "
		echo "Impl: $impl"
		echo "Clients: $nclients"
		echo "Inserts: $ninserts"
		echo "Sample: $((s+1)) of $NSAMPLES"
		echo
		sample=$(printf "%0.2d" $s)
		$scriptsdir/tools/run_bench.sh -c $config -o "$outdir/${impl}_${nclients}c_${ninserts}i_${sample}" -b $benchmark "$ro_flag"
		sleep 5
	    done
	done
    done
done

