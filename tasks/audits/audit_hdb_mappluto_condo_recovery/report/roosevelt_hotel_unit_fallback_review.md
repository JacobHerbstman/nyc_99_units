# 121-09 Roosevelt Avenue: corrected unit-source fallback

**September 20 implementation update.** The main producer now takes Class A units from the unfiltered staged Housing Database, preserving recorded zeros. DOB supplies units only when the HDB count is missing. Zero-Class-A filings remain in membership as `zero_class_a`, with their original DOB counts and dates, but contribute no housing units or residential constituent. The canonical panels, plots, weights, and existing pilot have been rebuilt from this rule. The account below describes the error found before that correction.

## Discovery

`post_policy__Q01274555-I1` was a confirmed unit-definition error in the pre-correction `included_ab` panel. The September 18, 2025 filing is the Metropolitan Park gaming facility and hotel. The DCP Housing Database 25Q4 **raw** row for job `Q01274555` records `classaprop=0` and `hotelprop=1000`. The [applicant's June 25, 2025 executive summary, PDF page 2](https://nycasinos.ny.gov/metropolitan-park-executive-summary) calls the 1,000 count “Total Luxury Hotel Rooms” (including 393 suites). These are hotel guest rooms, not 1,000 proposed Class A dwellings. The original PDF and checksum are in [the source folder](../../download_parent_review_documents/code/site_research_followup_2026-09-20_roosevelt_hotel/README.md). The DOB NOW I1 extract nevertheless has `proposed_dwelling_units=1000`; its description says “NEW GAMING FACILITY WITH PARKING,” while subsequent DOB NOW `S1` (September 19, 2025) expressly says “NEW GAMING FACILITY AND HOTEL WITH PARKING.”

The error arose in our implementation of HDB-first source priority. The old
`construct_parent_cohorts.R` built its HDB lookup from records already passing
a six-unit minimum and land-data requirements. The zero-Class-A row therefore
vanished from the lookup. The later `coalesce(hdb_units, dob_i1_units)` treated
that absence as missing information and selected DOB's 1,000. The resulting
parent passed the canonical size and date filters and entered `included_ab`.
The separate exposure classifier searched the initial filing description for
“HOTEL”; the initial description said only “gaming facility with parking.”
This code path explains why both the unit priority and hotel screen failed.

## Pre-correction diagnostic

The [reproducible fallback diagnostic](../output/hdb_unit_fallback.csv) joins
included constituents to membership and the raw 25Q4 Housing Database by
`root_job_id`. Before correction, 388 of 2,644 included constituents used DOB
counts. Nineteen had matching HDB records, including these five recorded zeros:

| Job | DOB units used before correction | HDB Class A | HDB hotel | HDB other Class B | Administrative description |
| --- | ---: | ---: | ---: | ---: | --- |
| `B01191367` | 160 | 0 | 0 | 4 | Community facility with sleeping accommodation |
| `B01234850` | 149 | 0 | 0 | 149 | Nonprofit community facility with sleeping accommodation |
| `Q01160326` | 129 | 0 | 0 | 5 | Community facility with sleeping accommodation |
| `Q01274555` | 1,000 | 0 | 1,000 | 0 | Casino/hotel |
| `X01171565` | 27 | 0 | 0 | 27 | Supportive accommodations, Use Groups IIIA/IIIB |

These five contributed 1,465 units to the former sample. The other matched
records included two positive-count disagreements: B01193536 had ten DOB
units versus five Class A dwellings, and B01341355 had 81 versus 80. Twelve
matched records agreed, including both exact-99 constituents in this matched
set. The other 369 DOB fallbacks had no HDB match; absence supplies no evidence
of a zero. The current diagnostic is empty because the producer now uses every
available HDB count.

## Applied correction and consequences

`construct_parent_cohorts.R` reads `dcp_housing_database_project_level_25q4.parquet` directly for unit counts. It joins one HDB row per job before choosing between HDB and DOB. Size, date, land coverage, and sample eligibility do not remove a recorded count from that lookup. The Class A measure is the established residential outcome; a zero does not establish that the building has no residents, sleeping rooms, or beds. No outside documentary unit count is adopted.

In the included rental panel, four all-zero-Class-A parents drop (Metropolitan Park, Mermaid, Meserole, and Jamaica); the Bronx parent becomes 69 rather than 69+27; B01341355 changes from 81 to 80; and B01193536 changes from 10 to five, falling below the six-unit panel minimum. The wider panel also drops X01157137, whose 233 DOB units were already outside `included_ab`. The unchanged linkage universe retains these original source records.

For the reweighting/pilot sample (included rental parents with at least 50 units and complete site characteristics), post parents change from **316 to 312**, units from **43,807 to 42,341**, and 301+ parents from **25 to 24**. The 1,466-unit correction is 1,465 zero-Class-A fallback units plus the one-unit positive-count correction. The smaller five-unit filing does not enter this 50+ sample. Historical membership and units are unchanged. The post sample still has **39 exact-99 parents and nine exact-99 pairs**. All parent IDs, membership connections, original filing dates, and refiling dates are preserved in the membership source.

Before correction, the hotel entered both canonical panels, the post-period calibration target, and the pure-notch pilot. It also entered the pooled 301+ tail and the denominators of the normalized distributions and CDF. It did not create an exact-99 point or a 99-location map marker. The data correction does not resolve the separate land-boundary and parent-link questions, and estimation remains provisional pending those reviews.

Run `make data` for the canonical panels, `make` for main plots/maps, and `make logbook` for the linked audits and research record. `make dof-site-review` also reruns `audit_hdb_unit_fallback.R`: its current output should contain no included DOB fallback with an available HDB unit count. The original 19 matched fallback rows and five known-zero observations above describe the discovery, not the corrected output. The DCP source vintage remains the [25Q4 Housing Database](https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/housing-project-level/nychdb_25q4_csv.zip).
