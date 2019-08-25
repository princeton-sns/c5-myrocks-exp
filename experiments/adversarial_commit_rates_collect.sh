#!/usr/bin/env bash

IMPLS=("kuafu") # impls correspond to git tags
NCLIENTS=(32)
NINSERTS=(0 1 2 4 8 16 32 64 128 256)

config=""
outdir=""

print_usage() {
    echo "Usage: $0 -c config -o outdir"
    exit 1
}

while getopts 'c:o:' flag; do
    case "${flag}" in
	c) config="${OPTARG}" ;;
	o) outdir="${OPTARG}" ;;
	*) print_usage ;;
    esac
done

if [[ -z $config || -z $outdir ]]; then
    print_usage
fi

config=$(realpath $config)
outdir=$(realpath $outdir)

projectdir=$(awk -F' ' '/projectdir/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
benchmark=$(awk -F' ' '/benchmark/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)

scriptsdir="$projectdir/mysql_scripts"
srcdir="$projectdir/mysql-5.6"

ssh="ssh -o StrictHostKeyChecking=no"

echo "Starting experiments"

for impl in ${IMPLS[@]}; do
    echo "Building impl: $impl"
    cd $srcdir
    git checkout $impl && $scriptsdir/tools/build.sh -l -c $config
    cd -

    cfg=$scriptsdir/tools/$benchmark.xml

    for nclients in ${NCLIENTS[@]}; do
	for ninserts in ${NINSERTS[@]}; do
	    weights=""
	    for ni in 0 1 2 4 8 16 32 64 128 256; do
		[[ $ni -eq $ninserts ]] && weights="${weights}100," || weights="${weights}0,"
	    done
	    weights="${weights:0:-1}"

	    echo "Editing configs"
	    sed -i -e "s!\(<terminals>\)[0-9]\+\(</terminals>\)!\1${nclients}\2!g" $cfg
	    sed -i -e "s!\(<inserts>\)[0-9]\+\(</inserts>\)!\1${ninserts}\2!g" $cfg
	    sed -i -e "s!\(<weights>\)[0-9,]\+\(</weights>\)!\1${weights}\2!g" $cfg

	    for ((s=0;s<NSAMPLES;s++)); do
		echo "Starting experiment: "
		echo "Impl: $impl"
		echo "Clients: $nclients"
		echo "Inserts: $ninserts"
		echo "Sample: $((s+1)) of $NSAMPLES"
		echo
		sample=$(printf "%0.2d" $s)
		$scriptsdir/tools/run_bench.sh -c $config -o "$outdir/${impl}_${nclients}c_${ninserts}i_${sample}"
		sleep 5
	    done
	done
    done
done

