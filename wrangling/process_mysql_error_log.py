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

    return parser.parse_args()


def process_replication_lag(writer, reader, server):
    writer.writerow(["server", "lag_type", "txn_id", "lag"])

    rows = []
    rep_start = re.compile(r".*Slave SQL thread initialized, starting replication.*$")
    comm_ms = re.compile(r".*jhelt,comm_ms,.*$")
    snap_ms = re.compile(r".*jhelt,snap_ms,.*$")
    for line in reader:
        match = rep_start.match(line)
        if match:
            rows = [] # Only keep commits after last time we start replication

        match = comm_ms.match(line)
        if match:
            parts = line.split(",")
            seqno = int(parts[2])
            master_commit_ts_ms = int(parts[3])
            slave_commit_ts_ms = int(parts[4])
            rows.append(("master_comm_ms", seqno, master_commit_ts_ms))
            rows.append(("slave_comm_ms", seqno, slave_commit_ts_ms))

        match = snap_ms.match(line)
        if match:
            parts = line.split(",")
            seqno = int(parts[2])
            snap_ts_ms = int(parts[3])
            rows.append(("snap_ms", seqno, snap_ts_ms))

    seqno_master_ts = {}
    seqno_slave_ts = {}
    last_snap = 0
    for r in rows:
        metric = r[0]
        seqno = r[1]
        commit_ts_ms = r[2]

        if metric == "master_comm_ms":
            seqno_master_ts[seqno] = commit_ts_ms
        elif metric == "slave_comm_ms":
            seqno_slave_ts[seqno] = commit_ts_ms

            lag = commit_ts_ms - seqno_master_ts[seqno]
            writer.writerow((server, "replication", seqno, lag))

            del seqno_master_ts[seqno]
        elif metric == "snap_ms":
            for s in range(last_snap, seqno):
                if s in seqno_slave_ts:
                    lag = commit_ts_ms - seqno_slave_ts[s]
                    writer.writerow((server, "snapshot", s, lag))

                    del seqno_slave_ts[s]
                else:
                    print("WARNING: slave ts not found for seqno", s)

            last_snap = seqno


def main():
    args = parse_args()

    server = args.server
    input = args.input
    outdir = args.outdir

    with open(os.path.join(outdir, "replication_lag.{}.csv".format(server)), "w+") as f:
        writer = csv.writer(f)
        reader = input.readlines()
        process_replication_lag(writer, reader, server)


if __name__ == "__main__":
    main()
