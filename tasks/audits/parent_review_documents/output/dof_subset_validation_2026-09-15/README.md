# Sources for checking the twelve-parent sample's lot areas

Retrieved September 15, 2026. The consumer is
`audit_hdb_mappluto_condo_recovery/code/validate_dof_subset_areas.R`.

`assessments.json` preserves the original NYC DOF public SODA response from
dataset `8y4t-faws`. It requests 34 filing, predecessor, and neighboring BBLs
from the twelve-parent review. Its 236 records include tentative and final
assessment rolls for fiscal years ending 2023-27. The separate count response
also returns 236, below the requested 50,000-record limit. Every record is
ordinary real estate, with no easement identifier. Exact queries are in the
`*_url.txt` files; `assessment_schema.json` preserves publisher metadata and
column names. No credential is required for these public queries.

The DOF record layout defines `PERIOD=1` as tentative and `PERIOD=3` as final.
The consumer retains the 119 final records. `YEAR=2027` means fiscal 2026/27;
the latest underlying `EXTRACRDT` is May 15, 2026. Retrieval in September does
not make these contemporaneous September measurements. The earliest extract
is January 10, 2022; earlier calendar years are not covered by this API snapshot.

These mutable API responses are committed intact. `json.sha256` fingerprints
their bytes. `dof_subset_validation.make`, included by the acquisition Makefile,
can request the recorded URLs and verifies the expected hashes before publishing
the responses. An ordinary unchanged build uses the included snapshot. If the
service changes, replication requires the included original bytes; a source
refresh needs a new vintage and an explicit comparison.

`sources.csv` records eight additional documents and their hashes. Concrete
Make rules download them into this task's `output/` directory:

- DOF assessment layout: period definitions and total land-area field.
- Brooklyn CB1 notice, dated May 27 for its June 9, 2026 meeting: pages 2-3
  describe the Noble/Oak site, its area, and tentative division into lots 1/10.
- NYSDEC July 6, 2022 Sackett property attachment: page 1 describes the
  38,500-square-foot cleanup boundary; PDF page 11 contains the title survey.
- The corresponding Sackett project description: planning context, without
  an exact link to the panel's 300-unit filing footprint.
- September 13, 2022 DOF map of Brooklyn block 426: the 48,500-square-foot
  intermediate parcel, before the September 2025 subdivision.

- March 2022 NYSDEC IRM work plan: the 560 Degraw cleanup boundary and
  contemporary development description.
- March 2024 ESD Existing Conditions Report: the Appendix lists 563 Sackett
  at 48,500 square feet; administrative corroboration rather than a survey.
- November 2019 NYSDEC Greenpoint amendment: a distinct cleanup boundary and
  a reproduced 2016 survey, useful for distinguishing it from the parent site.

[Manual portal notes](manual_portal_review.md) document the September 15 DOB
and ACRIS inspections, with exact document IDs and pages. These are human
transcriptions, not raw downloaded records. The original Sackett ZD1 and
Noble's cited 2024 survey remain unverified. The notes explain the live DOB
record's date and the different street boundaries in Noble's deeds.

The preceding `dof_subset_2026-09-15/` snapshot supplies the other dated maps
and the March 2026 NYSDEC amendment. Its deed Schedule A, PDF pages 30-31,
describes Sackett lots 17/47. PLUTO 25v4's ZIP metadata explicitly labels the
supplied geometry as shoreline clipped and identifies DOF as its source.
DOF and PLUTO therefore are not independent measurements of parcel boundaries.

Run `make dof-subset-review` from the repository root to prepare the new sources
and produce the lot-level checks. This source acquisition has no production
panel or model consumer.
