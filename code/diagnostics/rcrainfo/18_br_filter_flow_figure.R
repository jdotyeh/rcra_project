library(ggplot2)

hd_fill   <- "#ffd166"
br_fill   <- "#8ecae6"
cat_fills <- c("#8ecae6", "#b9dff0", "#ddeef8")
box_line  <- "grey40"

stage1 <- data.frame(
  xmin = c(5, 36.25, 67.5),
  xmax = c(32.5, 63.75, 95),
  ymin = 82, ymax = 93,
  title = c("LQG", "SQG", "VSQG"),
  body  = c("≥ 1,000 kg/month\n(or > 1 kg acute)",
            "100 – 1,000 kg/month",
            "≤ 100 kg/month")
)

stage3 <- data.frame(
  xmin = c(5, 36.25, 67.5),
  xmax = c(32.5, 63.75, 95),
  ymin = 28, ymax = 42,
  title = c("L · LQG", "E · Episodic", "N · Not LQG"),
  body  = c("≥ 13.22 t/yr generated,\nacute > 0.012 t, or\nacute spill > 1.32 t",
            "1.10 – 13.22 t/yr", "< 1.10 t/yr")
)

funnel <- data.frame(
  x = c(5, 95, 68, 32),
  y = c(81, 81, 66.5, 66.5)
)

p <- ggplot() +
  annotate("text", x = 5, y = 96,
           label = "1 · SELF-REPORTED CATEGORY — HANDLER MODULE (FORM 8700-12)",
           family = "Georgia", size = 3.5, color = "grey45", hjust = 0) +
  geom_rect(data = stage1,
            aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill = hd_fill, alpha = 0.5, color = box_line, linewidth = 0.35) +
  geom_text(data = stage1, aes(x = (xmin + xmax) / 2, y = 90.2, label = title),
            family = "Georgia", fontface = "bold", size = 4.6, color = "grey15") +
  geom_text(data = stage1, aes(x = (xmin + xmax) / 2, y = 85.6, label = body),
            family = "Georgia", size = 3.3, color = "grey25", lineheight = 0.95) +
  geom_polygon(data = funnel, aes(x = x, y = y),
               fill = "grey75", alpha = 0.30) +
  annotate("text", x = 50, y = 76.5,
           label = "Federal rule: every LQG (and TSDF) must file",
           family = "Georgia", size = 3.7, color = "grey20") +
  annotate("text", x = 50, y = 72,
           label = "states may also pull in SQGs and VSQGs",
           family = "Georgia", size = 3.3, color = "grey40", fontface = "italic") +
  annotate("rect", xmin = 32, xmax = 68, ymin = 52, ymax = 66.5,
           fill = br_fill, alpha = 0.55, color = box_line, linewidth = 0.35) +
  annotate("text", x = 50, y = 62.3, label = "BR reporting pool",
           family = "Georgia", fontface = "bold", size = 4.6, color = "grey15") +
  annotate("text", x = 50, y = 58.3, label = "Form 8700-13 · GM & WR forms",
           family = "Georgia", size = 3.4, color = "grey25") +
  annotate("text", x = 50, y = 55, label = "~24,000 facilities in the 2023 cycle",
           family = "Georgia", size = 3.2, color = "grey40") +
  annotate("segment", x = 50, xend = 50, y = 52, yend = 44.8,
           color = "grey40", linewidth = 0.4,
           arrow = arrow(length = unit(5, "pt"), type = "closed")) +
  annotate("text", x = 52.5, y = 48.4,
           label = "EPA recalculates from reported tonnage\n(Calculated Generator Status)",
           family = "Georgia", size = 3.3, color = "grey35",
           hjust = 0, lineheight = 0.95) +
  geom_rect(data = stage3,
            aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            fill = cat_fills, alpha = 0.6, color = box_line, linewidth = 0.35) +
  geom_text(data = stage3, aes(x = (xmin + xmax) / 2, y = 39, label = title),
            family = "Georgia", fontface = "bold", size = 4.4, color = "grey15") +
  geom_text(data = stage3, aes(x = (xmin + xmax) / 2, y = 33.8, label = body),
            family = "Georgia", size = 3.2, color = "grey25", lineheight = 0.95) +
  annotate("text", x = 5, y = 24.5,
           label = "2 · CALCULATED GENERATOR STATUS — BR MODULE",
           family = "Georgia", size = 3.5, color = "grey45", hjust = 0) +
  scale_x_continuous(limits = c(0, 100), expand = c(0, 0)) +
  scale_y_continuous(limits = c(21, 100), expand = c(0, 0)) +
  labs(title = "From Self-Report to Biennial Report",
       subtitle = "How facilities enter the BR and get re-categorized") +
  theme_void(base_family = "Georgia") +
  theme(plot.title = element_text(face = "bold", size = 17, hjust = 0.5,
                                  margin = margin(b = 4)),
        plot.subtitle = element_text(size = 12, hjust = 0.5, color = "grey35",
                                     margin = margin(b = 10)),
        plot.margin = margin(15, 20, 10, 20))

dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
ggsave("output/diagnostics/BR_filter_flow.png", p, width = 9, height = 7.2, dpi = 300,
       bg = "white", device = ragg::agg_png)
quartz(type = "pdf", file = "output/diagnostics/BR_filter_flow.pdf", width = 9,
       height = 7.2, bg = "white")
print(p)
invisible(dev.off())
