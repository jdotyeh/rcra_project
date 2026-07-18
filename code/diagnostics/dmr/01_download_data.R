# =============================================================================
# FILE:     01_download_data.R
# PURPOSE:  Download EPA DMR annual pollutant-loading data from the ECHO Loading
#           Tool REST API, one folder per reporting year. Self-throttles and
#           resumes across days when the API rate limit is hit.
# INPUTS:   ECHO Loading Tool REST API (dmr_rest_services.get_custom_data_annual);
#           code/diagnostics/dmr/state_codes.csv
# OUTPUTS:  data/dmr/<year>/DMR_*.csv and data/dmr/DMR_POLLUTANTS.csv
# AUTHOR:   Jason Ye
# CREATED:  2026-07-10
# UPDATED:  2026-07-10
# =============================================================================

# Download EPA Discharge Monitoring Report (DMR) annual pollutant-loading data
# into data/dmr, one folder per reporting year.
#
# DMR is served only through the ECHO Loading Tool REST API (no bulk file), so
# this queries it the way standardizedinventories/stewi/DMR.py (Option A) does:
# per state, one CSV of annual loads, plus nutrient-aggregated variants for
# nitrogen (N_) and phosphorus (P_). When a state/year exceeds the API's 100,000
# record cap it is re-queried split by permit type (NGP, GPC, NPD) and combined.
# Also grabs the pollutant parameter list and per-year state totals (used later
# for validation). Raw only: CSVs saved as returned.
#
# API base: https://echodata.epa.gov/echo/dmr_rest_services.get_custom_data_annual
# (this host is current; echo.epa.gov / ofmpub.epa.gov return 404. A run that
# fails on every state with "cannot open URL" is not a dead link -- it is ECHO's
# rate limiter returning HTTP 429, which R surfaces as "cannot open URL".)
#
# THROTTLE: ECHO caps at 300 requests/hour AND 1,500/day; over either it returns
# 429 with body "...ECHO has exports of bulk data available for download at
# https://echo.epa.gov/tools/data-downloads." This script therefore:
#   - paces requests at `sleep_sec` >= 12s (<= 300/hour),
#   - retries a 429 up to `max_tries` times, waiting `throttle_wait`s each time,
#   - aborts cleanly if still throttled (daily cap likely hit) and skips already
#     downloaded (non-empty) files, so re-running later resumes where it stopped.
# A full year is ~3 x 56 = ~168 requests; 10 years (~1,680) exceeds the daily
# cap, so a multi-year pull will span more than one day of resumed runs.
# Run from the repo root.
#
# Files are saved with RCRAInfo-style names: DMR_LOADS_<state>.csv and the
# nutrient variants DMR_NITROGEN_<state>.csv / DMR_PHOSPHORUS_<state>.csv per
# year, plus DMR_TOTALS.csv (per-year state totals) and DMR_POLLUTANTS.csv.

# Set the reporting years, the output root, and the folder holding the state list.
years        <- 2014:2023
out_root     <- "data/dmr"
this_dir     <- "code/diagnostics/dmr"
# Set the throttle behavior.
sleep_sec    <- 12     # pace between calls; 12s keeps under the 300/hour cap
max_tries    <- 4      # retry a 429 up to this many times before giving up
throttle_wait <- 90    # wait this many seconds between 429 retries

# Set the API endpoints: annual loads, per-year state totals, and the pollutant list.
base_url  <- "https://echodata.epa.gov/echo/dmr_rest_services.get_custom_data_annual?"
state_url <- "https://echodata.epa.gov/echo/dmr_rest_services.get_state_stats?p_year=%s&output=csv"
poll_url  <- "https://echodata.epa.gov/echo/dmr_rest_services.get_loading_tool_params?output=csv"

# Allow long downloads and create the output root.
options(timeout = 1800)
dir.create(out_root, recursive = TRUE, showWarnings = FALSE)

