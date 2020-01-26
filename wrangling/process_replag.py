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
    parser.add_argument("-c", "--clients", required=True)
    parser.add_argument("-w", "--workers", required=True)
    parser.add_argument("-r", "--roclients", required=True)

    return parser.parse_args()


def process_replication_lag(writer, reader, duration_s, impl, nclients, nworkers, nroclients):
    writer.writerow(["impl", "n_clients", "n_workers", "n_roclients", "lag_type", "txn_id", "lag"])

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

    final_rows = []
    seqno_master_ts = {}
    # seqno_slave_ts = {}
    last_snap = 0
    for r in rows:
        metric = r[0]
        seqno = r[1]
        commit_ts_ms = r[2]

        if metric == "master_comm_ms":
            seqno_master_ts[seqno] = commit_ts_ms
        # elif metric == "slave_comm_ms":
        #     seqno_slave_ts[seqno] = commit_ts_ms

        #     lag = commit_ts_ms - seqno_master_ts[seqno]
        #     final_rows.append((commit_ts_ms, "replication", seqno, lag))

        elif metric == "snap_ms":
            for s in range(last_snap, seqno):
                # if s in seqno_slave_ts:
                #     lag = commit_ts_ms - seqno_slave_ts[s]
                #     final_rows.append((commit_ts_ms, "snapshot", s, lag))
                #     del seqno_slave_ts[s]
                # else:
                #     print("WARNING: slave ts not found for seqno", s)

                if s in seqno_master_ts:
                    lag = commit_ts_ms - seqno_master_ts[s]
                    final_rows.append((commit_ts_ms, "total", s, lag))
                    del seqno_master_ts[s]
                else:
                    print("WARNING: master ts not found for seqno", s)

            last_snap = seqno

    final_rows = list(filter(lambda r: r[1] == "total", final_rows))
    min_lag = min(final_rows, key=lambda r: r[3])[3]

    print(min_lag)

    offset_ms = 15 * 1000
    duration_ms = duration_s * 1000

    start = min(final_rows, key=lambda r: r[0])[0] + offset_ms
    end = start + duration_ms - 2 * offset_ms

    final_rows = filter(lambda r: start <= r[0] and r[0] <= end, final_rows)
    final_rows = map(lambda r: (impl, nclients, nworkers, nroclients, r[1], r[2], r[3] - min_lag), final_rows)

    writer.writerows(final_rows)


def main():
    args = parse_args()

    duration_s = 120

    input = args.input
    outdir = args.outdir

    impl = args.server
    nclients = args.clients
    nworkers = args.workers
    nroclients = args.roclients

    with open(os.path.join(outdir, "replication_lag.csv"), "w+") as f:
        writer = csv.writer(f)
        reader = input.readlines()
        process_replication_lag(writer, reader, duration_s, impl,
                                nclients, nworkers, nroclients)


if __name__ == "__main__":
    main()
