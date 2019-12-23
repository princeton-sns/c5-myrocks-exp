#!/usr/bin/env bash

IMPLS=("fdr+fro") # impls correspond to git tags
NINSERTS=(1 2 4 8 16 32 64)
NSAMPLES=15

# ro impls
declare -A RO_IMPLS
RO_IMPLS["fdr+fro"]=""
RO_IMPLS["kuafu+kro"]=""

# num clients varies for each exp
declare -A NCLIENTS
NCLIENTS[1]=4
NCLIENTS[2]=4
NCLIENTS[4]=4
NCLIENTS[8]=4
NCLIENTS[16]=5
NCLIENTS[32]=5
NCLIENTS[64]=6

# num workers varies for each exp
declare -A NWORKERS
NWORKERS[1]=2
NWORKERS[2]=2
NWORKERS[4]=3
NWORKERS[8]=3
NWORKERS[16]=4
NWORKERS[32]=4
NWORKERS[64]=6

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

    for ninserts in ${NINSERTS[@]}; do
	roimpl=${RO_IMPLS[$impl]}
	nclients=${NCLIENTS[$ninserts]}
	nworkers=${NWORKERS[$ninserts]}

	weights=""
	for ni in 0 1 2 4 8 16 32 64; do
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
	    ro=$([[ -z "$roimpl" ]] && echo "none" || echo "$roimpl")
	    $scriptsdir/tools/run_bench.sh -c $config -o "$outdir/${impl}_${ro}_${nclients}c_${nworkers}w_${ninserts}i_${sample}" -b $benchmark -r "$roimpl"
	    sleep 5
	done
    done
done

