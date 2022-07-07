#!/usr/bin/env bash

IMPLS=("fdr+fro") # impls correspond to git tags
NCLIENTS=(9)
NROCLIENTS=(0 1 2 4 8 16)
NSAMPLES=5

# ro impls
declare -A RO_IMPLS
RO_IMPLS["fdr+fro"]="fro"
RO_IMPLS["kuafu+kro"]=""

# optimal num workers varies for each implementation
declare -A NWORKERS
NWORKERS["fdr+fro"]=8
NWORKERS["kuafu+kro"]=1

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

benchmark="insert"
robenchmark="insert-ro"
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
    rocfg=$scriptsdir/tools/$robenchmark.xml

    nworkers=${NWORKERS[$impl]}
    roimpl=${RO_IMPLS[$impl]}
    for nclients in ${NCLIENTS[@]}; do
        for nroclients in ${NROCLIENTS[@]}; do

            echo "Editing configs"
            sed -i -e "s!\(<terminals>\)[0-9]\+\(</terminals>\)!\1${nclients}\2!g" $cfg

            sed -i -e "s!\(<terminals>\)[0-9]\+\(</terminals>\)!\1${nroclients}\2!g" $rocfg

            sed -i -e "s!\(nworkers\)\s\+[0-9]\+!\1 $nworkers!g" $config

            for ((s=0;s<NSAMPLES;s++)); do
                echo "Starting experiment: "
                echo "Impl: $impl"
                echo "Clients: $nclients"
                echo "Sample: $((s+1)) of $NSAMPLES"
                echo
                sample=$(printf "%0.2d" $s)
	        ro=$([[ -z "$roimpl" ]] && echo "none" || echo "$roimpl")
                $scriptsdir/tools/run_bench.sh -c $config -o "$outdir/${impl}_${ro}_${nclients}c_${nworkers}w_${nroclients}r_${sample}" -b $benchmark -a $robenchmark -r "$roimpl"
                sleep 5
            done
        done
    done
done