# Read the vendored ECHO state list: 50 states + DC + territories.
sc <- read.csv(file.path(this_dir, "state_codes.csv"),
               stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM")
# Combine the three groups and drop blanks.
STATES <- unique(c(sc$states, sc$dc, sc$territories))
STATES <- STATES[!is.na(STATES) & STATES != ""]

# Build a get_custom_data_annual URL. Empty params are dropped (matches StEWI).
dmr_url <- function(year, state, nutrient = "") {
  # Start from the base query parameters.
  params <- c(p_year = year, p_st = state, p_nd = "HALF", output = "CSV",
              p_param_group = "Y", suppress_headers = "Y")
  # Add nutrient aggregation for the N / P variants; turn it off otherwise.
  if (nutrient != "") {
    params["p_poll_cat"]     <- paste0("Nut", nutrient)
    params["p_nutrient_agg"] <- "Y"
  } else {
    params["p_nutrient_agg"] <- "N"
  }
  # Join the parameters into the final URL.
  paste0(base_url, paste(names(params), params, sep = "=", collapse = "&"))
}

# Fetch a URL to `dest`, returning "ok" | "error" | "throttled".
# A 429 (raised by download.file as an error, or returned 200 with a throttle
# JSON body) is retried up to `max_tries` with `throttle_wait`s between tries;
# still throttled -> "throttled". Non-data error payloads -> "error". Any
# unusable file is removed so a resumed run re-fetches it.
fetch <- function(url, dest) {
  # Try the request up to max_tries times.
  for (attempt in seq_len(max_tries)) {
    msg <- ""
    # Capture both warnings and errors: download.file reports the 429 HTTP status
    # as a WARNING and raises only a generic "cannot open URL" error.
    ok <- tryCatch(
      withCallingHandlers(
        { download.file(url, dest, mode = "wb", quiet = TRUE); TRUE },
        warning = function(w) { msg <<- paste(msg, conditionMessage(w))
                                invokeRestart("muffleWarning") }),
      error = function(e) { msg <<- paste(msg, conditionMessage(e)); FALSE })
    if (!ok) {
      # Remove whatever partial file was left behind.
      if (file.exists(dest)) invisible(file.remove(dest))
      # Wait and retry when the failure was a 429; give up otherwise.
      if (grepl("429", msg)) {
        cat(sprintf("    throttled (429); waiting %ds [%d/%d]\n",
                    throttle_wait, attempt, max_tries)); Sys.sleep(throttle_wait); next
      }
      return("error")
    }
    # Inspect the response size and first lines.
    size <- file.info(dest)$size
    head_txt <- suppressWarnings(paste(readLines(dest, n = 5, warn = FALSE),
                                       collapse = " "))
    # Detect a 200 response carrying a throttle JSON body (not the record-cap
    # note), then wait and retry.
    if (size < 1000 && grepl("bulk data|exceed|throttle", head_txt, ignore.case = TRUE) &&
        !grepl("Maximum number of records", head_txt)) {
      invisible(file.remove(dest))
      cat(sprintf("    throttled (body); waiting %ds [%d/%d]\n",
                  throttle_wait, attempt, max_tries)); Sys.sleep(throttle_wait); next
    }
    # Treat an empty file as an error.
    if (size == 0) { invisible(file.remove(dest)); return("error") }
    return("ok")
  }
  # Report throttled after exhausting every attempt.
  "throttled"
}

# Download one state/year(/nutrient) query, splitting by permit type if the API
# reports the 100,000-record cap was hit. Returns "ok" | "error" | "throttled".
download_state <- function(year, state, nutrient, out_file) {
  # Fetch the main query.
  url <- dmr_url(year, state, nutrient)
  st  <- fetch(url, out_file)
  if (st != "ok") return(st)

  # Inspect the response size and first lines.
  head_txt <- suppressWarnings(paste(readLines(out_file, n = 5, warn = FALSE),
                                     collapse = " "))
  size <- file.info(out_file)$size
  # Drop other small error payloads (not throttle, not record cap) so a later
  # run retries them.
  if (size < 1000 && grepl("ErrorMessage|\"Error\"", head_txt) &&
      !grepl("Maximum number of records", head_txt)) {
    invisible(file.remove(out_file)); return("error")
  }
  # Split the query by permit type when the 100,000-record cap was hit.
  if (size < 1000 && grepl("Maximum number of records", head_txt)) {
    invisible(file.remove(out_file))
    first <- TRUE
    for (ptype in c("NGP", "GPC", "NPD")) {
      # Fetch the permit-type slice into a temporary file.
      tmp <- tempfile(fileext = ".csv")
      st  <- fetch(paste0(url, "&p_permit_type=", ptype), tmp)
      # Stop everything on a throttle; skip the slice on other errors.
      if (st == "throttled") { if (file.exists(out_file)) invisible(file.remove(out_file)); return("throttled") }
      if (st != "ok") next
      # Append the slice, keeping the header from the first slice only.
      lines <- suppressWarnings(readLines(tmp, warn = FALSE))
      if (length(lines) > 1) {
        if (first) { writeLines(lines, out_file); first <- FALSE }
        else { con <- file(out_file, "at"); writeLines(lines[-1], con); close(con) }
      }
      # Discard the temporary file and pace the next call.
      invisible(suppressWarnings(file.remove(tmp)))
      Sys.sleep(sleep_sec)
    }
  }
  "ok"
}

# Explain how to resume after a persistent 429 (daily cap likely spent); a later
# run skips the (non-empty) files already saved.
resume_msg <- function()
  cat("Throttled by ECHO (daily cap likely reached). Re-run later to resume; ",
      "completed files are skipped.\n", sep = "")

run <- function() {
  # Download the pollutant parameter list once.
  poll_file <- file.path(out_root, "DMR_POLLUTANTS.csv")
  if (!file.exists(poll_file) || file.info(poll_file)$size == 0) {
    cat("[DMR] pollutant parameter list\n")
    if (fetch(poll_url, poll_file) == "throttled") { resume_msg(); return(invisible()) }
  }

  for (year in years) {
    # Create the year folder and log the plan.
    yr   <- as.character(year)
    ydir <- file.path(out_root, yr)
    dir.create(ydir, recursive = TRUE, showWarnings = FALSE)
    cat(sprintf("[DMR %s] %d states x {base, N, P}\n", yr, length(STATES)))

    # Download the per-year state totals once.
    st_file <- file.path(ydir, "DMR_TOTALS.csv")
    if (!file.exists(st_file) || file.info(st_file)$size == 0) {
      if (fetch(sprintf(state_url, yr), st_file) == "throttled") { resume_msg(); return(invisible()) }
      Sys.sleep(sleep_sec)
    }

    # Loop over the base, nitrogen, and phosphorus variants.
    for (variant in c("", "N", "P")) {
      # Choose the file-name word for the variant.
      word <- if (variant == "") "LOADS" else if (variant == "N") "NITROGEN" else "PHOSPHORUS"
      for (state in STATES) {
        out_file <- file.path(ydir, sprintf("DMR_%s_%s.csv", word, state))
        # Skip only genuinely completed (non-empty) files, so retried gaps re-run.
        if (file.exists(out_file) && file.info(out_file)$size > 0) next
        # Download the state file, stopping cleanly on a throttle.
        status <- download_state(yr, state, variant, out_file)
        if (status == "throttled") { resume_msg(); return(invisible()) }
        if (status == "error") cat("  query failed:", word, state, "\n")
        # Pace the next request.
        Sys.sleep(sleep_sec)
      }
    }
  }
  # Print the completed years as confirmation.
  cat("Done. Years in", out_root, ":", paste(list.files(out_root), collapse = ", "), "\n")
}

# Run the download.
run()
