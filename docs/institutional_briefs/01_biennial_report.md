# The Biennial Report

## What it is

Every other year the larger hazardous waste sites report what they handled, and
the EPA compiles those filings into the Biennial Report. ==Under the federal rule two kinds of site must file. LQGs must report, and TSDFs
must report.== A filing covers a single odd-numbered data year, and it is due by
the first of March in the following even-numbered year, so the 2019 data year was
filed at the start of 2020. @@The federal rule exempts SQGs and VSQGs from the report.@@

A filing describes each waste stream and gives four tonnage figures for it: the quantity generated during the year, the quantity treated, disposed, or
recycled on site, the quantity shipped off site, and the quantity received from
elsewhere. ==Each waste line also carries flags that state whether that line is
counted toward the national totals,== because a facility records more detail than
the national report is designed to sum.

## Where the states complicate the picture

The federal rule is a floor, and many states ask for more. The state-by-state
reference in `resources/table.md` records the variation, and a few patterns
matter for the data. Some states require SQGs to report as
well, so North Dakota, Mississippi, Wisconsin, Arkansas, Idaho, and Indiana among
others take in filings that the federal rule would not require. Some states
collect an annual report rather than a biennial one and then treat it as
satisfying the federal requirement. @@A handful of states do not use RCRAInfo for
this reporting at all, including Kentucky, Montana, New Hampshire, Tennessee,
Texas, and Oregon,@@ so their filings reach the national system by a different
route and can differ in timing and completeness.

## Implications for the data

The report cycle is the natural time index for anything built from this module.
The panels in `code/modules/03_panels/` use the odd-numbered cycles from 2015
through 2023, and ==a handler is placed in a cycle by its `REPORT_CYCLE` rather than
by any receive date,== which is why the panel code classifies Biennial Report
records on the cycle.

The balanced panel keeps only handlers recognized as an LQG or a TSDF in all five cycles, and the
unbalanced panel keeps a handler in any cycle where it was recognized. ==Generator
status comes from `CALCULATED_GENERATOR_STATUS`, where the value that marks a
large quantity generator is `L`,== and the treatment, storage, and disposal role is
read from the national-inclusion flags on the managed and received identifiers.
==The tonnage columns are summed only over the waste lines that the report counts
toward the national totals,== which is what the inclusion flags on each line are
for, so the panel totals line up with the published national figures rather than
with the raw sum of every line.

Because states differ in who must file, coverage is not uniform across state
lines. A SQG will appear in the reports of a state that
requires SQG reporting and will be absent in a state that does not, @@so
counts of reporting sites are not directly comparable across states without
accounting for this.@@ The [state authorization brief](04_state_authorization.md)
develops this point.
