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

line_plot <- function(data, x = x, y = y, color = color,
                      xlims = NULL, xbreaks = NULL,
                      ylims = NULL, ybreaks = NULL,
                      xtitle = NULL, ytitle = NULL, colortitle = NULL) {
  g <- ggplot(
    data,
    aes(
      x = !!enquo(x),
      y = !!enquo(y),
      color = as.factor(!!enquo(color)),
      linetype = as.factor(!!enquo(color))
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

  g <- g +
    geom_line(size = 2) +
    ## geom_point(size = 1.5) +
    scale_x_continuous(
      limits = xlims,
      breaks = xbreaks,
      expand = c(0, 0),
      labels = comma
    ) +
    scale_y_continuous(
      limits = ylims,
      breaks = ybreaks,
      expand = c(0, 0),
      labels = comma
    ) +
    scale_color_brewer(type = "div", palette = "Spectral") +
    labs(
      x = xtitle,
      y = ytitle,
      color = colortitle,
      linetype = colortitle
    ) +
    guides(color = guide_legend(nrow = 2)) +
    theme_classic(
      base_size = 26,
      base_family = "serif"
    ) +
    theme(
      axis.text = element_text(size = 28, color = "black"),
      axis.title = element_text(size = 32, color = "black"),
      legend.key.size = unit(1.8, "cm"),
      legend.text = element_text(size = 28, color = "black"),
      legend.title = element_text(size = 32, color = "black"),
      legend.position = "top",
      legend.justification = "left",
      legend.margin = margin(0, 0, -25, 0),
      panel.grid.major.y = element_line(color = "black", linetype = 2),
      panel.spacing = unit(0, "lines"),
      strip.background = element_blank(),
      strip.placement = "outside",
      strip.text = element_text(size = 28, color = "black", vjust = 3.0),
      plot.margin = margin(5, 5, 5, 5),
    )

  return(g)
}

names <- c(
  Primary = "MASTER (F1)",
  `Single-threaded` = "VANILLA (F1)",
  `Table-granularity` = "TBL (F1)",
  CopyCat = "STMT (F1)"
)

xrange <- c(41500, 65500)

summary <- data %>% mutate(
    time_secs = time_secs - min(time_secs),
    time_secs = time_secs - xrange[[1]],
    time_mins = time_secs / 60,
    time_hours = time_mins / 60,
    name = fct_recode(name, !!!names),
  ) %>%
  filter(between(time_secs, 0, xrange[[2]] - xrange[[1]]))

p <- line_plot(summary,
  x = time_mins, y = rows_mutated, color = name,
  xtitle = "Time (mins)", ytitle = "Throughput (rows/sec)",
  xlims = c(0, 412), xbreaks = 6,
  ylims = c(0, 4100), ybreaks = 5
)

# Output
width <- 10 # inches
height <- (9 / 16) * width

ggsave(out, plot = p, height = height, width = width, units = "in")
