# Historical parent-link feasibility audit

This audit asks whether the 2010--2023 historical period can support a
parent-development-opportunity definition richer than same-BBL aggregation. It
does not construct the final parent crosswalk.

The audit distinguishes evidence observable by the filing date from evidence
that appears only in later lot records. That distinction is necessary because
the site panel sometimes recovers a pre-filing feature lot through
the current APPBBL crosswalk. A link dated after the filing can help reconstruct
what ultimately happened, but it is not a leakage-safe predictor of the
developer's original opportunity.

The historical inputs are the DCP Housing Database, the DOB NOW initial-filing
extract, the leakage-safe MapPLUTO release assignment already used by the
site panel, and the corresponding frozen PLUTO or MapPLUTO archive. Raw
PLUTO fields are read only for the filing lots required by each selected
release.

The audit evaluates four signals:

- exact parcel geometry where archived MapPLUTO shapefiles exist, with
  coordinate proximity treated only as a candidate signal elsewhere;
- exact historical PLUTO owner-name matches combined with proximity, plus DOB
  filing-owner matches where DOB NOW exists. Tax-lot owner matches remain
  review candidates unless another high-confidence signal corroborates them;
- archived APPBBL and APPDate evidence for mergers, splits, and condominium
  conversions, separated from current-crosswalk and post-filing links; and
- explicit companion-job references and shared MPP project codes parsed from
  filing descriptions.

## Findings

The richer historical construction is feasible, but only a narrow subset of
the links is clean enough to use automatically in historical parent construction.
The preferred 2010--2023 sample contains 5,917 filings.

- Adjacent lots are only partially recoverable. Archived MapPLUTO provides
  exact parcel polygons beginning with release 18v1.1, safely available on
  December 7, 2018. In this training sample, exact pre-filing geometry covers
  95.2 percent of 2019 filings and all filings from 2020 onward. Historical
  tax-lot coordinates cover 97.6 percent of all filings, but centroid distance
  is a candidate-screening measure rather than proof that two lots share a
  boundary. This audit establishes geometry availability; it does not yet add
  polygon adjacency to the automatic grouping rule.
- Shared tax-lot owner names are widely observed but noisy. Historical PLUTO
  owner names are present for 99.3 percent of filings. Among filings no more
  than one year apart, there are 1,036 same-owner pairs within 100 meters. Only
  155 of those pairs use lot identities established without a current APPBBL
  recovery. Another 190 depend on a current crosswalk whose APPDate predates
  filing, and 691 depend on a post-filing lot linkage. Public agencies and
  other repeat owners also generate many unrelated matches. DOB filing-owner
  names add 124 nearby pairs, but DOB NOW coverage begins only in 2021.
- Mergers and subdivisions are observable, provided timing is enforced.
  APPBBL and APPDate exist in all 40 selected historical releases. The archived
  releases identify 78 pair links sharing a documented lot-history group.
  However, the current site-panel crosswalk recovers the historical lot for
  2,161 filings, including 1,203 cases in which the linking APPDate is after the
  filing date. Those later links can describe realized project outcomes, but
  cannot support a leakage-safe historical link.
- Explicit job references are high-specificity but low-recall. The descriptions
  identify 12 linked pairs covering 24 jobs, and the referenced job numbers
  correspond to jobs in the training data. No repeated MPP project codes were
  found. Description coverage is only 12--33 percent before 2021 and rises to
  about 99 percent in 2022--2023 after DOB NOW becomes available.

The conservative automatic rule links filings that share a filing BBL, share a
strictly pre-filing feature lot, share a lot-history group visible in the frozen
pre-filing archive, or explicitly name one another. It places 190 filings in 78
multi-filing parent groups, or 3.2 percent of the training sample. A same-BBL
rule alone places 150 filings in 59 multi-filing groups. Thus richer defensible
history adds 19 groups and 40 filings, but does not make multi-filing parents
common in the historical data.

Adding strict pre-filing PLUTO-owner and DOB-owner candidates would place 420
filings in 184 multi-filing groups, or 7.1 percent of the sample. This is a
sensitivity bound, not a preferred parent definition: identical tax-lot names
do not establish common economic control, and connected components can amplify
one mistaken pair link into a larger parent.

## Implication for parent construction

The historical parent construction should use only the conservative automatic
links. Owner and coordinate links should remain review flags. Exact polygon
adjacency is a separately audited high-confidence signal for the 2019--2023
portion of the sample. The
pre-2019 years should retain same-BBL and documented lot-history links unless a
separate historical parcel-geometry source is found.

This result also answers the question of whether parent aggregation is simply
absent in the pre-period: it is not absent, but it is uncommon under evidence
that is both available by filing and sufficiently specific.

## Outputs

- `historical_parent_filing_coverage_by_year.csv` reports signal coverage and
  the timing risk by filing year.
- `historical_parent_link_signal_summary.csv` partitions pair links by evidence
  source and timing.
- `historical_parent_grouping_sensitivity.csv` compares the conservative and
  owner-inclusive connected-component definitions.
- `historical_parent_candidate_pairs.parquet` preserves pair-level provenance
  for review without coding candidates as final parents.
- `historical_parent_source_inventory.csv` records field and geometry
  availability in every selected historical release.

Run the audit from `code/` with `make`. The Makefile exposes the training years,
minimum unit count, distance radii, and filing-time window. All outputs are
audit-only diagnostics.
