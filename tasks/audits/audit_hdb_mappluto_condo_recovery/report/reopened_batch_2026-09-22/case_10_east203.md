# Reopened boundary review: 270 East 203rd Street

**Parent:** `historical__210179974`. **Decision proposed for review:** 20,000 square feet of earlier land, comprising Bronx block 3308 lots 54, 55, 57, 59, 60, 61, and 62. The 160 housing units from the 23Q4 Housing Database remain unchanged. The old 278 East 203rd Street filing is earlier construction on land subsequently assembled and cleared, not a second component of the 2019 160-unit project. Keep its exact completion/CO status qualified.

## Ground and timing

The [NYC Finance tax map effective 2008-12-05](https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20330820081205152609), p. 1, draws seven separate, contiguous street-facing lots 54/55/57/59/60/61/62 between retained lot 51 to the west and retained lot 63 to the east. The [successor tax map effective 2019-09-17](https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/20330820190917174936), p. 1, draws **lot 59 alone over their exact combined 200-by-100-foot rectangle**; lots 51 and 63 stay separate. This is an exact site boundary, not merely a nearby-lot search radius. The DOF alteration book (`dtm_9`, transaction **86486**, 2019-09-17) independently calls the event a **lot merger** and lists all seven prior lots, with six acquisition CRFNs in its authorization field. Its recorded-map index (`dtm_8`) gives the two map IDs above and their effective dates. The 2020–21 [NYC Finance tentative assessment for BBL 2033080059](https://a836-pts-access.nyc.gov/care/datalets/datalet.aspx?LMparent=20&UseSearch=no&jur=65&mode=asmt_tent_2021&pin=2033080059&taxyr=2026), taxable-status date 2020-01-05, names Bolivar Ventures II LLC, calls the parcel class V0 (vacant zoned residential), and records 200-foot frontage, 100-foot depth, and 20,000 square feet. DCP MapPLUTO 20v1 likewise records lot 59 as 20,000 square feet with zero buildings/units. DCP 23v3_1 later records 160 units and 134,829 square feet of building area on the same 20,000-square-foot BBL.

The 2019 [DOB BIS job application extract](https://data.cityofnewyork.us/resource/ic3t-wcy2.json?job__=210179974), document 01, identifies job **210179974**, new building at 270 East 203 Street, block 3308 lot 59, BIN 2113436, filed **2019-07-25**. It proposes 160 dwelling units, 119,649 square feet of *zoning* floor area, and 140,034 square feet of total construction floor area. Those are proposed filing fields, not the earlier built-floor measure. The filing precedes the tax-lot merger, so the post-merger lot number alone would not prove the original footprint; the map transition, DOF transaction, and later assessment establish it. The old neighboring parcels were incorporated into this project lot rather than retained as separate tax parcels.

## Earlier buildings and the three-unit filing

The DCP 18v2Beta MapPLUTO snapshot used for the pre-filing reference has one row per old BBL:

| Old lot / address | Lot sf | Existing residential units | Existing gross building sf | PLUTO built FAR |
| --- | ---: | ---: | ---: | ---: |
| 54 / 258 East 203 Street | 2,500 | 1 | 1,208 | 0.48 |
| 55 / 260 East 203 Street | 5,000 | 2 | 1,908 | 0.38 |
| 57 / 266 East 203 Street | 4,000 | 3 | 1,660 | 0.42 |
| 59 / 270 East 203 Street | 2,250 | 3 | 3,510 | 1.56 |
| 60 / 274 East 203 Street | 2,100 | 3 | 3,300 | 1.57 |
| 61 / 276 East 203 Street | 2,058 | 3 | 3,434 | 1.67 |
| 62 / 278 East 203 Street | 2,092 | 3 | 3,735 | 1.79 |
| **Assembled earlier ground** | **20,000** | **18** | **18,755** | **0.93775 aggregate** |

The aggregate is `18,755 / 20,000`, calculated from the parcel building-area fields, not the mean of parcel FARs. It is **gross building area per land area**, an observed proxy; it is not a verified earlier *zoning* floor-area ratio. Lot 59 alone (2,250 square feet and FAR 1.56) understates the denominator and omits 15 of the 18 earlier dwelling units and 15,245 of the 18,755 recorded building square feet. The 19v1 MapPLUTO snapshot has the same seven buildings and figures; 20v1 records the merged lot as vacant. These snapshots support clearance of the earlier buildings, though they do not date each demolition.

The [DOB BIS extract for job 200649557](https://data.cityofnewyork.us/resource/ic3t-wcy2.json?job__=200649557) resolves its original location: 278 East 203 Street, **block 3308 lot 62**, BIN **2017255**, three proposed dwelling units, document 01 filed 2000-12-06 and fully permitted 2001-06-29. Its `total_construction_floor_area` is 3,435 square feet; the later DCP parcel measure is 3,735 square feet, which should not be silently substituted for DOB's plan measure. The DOB extract repeats documents 01 and 02 across five source rows; these are not five buildings. DOB still labels the job “permit issued—entire job/work” and does not record a completion date in the 23Q4 HDB record. However, the same old lot 62 is an observed three-unit building with year built 2000 in DCP 18v2Beta and 19v1, and [NYC Finance's 2018 Bronx annualized-sales roll](https://www.nyc.gov/assets/finance/downloads/pdf/rolling_sales/annualized-sales/2018/2018_bronx.pdf) lists its 2018 sale as a three-family dwelling at 278 East 203rd Street (block 3308, lot 62; 3 units; 2,092 square feet of land; 3,735 square feet of building). The independent address, old lot, BIN, unit count, and observed building make an unbuilt alternative unlikely. A final certificate of occupancy tying the historical structure to this job was not recovered, so “completed job” should remain an inference rather than a recorded DOB status.

## Proposed table values and limits

- `documented_development_bbls` / `documented_reference_bbls`: `2033080054;2033080055;2033080057;2033080059;2033080060;2033080061;2033080062` at the 18v2Beta reference; 2019 successor BBL `2033080059`.
- `documented_development_area_sqft` / `documented_reference_area_sqft`: **20,000**; `documented_reference_vintage`: `18v2Beta`; `documented_whole_site`: **TRUE** for the assembled 2019 site. The 2019-09-17 merger is after the 2019-07-25 filing but maps precisely to the seven earlier parcels. The DOF map shows neighboring lots 51 and 63 outside the merged rectangle.
- Earlier-land gross built area **18,755 square feet**, earlier-land gross built FAR **0.93775**, and earlier units **18** are audit quantities, not Housing Database replacements. If the production field is intended to be *zoning* floor area, leave it missing pending an actual zoning-area source; DOB's 2019 `existing_zoning_sqft=0` describes its cleared-site filing, not the earlier buildings.
- Review old job `200649557` as an **earlier built structure on former lot 62, later cleared within the site**. It is not a component of parent `historical__210179974` and should not be added to its fixed 160 units. Its administrative job status remains permitted; no exact CO or completion date was verified.
- The 2019 new-building filing uses a 20,000-square-foot site whose old building floor is absent from its proposed zoning-area calculation. This does **not** mean the pre-filing 18v2Beta baseline had no built floor: the seven-lot baseline already contains the earlier three-unit building and the other six structures. Avoid adding job 200649557's 3,435 proposed square feet again to that baseline.

The local [acquisition record](../../../download_parent_review_documents/code/reopened_batch_2026-09-22_10/README.md) gives exact URLs, IDs, hashes, and paths. The DOF sales PDF could not be saved locally (publisher returned HTTP 403 to the download), so its searchable official page is corroboration only; the independent DOB, DCP, DOF map/merger, and assessment records are the basis for the proposed decision. No shared manual table or production output was changed in this case audit.

## Supervisor adjudication — September 22, 2026

Root inspected the2019 DOF map and independently checked all seven18v2beta land/floor/FAR rows. Applied20000 ground and18755 gross prior floor. Classified the older three-unit filing as a building already captured in the reference map, with no new administrative completion date or unit override.
