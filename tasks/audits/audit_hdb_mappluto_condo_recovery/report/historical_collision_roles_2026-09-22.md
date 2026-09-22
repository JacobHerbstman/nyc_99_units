# Two 23Q4 historical filing collisions, September 22, 2026

This is a source review for filing roles, not a change to the administrative
unit counts. The 23Q4 observations come from the official [DCP Housing Database
archive](https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/housing-database/nychousingdb_23q4_csv.zip),
`HousingDB_post2010_inactive_included.csv`, pinned in
`tasks/fetch_dcp_housing_database/output/` (SHA-256
`ba204b240053f2477241d46eb9f4f4b11a15907484009e21264914c8cff1d45e`).
The DOB comparison is the saved July 10, 2026 extract of the official
[DOB NOW Build Job Application Filings dataset](https://data.cityofnewyork.us/resource/w9ak-ipjd.json);
the exact query is in `tasks/fetch_dob_now_new_building_filings/code/source_files.csv`.

| Job | Filed | 23Q4 status | 23Q4 Class A proposed | 23Q4 identifiers and description |
|---|---|---|---:|---|
| B00646589 | 2021-12-22 | Permitted | 189 | 2971 Shell Road; BIN 3429395; BBL 3072690001; residential flag; new-building consultation |
| B00775071 | 2022-09-19 | Permitted | 189 | 773 Neptune Avenue; BIN 3429394; BBL 3072690050; both residential and nonresidential flags; **“PROPOSE TO ERECT 1 STORY HOUSE OF WORSHIP NEW BUILDING.”** |
| M00536051 | 2021-07-29 | Withdrawn | 158 | 504 West 49 Street; BIN 1089491; BBL 1010770029; **“FILING FOR MIXED USE RESIDENTIAL BUILDING”** |
| M00580473 | 2021-08-31 | Permitted | 158 | 509 West 48 Street; BIN 1091768; BBL 1010770029; **same description** |

**Shell/Neptune.** B00775071 is an institutional filing, not another
189-apartment building. Its own archived description and `NonresFlag` say so;
the archived residential flag and copied 189 Class A count conflict with that
description. The DOB initial filing `B00775071-I1` now reports a four-story
high school and **zero** proposed dwellings, whereas `B00646589-I1` reports
189 dwellings. The DOB snapshot is later corroboration, not a replacement for
the 23Q4 count. The [May 2022 school-lot deed](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022052000328001)
and [residential-lot deed](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022052000544001)
give the two filings distinct successor parcels, as detailed in
[`site_research_followup_schools.md`](site_research_followup_schools.md).
Assign B00775071 a reviewed **nonresidential filing** role and retain
B00646589 as the 189-unit residential observation. Do not turn this into a
general `NonresFlag` exclusion: mixed-use residential jobs also carry that
flag.

**West 48/49.** M00536051 is an archived withdrawn version and M00580473
is the observed surviving version of the same 158-unit proposal: the two
share a BBL, exact job description and proposed count, and were filed 33
days apart. They are the only 2020–2022 New Building records on that BBL in
the inactive-inclusive 23Q4 CSV. The differing BIN and street address mean the strict same-BIN,
same-address alternative rule cannot identify this case. DOB's saved
`M00580473-I1` record confirms the 509 West 48 Street job, 158 proposed
dwellings and Douglaston Development as owner/business name; the old job is
absent from this current initial-filing extract. The certified March 2022
[HPD environmental assessment](https://zap-api-production.herokuapp.com/document/artifact/sites/nycdcppfs/dcp_artifacts/2019M0374%20-%20Certified%20EAS_21HPD031M%20-%201_A6CF3F6831ACEC11B3FE001DD804D73E/21HPD031M_Certified_EAS_03232022.pdf)
(physical pp. 19, 21, 32, 40) describes **one** proposed eight-story housing
building on the western approximately 21,923-square-foot part of lot 29,
with the eastern part retained as open space. Its early 163-unit planning
estimate must not override HDB's 158; the [October 2022 Council summary](https://legistar.council.nyc.gov/View.ashx?GUID=44B70351-B5A1-434B-9D21-4AB2500204B6&ID=11570042&M=F)
(physical p. 33) later describes 157 dwellings plus one superintendent unit.
The EAS and Council record do not name both DOB jobs, so the exact linkage
remains an inference from the administrative pair and single documented
site. A **reviewed superseded-alternative** role for M00536051, pointing to
M00580473, is supported; preserve the original July 29 filing date and the
August 31 successor date, and count only the latter's 158 units. Do not
generalize from same BBL and equal counts alone. The archived withdrawn
status is observed by 23Q4, but its `DateLstUpd` of September 1, 2021 is
**not a documented withdrawal date** and cannot establish that withdrawal
preceded the August 31 successor filing.

The adopted role rows are `B00775071,nonresidential_filing,` and
`M00536051,superseded_alternative,M00580473`. They apply only to the
historical residential-constituent calculation. The source records,
including conflicting unit fields, remain available for audit.

## Bedford Square's reused archived BIN

The four accepted Bedford Square jobs are one documented 877-unit economic
parent with four separately described buildings and a complete reviewed land
allocation; see the [recorded environmental-easement evidence](https://extapps.dec.ny.gov/data/DecDocs/C224384/Easement.BCP.C224384.2024-12-20.Recorded%20EE.pdf)
and `site_lot_decisions.csv`. The 23Q4 HDB assigns **BIN 3117909 to both**
east-side jobs `B00698118` and `B00722009`, creating one duplicate-BIN row
even though their addresses and unit counts differ. The saved official DOB NOW
initial-filing rows give four distinct, valid BINs:

| Initial job | Address and proposed units | 23Q4 HDB BIN | Later DOB NOW BIN and BBL |
|---|---|---:|---|
| `B00698115-I1` | 2201 Beverly Road, 296 | 3429365 | 3429365; 3051330044 |
| `B00698117-I1` | 2366 Bedford Avenue, 354 | 3429366 | 3429366; 3051330046 |
| `B00698118-I1` | 2363 Bedford Avenue, 132 | **3117909** | **3429348**; 3051350053 |
| `B00722009-I1` | 158 Lott Street, 95 | **3117909** | **3429347**; 3051350029 |

The DOB rows are from the dated July 10, 2026 extract of the official dataset
linked above. They corroborate distinct building identities; they do not
replace the archived BINs or the 23Q4 unit counts. In the rebuilt historical
site output before the narrow exception, **119** parents across all years have
duplicate archived BIN rows, including **34** with 2019–2022 cohort dates.
Only Bedford Square has both an exact full additive filing set already covered
by production `site_lot_decisions.csv` and complete, mutually distinct valid
DOB initial-filing BINs for those same jobs. Thus a reviewed-Bedford exception
to the duplicate-BIN composition screen has one qualifying parent, 877 units;
the remaining duplicate-BIN parents keep their review flags. The raw archived
BIN collision stays in the source and site diagnostics.
