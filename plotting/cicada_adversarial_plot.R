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

# Fix throughput
data <- data %>%
    mutate(
        n_commits = if_else(server == "Primary", n_commits, n_commits / (n_inserts+1)),
        commit_rate_tps = if_else(server == "Primary", commit_rate_tps, commit_rate_tps / (n_inserts+1)),
        relative_commit_rate = if_else(server == "Primary", relative_commit_rate, relative_commit_rate / (n_inserts+1)),
    )

data

n_clients <- data %>%
    filter(server == "Primary") %>%
    group_by(n_inserts, n_clients) %>%
    summarize(
        mean_commit_rate = mean(commit_rate_tps),
        med_commit_rate = median(commit_rate_tps)
    ) %>%
    group_by(n_inserts) %>%
    mutate(
        max_mean_commit_rate = max(mean_commit_rate),
        max_med_commit_rate = max(med_commit_rate)
    ) %>%
    filter(med_commit_rate == max_med_commit_rate) %>%
    select(n_inserts, n_clients)


data <- data %>%
    semi_join(n_clients) %>%
    ## filter(server != "Primary") %>%
    group_by(server, n_clients, n_inserts, n_workers) %>%
    summarize(
        med_relative_commit_rate = median(relative_commit_rate),
        mean_relative_commit_rate = mean(relative_commit_rate),
        sd = sd(relative_commit_rate),
        se = sd(relative_commit_rate) / sqrt(n())
    ) %>%
    group_by(server, n_clients, n_inserts) %>%
    mutate(
        max_mean_relative_commit_rate = max(mean_relative_commit_rate),
        max_med_relative_commit_rate = max(med_relative_commit_rate)
    ) %>%
    filter(med_relative_commit_rate == max_med_relative_commit_rate) %>%
    ungroup() %>%
    mutate(
        n_inserts = factor(n_inserts),
        med_relative_commit_rate = if_else(med_relative_commit_rate > 1.0, 1.0, med_relative_commit_rate),
        server = fct_relevel(server, c("CopyCat", "CopyCat+ccRO", "CopyCat+kRO", "CopyCat+CO", "KuaFu", "KuaFu+kRO", "KuaFu+CO"))
    )

data


## p <- bar_chart(summary,
##                x = n_inserts, y = med_relative_commit_rate, fill = server,
##                ylims = c(0, 1.02), ybreaks = 6,
##                xtitle = "Inserts per Transaction", ytitle = "Relative Throughput"
##                )


## if (is.null(ybreaks)) {
##     ybreaks <- waiver()
## } else if (is.numeric(ybreaks) && length(ybreaks) == 1) {
##     ybreaks <- pretty_breaks(n = ybreaks)
## }

barwidth <- 0.9
errorwidth <- 0.4

p <- ggplot(data, aes(x = n_inserts, y = med_relative_commit_rate, fill = server)) +
    geom_col(position = position_dodge(width = barwidth), color = "black") +
    ## geom_errorbar(position = position_dodge(width = barwidth), width = errorwidth) +
    scale_y_continuous(
        limits = c(0, 1.02),
        breaks = pretty_breaks(n = 6),
        expand = c(0, 0)
    ) +
    scale_fill_brewer(type = "div", palette = "Paired") +
    labs(
        x = "Inserts per Transactions",
        y = "Relative Throughput",
        fill = ""
    ) +
                                        # guides(fill = guide_legend(nrow = 2)) +
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

                                        # Output
width <- 10 # inches
height <- (9 / 16) * width

ggsave(out, plot = p, height = height, width = width, units = "in")
