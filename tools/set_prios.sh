#!/usr/bin/env bash

# Set worker priorities and pin to cores
i=0
for pid in `ps -eL | grep my-hfunc | awk '{ print $2 }'`; do
	renice -n -20 -p $pid
	taskset -c -p $i $pid
	i=$((i+1))
done

for pid in `ps -eL | grep my-slaveworker | awk '{ print $2 }'`; do
	renice -n -20 -p $pid
	taskset -c -p $i $pid
	i=$((i+1))
done

