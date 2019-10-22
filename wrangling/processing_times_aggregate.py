#!/usr/bin/env python3

import argparse
import csv
import json
import os
import re
import subprocess


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("-i", "--input", required=True, type=argparse.FileType("r"))
    parser.add_argument("-o", "--output", required=True, type=argparse.FileType("w+"))

    return parser.parse_args()


def process(writer, reader):
    rows = []
    r = re.compile(r".*jhelt,.*$")
    for line in reader:
        match = r.match(line)
        if match:
            parts = line.split(",")
            metric = parts[1]
            time = int(parts[2])
            ev_type = parts[3]
            ev_id = parts[4].strip()
            rows.append((metric, time, ev_type, ev_id))

    start_times = {}
    wait_times = {}
    process_times = {}
    ev_types = {}
    row_start_times = {}
    row_times = {}

    for r in rows:
        time = r[1]
        ev_type = r[2]
        ev_id = r[3]

        if ev_id not in ev_types:
            ev_types[ev_id] = ev_type
        elif ev_types[ev_id] != ev_type:
            print("WARNING: event type changed", ev_id)
        
        if r[0] == "call_execute":
            if ev_id not in start_times:
                start_times[ev_id] = time
            else:
                print("WARNING: Possibly duplicate event IDs", ev_id)
                
        elif r[0] == "begin_execute":
            if ev_id in start_times:
                if ev_id not in wait_times:
                    wait_times[ev_id] = time - start_times[ev_id]
                else:
                    print("WARNING: Possibly duplicate event IDs", ev_id)
                    
        elif r[0] == "finish_execute":
            if ev_id in wait_times:
                if ev_id not in process_times:
                    process_times[ev_id] = (time - start_times[ev_id]) - wait_times[ev_id]
                else:
                    print("WARNING: Possibly duplicate event IDs", ev_id)

        elif r[0] == "begin_rows":
            if ev_id not in row_start_times:
                row_start_times[ev_id] = time
            else:
                print("WARNING: Possibly duplicate event IDs", ev_id)

        elif r[0] == "end_rows":
            if ev_id in row_start_times:
                if ev_id not in row_times:
                    row_times[ev_id] = time - row_start_times[ev_id]
                else:
                    print("WARNING: Possibly duplicate event IDs", ev_id)


    writer.writerow(["metric", "ev_id", "time_micros", "ev_type"])
    for k,v in wait_times.items():
        writer.writerow(["wait", k, v, ev_types[k]])

    for k,v in process_times.items():
        writer.writerow(["process", k, v, ev_types[k]])

    for k,v in row_times.items():
        writer.writerow(["row", k, v, ev_types[k]])
        
        

def main():
    args = parse_args()

    input = args.input
    output = args.output

    writer = csv.writer(output)
    reader = input.readlines()
    process(writer, reader)


if __name__ == "__main__":
    main()
