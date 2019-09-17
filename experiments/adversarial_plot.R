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
      limits = ylims,
      breaks = ybreaks,
      expand = c(0, 0)
    ) +
    labs(
      x = xtitle,
      y = ytitle,
      fill = filltitle
    ) +
    scale_fill_npg() +
    theme_classic(
      base_size = 24,
      base_family = "serif"
    ) +
    theme(
      axis.text.x = element_text(size = 24, color = "black"),
      axis.text.y = element_text(size = 24, color = "black"),
      legend.text = element_text(size = 18, color = "black"),
      legend.title = element_text(size = 24, color = "black"),
      legend.position = "top",
      legend.justification = "left",
      legend.margin = margin(0, 0, 0, 0),
      panel.grid.major.y = element_line(color = "grey")
    )

  return(g)
}

summary <- data %>%
  filter(server != "Primary") %>%
  group_by(n_clients, n_inserts, server) %>%
  summarize(
    mean_relative_commit_rate = mean(relative_commit_rate),
    sd = sd(relative_commit_rate),
    se = sd(relative_commit_rate) / sqrt(n())
  ) %>%
  mutate(
    server = fct_relevel(server, c("FDR", "FDR+RO", "KuaFu", "KuaFu+RO"))
  )

p <- bar_chart(summary,
  x = n_inserts, y = mean_relative_commit_rate, se = se, fill = server,
  ylims = c(0, 1.05), ybreaks = 10,
  xtitle = "Inserts per Transaction", ytitle = "Relative Commit Rate"
)

# Output
width <- 10 # inches
height <- (9 / 16) * width

ggsave(out, plot = p, height = height, width = width, units = "in")
