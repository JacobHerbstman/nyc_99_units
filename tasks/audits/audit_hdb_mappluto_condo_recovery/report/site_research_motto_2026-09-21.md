# Motto parent-site covariates, 21 September 2026

This note records primary-source evidence for the accepted two-building parent `historical__210180533`: DOB jobs `210180533` (141 HDB units) and `210180542` (123 HDB units), both filed December 26, 2019. It proposes a fixed-vintage covariate row for root adjudication and does not modify the central decision table, production data, or code. Original files and their URL/hash register are in `tasks/audits/download_parent_review_documents/code/site_research_followup_2026-09-21_motto/`.

## Development boundary

The June 2019 Phase I environmental site assessment preserved in the official NYS DEC final-engineering-report appendix identifies the 2455 Third Avenue **Subject Property** as part of old Bronx block 2319 lot 37 plus all of lot 155, approximately 0.58 acre (PDF pp. 148, 154-155). Its Figure 2 on **PDF p. 184** draws that boundary: it includes the warehouse/parking portion of old lot 37 and the contiguous storage/parking parcel 155, while excluding the southwest building retained on old lot 37. This predates both December 2019 filings and is the clearest filing-era physical-site plan.

DOF transaction `89746`, effective April 16, 2020, apportioned old lot 37 into retained lot 37 and new lots 38 and 39. The before/after maps show the partition, and the raw transaction identifies lots 38 and 39 as new. In 20v5 MapPLUTO, lots 38 and 39 have administrative areas 10,157 and 9,425 square feet. Lot 155 remains 5,298 square feet. The documented development ground is therefore **24,880 square feet** (10,157 + 9,425 + 5,298). Retained lot 37 is excluded.

The recorded instruments independently confirm the allocation. The zoning-lot development agreement (ACRIS `2020090200965004`) defines the Developer Land as lots 38, 39, and 155 on PDF p. 4. PDF p. 9 restricts lot 155 above a low limiting plane but expressly preserves project-related driveway or entry fixtures, walkways, landscaping, and utility equipment there. The separate egress agreement (ACRIS `2020090200965011`) names exact jobs `210180533` and `210180542` on lots 38 and 39, respectively, on PDF p. 3; retained lot 37 supplies only an emergency-egress easement. The broad zoning declaration and development-rights transfers therefore do not add retained lot 37 to the physical ground.

Lot 155 is included for a different reason from a zoning-lot or air-rights donor. The filing-era DEC plan places the entire parcel inside the project's Subject Property; the later recorded agreement puts it in the developer-owned parcel and reserves it for ancillary improvements serving lots 38 and 39. It is not part of the DEC cleanup boundary after the 2020 amendment, but that narrower remediation boundary does not undo the documented economic-site boundary.

## Fixed-vintage covariates

The production reference should remain **19v1**, before the December 2019 filings. At that vintage, old lot 37 records 35,049 square feet of land and 83,936 square feet of floor area; lot 155 records 5,298 land and zero floor area. Both have `M1-3/R8`, residential FAR 6.02, commercial FAR 5.0, and facility FAR 6.5.

The later partition reconciles the earlier floor area exactly: 20v5 retained lot 37 has 69,357 square feet of floor, while new lots 38 and 39 have 13,458 and 1,121; 69,357 + 13,458 + 1,121 = 83,936. Excluding the retained building therefore leaves **14,579 square feet** of earlier observed floor on the 24,880-square-foot development ground, or built FAR **0.5859726688**. The successor ground areas total 24,880, 19 square feet below the old 19v1 administrative sum of 40,347 minus retained 15,448; this is a documented administrative-vintage difference, not a reason to invent a 19-square-foot allocation.

The parcel-specific preconstruction 20v5 uses are industrial/manufacturing (lot 38, land-use 06), transportation/utility (lot 39, land-use 07), and vacant land (lot 155, land-use 11). The parent treatment is therefore `mixed_prior_use`. HDB units remain 141 + 123 = 264; the later MapPLUTO residential counts do not override them.

## Proposed production row

`motto_proposed_site_lot_decision.csv` supplies one grouped 19v1 row with reference BBLs `2023190037;2023190155`, reference area 40,347, development area 24,880, excluded building area 69,357, and `mixed_prior_use`. The basis is a filing-era agency site plan, exact-job recorded instruments, and a successor administrative partition whose building-floor totals reconcile exactly to the frozen source row.

## Reviewed pages

- DEC final-engineering-report Appendix D: PDF pp. 37, 148, 154-155, and 184.
- DEC BCA amendment: PDF pp. 4-5.
- ACRIS development agreement `2020090200965004`: PDF pp. 4, 9, and 32-34.
- ACRIS egress agreement `2020090200965011`: PDF p. 3.
- DOF maps effective June 17, 2019 and April 16, 2020: p. 1 of each.

