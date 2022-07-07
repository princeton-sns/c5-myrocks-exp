#!/usr/bin/env bash

# Set RO thread priorities and pin to cores
i=0
for pid in `ps -eL | grep my-oneconnectio | awk '{ print $2 }'`; do
        j=$((i % 10 + 10))
	renice -n -10 -p $pid
	taskset -c -p $j $pid
	i=$((i+1))
done

