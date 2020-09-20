#!/usr/bin/env bash

IMPLS=("fdr+fro" "kuafu+kro") # impls correspond to git tags
PERCENT_NEWORDER=(0 100)
NSAMPLES=15

# optimal num clients varies for each percent neworder
declare -A NCLIENTS
NCLIENTS["0,Opt"]=8
NCLIENTS["0,Unopt"]=4
NCLIENTS["100,Opt"]=30
NCLIENTS["100,Unopt"]=10

# optimal num workers varies for each implementation and percent neworder
declare -A NWORKERS
NWORKERS["fdr+fro,0"]=3
NWORKERS["fdr+fro,100"]=4
NWORKERS["kuafu+kro,0"]=1
NWORKERS["kuafu+kro,100"]=1

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

    for opt in "" "Opt"; do
        optname=$([[ -z "$opt" ]] && echo "Unopt" || echo "$opt")
        for percent_neworder in ${PERCENT_NEWORDER[@]}; do
            percent_payment=$(echo "100 - $percent_neworder" | bc)
            weights=""
            for txn in NewOrder NewOrderOpt Payment PaymentOpt OrderStatus Delivery StockLevel; do
                if [[ "$txn" == "NewOrder${opt}" ]]; then
                    weights="${weights}$percent_neworder,"
                elif [[ "$txn" == "Payment${opt}" ]]; then
                    weights="${weights}$percent_payment,"
                else
                    weights="${weights}0,"
                fi
            done
            weights="${weights:0:-1}"

            nclients=${NCLIENTS[$percent_neworder,$optname]}
            nworkers=${NWORKERS[$impl,$percent_neworder]}

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
                $scriptsdir/tools/run_bench.sh -c $config -o "$outdir/${impl}_${ro}_${nclients}c_${nworkers}w_${optname}t_${percent_neworder}n_${sample}" -b $benchmark "$ro_flag"
                sleep 5
            done
        done
    done
done

