# =============================================================================
# FILE:     17_br_hd_venn_figure.R
# PURPOSE:  Venn diagram of BR vs HD handler overlap — render a PNG showing the three regions (BR-only, HD-only, both).
# INPUTS:   data/rcrainfo/br/BR_REPORTING_*.csv, data/rcrainfo/hd/HD_HANDLER.csv
# OUTPUTS:  console prints (and any figure files noted inline below)
# AUTHOR:   Jason Ye
# CREATED:  2026-07
# UPDATED:  2026-07
# =============================================================================

library(ggplot2)
library(ggforce)

# Handler-cycle counts from the console output of 15_br_hd_overlap.R.
# Update these three numbers after rerunning that script.
n_both    <- 81020
n_br_only <- 212793
n_hd_only <- 130864

a_br <- n_both + n_br_only
a_hd <- n_both + n_hd_only

r_br <- sqrt(a_br / pi)
r_hd <- sqrt(a_hd / pi)

lens_area <- function(d, r1, r2) {
  if (d >= r1 + r2) return(0)
  if (d <= abs(r1 - r2)) return(pi * min(r1, r2)^2)
  d1 <- (d^2 - r2^2 + r1^2) / (2 * d)
  d2 <- d - d1
  r1^2 * acos(d1 / r1) - d1 * sqrt(r1^2 - d1^2) +
    r2^2 * acos(d2 / r2) - d2 * sqrt(r2^2 - d2^2)
}

d <- uniroot(function(d) lens_area(d, r_br, r_hd) - n_both,
             interval = c(abs(r_br - r_hd) + 1e-6, r_br + r_hd - 1e-6))$root

circles <- data.frame(
  x = c(0, d),
  y = c(0, 0),
  r = c(r_br, r_hd),
  set = c("BR", "HD")
)

fmt <- function(n) formatC(n, format = "d", big.mark = ",")

x_br_only <- (-r_br + (d - r_hd)) / 2
x_lens    <- ((d - r_hd) + r_br) / 2
x_hd_only <- (r_br + (d + r_hd)) / 2

p <- ggplot() +
  geom_circle(data = circles,
              aes(x0 = x, y0 = y, r = r, fill = set),
              color = NA, alpha = 0.55) +
  geom_circle(data = circles,
              aes(x0 = x, y0 = y, r = r),
              color = "grey35", linewidth = 0.35, fill = NA) +
  annotate("text", x = x_br_only, y = 0,
           label = fmt(n_br_only), family = "Georgia", size = 4.8, color = "grey15") +
  annotate("text", x = x_lens, y = 0,
           label = fmt(n_both), family = "Georgia", size = 4.8, color = "grey15") +
  annotate("text", x = x_hd_only, y = 0,
           label = fmt(n_hd_only), family = "Georgia", size = 4.8, color = "grey15") +
  annotate("text", x = -r_br, y = r_br * 0.95,
           label = "BR module", family = "Georgia", fontface = "bold",
           size = 5.6, color = "#2b5876", hjust = 0) +
  annotate("text", x = d + r_hd, y = r_br * 0.95,
           label = "Handler module (Source Type R)", family = "Georgia",
           fontface = "bold", size = 5.6, color = "#8a6d3b", hjust = 1) +
  scale_fill_manual(values = c(BR = "#8ecae6", HD = "#ffd166")) +
  coord_fixed(xlim = c(-r_br - 30, d + r_hd + 30),
              ylim = c(-r_br - 20, r_br * 1.06), expand = FALSE, clip = "off") +
  labs(title = "Handler-Cycles Reported in BR vs. Handler Module",
       subtitle = "Distinct Handler ID × Report Cycle combinations") +
  theme_void(base_family = "Georgia") +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", size = 17, hjust = 0.5,
                                  margin = margin(b = 4)),
        plot.subtitle = element_text(size = 12, hjust = 0.5, color = "grey35",
                                     margin = margin(b = 12)),
        plot.margin = margin(15, 25, 15, 25))

dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
ggsave("output/diagnostics/BR_HD_venn.png", p, width = 10, height = 6.9, dpi = 300,
       bg = "white", device = ragg::agg_png)
quartz(type = "pdf", file = "output/diagnostics/BR_HD_venn.pdf", width = 10,
       height = 6.9, bg = "white")
print(p)
invisible(dev.off())
