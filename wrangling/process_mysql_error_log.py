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
    parser.add_argument("-o", "--outdir", required=True)
    parser.add_argument("-s", "--server", required=True)
    parser.add_argument("-d", "--duration", required=True)

    return parser.parse_args()


def process(writer, reader, duration_s):
    rows = []
    rep_start = re.compile(r".*Slave SQL thread initialized, starting replication.*$")
    r = re.compile(r".*jhelt,.*$")
    for line in reader:
        match = rep_start.match(line)
        if match:
            rows = [] # Only keep commits after last time we start replication
        
        match = r.match(line)
        if match:
            parts = line.split(",")
            metric = parts[1]
            time_ms = int(parts[2]) / 1000
            d = parts[3:]
            rows.append((metric, time_ms, d))

    # Sort by time
    rows = sorted(rows, key=lambda r: r[1])

    # Adjust for start time
    start_time = min(map(lambda r: r[1], rows))
    rows = list(map(lambda r: (r[0], r[1] - start_time, r[2]), rows))

    be_ids = {}
    # Process metrics
    i = 0
    for r in rows:
        metric = r[0]
        d = r[2]

        if metric == "enqueue_dep":
            rows[i] = (r[0], r[1], i+1)
        elif metric == "event_execute":
            rows[i] = ("execute_{}".format(d[0]), r[1], int(d[1]))
        elif metric == "transaction_execute":
            rows[i] = (r[0], r[1], int(d[0]))
        elif metric == "start_be":
            be_id = int(d[0])
            if be_id in be_ids:
                print("WARNING: Found duplicate begin event IDs: ", be_id)
            else:
                be_ids[be_id] = True

        i += 1


    # start_assigned = float("inf")
    # start_time = float("-inf")

    # for row in rows:
    #     assigned = int(row[2])
    #     t = int(row[0])
        
    #     if assigned >= 10 and assigned <= start_assigned:
    #         start_time = int(row[0])
    #         start_assigned = int(row[2])

    #     t = int(row[0]) - start_time
    #     a = int(row[2]) - start_assigned


    # duration_ms = duration_s * 1000
    # end = min(rows, key=lambda r: abs((start_time + duration_ms) - int(r[0])))
    # end_time = int(end[0])

    # print(start_time, start_assigned)
    # print(end_time)

    # event_rows = filter(lambda r: r[1] == "begin_event" or r[1] == "end_event", rows)
    # active_workers = []
    # n = 0
    # for row in event_rows:
    #     if row[1] == "begin_event":
    #         n += 1
    #     elif row[1] == "end_event":
    #         n -= 1

    #     active_workers.append([row[0], "active_workers", n])
    # rows = rows + active_workers

    # event_rows = filter(lambda r: r[1] == "thread_sleep" or r[1] == "thread_wake", rows)
    # asleep_workers = []
    # n = 0
    # for row in event_rows:
    #     if row[1] == "thread_sleep":
    #         n += 1
    #     elif row[1] == "thread_wake":
    #         n -= 1

    #     asleep_workers.append([row[0], "asleep_workers", n])
    # rows = rows + asleep_workers

    # rows = sorted(rows, key=lambda r: float(r[0]))
    # rows = filter(lambda r: start_time <= int(r[0]) and int(r[0]) <= end_time, rows)
    # rows = map(lambda r: [r[1], int(r[0]) - start_time, r[2]], rows)

    # events = [
    #     "mts_groups_assigned",
    #     "begin_event",
    #     "end_event",
    #     "dep_wait", "dep_wake",
    #     "thread_wake", "thread_sleep",
    #     "m_next_seqno",
    #     "lwm_seqno",
    #     # "active_workers",
    #     # "dep_prepared",
    # ]
    # rows = filter(lambda r: r[0] in events, rows)

    writer.writerow(["server", "time_ms", "commits_processed"])
    for r in rows:
        writer.writerow(r)


def main():
    args = parse_args()

    duration_s = int(args.duration)
    server = args.server
    input = args.input
    outdir = args.outdir

    with open(os.path.join(outdir, "metrics.{}.csv".format(args.server)), "w+") as f:
        writer = csv.writer(f)
        reader = input.readlines()
        process(writer, reader, duration_s)


if __name__ == "__main__":
    main()
