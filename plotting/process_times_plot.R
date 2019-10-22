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

histogram <- function(data, x = x, color = color,
                      xlims = NULL, xbreaks = NULL,
                      ylims = NULL, ybreaks = NULL,
                      xtitle = NULL, ytitle = NULL, colortitle = NULL) {
  g <- ggplot(
    data,
    aes(
      x = !!enquo(x),
      color = as.factor(!!enquo(color))
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

  ## barwidth <- 0.9
  ## errorwidth <- 0.4
  binwidth <- 100

  g <- g +
    geom_freqpoly(binwidth = binwidth) +
    ## geom_errorbar(position = position_dodge(width = barwidth), width = errorwidth) +
    scale_x_continuous(
      limits = xlims,
      breaks = xbreaks,
      expand = c(0, 0),
      labels = comma,
    ) +
    scale_y_continuous(
      limits = ylims,
      breaks = ybreaks,
      expand = c(0, 0),
      labels = comma,
    ) +
    scale_color_brewer(type = "div", palette = "Paired") +
    labs(
      x = xtitle,
      y = ytitle,
      color = colortitle
    ) +
    ## guides(fill = guide_legend(nrow = 2)) +
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
      legend.margin = margin(0, 0, -10, 0),
      panel.grid.major.y = element_line(color = "black", linetype = 2),
      panel.spacing = unit(0, "mm"),
      plot.margin = margin(5, 5, 10, 5),
    )

  return(g)
}

summary <- data %>%
    filter(metric %in% c("process", "row") & ev_type %in% c(30, 31))

p <- histogram(summary,
               x = time_micros, color = interaction(metric, ev_type),
               xlims = c(0, 25000), ylims = c(0, 5000),
               colortitle = "Event type",

  ## xtitle = "Inserts per Transaction", ytitle = "Relative Commit Rate"
)

# Output
width <- 10 # inches
height <- (9 / 16) * width

ggsave(out, plot = p, height = height, width = width, units = "in")
