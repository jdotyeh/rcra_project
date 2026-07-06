# Master script: run every module in order.
#
# Modules live under code/modules/<stage>/<module>/, e.g.
#   01_download/echo_rcra          - EPA ECHO RCRAInfo dataset + data dictionary
#   01_download/echo_rcra_pipeline - EPA ECHO RCRA pipeline dataset + data dictionary
#   01_download/rcrainfo           - RCRAInfo CSV exports + data dictionaries
#
# Scripts run in alphabetical path order (stage, module, then 01, 02, ...),
# each in its own environment so they don't interfere.
# Run from the repo root. Downloads several GB, so this takes a while.

scripts <- sort(list.files("code/modules",
                           pattern = "\\.R$", full.names = TRUE, recursive = TRUE))

for (s in scripts) {
  cat("\n========", s, "========\n")
  source(s, local = new.env())
}

cat("\nAll modules finished.\n")
