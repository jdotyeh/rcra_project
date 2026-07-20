library(ggplot2)
library(scales)

# Distinct-facility totals per Biennial Report cycle, taken from the console
# output of 10_br_facility_cycles.R. Update after rerunning that script.
facilities <- data.frame(
  year = c(2001, 2003, 2005, 2007, 2009, 2011, 2013, 2015, 2017, 2019, 2021, 2023),
  distinct_facilities = c(21689, 24756, 25245, 21349, 21700, 21212, 26622, 29845, 26858, 25707, 24830, 24000)
)

administrations <- data.frame(
  start = c(2001, 2009, 2017, 2021),
  end = c(2009, 2017, 2021, 2024),
  party = c("Republican", "Democratic", "Republican", "Democratic")
)

p <- ggplot(facilities, aes(x = year)) +
  geom_rect(
    data = administrations,
    aes(xmin = start, xmax = end, ymin = -Inf, ymax = Inf, fill = party),
    inherit.aes = FALSE,
    alpha = 0.45
  ) +
  geom_line(aes(y = distinct_facilities), color = "#6CA6A6", linewidth = 0.8) +
  geom_point(aes(y = distinct_facilities), color = "#6CA6A6", size = 2.2) +
  scale_x_continuous(
    breaks = facilities$year,
    limits = c(2001, 2024)
  ) +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(
    values = c(
      "Democratic" = "#EAF3FB",
      "Republican" = "#FCEFE8"
    )
  ) +
  labs(
    title = "Distinct Facilities Over Time",
    x = "Year",
    y = "Number of distinct facilities",
    fill = NULL
  ) +
  theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 16),
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.minor = element_blank(),
    legend.position = "bottom",
    legend.text = element_text(size = 8.5),
    legend.key.size = unit(0.3, "cm"),
    legend.margin = margin(t = -6),
    legend.box.margin = margin(t = -8),
    plot.margin = margin(10, 10, 10, 10)
  )

dir.create("output/diagnostics", showWarnings = FALSE, recursive = TRUE)
ggsave("output/diagnostics/BR_facility_trend.png", p, width = 9, height = 5.5,
       dpi = 300, bg = "white")
