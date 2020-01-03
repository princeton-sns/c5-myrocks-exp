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

boxplot <- function(data, x = x, y = y, fill = fill,
                      ylims = NULL, ybreaks = NULL,
                      xtitle = NULL, ytitle = NULL, filltitle = NULL) {
  g <- ggplot(
    data,
    aes(
      x = as.factor(!!enquo(x)),
      y = !!enquo(y),
      fill = as.factor(!!enquo(fill)),
    )
  )

  if (is.null(ybreaks)) {
    ybreaks <- waiver()
  } else if (is.numeric(ybreaks) && length(ybreaks) == 1) {
    ybreaks <- pretty_breaks(n = ybreaks)
  }

  g <- g +
    geom_boxplot() +
    ## geom_violin() +
    scale_y_continuous(
      limits = ylims,
      breaks = ybreaks,
      expand = c(0, 0)
    ) +
    scale_fill_brewer(type = "div", palette = "Paired") +
    labs(
      x = xtitle,
      y = ytitle,
      fill = filltitle
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
    )

min_rep_lag <- min_lag %>%
    filter(lag_type == "replication") %>%
    pull(min_lag)

min_snap_lag <- min_lag %>%
    filter(lag_type == "snapshot") %>%
    pull(min_lag)

summary <- data %>%
    mutate(
        lag = case_when(
            lag_type == "replication" ~ lag - min_rep_lag,
            lag_type == "snapshot" ~ lag - min_snap_lag
        )
    )

summary %>% filter(lag >= 500)

summary %>%
    group_by(server, lag_type) %>%
    summarize(
        avg = mean(lag),
        med = median(lag),
        `25` = quantile(lag, probs = 0.25),
        `75` = quantile(lag, probs = 0.75)
    )

p <- boxplot(summary,
  x = server, y = lag, fill = lag_type,
  ylims = c(0, 600), ybreaks = 7,
  xtitle = "Server", ytitle = "Replication Lag (ms)", filltitle = "Lag Type"
)

# Output
width <- 10 # inches
height <- (9 / 16) * width

ggsave(out, plot = p, height = height, width = width, units = "in")
