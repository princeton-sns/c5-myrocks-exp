#/usr/bin/env bash

while [[ $(ps aux | grep oltpbench | wc -l) -gt 1 ]]; do
    sleep 0.2
done

