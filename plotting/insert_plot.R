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

## summary <- data %>%
##     filter(server == "Primary") %>%
##     group_by(impl, server, n_clients, n_workers) %>%
##     summarize(
##         med_commit_rate_tps = median(commit_rate_tps),
##         med_relative_commit_rate = median(relative_commit_rate)
##     ) %>%
##     ungroup() %>%
##     mutate(
##         impl = fct_recode(impl, `With Logging` = "CopyCat", `Without Logging` = "none")
##     )

data <- data %>%
    filter(impl != "none") %>%
    group_by(impl, server, n_clients, n_workers) %>%
    summarize(
        med_commit_rate_tps = median(commit_rate_tps),
        med_relative_commit_rate = median(relative_commit_rate)
    ) %>%
    ungroup() %>%
    mutate(
        server = fct_relevel(server, c("Primary", "CopyCat", "CopyCat+ccRO", "CopyCat+kRO", "CopyCat+CO", "KuaFu", "KuaFu+kRO", "KuaFu+CO")),
        n_clients = factor(n_clients)
    )

data

barwidth <- 0.9
errorwidth <- 0.4

p <- ggplot(
    data,
    aes(x = n_clients, y = med_commit_rate_tps, fill = server)
    ) +
    geom_col(position = position_dodge(width = barwidth), color = "black") +
    ## geom_errorbar(position = position_dodge(width = barwidth), width = errorwidth) +
    scale_y_continuous(
        labels = scientific,
        limits = c(0, 4.02e7),
        breaks = pretty_breaks(n = 5),
        expand = c(0, 0),
    ) +
    scale_fill_brewer(type = "div", palette = "Paired") +
    labs(
        x = "Number of Clients",
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
