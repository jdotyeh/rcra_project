# Generators, Handlers, and TSDFs

## The regulated universe

Everyone the program regulates is a handler, and a handler receives an
ID number when it notifies the agency of its activity on Form
8700-12. The number is tied to a site, and the site can be a generator, a
transporter, a TSDF, or several of these at
once. The Handler module is where a site's identity, location, industry codes,
owners and operators, and declared activities live.

## Generator size categories

How much hazardous waste a site generates in a calendar month decides its
category, and the category decides which rules it must follow. ==A VSQG produces no more than 100 kg of hazardous waste a month. A SQG produces more than 100 kg but less than
1,000 kg (1T) a month. An LQG produces 1,000 kg or more a month, or more than a small amount of acutely hazardous waste.==
A rule finalized in 2016 renamed the smallest category, which had been called the
conditionally exempt small quantity generator (CESQG), and added a path for a site to
handle a one-time episodic surge without moving permanently into a higher
category.

@@The categories are a federal floor, and states adjust them.@@ Kansas inserts a
state small quantity tier between twenty-five and one hundred kilograms.
California regulates only small and large quantity generators and treats any
generator of federal hazardous waste as at least a small quantity generator.
Washington uses its own dangerous waste tiers in place of the federal ones. The
state-by-state detail is in `resources/table.md`.

## TSDFs

A facility that treats, stores, or disposes of hazardous waste sits at the end of
the cradle to grave chain and carries the heaviest obligations. It generally
needs a permit, it is subject to corrective action for releases, and it must carry
financial assurance. These facilities are the subject of the permitting, corrective
action, and financial assurance briefs.

## Implications for the data

The Handler master file in `code/modules/02_modular_master_files/` is built by
crossing the central handler record with its dimension tables, @@so a single
handler expands into many rows as its owners, operators, industry codes, and
declared activities multiply.@@ That shape is deliberate, and it is why identifiers
have to be read carefully rather than counted naively.

The panels lean on two derived facts from this module. ==A handler counts as a large
quantity generator in a cycle when its calculated generator status is `L`, and it
counts as a TSDF when the national-inclusion
flags mark it as managing or receiving waste counted in the national report.== When
a handler files more than one value for the same attribute in the same year, ==the
panel records that disagreement in a conflicts column rather than silently picking
one,== so a reader can see where a facility's own filings do not agree.

@@Because states draw the category lines differently, generator status is not a
clean cross-state variable.@@ A site that California treats as a small quantity
generator might fall below the federal small quantity line elsewhere, so a
category should be read together with the state that assigned it. The industry
codes attached here follow a defined primary-selection rule so that a handler with
several reported codes resolves to one, which keeps the panels one row per
handler and cycle.
