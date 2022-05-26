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

data

data <- data %>%
    select(-relative_commit_rate) %>%
    mutate(
        n_commits = if_else(server == "Primary", n_commits, n_commits / (n_inserts+1)),
        commit_rate_tps = if_else(server == "Primary", commit_rate_tps, commit_rate_tps / (n_inserts+1)),
        server = case_when(
            impl == "none" ~ "Primary",
            impl == "CopyCat" & server == "Primary" ~ "Primary-Log",
            impl == "CopyCat" & server == "CopyCat" ~ "CopyCat"
        )
    )

data

primary <- data %>%
    filter(server == "Primary") %>%
    group_by(n_inserts, n_clients) %>%
    mutate(
        mean_commit_rate = mean(commit_rate_tps),
        med_commit_rate = median(commit_rate_tps)
    ) %>%
    group_by(n_inserts) %>%
    mutate(
        max_mean_commit_rate = max(mean_commit_rate),
        max_med_commit_rate = max(med_commit_rate)
    ) %>%
    filter(med_commit_rate == max_med_commit_rate) %>%
    select(server, n_inserts, commit_rate_tps)

backup <- data %>%
    filter(server %in% c("CopyCat")) %>%
    group_by(server, n_inserts, n_workers) %>%
    mutate(
        mean_commit_rate = mean(commit_rate_tps),
        med_commit_rate = median(commit_rate_tps)
    ) %>%
    group_by(n_inserts) %>%
    mutate(
        max_mean_commit_rate = max(mean_commit_rate),
        max_med_commit_rate = max(med_commit_rate)
    ) %>%
    filter(med_commit_rate == max_med_commit_rate) %>%
    select(server, n_inserts, commit_rate_tps)

data <- bind_rows(primary, backup) %>%
    group_by(server, n_inserts) %>%
    mutate(
        med_commit_rate = median(commit_rate_tps),
        min_commit_rate = min(commit_rate_tps),
        max_commit_rate = max(commit_rate_tps),
        ) %>%
    ungroup() %>%
    mutate(
        server = fct_relevel(server, c("Primary", "CopyCat", "Primary-Log", "CopyCat+ccRO", "CopyCat+kRO", "CopyCat+CO", "KuaFu", "KuaFu+kRO", "KuaFu+CO")),
        n_inserts = factor(n_inserts)
    )

data

barwidth <- 0.9
errorwidth <- 0.4

p <- ggplot(data, aes(x = n_inserts, y = med_commit_rate, ymin = min_commit_rate, ymax = max_commit_rate,fill = server)) +
    geom_col(position = position_dodge(width = barwidth), color = "black") +
    geom_errorbar(position = position_dodge(width = barwidth), width = errorwidth, size = 1) +
    scale_y_continuous(
        limits = c(0, 6.03e6),
        breaks = pretty_breaks(n = 7),
        labels = scientific,
        expand = c(0, 0)
    ) +
    scale_fill_brewer(type = "div", palette = "Paired") +
    labs(
        x = "Inserts Per Transaction",
        y = "Throughput (txns/sec)",
        fill = ""
    ) +
    theme_classic(
        base_size = 28,
        base_family = "serif"
    ) +
    theme(
        axis.text = element_text(size = 28, color = "black"),
        axis.title = element_text(size = 32, color = "black"),
        legend.text = element_text(size = 28, color = "black"),
        legend.title = element_text(size = 32, color = "black"),
        legend.position = "top",
        legend.justification = "left",
        legend.margin = margin(0, 0, -10, 0),
        panel.grid.major.y = element_line(color = "black", linetype = 2),
        panel.spacing = unit(0, "mm"),
        plot.margin = margin(5, 5, 10, 5),
        )

width <- 10 # inches
height <- (9 / 16) * width

ggsave(out, plot = p, height = height, width = width, units = "in")
