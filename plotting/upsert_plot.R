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

parser$add_argument("-o", "--out", type = "character", help = "out directory for plots")
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

density_estimate <- function(data, x = x, fill = fill,
                             xlims = NULL, xbreaks = NULL,
                             ylims = NULL, ybreaks = NULL,
                             xtitle = NULL, ytitle = NULL, filltitle = NULL) {
  g <- ggplot(
    data,
    aes(
      x = !!enquo(x),
      fill = as.factor(!!enquo(fill)),
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

  barwidth <- 0.9
  errorwidth <- 0.4

  g <- g +
    geom_density() +
    scale_x_continuous(
        limits = xlims,
        breaks = xbreaks,
        expand = c(0, 0)
    ) +
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

  return(g)
}

histogram <- function(data, x = x, fill = fill, binwidth,
                      xlims = NULL, xbreaks = NULL,
                      ylims = NULL, ybreaks = NULL,
                      xtitle = NULL, ytitle = NULL, filltitle = NULL) {
  g <- ggplot(
    data,
    aes(
      x = !!enquo(x),
      fill = as.factor(!!enquo(fill)),
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
    geom_histogram(binwidth = binwidth) +
    scale_x_continuous(
        limits = xlims,
        breaks = xbreaks,
        expand = c(0, 0)
    ) +
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

  return(g)
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
  errorwidth <- 0.6

  g <- g +
    geom_col(position = position_dodge(width = barwidth), color = "black") +
    geom_errorbar(position = position_dodge(width = barwidth), width = errorwidth, size = 1) +
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

  return(g)
}

density <- data %>%
    select(impl, server, n_clients, n_workers, use_upsert, total_time_ms, commit_rate_tps) %>%
    filter(server != "Primary")

density

# Output
width <- 10 # inches
height <- (9 / 16) * width

fname <- file.path(out, "upsert_density.pdf")
p <- density_estimate(density, x = total_time_ms, fill = use_upsert,
                      ## ylims = c(0, 0.3),
                      xtitle = "Total Time (ms)", ytitle = "Density",
                      filltitle = "Upsert")
ggsave(fname, plot = p, height = height, width = width, units = "in")

fname <- file.path(out, "upsert_histogram.pdf")
p <- histogram(density, x = total_time_ms, fill = use_upsert, binwidth = 1,
               ## xlims = c(320, 360), ylims = c(0, 18.1),
               xbreaks = 10, ybreaks = 10,
               xtitle = "Total Time (ms)", ytitle = "Count",
               filltitle = "Upsert")
ggsave(fname, plot = p, height = height, width = width, units = "in")

throughput <- data %>%
    filter(server != "Primary") %>%
    group_by(impl, server, n_clients, n_workers, use_upsert) %>%
    summarize(
        mean_commit_rate_tps = mean(commit_rate_tps),
        sd_commit_rate_tps = sd(commit_rate_tps),
        se_commit_rate_tps = sd_commit_rate_tps / sqrt(n()),
    ) %>%
    ungroup() %>%
    mutate(
        server = fct_relevel(server, c("Primary", "CopyCat", "CopyCat+ccRO", "CopyCat+kRO", "CopyCat+CO", "KuaFu", "KuaFu+kRO", "KuaFu+CO"))
    )

throughput

fname <- file.path(out, "upsert_throughput.pdf")
p <- bar_chart(throughput, x = n_workers, y = mean_commit_rate_tps, se = sd_commit_rate_tps,
               fill = use_upsert,
               ## xlims = c(320, 360), ylims = c(0, 18.1),
               ## xbreaks = 10, ybreaks = 10,
               xtitle = "Number of Threads", ytitle = "Throughput (Txns/sec)",
               filltitle = "Upsert")
ggsave(fname, plot = p, height = height, width = width, units = "in")

