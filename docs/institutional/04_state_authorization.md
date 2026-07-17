# State Authorization and Federalism

## The division of labor

The hazardous waste program is federal law carried out mostly by the states. The
statute lets the Environmental Protection Agency authorize a state to run its own
hazardous waste program in place of the federal one, and almost every state is
authorized for the base program. Where a state is not authorized the federal
agency runs the program through its regional office, which the state-by-state
reference shows for Alaska through Region 10 and Iowa through Region 7. An
authorized state may be more stringent than the federal rule or may reach wastes
the federal rule does not, and it may not be less stringent.

## Why records differ across state lines

Because each authorized state runs its own program, the same activity can be
recorded differently depending on where it happens. The state-by-state reference
in `resources/table.md` lays out the variation, and three kinds of difference
matter most for the data. States differ in who must report, so some require small
quantity generators to file while the federal rule exempts them. States differ in
the systems they use, so most report through RCRAInfo while Kentucky, Montana, New
Hampshire, Tennessee, Texas, and Oregon collect reports through their own portals
or on paper and feed the national system separately. States differ in the wastes
they regulate, so many maintain state-only waste codes that never appear in
another state.

## Implications for the data

This division of labor is the reason the enforcement panel separates state actions
from federal actions, and it is the reason organizational codes carry a state
prefix. Reading either without the authorization context invites a wrong
conclusion, because a low federal count in a state is usually a sign that the state
is leading rather than a sign that little is happening.

The variation also sets the limits of cross-state comparison. Counts of reporting
sites are not comparable across states without accounting for which generators
each state requires to report, and the states that do not use RCRAInfo can differ
in the timing and completeness of what reaches the national system. State-only
waste codes will appear for some states and not others and should not be treated
as missing data elsewhere. The public site built by `code/utils/build_site.R`
renders `resources/table.md` as a searchable page, so the state detail behind
these cautions is browsable rather than buried.
