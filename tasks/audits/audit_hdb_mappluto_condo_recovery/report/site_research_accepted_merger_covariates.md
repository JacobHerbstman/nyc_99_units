# Production allocation evidence: Godwin/Kimberly and Elara

This note supplies the fixed-vintage parcel characteristics needed to implement two already accepted economic-parent mergers. It does not revisit membership or certify either group as one legal wage-assessment unit.

## Godwin Terrace / Kimberly Place

**Production parent and order:** `post_policy__X01201390-I1`; components `X01201390-I1;X01202536-I1`. Both filings are dated **2025-03-31**, so the existing date/job ordering places `X01201390-I1` first.

The fixed post-policy reference is **23v3_1 block 5700 lot 78**, BBL `2057000078`: recorded area **17,670**, building area **8,215**, residential FAR **2.43**, broad FAR **4.8**, zoning **R6**, land use **05**, zero residential units. The producer therefore classifies its unoverridden prior use as `commercial_industrial` and its zone detail as `R6`.

The [July 2026 recorded development agreement](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2026071500691002) provides the physical allocation. Physical p. **4** says historical lot 78 was reapportioned into current lots 78, 79, and 88. Physical p. **6** assigns 99 dwellings to the lot-79 building and separately identifies 8,967.30 square feet of commercial floor used by the retained lot-78 building. Physical p. **7** assigns 65 dwellings to the lot-88 building. Physical pp. **25** and **27** give separate legal descriptions for lots 79 and 88. Lot 79's rounded courses imply approximately 12,539.9 square feet versus its **12,541-square-foot** administrative area; lot 88's orthogonal courses give exactly **5,900 square feet**. The [DOF map effective 2025-11-19](https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20570020251119112812), p. **1**, depicts the same three-way partition.

The fixed 23v3_1 building-area value is **8,215**, while the later agreement reports 8,967.30 commercial square feet on retained lot 78. The later number should locate the building, not overwrite the frozen measure. Excluding all **8,215** frozen square feet leaves zero pre-existing floor on the two residential building parcels. The May 2025 recorded drawing, [document 2025052300873001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2025052300873001), physical p. **11**, independently draws the one-story masonry building on tentative retained lot 78. The drawing does not label the new parcels' open land as parking, so the production row should leave `prior_site_use` blank and preserve the archival `commercial_industrial` category rather than invent a parking classification.

**Proposed allocation:** one reference row, development ground **18,441** square feet, excluded building area **8,215**. Resulting parent covariates are lot area 18,441, built FAR 0, residential FAR 2.43, broad FAR 4.8, R6, and `commercial_industrial` prior use. The 17,670 recorded reference area is internally inconsistent with the old parcel polygon, but remains the exact 23v3_1 field that the source-row validator requires; it is not used as the development-ground measure.

## Elara / 41st Street

**Production parent and order:** `post_policy__Q01254595-I1`; components `Q01254595-I1;Q01254580-I1`. Their filing dates are **2025-10-06** and **2025-10-07**, respectively.

The [MIH declaration](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2026082500424001), physical p. **13**, defines the 35-53 41st Street premises as block 670 lots 47 and 4; physical p. **16** names exact job `Q01254595`, its 330 units, and both lots. The [joint mortgage](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2026082500424009), physical pp. **1–4**, covers both Site A and Site B borrowers and all three parcels. Schedule A, physical pp. **31–32**, legally describes block 669 lot 36 and block 670 lots 4 and 47. Schedule B, physical pp. **33–34**, names exact jobs `Q01254595-I1` for Site A and `Q01254580-I1` for Site B. Schedule C, physical p. **35**, records joint financing dated August 5, 2025, before both filings. The developer's [Elara project page](https://thedomaincos.com/portfolio/elara/) reports one 429-apartment project.

All three parcels are complete 23v3_1 reference parcels and complete development ground, so none of their frozen building area is excluded:

| Reference BBL | Ground | Frozen building area | Residential FAR | Broad FAR | Zoning | Land use / production category |
|---|---:|---:|---:|---:|---|---|
| `4006690036` | 13,216 | 13,850 | 0 | 6.5 | M1-4/R7-3 | 06 / `commercial_industrial` |
| `4006700004` | 10,020 | 9,900 | 0 | 6.5 | M1-4/R7-3 | 06 / `commercial_industrial` |
| `4006700047` | 15,767 | 15,700 | 9 | 10.0 | M1-5/R9-1 | 06 / `commercial_industrial` |

