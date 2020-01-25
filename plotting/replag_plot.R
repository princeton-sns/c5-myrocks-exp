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

boxplot <- function(data, x = x,
                    ymin = ymin, lower = lower, middle = middle, upper = upper, ymax = ymax,
                    ylims = NULL, ybreaks = NULL,
                    xtitle = NULL, ytitle = NULL) {
  g <- ggplot(
    data,
    aes(
      x = as.factor(!!enquo(x)),
      ymin = !!enquo(ymin),
      lower = !!enquo(lower),
      middle = !!enquo(middle),
      upper = !!enquo(upper),
      ymax = !!enquo(ymax),
    )
  )

  if (is.null(ybreaks)) {
    ybreaks <- waiver()
  } else if (is.numeric(ybreaks) && length(ybreaks) == 1) {
    ybreaks <- pretty_breaks(n = ybreaks)
  }

  g <- g +
    geom_errorbar(width = 0.5) +
    geom_boxplot(stat = "identity", fill = "grey") +
    scale_y_continuous(
      limits = ylims,
      breaks = ybreaks,
      expand = c(0, 0)
    ) +
    labs(
      x = xtitle,
      y = ytitle
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

  return(g)
}

min_lag <- data %>%
    group_by(lag_type) %>%
    summarize(
        min_lag = min(lag)
    ) %>%
    pull(min_lag)

min_lag

summary <- data %>%
    mutate(
        lag = lag - min_lag
    ) %>%
    group_by(impl, n_clients, n_workers, n_roclients, lag_type) %>%
    summarize(
        lagavg = mean(lag),
        lag0 = min(lag),
        lag25 = quantile(lag, 0.25),
        lag50 = median(lag),
        lag75 = quantile(lag, 0.75),
        lag100 = max(lag)
    )

summary

p <- boxplot(summary,
             x = n_roclients,
             ymin = lag0, lower = lag25, middle = lag50, upper = lag75, ymax = lag100,
             ylims = c(0, 410), ybreaks = 8,
             xtitle = "Number of RO Clients", ytitle = "Replication Lag (ms)")

# Output
width <- 10 # inches
height <- (9 / 16) * width

ggsave(out, plot = p, height = height, width = width, units = "in")
