# Financial Assurance

## What it is

A facility that treats, stores, or disposes of hazardous waste must prove in
advance that it can pay to close safely and, for a disposal facility, to care for
the site long after it closes. The requirement exists so that the cost of cleanup
does not fall on the public if a facility goes bankrupt or walks away. It has two
sides. The facility estimates the cost of the work it must be able to fund, which
includes closure, post-closure care, and in some cases liability for harm to
others. ==The facility then backs that estimate with an approved funding mechanism,
such as a trust fund, a surety bond, a letter of credit, an insurance policy, or a
financial test in which a large company demonstrates the strength to self-insure.==

## Implications for the data

The Financial Assurance master file in `code/modules/02_modular_master_files/`
joins the cost estimate to the mechanism that funds it, so one side of the record
says what a facility must be able to pay for and the other says how that money is
guaranteed. @@Reading the two together is the point, because a large cost estimate
means something different depending on whether it is backed by cash in a trust or
by a corporate financial test.@@ The project builds this master file but does not
build a financial assurance panel.
