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

bar_chart <- function(data, x = x, y = y, se = se, fill = fill,
                      ylims = NULL, ybreaks = NULL,
                      xtitle = NULL, ytitle = NULL, filltitle = NULL) {
  g <- ggplot(
    data,
    aes(
      x = as.factor(!!enquo(x)),
      y = !!enquo(y),
      fill = as.factor(!!enquo(fill)),
      ymin = !!enquo(y) - !!enquo(se),
      ymax = !!enquo(y) + !!enquo(se)
    )
  )

  if (is.null(ybreaks)) {
    ybreaks <- waiver()
  } else if (is.numeric(ybreaks) && length(ybreaks) == 1) {
    ybreaks <- pretty_breaks(n = ybreaks)
  }

  barwidth <- 0.9
  errorwidth <- 0.4

  g <- g +
    geom_col(position = position_dodge(width = barwidth), color = "black") +
    geom_errorbar(position = position_dodge(width = barwidth), width = errorwidth) +
    scale_y_continuous(
      labels = comma,
      limits = ylims,
      breaks = ybreaks,
      expand = c(0, 0)
    ) +
    labs(
      x = xtitle,
      y = ytitle,
      fill = filltitle
    ) +
    guides(
        fill = FALSE
    ) +
    scale_fill_brewer(type = "div", palette = "Paired") +
    theme_classic(
      base_size = 26,
      base_family = "serif"
    ) +
    theme(
      axis.text = element_text(size = 24, color = "black"),
      axis.title = element_text(size = 28, color = "black"),
      legend.text = element_text(size = 24, color = "black"),
      legend.title = element_text(size = 28, color = "black"),
      legend.position = "top",
      legend.justification = "left",
      legend.margin = margin(0, 0, 0, 0),
      panel.grid.major.y = element_line(color = "black", linetype = 2),
      panel.spacing = unit(0, "mm"),
      plot.margin = margin(15, 5, 5, 5),
    )

  return(g)
}

summary <- data %>%
  group_by(impl, n_clients, n_workers, server) %>%
  summarize(
    mean_commit_rate = mean(commit_rate_tps),
    sd = sd(commit_rate_tps),
    se = sd(commit_rate_tps) / sqrt(n())
  ) %>%
  mutate(
    server = fct_relevel(server, c("FDR", "FDR+fRO", "FDR+kRO", "FDR+CO", "KuaFu", "KuaFu+kRO", "KuaFu+CO"))
  )

summary

# p <- bar_chart(summary,
#   x = server, y = mean_commit_rate, se = se, fill = server,
#   ylims = c(0, 30000), ybreaks = 7,
#   ytitle = "Commit Rate (Txns/Sec)"
# )
#
# # Output
# width <- 10 # inches
# height <- (9 / 16) * width
#
# ggsave(out, plot = p, height = height, width = width, units = "in")
