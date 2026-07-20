# =============================================================================
# 25_panel_profile.R
#
# Descriptive profile of the coherent panel facilities:
#   (a) how much hazardous waste a typical panel facility encounters, and
#   (b) how the panel group differs from the broader handler / BR-filer universe.
# Prints to console; writes a small summary to output/diagnostics/.
# =============================================================================

library(readr); library(dplyr); library(purrr); library(stringr); library(tidyr)

source("code/diagnostics/rcrainfo/23_panel_facilities.R")   # -> coherent_facilities, facility_status_by_year
keep_ids <- coherent_facilities$HANDLER_ID
clean_names <- function(df) rename_with(df, ~ str_replace_all(.x, " ", "_"))

PANEL_YEARS <- seq(2015L, 2023L, by = 2L)
BR_DIR      <- "data/rcrainfo/br"
num <- function(x) suppressWarnings(as.numeric(x))

# ---- Pass over raw BR: panel vs non-panel, waste throughput -----------------
sel <- c("HANDLER ID","BR FORM","GENERATION TONS","MANAGED TONS","RECEIVED TONS",
         "SHIPPED TONS","WASTEWATER","FEDERAL WASTE","PRIMARY NAICS","STATE")

read_year <- function(year) {
  f <- file.path(BR_DIR, sprintf("BR_REPORTING_%d.csv", year))
  read_csv(f, col_select = all_of(sel),
           col_types = cols(.default = col_character()),
           show_col_types = FALSE, progress = FALSE) |>
    clean_names() |>
    mutate(year = year,
           is_panel = HANDLER_ID %in% keep_ids,
           GENERATION_TONS = num(GENERATION_TONS), MANAGED_TONS = num(MANAGED_TONS),
           RECEIVED_TONS = num(RECEIVED_TONS), SHIPPED_TONS = num(SHIPPED_TONS))
}

message("Reading raw BR cycles for waste totals ...")
br <- map(PANEL_YEARS, read_year) |> bind_rows()

# Facility-year throughput (generated on GM lines + received on WR lines)
fy <- br |>
  group_by(year, is_panel, HANDLER_ID) |>
  summarise(gen = sum(GENERATION_TONS, na.rm = TRUE),
            recv = sum(RECEIVED_TONS, na.rm = TRUE),
            mgd = sum(MANAGED_TONS, na.rm = TRUE),
            gen_nonww = sum(GENERATION_TONS * (WASTEWATER == "N"), na.rm = TRUE),
            .groups = "drop") |>
  mutate(throughput = gen + recv)

message("\n===== (A) WASTE A TYPICAL PANEL FACILITY ENCOUNTERS (tons / facility-year) =====")
panel_fy <- filter(fy, is_panel)
qs <- function(x) round(quantile(x, c(.25,.5,.75,.9,.99), na.rm = TRUE), 1)
cat("Total generated  : median", median(panel_fy$gen), " mean", round(mean(panel_fy$gen)), "\n")
cat("  quantiles (p25/50/75/90/99):\n"); print(qs(panel_fy$gen))
cat("Generated, NON-wastewater:\n"); print(qs(panel_fy$gen_nonww))
cat("Received (TSDF role):\n"); print(qs(panel_fy$recv))
cat("Throughput (gen+recv):\n"); print(qs(panel_fy$throughput))

message("\n===== (B) PANEL vs NON-PANEL FILERS =====")
cmp <- fy |> group_by(is_panel) |>
  summarise(n_fac_years = n(),
            med_gen = median(gen), mean_gen = round(mean(gen)),
            med_throughput = median(throughput), .groups = "drop")
print(cmp)

