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


def process_commit_rates(writer, reader, server):
    writer.writerow(["server", "total_time_ms", "n_commits", "commit_rate_tps"])

    rows = list(filter(lambda r: r[1] == "com_commit", reader))

    min_commits = float("inf")
    min_time = float("-inf")
    max_commits = float("-inf")
    max_time = float("inf")

    for row in rows:
        commits = int(row[2])
        t = int(row[0])
        
        if commits <= min_commits:
            min_commits = commits
            min_time = t

        if commits > max_commits:
            max_commits = commits
            max_time = t
    
    total_time_ms = max_time - min_time
    n_commits = max_commits - min_commits
    commit_rate =  1000 * float(n_commits) / total_time_ms

    writer.writerow([server, total_time_ms, n_commits, commit_rate])


def main():
    args = parse_args()

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
        process_commit_rates(writer, reader, server)


if __name__ == "__main__":
    main()
