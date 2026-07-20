# =============================================================================
# FILE:     build_panels.R
# PURPOSE:  Build the RCRA facility panels end to end, running only the stages
#           the panels depend on. It runs setup, downloads the FRS Program Links
#           file and the RCRAInfo tables if the raw inputs are missing, builds
#           the Handler and Compliance master files if they are missing, and
#           then builds the four panels. This is a shortcut for the panel
#           outputs; code/master.R runs the full pipeline.
# INPUTS:   data/frs/FRS_PROGRAM_LINKS.csv (downloaded if missing);
#           data/rcrainfo/{hd,ce,br}/ raw tables
# OUTPUTS:  output/panels/BR_PANEL_2015_2023_BALANCED/,
#           output/panels/BR_PANEL_2015_2023_UNBALANCED/,
#           output/panels/CE_PANEL_2015_2023/ (evaluation and enforcement panels)
# AUTHOR:   Jason Ye
# CREATED:  2026-07-16
# UPDATED:  2026-07-16
# =============================================================================

# Run from the repository root so that every relative path resolves.
if (!file.exists("code/master.R")) {
  stop("Run from the repository root: Rscript code/modules/03_panels/rcrainfo/build_panels.R")
}

# Source a script in its own environment, announcing it like master.R does.
run <- function(path) {
  cat("\n========", path, "========\n")
  source(path, local = new.env())
}

# ---- Stage 0: environment -------------------------------------------------
# Installs and loads packages and creates the output folders.
run("code/modules/00_setup/00_setup.R")

# ---- Stage 1a: FRS Program Links ------------------------------------------
# Every panel attaches the FRS REGISTRY_ID through this file. Download it only
# when it is absent, because the archive is about a gigabyte.
frs_file <- "data/frs/FRS_PROGRAM_LINKS.csv"
if (file.exists(frs_file)) {
  cat("\n", frs_file, " present; skipping download.\n", sep = "")
} else {
  run("code/modules/01_download/frs/01_download_data.R")
}

# ---- Stage 1: raw RCRAInfo tables -----------------------------------------
# The panels read the Biennial Report, Handler, and Compliance modules. Download
# only when the raw inputs are absent, because the full RCRAInfo download is
# several gigabytes and takes hours.
cycles <- seq(2015, 2023, by = 2)
rcrainfo_inputs <- c(
  "data/rcrainfo/hd/HD_HANDLER.csv",
  "data/rcrainfo/ce/CE_REPORTING.csv",
  file.path("data/rcrainfo/br", sprintf("BR_REPORTING_%d.csv", cycles))
)
if (all(file.exists(rcrainfo_inputs))) {
  cat("\nRaw RCRAInfo inputs present; skipping download.\n")
} else {
  run("code/modules/01_download/rcrainfo/01_download_data.R")
}

# ---- Stage 2: master files ------------------------------------------------
# The panels read the Handler and Compliance master files. Build a master only
# when it is absent; delete a master file to force it to rebuild.
build_if_missing <- function(out_file, script) {
  if (file.exists(out_file)) {
    cat("\n", out_file, " present; skipping rebuild.\n", sep = "")
  } else {
    run(script)
  }
}
build_if_missing(
  "output/modular_master_files/HD_MASTER.csv",
  "code/modules/02_modular_master_files/rcrainfo/01_hd_master.R"
)
build_if_missing(
  "output/modular_master_files/CE_MASTER.csv",
  "code/modules/02_modular_master_files/rcrainfo/02_ce_master.R"
)

# ---- Stage 3: the panels --------------------------------------------------
# Small outputs, always rebuilt so they reflect the current masters.
run("code/modules/03_panels/rcrainfo/01_panel_2015_2023_balanced.R")
run("code/modules/03_panels/rcrainfo/02_panel_2015_2023_unbalanced.R")
run("code/modules/03_panels/rcrainfo/03_panel_eval_2015_2023.R")
run("code/modules/03_panels/rcrainfo/04_panel_enf_2015_2023.R")

cat("\nDone. Panels are under output/panels/.\n")
