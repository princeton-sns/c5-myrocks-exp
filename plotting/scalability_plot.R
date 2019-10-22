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

line_plot <- function(data, x = x, y = y, color = color, shape = shape,
                      xlims = NULL, xbreaks = NULL, xtrans = "identity",
                      ylims = NULL, ybreaks = NULL, ytrans = "identity",
                      xtitle = NULL, ytitle = NULL, colortitle = NULL, shapetitle = NULL) {
  g <- ggplot(
    data,
    aes(
      x = !!enquo(x),
      y = !!enquo(y),
      color = as.factor(!!enquo(color)),
      shape = as.factor(!!enquo(shape))
    )
  )

  if (is.null(xbreaks)) {
    xbreaks <- waiver()
  } else if (is.numeric(xbreaks) && length(xbreaks) == 1) {
    xbreaks <- pretty_breaks(n = xbreaks)
  }

  if (is.null(ybreaks)) {
    ybreaks <- waiver()
  } else if (is.numeric(ybreaks) && length(ybreaks) == 1) {
    ybreaks <- pretty_breaks(n = ybreaks)
  }

  xlims

  g <- g +
    geom_point(size = 3, stroke = 2) +
    scale_x_continuous(
      limits = xlims,
      breaks = xbreaks,
      expand = c(0, 0),
      trans = xtrans
    ) +
    scale_y_continuous(
      limits = ylims,
      breaks = ybreaks,
      expand = c(0, 0),
      trans = ytrans
    ) +
    labs(
      x = xtitle,
      y = ytitle,
      color = colortitle,
      shape = shapetitle
    ) +
    guides(color = guide_legend(nrow = 1)) +
    scale_shape_discrete(
      solid = FALSE
    ) +
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
      panel.spacing = unit(0, "lines"),
      strip.background = element_blank(),
      strip.placement = "outside",
      strip.text = element_text(size = 28, color = "black", vjust = 3.0),
      plot.margin = margin(5, 5, 5, 5),
    )

  return(g)
}

data <- data %>%
  mutate(
    server = fct_relevel(server, c("Primary"))
  ) %>%
  filter(n_workers == n_clients)

p <- line_plot(data,
  x = n_workers, y = commit_rate_tps, color = server, shape = n_inserts,
  xtitle = "# Replica Workers", ytitle = "Commit Rate", 
  xlims = c(1, 290), xtrans = "log2",
  ylims = c(0, 800), ybreaks = 8
)

# Output
width <- 10 # inches
height <- (9 / 16) * width

ggsave(out, plot = p, height = height, width = width, units = "in")
