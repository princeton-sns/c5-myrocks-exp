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

boxplot <- function(data, x = x, fill = fill,
                    ymin = ymin, lower = lower, middle = middle, upper = upper, ymax = ymax,
                    ylims = NULL, ybreaks = NULL,
                    xtitle = NULL, ytitle = NULL, filltitle = NULL) {
  g <- ggplot(
    data,
    aes(
      x = as.factor(!!enquo(x)),
      ymin = !!enquo(ymin),
      lower = !!enquo(lower),
      middle = !!enquo(middle),
      upper = !!enquo(upper),
      ymax = !!enquo(ymax),
      fill = as.factor(!!enquo(fill))
    )
  )

  if (is.null(ybreaks)) {
    ybreaks <- waiver()
  } else if (is.numeric(ybreaks) && length(ybreaks) == 1) {
    ybreaks <- pretty_breaks(n = ybreaks)
  }

  boxwidth <- 0.9
  errorwidth <- 0.5

  g <- g +
    geom_errorbar(position = position_dodge(width = boxwidth), width = errorwidth, size = 1.0) +
    geom_boxplot(stat = "identity", width = boxwidth, size = 0.9) +
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

summary <- data %>%
    mutate(
        chunk = as_factor(chunk),
        chunk = fct_recode(chunk, "0-30 Secs" = "0", "30-60 Secs" = "1", "60-90 Secs" = "2"),
        chunk = fct_relevel(chunk, c("0-30 Secs", "30-60 Secs", "60-90 Secs"))
    ) %>%
    group_by(impl, n_clients, n_workers, n_roclients, lag_type, chunk) %>%
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
             x = n_roclients, fill = chunk,
             ymin = lag0, lower = lag25, middle = lag50, upper = lag75, ymax = lag100,
             ylims = c(0, 410), ybreaks = 8,
             xtitle = "Number of Read-only Clients", ytitle = "Replication Lag (ms)",
             filltitle = "")

# Output
width <- 10 # inches
height <- (9 / 16) * width

ggsave(out, plot = p, height = height, width = width, units = "in")
