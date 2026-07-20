# =============================================================================
# 07_hd_hsm_master.R  —  Combine the four HSM handler files into one HD_HSM file
# -----------------------------------------------------------------------------
# Joins the four Hazardous Secondary Material (HSM) tables from the handler
# folder into a single wide file:
#
#   BASIC      one row per HSM notification   (effective date, financial assurance)
#   ACTIVITY   per HSM sequence               (facility code, short tons, land unit)
#   WASTE CODE per HSM sequence               (waste code owner + code)
#   RECYCLER   per handler notification       (recycler indicator)
#
# Join keys:
#   BASIC  <-> ACTIVITY : HANDLER ID, ACTIVITY LOCATION, SOURCE TYPE, SEQ NUMBER
#   ACTIVITY <-> WASTE  : the four keys above PLUS HSM SEQ NUMBER
#   RECYCLER            : the four keys above
#
# A full (outer) join is used at every step so no record from any of the four
# files is lost.  Most RECYCLER rows describe handlers that never filed an HSM
# notification, so they appear as their own rows with the notification fields
# left blank.
# =============================================================================

# ----------------------------- Paths ----------------------------------------
in_dir   <- "data/rcrainfo/hd"
out_file <- "output/diagnostics/HD_HSM.csv"
dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)

# Read one of the CSV files, keeping the original column names and treating
# every value as text (handler IDs, codes and dates are not numbers).
# Empty fields become NA; the literal text "NA" (a real land-unit code) is kept.
read_hsm <- function(name) {
  path <- file.path(in_dir, name)
  read.csv(path, check.names = FALSE, colClasses = "character", na.strings = "")
}

basic    <- read_hsm("HD_HSM_BASIC.csv")
activity <- read_hsm("HD_HSM_ACTIVITY.csv")
waste    <- read_hsm("HD_HSM_WASTE_CODE.csv")
recycler <- read_hsm("HD_HSM_RECYCLER.csv")

# ----------------------------- Join keys ------------------------------------
handler_keys <- c("HANDLER ID", "ACTIVITY LOCATION", "SOURCE TYPE", "SEQ NUMBER")
hsm_keys     <- c(handler_keys, "HSM SEQ NUMBER")

# ----------------------------- Merge step by step ---------------------------
# 1) notification details + activity-level details
hsm <- merge(basic, activity, by = handler_keys, all = TRUE)

# 2) add the waste codes (matched on the HSM sequence as well)
hsm <- merge(hsm, waste, by = hsm_keys, all = TRUE)

# 3) add the recycler indicator (matched on the handler notification)
hsm <- merge(hsm, recycler, by = handler_keys, all = TRUE)

# ----------------------------- Order the columns ----------------------------
final_columns <- c(
  "HANDLER ID",
  "ACTIVITY LOCATION",
  "SOURCE TYPE",
  "SEQ NUMBER",
  "HSM SEQ NUMBER",
  "HSM EFFECTIVE DATE",
  "HSM FA",
  "FACILITY CODE OWNER",
  "FACILITY CODE",
  "ESTIMATE SHORT TONS",
  "ACTUAL SHORT TONS",
  "LAND BASED UNIT",
  "WASTE CODE OWNER",
  "WASTE CODE",
  "RECYCLER INDICATOR"
)
hsm <- hsm[final_columns]

# ----------------------------- Sort the rows --------------------------------
hsm <- hsm[order(hsm[["HANDLER ID"]],
                 hsm[["ACTIVITY LOCATION"]],
                 hsm[["SOURCE TYPE"]],
                 hsm[["SEQ NUMBER"]],
                 hsm[["HSM SEQ NUMBER"]]), ]

# ----------------------------- Write the result -----------------------------
write.csv(hsm, out_file, row.names = FALSE, na = "")
cat("Wrote", nrow(hsm), "rows to", out_file, "\n")
