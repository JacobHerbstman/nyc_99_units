# Historical exact parcel adjacency audit

This audit tests whether archived MapPLUTO polygons can add a leakage-safe
adjacent-lot signal to the historical parent-opportunity construction. It is
separate from the parent-link feasibility audit and does not change the
no-notch model.

For every pair of 2019--2023 filings no more than 365 days apart, the audit uses
the MapPLUTO release assigned to the earlier filing. That release was already
public before either filing in the pair. Both filing BBLs must exist in this
single common snapshot. Two distinct filing lots are exact neighbors when their
source polygons touch in that snapshot.

This common-snapshot rule is deliberately conservative. It will leave a pair
unresolved when the later filing uses a BBL that did not yet exist before the
earlier filing. It does not use a later subdivision or merger to reconstruct
the earlier parcel arrangement.

The one-meter near-touch measure is a robustness diagnostic for small topology
gaps. It is never part of the preferred exact-adjacency definition. Polygon
overlaps and invalid geometries are reported as QC rather than silently fixed.

Exact adjacency alone establishes neighboring filing lots, not common economic
control. The preferred corroborated signal therefore requires exact touch plus
either filings no more than 30 days apart or a leakage-safe PLUTO/DOB owner
match. The 30-day window is an explicit Makefile parameter. All exact-touch
pairs within 365 days are retained as a broader sensitivity definition.

Run the audit from `code/` with `make`. The Makefile exposes the filing years,
maximum days between filings, corroboration window, and near-touch robustness
distance. The canonical pair-level output retains the common release, filing
BBLs, filing dates, unit counts, exact-touch status, and prior parent-link
evidence.

## Findings

The 2019--2023 sample contains 2,131 filings and 866,701 filing pairs no more
than one year apart. A common exact-geometry release exists for 852,869 pairs,
or 98.4 percent. Both filing BBLs are present as valid polygons in that common
snapshot for 523,696 pairs, or 60.4 percent of the full pair universe. The
remaining pairs are unresolved rather than reconstructed using later lot
history.

There are 52 exact-touch filing pairs. Eight were already linked by the prior
conservative definition, so exact geometry identifies 44 additional candidate
links. The one-meter sensitivity finds exactly the same 52 pairs. There are no
invalid needed geometries, polygon overlaps, post-filing common snapshots, or
exact-touch pairs omitted by the earlier coordinate candidate screen.

Thirty-eight exact-touch pairs meet the corroboration rule, of which 30 are new
links. Fourteen pairs rely only on adjacency and filings 31--365 days apart;
these remain in the broad sensitivity rather than the preferred extension.

Within 2019--2023, the prior conservative rule places 98 filings in 41
multi-filing parents. Adding corroborated exact adjacency raises this to 156
filings in 69 parents. Adding every exact adjacency raises it to 174 filings in
77 parents. In the full 2010--2023 training sample, the corresponding shares of
filings in multi-filing groups are 3.2 percent, 4.2 percent, and 4.5 percent.

The preferred parent-model extension is therefore conservative links plus
corroborated exact adjacency. All exact adjacency is informative, but adjacency
alone does not establish common economic control and should remain a
sensitivity definition.