The three rows sum to accepted ground **39,003** and prior building area **39,450**, with excluded building area zero. The resulting area-weighted covariates are built FAR **1.011460657**, residential FAR **3.638258595**, and broad FAR **7.914878343**; zone detail is `MX_slash` and prior use is `commercial_industrial`. Keep separate rows because lot 47 differs in both residential and broad FAR. Using one grouped three-BBL row would fail the producer's same-FAR requirement. Three single-BBL rows also retain the Site A/Site B source crosswalk without an invented internal allocation.

## Proposed `site_lot_decisions.csv` rows

```csv
sample,parent_id,expected_component_jobs,reference_vintage,reference_bbls,reference_recorded_area_sqft,development_area_sqft,excluded_building_area_sqft,prior_site_use,area_basis,review_source,review_basis,review_date
post_policy,post_policy__X01201390-I1,X01201390-I1;X01202536-I1,23v3_1,2057000078,17670,18441,8215,,successor_recorded_area_checked_against_legal_dimensions,https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2026071500691002;https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20570020251119112812,"Agreement pp. 4 and 6-7 assigns the 99- and 65-unit buildings to successor lots 79 and 88 and the existing commercial building to retained lot 78. Legal descriptions pp. 25 and 27 corroborate successor areas 12541 and 5900. Exclude all 8215 square feet of frozen 23v3_1 building area because it lies on retained lot 78; preserve the old R6 FAR and land-use fields on the reconstructed 18441-square-foot residential ground.",2026-09-21
post_policy,post_policy__Q01254595-I1,Q01254595-I1;Q01254580-I1,23v3_1,4006690036,13216,13216,0,,archival_recorded_area,https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2026082500424009;https://thedomaincos.com/portfolio/elara/,"Joint mortgage pp. 1-4 and 31-35 covers both Elara sites, legally describes lot 36, and names exact Site B job Q01254580-I1. Count complete fixed-vintage lot 36 once with all 13850 square feet of prior floor and its own FAR fields.",2026-09-21
post_policy,post_policy__Q01254595-I1,Q01254595-I1;Q01254580-I1,23v3_1,4006700004,10020,10020,0,,archival_recorded_area,https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2026082500424001;https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2026082500424009;https://thedomaincos.com/portfolio/elara/,"MIH declaration pp. 13 and 16 assigns lots 4 and 47 to exact Site A job Q01254595 and its 330 units. Joint mortgage pp. 1-4 and 31-35 covers both Elara sites and names both exact jobs. Count complete fixed-vintage lot 4 once with all 9900 square feet of prior floor and its own FAR fields.",2026-09-21
post_policy,post_policy__Q01254595-I1,Q01254595-I1;Q01254580-I1,23v3_1,4006700047,15767,15767,0,,archival_recorded_area,https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2026082500424001;https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2026082500424009;https://thedomaincos.com/portfolio/elara/,"MIH declaration pp. 13 and 16 assigns lots 4 and 47 to exact Site A job Q01254595 and its 330 units. Joint mortgage pp. 1-4 and 31-35 covers both Elara sites and names both exact jobs. Count complete fixed-vintage lot 47 once with all 15700 square feet of prior floor and its distinct FAR fields.",2026-09-21
```

The current producer's reviewed-reference bind must include `dcp_mappluto_archive_23v3_1.parquet` before these rows can validate. No uncertainty remains about the numeric allocation. The only classification judgment is whether to override Godwin's prior use to parking; the reviewed drawings do not say that, so the proposed row conservatively preserves the frozen commercial/industrial category.

Saved originals checked for this note are `site_research_supervisor_2026-09-16/godwin_agreement_2026071500691002.pdf`, `godwin_agreement_2025052300873001.pdf`, and `site_research_followup_2026-09-20_sourceids/41st_declaration_2026082500424001.pdf`, `41st_joint_loan_2026082500424009.pdf`, and `elara_developer.html`. Their SHA-256 hashes remain in those acquisition folders' existing manifests.
