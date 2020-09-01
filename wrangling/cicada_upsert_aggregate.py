#!/usr/bin/env python3

import argparse
import csv
import os
import re


MILLISECONDS = 1000
IMPL_NAMES = {
    "MICA_CCC_NONE": "none",
    "MICA_CCC_COPYCAT": "fdr"
}


def parse_args():
    parser = argparse.ArgumentParser()

    parser.add_argument("-i", "--inputdir", required=True)
    parser.add_argument("-o", "--outdir", required=True)

    return parser.parse_args()

def extract_throughputs(filename):
    elapsed_re = re.compile(r"elapsed:\s+([0-9\.]+)")
    transactions_re = re.compile(r"transactions:\s+([0-9\.]+)")

    throughputs = []

    with open(filename, "r") as f:
        filetext = f.read()
        transactions_matches = transactions_re.findall(filetext)
        elapsed_matches = elapsed_re.findall(filetext)

        assert(len(transactions_matches) == len(elapsed_matches))

        transactions_matches = list(map(lambda m: int(m), transactions_matches))
        elapsed_matches = list(map(lambda m: float(m) * MILLISECONDS, elapsed_matches))

        for i in range(len(transactions_matches)):
            throughputs.append((transactions_matches[i], elapsed_matches[i]))

    return throughputs

def process_throughputs(inputdir):

    i_re = re.compile(r".*__seq@(\S+?)__.*")
    impl_re = re.compile(r".*__ccc@(\S+?)__.*")
    nclients_re = re.compile(r".*__thread_count@(\S+?)__.*")
    nworkers_re = re.compile(r".*__thread_count@(\S+?)__.*")
    upsert_re = re.compile(r".*[__]?use_upsert@(\S+?)[__]?.*")

    for entry in os.scandir(inputdir):
        if entry.is_file() and not re.match(r".*\.failed-*", entry.path) and not re.match(r".*\.csv", entry.path):
            i = i_re.match(entry.path).group(1)
            impl = impl_re.match(entry.path).group(1)
            nclients = nclients_re.match(entry.path).group(1)
            nworkers = nworkers_re.match(entry.path).group(1)
            use_upsert = upsert_re.match(entry.path).group(1)

            impl = IMPL_NAMES[impl]
            ro_impl = "none"

            tputs = extract_throughputs(entry.path)

            newdir = "{}_{}_{}u_{}c_{}w_{:02.0f}".format(impl, ro_impl, use_upsert, nclients, nworkers, int(i))
            os.makedirs(os.path.join(inputdir, newdir), exist_ok=True)

            server = "primary"
            for tput in tputs:
                commit_rate = tput[0] / (tput[1] / 1000)
                with open(os.path.join(inputdir, newdir, "commit_rate.{}.csv".format(server)), "w+") as f:
                    writer = csv.writer(f)
                    writer.writerow(["server", "total_time_ms", "n_commits", "commit_rate_tps"])
                    writer.writerow([server, str(tput[1]), str(tput[0]), str(commit_rate)])

                server = "backup"

def main():
    args = parse_args()

    inputdir = args.inputdir
    outdir = args.outdir

    process_throughputs(inputdir)

    os.system("./upsert_aggregate.sh -i {} -o {}".format(inputdir, outdir))


if __name__ == "__main__":
    main()
