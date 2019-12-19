#!/usr/bin/env Rscript
library("argparse")
library("dplyr")
library("forcats")
library("ggplot2")
library("ggsci")
library("readr")
library("scales")
library("tidyr")

parser <- ArgumentParser()

parser$add_argument("-o", "--out", type = "character", help = "out file for plot")
parser$add_argument("csvs",
  metavar = "csv", type = "character", nargs = "+",
  help = "list of csv files to read in"
)

args <- parser$parse_args()

out <- args$out

data <- tibble()
for (csv in args$csvs) {
  data <- bind_rows(data, read_csv(csv))
}

summary <- data %>%
    group_by(impl, n_clients, n_workers, server) %>%
    mutate(
        med_relative_commit_rate = median(relative_commit_rate)
    ) %>%
    ungroup() %>%
    filter(server != "Primary" & relative_commit_rate == med_relative_commit_rate) %>%
    select(server, commit_rate_tps, relative_commit_rate)

summary
