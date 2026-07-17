# 04_summary_tables

This stage builds one descriptive summary workbook for the central table of each
RCRAInfo module and one for each Biennial Report cycle. It holds a single
`rcrainfo/` subfolder because every summarized table so far comes from RCRAInfo;
a different data system would get its own sibling folder here.

The stage is descriptive and sits outside the panel-building chain: it reads only
the downloaded data, so it can run any time after the download stage.

See [rcrainfo/README.md](rcrainfo/README.md) for the engine, the per-module and
per-cycle scripts, and the outputs.
