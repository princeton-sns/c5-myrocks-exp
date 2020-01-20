#!/usr/bin/env bash

IMPLS=("fdr+fro") # impls correspond to git tags
NCLIENTS=(9)
NSAMPLES=5

# optimal num workers varies for each implementation
declare -A NWORKERS
NWORKERS["fdr+fro"]=3
NWORKERS["kuafu+kro"]=1

# ro impls
declare -A RO_IMPLS
RO_IMPLS["fdr+fro"]=""
RO_IMPLS["kuafu+kro"]=""

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

benchmark="tpcc"
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
    roimpl=${RO_IMPLS[$impl]}

    for opt in Payment PaymentOpt; do
        weights=""
        for txn in NewOrder Payment PaymentOpt OrderStatus Delivery StockLevel; do
            [[ $txn == $opt ]] && weights="${weights}100," || weights="${weights}0,"
        done
        weights="${weights:0:-1}"

        for nclients in ${NCLIENTS[@]}; do
            nworkers=${NWORKERS[$impl]}

            echo "Editing configs"
            sed -i -e "s!\(<terminals>\)[0-9]\+\(</terminals>\)!\1${nclients}\2!g" $cfg
	    sed -i -e "s!\(<weights>\)[0-9,]\+\(</weights>\)!\1${weights}\2!g" $cfg
            sed -i -e "s!\(nworkers\)\s\+[0-9]\+!\1 $nworkers!g" $config

            for ((s=0;s<NSAMPLES;s++)); do
                echo "Starting experiment: "
                echo "Impl: $impl"
                echo "Clients: $nclients"
                echo "Sample: $((s+1)) of $NSAMPLES"
                echo
                sample=$(printf "%0.2d" $s)
                ro=$([[ -z "$roimpl" ]] && echo "none" || echo "$roimpl")
                $scriptsdir/tools/run_bench.sh -c $config -o "$outdir/${impl}_${ro}_${nclients}c_${nworkers}w_${opt}t_${sample}" -b $benchmark "$ro_flag"
                sleep 5
            done
        done
    done
done

