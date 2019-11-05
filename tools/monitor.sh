#!/usr/bin/env bash

builddir=$1
cnf=$2

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 builddir cnf" >&2
    exit 1
fi

cd $builddir

while true; do
    out=$(./bin/mysqladmin --defaults-file=$cnf extended-status)
    t=$(date +%s%3N)

    echo "$out" | grep Com_commit | awk -F' ' '{ print $4 }' \
	| xargs printf "$t,com_commit,%s\n"

    if [[ $cnf == *"slave.cnf"* ]]; then
  echo "$out" | grep Com_queued | awk -F' ' '{ print $4 }' \
      | xargs printf "$t,com_queued,%s\n"
  echo "$out" | grep Com_dequeued | awk -F' ' '{ print $4 }' \
      | xargs printf "$t,com_dequeued,%s\n"
	echo "$out" | grep Slave_producer_scheduled | awk -F' ' '{ print $4 }' \
    	    | xargs printf "$t,producer_scheduled,%s\n"
	echo "$out" | grep Slave_dependency_next_waits | awk -F' ' '{ print $4 }' \
    	    | xargs printf "$t,next_waits,%s\n"
    fi
    
    sleep 0.1
done

cd -
