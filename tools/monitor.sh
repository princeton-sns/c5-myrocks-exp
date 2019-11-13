#!/usr/bin/env bash

builddir=$1
cnf=$2

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 builddir cnf" >&2
    exit 1
fi

cd $builddir

while true; do
    [[ $cnf == *"slave.cnf"* ]] && masterslave="slave" || masterslave="master"

    statusout=$($scriptsdir/tools/read_status.sh $builddir $cnf $masterslave)
    adminout=$(./bin/mysqladmin --defaults-file=$cnf extended-status)
    t=$(date +%s%3N)

    echo "$adminout" | grep Com_commit | awk -F' ' '{ print $4 }' \
	      | xargs printf "$t,com_commit,%s\n"

    if [[ $masterslave == "slave" ]]; then
        echo "$adminout" | grep Com_queued | awk -F' ' '{ print $4 }' \
            | xargs printf "$t,com_queued,%s\n"
        echo "$adminout" | grep Com_dequeued | awk -F' ' '{ print $4 }' \
            | xargs printf "$t,com_dequeued,%s\n"
	      echo "$adminout" | grep Slave_producer_scheduled | awk -F' ' '{ print $4 }' \
    	      | xargs printf "$t,producer_scheduled,%s\n"
	      echo "$adminout" | grep Slave_dependency_next_waits | awk -F' ' '{ print $4 }' \
    	      | xargs printf "$t,next_waits,%s\n"

        echo "$statusout" | tr "\n" "\t" | cut -f81 | xargs printf "$t,secs_lags,%s\n"
    fi

    sleep 0.1
done

cd -
