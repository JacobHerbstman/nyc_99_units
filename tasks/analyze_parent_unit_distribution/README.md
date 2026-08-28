# Parent unit-count distributions

This task compares exact parent-development unit counts from 80 through 120
for complete historical 2011--2022 cohorts and provisional post-policy cohorts
from January 1, 2025 through the current source end date. One parent can contain
several linked filings, so a multi-building development appears once with its
total proposed units.

The total-count figure deliberately shows raw mass over unequal observation
windows. The annualized figure divides the historical counts by 12 calendar
years and the post-period counts by the exact number of observed days divided
by 365.25. Post-period parents retain complete left-side linkage windows but
are provisional on the right because future filings can still join them.

The support audit verifies the apparent gap directly at four levels: the
plotted parent sample, all post-period parents including left-boundary-exposed
cases, raw initial DOB NOW filings, and each job's latest available filing
version. The build fails unless 100--104 are empty in all four layers and 105
is occupied. A separate case file lists every current 105-unit parent.

The exposure figures apply the parent-level categorical classification from
`audit_parent_485x_exposure`. One panel keeps only plausible Option A/B rental
opportunities. The second adds plausible outer-borough Option D homeownership
opportunities. `not_exposed` and `unresolved` parents remain in the exposure
data and review queue but are excluded from both plotted estimation samples.
The original all-project figures remain unchanged as an audit benchmark.

Additional views show the entire observed 6--1,754-unit support for all linked
parent proposals and a 50--150-unit zoom for the classified exposure samples.
The full-support histogram uses 25-unit bins; the other views retain exact
one-unit bins. Histogram and line versions are produced in both total-count and
annualized scales.

The vector PDF views from 50--300 units compare the 2011--2022 annual average
with the January 2025--July 8, 2026 total divided by its exact 1.5168-year
window. One combined figure shows all 6-plus parents and the primary A/B rental
opportunity sample; separate PDFs preserve each panel at a larger scale. The
reference lines at 99, 150, and 198 make the exact 99+99 parent configuration
visible in the wider distribution.

The normalized-density PDF removes the change in market scale by making each
period sum to 100 percent within the 50--300-unit A/B opportunity sample. It
shows the full 2011--2022 benchmark, the early 2011--2014 and late 2019--2022
pre-periods, and the post-policy period in exact one-unit bins.
Separate two-line PDFs compare the post-policy density with each of those three
pre-period benchmarks so the individual comparisons remain legible.
Matching two-line total-count and annualized-count PDFs are produced for the
full 2011--2022 and late 2019--2022 benchmarks. Together with the normalized
density PDFs, these separate changes in total filing volume from changes in the
distribution of proposed project sizes.

Run `make` from `code/`.
