# Universal Waste, Used Oil, and Recycling

## Why some wastes are handled under lighter rules

The full generator and facility standards are written for concentrated
industrial waste streams, and applying them unchanged to widely scattered
everyday items would push those items into the trash rather than into collection.
==The program therefore carves out several regimes that keep a waste inside
Subtitle C but replace the ordinary requirements with lighter ones, so that
collection is easier and the waste still reaches a facility able to handle it.==
These regimes are the reason a facility can hold a regulatory role in the records
without being a generator or a treatment facility in the usual sense.

The universal waste rules cover a defined federal list of items, batteries,
certain pesticides, mercury-containing equipment such as thermostats, lamps,
and, since 2019, aerosol cans, and a state may add to that list. A handler of
these wastes may accumulate and consolidate them under simplified conditions
before sending them on, and the records distinguish a small quantity handler from
a large quantity handler, which is one accumulating five thousand kilograms or
more of universal waste at any one time. At the end of the chain sits the
destination facility, which is where the universal waste is finally treated,
recycled, or disposed of and where the full standards return.

Used oil runs under its own regime. ==Used oil is not automatically a hazardous
waste, and oil headed for recycling is regulated as used oil rather than as
hazardous waste,== with separate standards for the transporter that moves it, the
transfer facility that holds it briefly, the processor or re-refiner that cleans
it, the burner that burns it for energy recovery, and the marketer that directs
it to a burner. The distinction between oil that meets the specification for
metals, halogens, and flash point and oil that does not decides how far the
standards reach.

Recycling more broadly sits at the edge of the program. A material that is
legitimately reclaimed may fall outside the definition of solid waste altogether,
a recycler that stores waste before reclaiming it is regulated differently from
one that does not, and burning waste for energy in a boiler or an industrial
furnace has its own standards. Underground injection of waste into a deep well is
regulated principally under the drinking water program rather than here, but the
activity is still declared on the notification.

## Implications for the data

These regimes appear in the data as activities a facility declares on its
notification, so they are attributes of a site rather than events, and they are
carried into the balanced and unbalanced panels as indicator columns from
`HD_MASTER.csv`. The counts below are from the balanced panel, over 27,200
facility-years at 5,440 facilities.

| Panel column | Facility-years marked | What it declares |
|---|---|---|
| `HD_UNIVERSAL_WASTE_LQ_HANDLER` | 4,172 | Handling universal waste above the large quantity threshold. |
| `HD_UNIVERSAL_WASTE_DEST_FACILITY` | 409 | Acting as the destination facility for universal waste. |
| `HD_USED_OIL_TRANSPORTER` | 726 | Transporting used oil. |
| `HD_USED_OIL_TRANSFER_FACILITY` | 881 | Holding used oil at a transfer facility. |
| `HD_USED_OIL_PROCESSOR` | 280 | Processing used oil. |
| `HD_USED_OIL_REFINER` | 107 | Re-refining used oil. |
| `HD_USED_OIL_BURNER` | 248 | Burning used oil for energy recovery. |
| `HD_USED_OIL_MARKET_BURNER` | 295 | Marketing used oil to a burner. |
| `HD_USED_OIL_SPEC_MARKETER` | 480 | Marketing used oil that meets the specification. |
| `HD_RECYCLER_STORAGE` | 1,433 | Recycling with storage of the waste beforehand. |
| `HD_RECYCLER_NONSTORAGE` | 297 | Recycling without that storage. |
| `HD_ONSITE_BURNER_EXEMPTION` | 81 | Burning waste on site under the exemption. |
| `HD_FURNACE_EXEMPTION` | 189 | Operating an exempt industrial furnace. |
| `HD_UNDERGROUND_INJECTION_ACTIVITY` | 110 | Injecting waste underground. |
| `HD_TRANSPORTER` | 1,460 | Transporting hazardous waste. |
| `HD_TRANSFER_FACILITY` | 1,033 | Operating a hazardous waste transfer facility. |

Three cautions follow from how these columns are filled. @@They are
self-declarations on the notification form rather than findings by a regulator,@@
so they record what the facility told the state it does. @@They are also sparse,
because the panel is a panel of large quantity generators and treatment
facilities and these roles are held by a small minority of them,@@ with the
largest column reaching 15 percent of facility-years and every other column
staying under 6 percent. And the roles are not exclusive, so one facility-year can be a
large quantity generator, a used oil burner, and a universal waste handler at the
same time, which means the columns should be read together rather than as a
classification.

`HD_RECYCLER_NONSTORAGE` is the one column that behaves differently. It is empty
on 10,379 facility-years and carries the unknown code `U` on a further 232, where
the other columns in the table are filled on all but a handful. The unknown code
follows the rule in the Handler master module README that reads an `N` on a
record received before 1 June 2017 as unknown rather than as a denial, because
the field was not collected on those records. The generator size categories these
roles sit beside are described in the
[generators and handlers](02_generators_and_handlers.md) brief, and the parts of
the rules these regimes occupy are the reason universal waste and used oil have
their own violation type codes, which is covered in the
[regulatory citations](14_regulatory_citations.md) brief.
