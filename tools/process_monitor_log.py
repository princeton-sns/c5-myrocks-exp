#!/usr/bin/env python3

import argparse
import json
import os
import subprocess
import csv


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("-i", "--input", required=True, type=argparse.FileType("r"))
    parser.add_argument("-o", "--outdir", required=True)
    parser.add_argument("-s", "--server", required=True)
    parser.add_argument("-d", "--duration", required=True)

    return parser.parse_args()


def process_queued(writer, reader, server):
    writer.writerow(["server", "time_ms", "queued_txns"])

    rows = list(reader)
    queued_rows = list(filter(lambda r: r[1] == "com_queued", rows))
    dequeued_rows = list(filter(lambda r: r[1] == "com_dequeued", rows))

    i = 0
    rows = []
    for r in queued_rows:
        if i >= len(dequeued_rows):
            break

        rows.append((r[0], "com_queued", int(r[2]) - int(dequeued_rows[i][2])))
        i += 1

    if len(rows) == 0:
        return

    start_time = int(rows[0][0])

    for r in rows:
        t = int(r[0]) - start_time
        c = int(r[2])

        writer.writerow([server, t, c])


def process_commits(writer, reader, server):
    writer.writerow(["server", "time_ms", "commits_processed"])

    rows = list(filter(lambda r: r[1] == "com_commit", reader))

    if len(rows) == 0:
        return

    start_time = int(rows[0][0])
    start_commit = int(rows[0][2])
    for r in rows:
        if start_commit == int(r[2]) and start_time < int(r[0]):
            start_time = int(r[0])
            start_commit = int(r[2])

    rows = list(filter(lambda r: start_time <= int(r[0]), rows))

    for r in rows:
        t = int(r[0]) - start_time
        c = int(r[2]) - start_commit

        writer.writerow([server, t, c])


def process_commit_rates(writer, reader, server, duration_s):
    writer.writerow(["server", "total_time_ms", "n_commits", "commit_rate_tps"])

    rows = list(filter(lambda r: r[1] == "com_commit", reader))

    start_commits = float("inf")
    start_time = float("-inf")
    end_commits = float("-inf")
    end_time = float("inf")

    for row in rows:
        commits = int(row[2])
        t = int(row[0])
        
        if commits <= start_commits:
            start_commits = commits
            start_time = t

    duration_ms = duration_s * 1000
    end = min(rows, key=lambda r: abs((start_time + duration_ms) - int(r[0])))
    end_commits = int(end[2])
    end_time = int(end[0])

    total_time_ms = end_time - start_time
    n_commits = end_commits - start_commits
    commit_rate =  1000 * float(n_commits) / total_time_ms

    writer.writerow([server, total_time_ms, n_commits, commit_rate])


def main():
    args = parse_args()

    duration_s = int(args.duration)
    server = args.server
    input = args.input
    outdir = args.outdir

    with open(os.path.join(outdir, "commits.{}.csv".format(args.server)), "w+") as f:
        writer = csv.writer(f)
        reader = csv.reader(input)
        process_commits(writer, reader, server)

    input.seek(0)

    with open(os.path.join(outdir, "queued.{}.csv".format(args.server)), "w+") as f:
        writer = csv.writer(f)
        reader = csv.reader(input)
        process_queued(writer, reader, server)

    input.seek(0)

    with open(os.path.join(outdir, "commit_rate.{}.csv".format(args.server)), "w+") as f:
        writer = csv.writer(f)
        reader = csv.reader(input)
        process_commit_rates(writer, reader, server, duration_s)


if __name__ == "__main__":
    main()
