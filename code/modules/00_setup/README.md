# 00_setup

Note: This folder has been verified.

This is the first stage the master script runs, and it prepares the environment
for everything that follows.

The single script `00_setup.R` names the R packages the pipeline depends on,
installs any that are not already present, and loads them. It then creates the
output folders that later stages write into, so that a fresh clone has somewhere
to put its results. Running the script a second time installs nothing and simply
confirms that the folders exist, so it is safe to run at any time.

Running this script on its own does not download data or produce results. It only
gets the session ready. The exact package versions the project was last run
against are listed in the [root README](../../../README.md).
