# =============================================================================
# 06_hd_episodic_master.R  —  Combine the four episodic-event handler files
# -----------------------------------------------------------------------------
# Joins the four episodic Hazardous Waste event tables from the handler folder
# into a single wide file:
#
#   EVENT       one row per episodic event  (event type, dates, emergency contact)
#   PROJECT     per episodic event          (project code + description)
#   WASTE       per waste sequence          (waste description, estimated quantity)
#   WASTE CODE  per waste sequence          (waste code owner + code)
#
# Join keys:
#   EVENT <-> PROJECT : HANDLER ID, ACTIVITY LOCATION, SOURCE TYPE, SEQ NUMBER
#   EVENT <-> WASTE   : the four keys above (WASTE adds WASTE SEQ NUMBER)
#   WASTE <-> CODE    : the four keys above PLUS WASTE SEQ NUMBER
#
# A full (outer) join is used at every step so no record from any of the four
# files is lost.  Every child here nests cleanly under EVENT, so the result is
# effectively driven by the event spine.  Some events carry more than one
# project, so those projects repeat across the event's waste lines.
#
# Column order mirrors HD_HSM: identity keys, then the sub-sequence, then the
# event-level attributes, then project, then waste, then waste codes.
# =============================================================================

# ----------------------------- Paths ----------------------------------------
in_dir   <- "data/rcrainfo/hd"
out_file <- "output/diagnostics/HD_EPISODIC.csv"
dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)

# Read one CSV, keeping original column names and reading everything as text.
# Empty fields become NA; no real code in these files is the text "NA".
read_ep <- function(name) {
  path <- file.path(in_dir, name)
  read.csv(path, check.names = FALSE, colClasses = "character", na.strings = "")
}

event     <- read_ep("HD_EPISODIC_EVENT.csv")
project   <- read_ep("HD_EPISODIC_PROJECT.csv")
waste     <- read_ep("HD_EPISODIC_WASTE.csv")
wastecode <- read_ep("HD_EPISODIC_WASTE_CODE.csv")

# ----------------------------- Join keys ------------------------------------
event_keys <- c("HANDLER ID", "ACTIVITY LOCATION", "SOURCE TYPE", "SEQ NUMBER")
waste_keys <- c(event_keys, "WASTE SEQ NUMBER")

# ----------------------------- Merge step by step ---------------------------
# 1) event details + project details (per event)
ep <- merge(event, project, by = event_keys, all = TRUE)

# 2) add the waste lines (this brings in WASTE SEQ NUMBER)
ep <- merge(ep, waste, by = event_keys, all = TRUE)

# 3) add the waste codes (matched on the waste sequence as well)
ep <- merge(ep, wastecode, by = waste_keys, all = TRUE)

# ----------------------------- Order the columns ----------------------------
final_columns <- c(
  "HANDLER ID",
  "ACTIVITY LOCATION",
  "SOURCE TYPE",
  "SEQ NUMBER",
  "WASTE SEQ NUMBER",
  "EPISODIC EVENT OWNER",
  "EPISODIC EVENT TYPE",
  "START DATE",
  "END DATE",
  "EMERG CONTACT FIRST NAME",
  "EMERG CONTACT LAST NAME",
  "EMERG CONTACT PHONE",
  "EMERG CONTACT PHONE EXT",
  "EMERG CONTACT EMAIL",
  "PROJECT CODE OWNER",
  "PROJECT CODE",
  "OTHER PROJECT DESC",
  "WASTE DESCRIPTION",
  "ESTIMATED QUANTITY",
  "WASTE CODE OWNER",
  "WASTE CODE"
)
ep <- ep[final_columns]

# ----------------------------- Sort the rows --------------------------------
ep <- ep[order(ep[["HANDLER ID"]],
               ep[["ACTIVITY LOCATION"]],
               ep[["SOURCE TYPE"]],
               ep[["SEQ NUMBER"]],
               ep[["WASTE SEQ NUMBER"]]), ]

# ----------------------------- Write the result -----------------------------
write.csv(ep, out_file, row.names = FALSE, na = "")
cat("Wrote", nrow(ep), "rows to", out_file, "\n")
