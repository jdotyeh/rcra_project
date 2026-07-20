# Facility Identifiers

## The several identifiers a site carries

A physical site can appear under more than one identifier, and keeping them
straight is what makes it possible to join records. Within the hazardous waste
program ==a site is known by its handler identification number, often called the EPA
identification number, which is assigned when the site notifies the agency and
which usually reads as a state prefix followed by a string of characters.== That
number identifies the site to the hazardous waste program specifically.

Across all of the agency's programs ==the same physical facility is also known by a
registry identifier in the Facility Registry Service, which is a master directory
that ties together the identifiers a facility carries in separate program systems,==
including the hazardous waste handler number, the toxics release inventory number,
and air and water program numbers. The Facility Registry Service therefore is the
bridge from the hazardous waste records to the other environmental datasets in
this project.

## Implications for the data

The panels attach a facility registry identifier by linking the handler number
through the Facility Registry Service Program Links file, matching on the program
system identifier where the program acronym marks it as a RCRAInfo record. The
join keeps one registry identifier per handler number and leaves the field empty
when no such link exists, @@so a reader should expect some handlers to carry no
registry identifier and should not read an empty value as an error.@@

This link is what would let the hazardous waste panels be joined to the
diagnostics inventories in `code/diagnostics/`, the toxics release inventory, the emissions
inventory, the greenhouse gas records, the power plant database, and the discharge
monitoring reports, since those datasets key on the registry identifier or on
program numbers the registry ties together. Because a single physical site can
carry several program numbers, and because not every handler number has a registry
link, @@the join is close but not perfect, and identifiers should be matched with
that caution in mind.@@ The manual step of obtaining the Program Links file is
described in the [download stage README](../../code/modules/01_download/README.md).
