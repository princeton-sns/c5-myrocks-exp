#!/usr/bin/env bash

pid=$1

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 pid" >&2
    exit 1
fi

kill -9 $pid
