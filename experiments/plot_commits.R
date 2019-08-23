#!/usr/bin/env Rscript
library("argparse")
library("dplyr")
library("ggplot2")
library("readr")
library("scales")

parser <- ArgumentParser()

parser$add_argument('-o', '--out', type='character', help='out file for plot')
parser$add_argument('csvs', metavar='csv', type='character', nargs='+',
                    help='list of csv files to read in')

args <- parser$parse_args()

out <- args$out

data <- tibble()
for (csv in args$csvs) {
    data <- bind_rows(data, read_csv(csv))
}

data <- data %>% 
  mutate(
    time_s = time_ms / 1000
  )

# Text
title <- 'Commits Processed vs. Time'
xlab <- 'Time (s)'
ylab <- 'Commits Processed'
colorlab <- 'Server'
colorlabs <- c('Backup', 'Primary')

# Limits
xlims <- NULL # c(0, 60)
xbreaks <- 30 # 100
ylims <- NULL # c(0, 1600)
ybreaks <- 10

# Output
width <- 10 # inches
height <- (9/16) * width

p <- data %>%
    ggplot(aes(x = time_s, y = commits_processed, color = server, shape = server)) +
    geom_line() +
    geom_point(size = 2) +
    labs(
        title = title,
        x = xlab,
        y = ylab,
        color = colorlab
    ) +
    scale_x_continuous(
        labels = comma,
        breaks = pretty_breaks(n = xbreaks),
        limits = xlims
    ) +
    scale_y_continuous(
        labels = comma,
        breaks = pretty_breaks(n = ybreaks),
        limits = ylims
    ) +
    scale_color_brewer(
        name = colorlab,
        labels = colorlabs,
        palette = 'Set1'
    ) +
    scale_shape_discrete(
        name = colorlab,
        labels = colorlabs
    ) +
    theme_classic(base_size = 14, base_family = 'serif') +
    theme(
        legend.position = 'bottom'
    )

ggsave(out, plot = p, height = height, width = width, units = 'in')