# Share of all reported hazardous-waste generation accounted for by the panel
share <- br |> group_by(year) |>
  summarise(nat_gen = sum(GENERATION_TONS, na.rm = TRUE),
            panel_gen = sum(GENERATION_TONS * is_panel, na.rm = TRUE),
            nat_fac = n_distinct(HANDLER_ID),
            panel_fac = n_distinct(HANDLER_ID[is_panel]),
            nat_recv = sum(RECEIVED_TONS, na.rm = TRUE),
            panel_recv = sum(RECEIVED_TONS * is_panel, na.rm = TRUE), .groups = "drop") |>
  mutate(pct_facilities = round(100*panel_fac/nat_fac,1),
         pct_generation = round(100*panel_gen/nat_gen,1),
         pct_received   = round(100*panel_recv/nat_recv,1))
message("Panel share of national BR totals, by cycle:")
print(share |> select(year, nat_fac, panel_fac, pct_facilities, pct_generation, pct_received))

# Federal vs state waste share
fed <- br |> mutate(g = GENERATION_TONS) |>
  group_by(is_panel) |>
  summarise(fed_share = round(100*sum(g*(FEDERAL_WASTE=="Y"),na.rm=TRUE)/sum(g,na.rm=TRUE),1), .groups="drop")
message("Federal-waste share of generation (panel vs non-panel):"); print(fed)

# ---- Handler-universe structure: status, TSDF, industry, geography ----------
message("\n===== (C) STRUCTURE vs FULL HANDLER UNIVERSE (HD_REPORTING) =====")
hd <- read_csv("data/rcrainfo/hd/HD_REPORTING.csv",
               col_select=c(`HANDLER ID`,GENSTATUS,`OPERATING TSDF`,TRANSPORTER,NAIC1,STATE),
               col_types=cols(.default=col_character()), show_col_types=FALSE, progress=FALSE) |>
  clean_names() |>
  distinct(HANDLER_ID, .keep_all=TRUE) |>
  mutate(is_panel = HANDLER_ID %in% keep_ids,
         is_tsdf = !is.na(OPERATING_TSDF) & str_detect(OPERATING_TSDF,"[^-]"),
         naics3 = str_sub(NAIC1,1,3))

message("Current generator status mix (% of group):")
print(hd |> count(is_panel, GENSTATUS) |> group_by(is_panel) |>
        mutate(pct=round(100*n/sum(n),1)) |> select(-n) |>
        pivot_wider(names_from=GENSTATUS, values_from=pct, values_fill=0))
message("TSDF share (%):")
print(hd |> group_by(is_panel) |> summarise(pct_tsdf=round(100*mean(is_tsdf),1),
                                            pct_transporter=round(100*mean(TRANSPORTER=="Y",na.rm=TRUE),1)))
message("Top NAICS-3 industries among PANEL facilities (vs universe share):")
naics_lab <- read_csv("data/rcrainfo/hd/HD_LU_NAICS.csv",
                      col_types=cols(.default=col_character()), show_col_types=FALSE) |> clean_names() |>
  filter(OWNER=="HQ") |> mutate(naics3=str_sub(NAICS_CODE,1,3)) |>
  distinct(naics3, .keep_all=TRUE) |> transmute(naics3, lab=str_trunc(NAICS_DESC,40))
top <- hd |> group_by(naics3) |>
  summarise(panel_n=sum(is_panel), univ_n=n(), .groups="drop") |>
  mutate(panel_pct=round(100*panel_n/sum(panel_n),1),
         univ_pct=round(100*univ_n/sum(univ_n),1)) |>
  arrange(desc(panel_n)) |> head(12) |> left_join(naics_lab, by="naics3")
print(top |> select(naics3, lab, panel_pct, univ_pct))
message("Top states (panel share of facilities):")
print(hd |> filter(is_panel) |> count(STATE, sort=TRUE) |> head(10))

# ---- small summary file -----------------------------------------------------
dir.create("output/diagnostics", showWarnings=FALSE, recursive=TRUE)
write_csv(share, "output/diagnostics/panel_profile_waste_shares.csv")
message("\nWritten -> output/diagnostics/panel_profile_waste_shares.csv")
