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


def process_commits(writer, reader, server):
    writer.writerow(["server", "time_ms", "commits_processed"])

    rows = filter(lambda r: r[1] == "com_commit", reader)

    i = 0
    for row in rows:
        if i == 0:
            start_time = int(row[0])
            start_commit = int(row[2])

        t = int(row[0]) - start_time
        c = int(row[2]) - start_commit

        writer.writerow([server, t, c])

        i += 1


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

    with open(os.path.join(outdir, "commit_rate.{}.csv".format(args.server)), "w+") as f:
        writer = csv.writer(f)
        reader = csv.reader(input)
        process_commit_rates(writer, reader, server, duration_s)


if __name__ == "__main__":
    main()
