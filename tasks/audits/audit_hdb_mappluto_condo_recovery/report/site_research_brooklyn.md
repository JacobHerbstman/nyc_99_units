# Brooklyn parent-site research

Current adjudications are in the [supervised review](site_research_supervised.md). The dated gathering rounds below preserve the evidence available at each stage.

## Result

The supervisor has accepted Ocean Parkway's 20,000-square-foot development
boundary after inspecting the recorded declaration and development agreement.
The other three cases remain unresolved. The governing [supervisor review](site_research_supervised.md)
holds the observed development boundary fixed and measures historical
characteristics within it. A later agency plan can establish that boundary;
the unresolved issue is the allocation of retained or common land.

North 8th's later lot 133 measures about 7,056 square feet; production carries
12,450. At Shepherd/Highland, later lots 48 and 49 measure about 17,121 square
feet and residual lot 148 about 3,037. At East 108th, the December 2025 map
shows lots 340 and 341 occupying about 40,974 square feet; the April 2026 split
creates lot 339, so current 340-plus-341 geometry measures only about 31,434.
The notes distinguish these map measurements from recorded legal areas.

No unit count, parent membership, legal wage-assessment-unit classification, or production file was changed.

## Evidence actually inspected

On September 16, 2026 I downloaded and visually inspected four one-page NYC DOF Digital Tax Map PDFs from the Property Information Portal. These are the literal identifiers in the citywide map index:

| Block | DOF map ID | Effective date | Map evidence |
|---:|---|---|---|
| 2315 | [30231520260601154944](https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/30231520260601154944) | 2026-06-01 | Lots 33 and 133 are separate; lot 133 fronts North 8th Street |
| 3958 | [30395820260520142453](https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/30395820260520142453) | 2026-05-20 | Lots 48, 148, and 49; 148 is on Highland Place and 49 fronts Shepherd Avenue |
| 7274 | [30727420250214160509](https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/30727420250214160509) | 2025-02-14 | Reconfigured lots 25 and 30; lot 30 is a 100-by-200-foot rectangle |
| 8235 | [30823520251202145125](https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/30823520251202145125) | 2025-12-02 | Lots 340 and 341 are carved from lot 342; lot 339 does not yet exist |

I also made one bounded live DOF current-lot query for the eleven relevant BBLs with geometry explicitly returned in **EPSG:2263**, then measured those polygons in square feet. The raw GeoJSON and source manifests are preserved in `tasks/audits/download_parent_review_documents/code/site_research_brooklyn_2026-09-16/`; the four PDFs are in that acquisition task's `output/` directory. Geometry area is not a recorded `LotArea` value and the map warns against using it as a legal survey.

I queried the live NYC Open Data [ACRIS Master](https://data.cityofnewyork.us/resource/bnx9-e6tj.json) and [Legals](https://data.cityofnewyork.us/resource/8h5j-fqxa.json) APIs by the four CRFNs named in the DOF authority. The valid 16-digit document IDs are:

| CRFN | ACRIS document ID | Legal rows |
|---|---|---|
| 2024000050425 | [2024022700757001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2024022700757001) | Block 7274, entire lots 25 and 30 |
| 2025000253774 | [2025091200907005](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025091200907005) | Block 8235, entire lot 342 |
| 2026000064330 | [2026022500765003](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026022500765003) | Block 8235, entire lots 340 and 341 |
| 2026000004050 | [2026010500213001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026010500213001) | Block 3958, entire lot 49 |

I inspected the ACRIS detail page for the Ocean Parkway instrument in Safari. It is a five-page "Deed, Other," dated January 30, 2024 and recorded February 28, 2024, with the Roman Catholic Church of the Guardian Angel on both party sides and entire-lot rows for lots 25 and 30. The image endpoint returned ACRIS's bandwidth-policy page. I did not bypass that restriction; no deed exhibit or survey image is represented as inspected. ACRIS `partial_lot = E` means entire lot, confirmed by the detail-page display.

Previously saved evidence supplies filing dates, descriptions, and BBL associations (`parent_site_other_filings.csv`), earlier/later intersections (`dof_all_parent_overlaps.parquet`), and action metadata (`dof_events.parquet`). Those are repository evidence, not newly inspected external documents.

## `post_policy__B01206874-I1`: 285 North 8th Street

B01206874 was filed April 8, 2025 for 99 units. The saved record uses 277 North 8th Street and describes a proposed 17-story mixed-use building. The audit associates the filing with **3023150133**, while HDB carries predecessor **3023150033** and production carries 12,450 square feet.

DOF transaction **601347**, effective June 1, 2026, affects lot 33 and creates lot 133. Its authority cites two 1927 deeds for parts of lot 33 (Liber 4826 page 416 and Liber 4842 page 85), a Tomasz Suwala survey dated April 14, 2026, and SI job 322121912. The inspected map shows both successors. EPSG:2263 geometry measures lot 133 at **7,056.20 square feet** and residual lot 33 at **5,075.97**, or 12,132.18 combined.

**Assessment:** production appears to approximate the broader pre-apportionment parcel, while the later filing lot is only about 7,056 square feet. The apportionment occurred fourteen months after filing. The tax map proves lineage and geometry but not whether the April 2025 opportunity used later lot 133 alone, all old lot 33, or another boundary.

**Status and missing fact:** unresolved. Candidate later footprint: **3023150133, 7,056.20 measured square feet**. Needed evidence is the B01206874 zoning/site plan or Suwala survey/deed schedules allocating old lot 33 at filing. No other live filing is identified in the audit envelope, but that absence does not allocate residual land.

## `post_policy__B01225983-I1`: 229 Shepherd Avenue and 240 Highland Place

B01225983 was filed May 23, 2025 for 99 units; B01241582 was filed June 19, 2025 for 99 units. Filing evidence names **3039580048 and 3039580049**. The reference map contains only lot 49, recorded at 20,653 square feet and measured at about 20,158.13.

DOF transaction **592544**, effective May 20, 2026, affects lot 49 and creates lots 48 and 148. It cites CRFN 2026000004050 and a Suwala survey dated April 29, 2026. ACRIS document **2026010500213001** names the entire old lot 49, not an allocation among the successors. The inspected map shows lot 48 at the Atlantic Avenue/Highland Place end, lot 148 adjoining it on Highland Place, and retained lot 49 along Shepherd Avenue.

Current EPSG:2263 geometry measures lot 48 at **6,934.40**, lot 49 at **10,186.96**, and lot 148 at **3,036.76 square feet**. All three total 20,158.12, matching old lot 49. Filing lots 48 and 49 total **17,121.36 square feet**.

**Assessment:** the map establishes geometric allocation, not economic-parent allocation. Lot 148 is omitted from the saved filing BBLs, yet it was created in the same action between lot 48 and the prior lot-49 land. That omission is evidence for review, not proof of exclusion.

**Status and missing fact:** unresolved. Candidate later filing footprint: **3039580048 + 3039580049, 17,121.36 measured square feet**; broader transaction footprint including 148: **20,158.12**. Needed evidence is the jobs' zoning/site plans or Suwala survey showing whether lot 148 is outside the development and any shared zoning lot.

## `post_policy__B01268544-I1`: 2978 Ocean Parkway

B01268544 was filed August 14, 2025 for 99 units on **3072740030**. Production reports 3,000 square feet, the stale recorded attribute in the reference source.

DOF transaction **238540**, effective February 14, 2025, moves the boundary between lots 25 and 30. It cites CRFN 2024000050425, an Anthony F. Muscat survey dated August 23, 2024, and SI job 322119417. ACRIS document **2024022700757001** covers entire lots 25 and 30; its detail page shows the same church on both party sides. The tax map shows lot 30 as 100 by 200 feet. Audit geometry measures **20,243.88 square feet** and the live EPSG:2263 query measures **20,243.90**. The later lot is only 34.4 percent of old lot 25's earlier geometry.

**Assessment:** 20,244 square feet is a well-supported later tax-lot measurement. The boundary changed after the policy date, and the 2024 recorded instrument encompasses both whole lots. A later recorded declaration with explicit metes and bounds was subsequently inspected; see the source-only round-two note below.

**Supervisor status:** accepted in the audit at **20,000 square feet**, using
the recorded legal boundary and the separate development agreement. The later
declaration states a 200-by-100-foot parcel, while January 2026 PLUTO still
carries the former lot's 3,000-square-foot attribute. The approximately
20,244-square-foot mapped geometry remains a comparison measurement. See the
supervisor report and preserved original instruments for the decision.

## `post_policy__B01297622-I1`: 937 and 951 East 108th Street

B01297622 was filed October 6, 2025 for 99 units; B01333932 followed December 16, 2025 for 99 units. The second description says the jobs are "one zoning lot with the same owner and applicant." Filing evidence names **3082350340 and 3082350341**. HDB carries predecessor **3082350342**, recorded at 77,600 square feet and measured at 70,674.91.

DOF transaction **458542**, effective December 2, 2025, affects lot 342 and creates lots 340 and 341. It cites CRFN 2025000253774 and a Krawczyk survey dated November 8, 2025. ACRIS document **2025091200907005** names the entire old lot 342. The inspected December map shows old lot 342 retained west of new lots 341 and 340; lot 339 is absent. Audit geometry for 340 and 341 totals **40,974.27 square feet**.

Transaction **570944**, effective April 23, 2026, then affects 340 and 341 and creates 339. It cites CRFN 2026000064330 and a January 13, 2026 Krawczyk survey. ACRIS document **2026022500765003** covers entire lots 340 and 341. Current EPSG:2263 geometry measures lot 339 at **9,540.58**, lot 340 at **15,155.66**, and lot 341 at **16,277.99 square feet**. Current 340+341 therefore totals only 31,433.65; adding 339 recovers **40,974.23**, the December footprint.

**Assessment:** the jobs support a common zoning lot but do not state its lot list or area. The first filing predates the December split; the second follows it by fourteen days. Lot 339's omission from the original filing BBLs cannot prove exclusion because it did not yet exist. All old lot 342 would add about 42 percent of the earlier parcel without development-allocation evidence.

**Status and missing fact:** unresolved. Candidate December footprint: **3082350340 + 3082350341, 40,974.27 measured square feet**. The same pre-April boundary is current **339 + 340 + 341, about 40,974.23**. Needed evidence is the jobs' zoning-lot diagram or Krawczyk surveys establishing the common boundary in old lot 342 and whether later lot 339 remains inside it.

## Proposed adjudication table

| Parent | Later measured candidate | Area (sq ft) | Exact missing evidence |
|---|---|---:|---|
| `post_policy__B01206874-I1` | 3023150133 | 7,056.20 | Filing site plan or Suwala survey/deed schedules allocating old lot 33 |
| `post_policy__B01225983-I1` | 3039580048 + 3039580049 | 17,121.36 | Site plans or Suwala survey establishing treatment of lot 148 |
| `post_policy__B01268544-I1` | 3072740030 | 20,243.9 | Muscat survey/deed exhibit or pre-development plan allocating earlier land |
| `post_policy__B01297622-I1` | 3082350340 + 3082350341 at December map | 40,974.27 | Zoning-lot diagram and Krawczyk surveys allocating old lot 342 and later lot 339 |

These measured candidates are checks and possible final values after documentary confirmation. They should not yet be adopted as recovered reference-date land.

## Round two: source gathering only

This section records additional source evidence without adjudicating a footprint. Under the project's framework, a later official plan can establish the complete observed development boundary even if that boundary was created after the policy date. The maintained research assumption then applies historical characteristics to that fixed observed footprint. The remaining question here is therefore whether an agency or filed instrument identifies all land in each observed development, including retained or residual lots.

### Official DOB NOW filing rows

I retrieved the six initial filings from NYC Open Data's [DOB NOW Job Application Filings](https://data.cityofnewyork.us/resource/w9ak-ipjd.json) endpoint. The exact JSON response is preserved as `dob_now_jobs_round2.json`.

| Job | DOB filing lot | BIN | Total construction floor area (sq ft) | Filing date | Additional scope evidence |
|---|---:|---:|---:|---|---|
| B01206874-I1 | 133 | 3430509 | 85,586.9 | 2025-04-08 | One 17-story mixed-use building; owner GW Infinity LLC |
| B01225983-I1 | 49 | 3430170 | 67,495.4 | 2025-05-23 | One eight-story mixed-use building; Empire Management & Construction |
| B01241582-I1 | 48 | 3430169 | 64,896.8 | 2025-06-19 | Separate building and BIN; same owner and architect as B01225983 |
| B01268544-I1 | 30 | 3196584 | 162,762.0 | 2025-08-14 | Mixed-use building with community facility/daycare; Rocklyn Asset Corp. |
| B01297622-I1 | 341 | 3427509 | 71,394.4 | 2025-10-06 | One seven-story mixed-use building |
| B01333932-I1 | 340 | 3427510 | 71,688.8 | 2025-12-16 | Description expressly says this and B01297622 are one zoning lot with the same owner and applicant |

These public rows are official initial-filing metadata, but they contain no site-area, zoning-lot-area, or multiple-lot field. Construction floor area is building floor area and must not be treated as land area. The rows strengthen the direct association of North 8th with lot 133, Ocean with lot 30, Shepherd with lot 49, Highland with lot 48, and the East 108th pair with lots 341 and 340. They do not answer whether residual lots 33, 148, 25, 342, or later 339 are inside a broader zoning/development site.

### Recorded instruments associated with the later lots

I retrieved bounded live ACRIS Master, Legals, and Parties responses for the relevant 2024-2026 parcel transactions. The raw responses are preserved as `acris_master_round2.json`, `acris_legals_round2.json`, and `acris_parties_round2.json`. No ACRIS scan image was requested in this round.

For **Ocean Parkway**, the August 11, 2026 closing transaction separates the fee parcel from broader land-use instruments:

- Document [2026080700950001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026080700950001) is a $17 million deed from the Roman Catholic Church of the Guardian Angel to 2980 Ocean Parkway LLC. Its ACRIS legal row is **entire lot 30 only**.
- Document [2026080700950002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026080700950002) is recorded as `DEVR` and has entire-lot legal rows for **both lots 25 and 30**.
- Document [2026080700950005](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026080700950005) is a declaration with entire-lot rows for **both lots 25 and 30**.
- The purchase-money mortgage and assignment documents, 2026080700950003 and 2026080700950004, attach to lot 30 only.

This metadata establishes that the purchaser acquired fee title to lot 30 while development rights or other declared land-use relationships also involved retained church lot 25. In the initial pass, neither scan had been inspected. The declaration was later supplied and read as documented below; the DEVR and its exhibits remain uninspected.

### Supervisor-saved Ocean legal descriptions

I independently inspected two ACRIS image PDFs saved by the supervising researcher in `tasks/audits/download_parent_review_documents/code/site_research_supervisor_2026-09-16/`. These files were supplied locally; I made no new ACRIS image request.

- Page 4 of deed **2024022700757001** describes then-lot 30 as a 100-by-30-foot rectangle beginning 700 feet north of West Brighton Avenue, or **3,000 square feet**. The same page describes then-lot 25 as the adjoining irregular parcel beginning 600 feet north of West Brighton Avenue. Its stated courses imply **57,000 square feet**.
- Page 6 of declaration **2026080700950005** describes new lot 30 as a 200-by-100-foot rectangle beginning 600 feet north of West Brighton Avenue, or **20,000 square feet**. It describes new lot 25 as a 200-by-200-foot rectangle beginning 700 feet north, or **40,000 square feet**.

The descriptions show that lot number 30 did not merely expand around its old location: the new 200-by-100-foot lot occupies the first 100 feet north of the 600-foot offset, while old lot 30 was the 100-by-30-foot rectangle beginning at the 700-foot offset. Thus the new lot-30 land was drawn from part of old lot 25, and the identifier's physical location changed. This is document content, not an adjudication of the research footprint.

The saved January 2026 PLUTO 25v4 CSV still records Brooklyn block 7274 lot 30 with `LotArea=3000`, `LotFront=30`, and `LotDepth=100`; lot 25 remains `LotArea=57000`. Its README dates the underlying DOF Digital Tax Map to January 14, 2026 and CAMA/PTS to January 26, 2026. Those attributes therefore predate the August 2026 declaration and retain the old legal descriptions. The saved 26v2 subset contains no block-7274 record, and the saved DOF assessment subset also omits this parcel. Consequently, no saved 26v2 or assessment record supplies a newer administrative `LotArea`. The best documentary area presently inspected is the declaration's explicit **20,000 square feet**, which is a recorded legal-description area and should remain distinct from the approximately **20,243.9 square feet** measured from mapped polygon geometry.

A court-filing search surfaced Kings County index **527949/2025**, NYSCEF document 2, the August 2025 purchase and sale agreement for the religious-corporation sale. The publicly indexed cover and contents identify the property as 2980 Ocean Parkway, block 7274 lot 30, and section 1 as "Sale of the Property, Acceptable Title and ZLDA." This was read only through a third-party indexed preview, not an official downloaded court file, so it is a lead rather than verified exhibit evidence. The ZLDA schedule and property exhibits remain needed.

For **East 108th Street**, the September 2025 transaction package attaches all eight instruments to entire old lot 342. The February/March 2026 package is more informative about relationships but not their spatial terms: agreement 2026022500765001 covers lots 340, 341, and 342; deed 2026022500765002 covers old lot 342; deed 2026022500765003 covers lots 340 and 341; consent 2026022500765004 and three easements 2026022500765005 through 2026022500765007 each cover all three lots. These records show continuing documented relationships between the two filing parcels and retained lot 342. Their uninspected exhibits are necessary to determine the common zoning lot, access, or retained-land treatment. Later lot 339 does not appear because these instruments predate its April 2026 creation.

For **Shepherd/Highland**, the January 2026 deed, mortgage, and assignment package attaches only to entire old lot 49. It predates the May apportionment and does not allocate later lots 48, 49, and 148. No later declaration, zoning-lot agreement, or easement document that identifies lot 148 was verified in this round.

For **North 8th**, no post-2024 ACRIS instrument in the bounded legal-record response supplies the old-lot-33 allocation. DOF's authority instead cites the two 1927 liber/page deeds and the 2026 Suwala survey. Those schedules remain the missing parcel-allocation documents.

### Zoning diagrams and agency searches

I tested the known public `ZD1_<job>_2.pdf` filename pattern for all six jobs. B01206874, B01225983, B01241582, and B01268544 returned HTTP 404. B01297622 appeared available to a HEAD request but returned an HTML 404 to an ordinary GET; B01333932 returned 404. No purported PDF was retained or treated as read.

Bounded searches for exact jobs and addresses on NYC.gov, ZAP, NYC community-board domains, DEC, and OER did not surface an official ZD1, zoning exhibit, environmental plan, or community-board package for these four sites. Search failure is not evidence that the records do not exist. The DOB NOW Public Portal drawing set remains the direct source for initial site area and zoning-lot diagrams; the specific needed sheets are the ZD1/zoning analysis and site plan for each initial filing.

### Document-level gaps after round two

| Case | Highest-value missing source |
|---|---|
| North 8th | B01206874 ZD1/site plan; Suwala SI job 322121912; 1927 deed schedules for the two parts of old lot 33 |
| Shepherd/Highland | ZD1/site plans for both jobs; April 29, 2026 Suwala survey showing lots 48, 49, and 148 and any common zoning lot |
| Ocean Parkway | B01268544 ZD1/site plan; ACRIS DEVR 2026080700950002 exhibits; NYSCEF 527949/2025 ZLDA schedules; Muscat survey. The declaration's legal schedule is now inspected and states a 20,000-square-foot lot 30. |
| East 108th | ZD1/site plans for both jobs; agreement/consent/easement exhibits in transaction 2026022500765; Krawczyk surveys showing retained lot 342 and later lot 339 |

This round adds source facts only. It does not select an observed parent footprint or recommend adoption of any measured area.

## Round three: September 16, 2026 source gathering

This round covers North 8th Street, Shepherd/Highland, and Charles Place. It preserves the project's July 8, 2026 post-period cutoff: records created after that date can clarify land use, but they do not automatically add a filing or its units to the frozen panel. No unit count or parent membership is changed here.

### Newly identified recorded instruments

I queried the official ACRIS Legals index for the three sites, then retrieved the corresponding Master and Parties rows. The unchanged responses are `acris_legals_round3.json`, `acris_master_round3.json`, and `acris_parties_round3.json` in the Brooklyn source folder.

For **North 8th**, the index identifies a zoning-lot statement, document [2026042300364002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026042300364002), dated April 16, 2026 and indexed to then-lot 33. After the subdivision, a May 27 package includes declaration [2026060300664001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026060300664001), development-rights instrument [2026060300664002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026060300664002), and two easements, 2026060300664003 and 2026060300664004. The first three are indexed to both lots 33 and 133. The parties include the Roman Catholic Church of Our Lady of Mount Carmel and 277 North 8 LLC; the fourth easement also identifies 275 North 8 LLC. The zoning statement and development-rights image were subsequently inspected, with page findings below.

For **Shepherd/Highland**, document [2026010600961002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026010600961002) is a zoning-lot statement dated December 31, 2025 and indexed to old lot 49 under Shepherd & Highland Holdings LLC. The post-split financing agreement [2026061900410001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026061900410001), dated June 16, is indexed to all three successor lots 48, 49, and 148. Separate June 17 deeds transfer lot 48 to **240 Highland Realty LLC** (2026061900410004) and lot 148 to **236 Highland Realty LLC** (2026061900410005); both entities use 49 Montrose Avenue. The subsequent OakNorth financing package groups lots 48 and 148 and names both entities, while lot 49 is absent from those particular instruments. This record structure shows that lot 148 was intentionally retained as a separately titled but affiliated parcel rather than an accidental map sliver. The zoning statement and all-lot agreement images are needed to determine the exact shared zoning boundary and any allocation of floor area or collateral.

For **Charles Place**, document [2026032600651001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026032600651001) is a zoning-lot statement dated March 25, 2026 and indexed to merged lot 71 under 21 Charles LLC. Other recorded instruments include a September 2025 declaration indexed to old lots 7 and 71 (2025090500755004), and February-July 2026 declarations, agreements, and easements indexed to merged lot 71 involving neighboring owners. The March zoning statement image was subsequently inspected, with page findings below.

### Page-level findings from the original zoning and development scans

The supervising researcher supplied four original ACRIS image PDFs after the index review. I rendered and inspected every page: all five pages of North 8 zoning document 2026042300364002, all 60 pages of North 8 development-rights document 2026060300664002, all four pages of Shepherd zoning document 2026010600961002, and all 13 pages of Shepherd agreement 2026061900410001. I also inspected all seven pages of Charles zoning document 2026032600651001. The files are in `tasks/audits/download_parent_review_documents/code/site_research_supervisor_2026-09-16/`.

**North 8.** The five-page zoning statement describes one broad zoning lot consisting of tax lot 1 and tentative lots 33 and 133; page 4 diagrams all three, and page 5 identifies the church as owner. That statement alone does not assign all zoning-lot land to the new building. The 60-page May 27 development agreement makes the allocation explicit. Page 2 defines **Parcel A** as lots 1 and 33 with the existing church buildings and **Parcel B** as lot 133 at 277 North 8 Street, ground leased to 277 North 8 LLC. Page 3 says current lot 33 was subdivided into Parcels A and B for development of a new Parcel B Building. Pages 4-5 allocate Parcel B exactly 72,600 square feet of floor-area development rights, capped at 70,000 residential and 2,600 community-facility square feet, and exactly **99 dwelling units**. Parcel A retains development rights above that allocation. Page 51's plan draws the proposed building entirely on lot 133 and labels lot 33 as the existing two-story brick church; it also shows a 30-by-71.06-foot light-and-air easement on lot 33 benefiting lot 133. The remaining driveway and elevation exhibits preserve the same separation. This is direct documentary evidence that the observed 99-unit building parcel is lot 133, while lots 1 and 33 provide a broader zoning-rights and easement context.

**Shepherd/Highland.** The December 31 zoning statement says on page 2 that the permit zoning lot is current lot 49 divided into proposed lots 48 and 49. Page 3 gives separate metes and bounds for 229 Shepherd/proposed lot 49 and 240 Highland/proposed lot 48; page 4 diagrams those two proposed pieces filling the old parcel. Hand calculation from the stated simplified courses gives approximately 10,328.84 square feet for proposed 49 and 10,411.16 for proposed 48, or 20,740.00 combined. This is close to the old recorded 20,653 square feet but should be treated as approximate because the scan contains apparent drafting errors and the Atlantic Avenue boundary is oblique. More importantly, the approximately 10,411-square-foot proposed-48 description spatially encompasses both final lot 48 (about 6,934 square feet) and the later carved lot 148 (about 3,037 square feet). The absence of the future number 148 from this December statement therefore does not exclude that land.

The June 16 mortgage splitter agreement confirms the later allocation. Page 3 identifies 240 Highland Place as lots **48 and 148** and 229 Shepherd Avenue as lot 49. Pages 4-5 divide the prior $5.8 million lien into $2.5 million on Premises A and $3.3 million on Premises B. Page 10 defines Premises A as lot 49. Page 11 defines Premises B as **lots 148 and 48** with separate legal descriptions. Thus, before the July 8 cutoff, the recorded instrument allocated lot 148 together with lot 48 to the Highland premises. The September 4 DOB filing later identifies lot 148 as a separate planned 21-unit building site. The documents establish a real timing distinction: lot 148 was within the Highland premises before the cutoff, then became the parcel for a separately filed third building after the cutoff. This section does not decide which observation-date boundary the analysis should adopt.

**Charles Place.** Page 3 of the March 25 zoning statement says the permit zoning lot consists of lots 71, 23, 6, and 19. Pages 3-6 provide their legal descriptions, and page 7 diagrams merged lot 71 as one continuous irregular parcel together with the three neighboring parcels. Because lot 71 had already absorbed old lot 7, the statement affirmatively includes the added old-lot-7 land in the permit zoning lot. The cover pages identify the other parcels' retained uses: lot 23 is an apartment building, lot 19 a two-family dwelling, and lot 6 an apartment building. The statement therefore supports the full merged lot 71 as the filing parcel but does not equate the four-lot zoning lot with the observed building's physical site. It reports no zoning-lot area or building envelope.

### Later official DOB evidence for lot 148

The official DOB NOW all-filings response adds a material fact that was absent from the earlier initial-filing snapshot. On September 4, 2026, amendments **B01225983-P5** and **B01241582-P4** each stated that they and new-building filing **B01446699-I1** are "related/under one zoning lot" and requested the same Hub Development examiner.

B01446699-I1 was filed the same day for **236 Highland Place, block 3958 lot 148, BIN 3430488**. It proposes a six-story-and-cellar residential building with **21 dwelling units** and 12,874.9 square feet of construction floor area. Its owner is Empire Management & Construction and its architect is DJLU, matching the two 99-unit jobs. This establishes a planned third building on lot 148 and an expressly shared zoning lot across all three jobs. Because the filing postdates the July 8 panel cutoff, it is later evidence about what the residual land was reserved for; it does not by itself change the frozen 198-unit parent or authorize adding 21 units.

The sequence narrows the Shepherd question. Before the cutoff, the June 16 financing agreement already covered lots 48, 49, and 148, while the June 17 deeds put 48 and 148 into separate affiliated LLCs. After the cutoff, DOB identifies lot 148 as a separate 21-unit building site sharing the zoning lot with the two 99-unit buildings. A plan or recorded exhibit must still show whether the study's observed-building boundary should allocate common land among the three buildings or treat lot 148 wholly as the later building parcel.

The unchanged DOB responses are `dob_now_all_round3.json` (59 rows across the four initial families) and `dob_now_b01446699_round3.json` (three rows). The latter contains the September 4 initial filing and two September 14 subsequent filings.

### Access record and remaining page targets

A fresh in-app browser request for an exact ACRIS document-detail URL returned `Browser is not available: iab` in this agent session. A direct ordinary request to the official DOB NOW public portal returned an Access Denied page; the unchanged response is `dobnow_portal_access_denied_round3.html`. I did not treat either failure as evidence that the documents are unavailable to the public, and did not attempt to bypass the restrictions.

After the scan review, the remaining highest-value image targets are narrower:

- North 8th: the reviewed development agreement already assigns the observed building to lot 133. The companion declaration may clarify zoning restrictions but is no longer needed to identify the building parcel.
- Shepherd/Highland: the initial or amended site plans are needed to establish when lot 148 changed from part of the recorded 240 Highland premises to a separately planned third building.
- Charles Place: the recorded statement includes merged lot 71 in a broader four-lot zoning lot. The B01320823 site plan is still needed to distinguish the building site and accessory areas within lot 71 from the neighboring retained-use parcels.

All new raw files are listed with URLs, retrieval date, byte counts, and SHA-256 hashes in `sources.csv` and `sources.sha256`. This section reports sources only and leaves boundary and parent adjudication to the supervising researcher.

## Supplemental primary-document inspection: East 108th and North 8th

The supervising researcher supplied the original 41-page East 108th development/easement agreement, document **2026022500765005**, and the related 15-page mortgage modification and spreader, document **2026022500765001**. I rendered and inspected all pages. The source PDFs are in `tasks/audits/download_parent_review_documents/code/site_research_supervisor_2026-09-16/`.

### East 108th Street

The easement agreement's page 4 defines **Parcel A** as retained lot 342 at 913 East 108th Street, owned by 913 East 108 LLC, and **Parcel B** as lots 341 and 340 at 937-951 East 108th Street, owned by Unity Grove LLC. It states that Parcel B will contain one or more new buildings. Pages 4-5 combine A and B as a zoning lot, transfer excess development rights needed to allow **198 dwelling units on Parcel B**, and preserve separate retained development rights for Parcel A.

The parking land remains Parcel A land. Section 2.A.xiii on pages 7-8 grants the Parcel B owner a **non-exclusive, permanent, and perpetual easement** for parking, ingress, and egress over the portion of Parcel A shown in Exhibit C. Parcel A may permit temporary or permanent obstructions only if they do not obstruct those uses, and the easement area must remain open and clear under applicable codes. Thus the 19 spaces drawn on lot 342 benefit Parcel B but are not conveyed as exclusive Parcel B fee land. Exhibit C on page 37 labels **19 spaces on lot 342, 35 spaces on lot 341, and 16 spaces on lot 340**, totaling 70 spaces. Page 39's form likewise grants light and air above part of Parcel A for the benefit of present and future Parcel B owners, beginning at elevation 15.66 feet; this too is an easement rather than a fee transfer.

Exhibit B on page 35 describes lot 341 as a 130.5-by-200-foot rectangle and lot 340 as a 90.5-by-200-foot rectangle. The stated legal-course areas are therefore **26,100** and **18,100 square feet**, or **44,200 square feet combined**. That is 3,226 square feet, or 7.30 percent, above the approximately 40,974-square-foot mapped December polygon. The instrument prints dimensions, not an area field; 44,200 is arithmetic from its legal courses.

The agreement expressly anticipates later parcel changes. Section 8 on pages 14-15 allows either owner to reapportion, merge, or subdivide the tax lots comprising its parcel, provided the agreement remains binding and the other owner's rights are not diminished. Page 38 is a light-and-air diagram; it is not a diagram of future lot 339. Because the later lots 339, 340, and 341 together recover the earlier mapped Parcel B extent, lot 339 was carved from the agreement's baseline Parcel B land. The document does not assign that later tax-lot number prospectively.

The related mortgage spreader confirms the fee-parcel division but does not alter it. Pages 3-4 define Parcel A as lot 342, Parcel B as lot 341, and Parcel C as lot 340; Unity Grove owns B and C. The mortgage lien on A is spread to the two new premises. Exhibits B and C on pages 14-15 repeat the same legal descriptions and 130.5-by-200 and 90.5-by-200 dimensions. Common mortgage collateral therefore corroborates the parcel relationship but is not additional physical land assigned to the new buildings.

### North 8th legal-course area check

The North 8 development agreement's Exhibit B describes lot 133 with parallel side depths of 91.07 and 50.06 feet, a North 8th Street frontage of 102.57 feet, and a 110.47-foot closing side. Enforcing geometric closure implies an approximately 90.008-degree angle between the frontage and parallel depths. The resulting trapezoid area is approximately **7,237.85 square feet**. This is a calculation from rounded legal courses, not a printed or administratively recorded `LotArea`. It is 181.65 square feet, or 2.51 percent, above the 7,056.20-square-foot EPSG:2263 polygon measurement. The agreement decisively assigns the observed building to lot 133 but does not print a parcel-area total, so the two area concepts should remain separately labeled.

## Round four: September 16, 2026 document inspection and large-site leads

This source-only round adds the Charles Place development agreement, confirms the North 8th legal-schedule page and checks current administrative area fields, then screens the two largest unresolved Brooklyn parents outside the original cases. It does not adjudicate a footprint.

### Charles Place development agreement

The supervising researcher supplied the 25-page original ACRIS image for zoning-lot development agreement **2026030200076003**. I rendered and inspected all pages. Physical PDF page 2 defines the **Owner Parcel** as lot 19 at 36 Troutman Street and the **Developer Parcel** as lot 71, formerly lots 7 and 71, at 21 Charles Place. It separately recites an August 2025 agreement under which retained lot 6 transferred excess development rights to the Developer Parcel. Physical page 3 similarly recites a December 2025 agreement transferring excess rights from retained lot 23, then says the developer intends to construct one or more new buildings on all or part of the Developer Land.

Physical pages 5-6 preserve lot 19's existing 1,962 square feet of floor area and two dwelling units as retained rights and transfer its excess development rights for use in a new building on the Developer Parcel. Physical page 24 is the legal description of the retained Owner Parcel, lot 19. Physical page 25 is the legal description of the Developer Parcel and explicitly labels it **block 3183 lot 71, formerly lots 7 and 71**. The agreement therefore distinguishes the physical development land, merged lot 71, from neighboring lots 6, 23, and 19, which remain separately owned parcels contributing rights or restrictions. It does not print a Developer Parcel area, proposed dwelling-unit count, or a count of buildings more specific than “one or more.”

### North 8th area-source check

The lot 133 metes-and-bounds schedule used for the 7,237.85-square-foot hand calculation is **physical PDF page 48** of the 60-page development agreement 2026060300664002. The page prints the four rounded courses but no area total.

I queried the current official NYC Open Data PLUTO row for BBL 3023150133. The row exists but its `lotarea`, `lotfront`, and `lotdepth` fields are null and therefore omitted from the JSON response. I also retrieved the official DOF Property Tax System FY2027 assessment page for 279 North 8th Street, block 2315 lot 133. The page identifies the parcel but displays **“-- No Data --”** rather than an assessment or parcel-area record. Neither current administrative response reports 7,238 square feet. Accordingly, 7,237.85 remains arithmetic from rounded legal courses, not a DOF-recorded `LotArea`.

### Larger unresolved Brooklyn parents outside the initial cases

For the 1,060-unit Noble/Oak parent, the official Brooklyn Community Board 1 revised June 9, 2026 meeting notice, physical PDF pages 2-3, describes a single vacant waterfront **Site** bounded by the East River, Noble Street, West Street, and Oak Street and reports an approximate site area of **173,834 square feet**. It says the site will contain two buildings: a 792-unit market-rate building at 10 Noble Street and a 268-unit affordable building at 2 Oak Street. It also says tentative tax-lot apportionment will divide lot 1 into lots 1 and 10. This is substantive official scope evidence for the complete two-building development site, but the notice's approximate area differs sharply from the audit's 252,780-square-foot old-lot area. The cited survey or apportionment map is still needed to reconcile whether the old mapped parcel includes land outside the described upland development site. The notice was already preserved by the acquisition task as `output/noble_cb1_notice_2026-06-09.pdf`; I inspected that unchanged file rather than downloading a duplicate. The current DOB response confirms B01312761-I1 is the 268-unit filing at 37 Oak Street and reports 262,530 square feet of construction floor area, which is a building field rather than land area.

For the 402-unit Schenectady Avenue parent, the official ACRIS indexes reveal a concentrated June 30, 2026 package recorded July 22 after the study cutoff. Document [2026070900638022](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026070900638022) is a zoning-lot statement indexed to lots 3 and 5. Agreement [2026070900638021](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026070900638021), declaration 2026070900638020, easements 2026070900638007 and 2026070900638008, and preliminary registration 2026070900638002 also connect lots 3 and 5 in the same transaction package. The initial DOB filing B01318629-I1 is on lot 3 and reports 402 units and 425,891 square feet of construction floor area. These indexes identify the zoning statement and agreements as the next decisive originals for distinguishing the building parcel from retained lot 5; their images were not inspected in this round. The July 22 recording date postdates the cutoff, while the master records date the instruments June 30, so both dates must be preserved.

The unchanged current PLUTO, DOF PTS, ACRIS, and DOB responses are stored in the Brooklyn source folder and recorded in `sources.csv` and `sources.sha256`. The Charles and North agreements are supervisor-supplied scans in the separate supervisor folder. No production table or adjudication was changed.

## Comprehensive Brooklyn flagged-parent inventory: frozen 62-case first pass

This table covers every unresolved Brooklyn parent selected from `/tmp/nyc_site_scope_before_round3.csv` by an unresolved flag and a candidate or filing BBL beginning with 3. “Frozen DOF audit” means saved parcel/action evidence, not a newly inspected primary drawing. Rows marked “Primary document” or “Primary agency notice” identify actual document review. This inventory does not change an adjudication or claim that all cases are resolved.

I also inspected the saved official DEC Brownfield Cleanup Program property package for 560 Degraw Street. Its text on physical pages 1–2 states a 38,500-square-foot environmental site made from 35,000 square feet of old lot 17 and 3,500 square feet of lot 49. Figure A-2 on physical page 7 draws that blue site boundary, and the Fehringer title survey on physical page 11 prints 38,499.76 square feet and labels Proposed Lots A and B. The March 2026 DEC amendment states that old lot 17 was subdivided into lots 16, 17, and 47 and that the amended BCP site retains lots 17 and 47 while removing lot 16. These sources narrow the land history shared by the 540 Degraw and 565 Sackett cases, but an environmental-site boundary is not automatically a building boundary.

| Parent | Concrete finding or evidence | Remaining unresolved item |
|---|---|---|
| `post_policy__B01312761-I1` | Primary agency notice: Brooklyn CB1 pp. 2–3 describes one 173,834-sf waterfront site with 792- and 268-unit buildings and tentative split of old lot 1 into lots 1/10. | Obtain the cited survey/apportionment map to reconcile the notice with the 252,780-sf historical mapped parcel. |
| `historical__321595403` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3011290050;3011290100; change 2019-11-12–2023-03-27; action 98370;87582. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__321387021` | Frozen DOF audit: source or reference-date disagreement; earlier lots 3024720002;3024720021; change 2018-12-20–2022-03-04; action 95288;93636;83294;83289; link review: connection supported. | Need the original filing lot schedule/ZD1 and dated DOF map from the same reference date. |
| `historical__321590532` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3011200001;3011200019; change 2022-08-16; action 96764;96762. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__321593986` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3011900029;3011900045;3011900050; change 2019-12-09; action 88012;88011. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__321595145` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3001740018;3001740023;3001740024; change 2020-01-07–2024-09-17; action 162222;88955;88954;88450;88437;88418; related filing(s) B01019417. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `post_policy__B01318629-I1` | Official indexes: June 30 package includes ZONE 2026070900638022 and AGMT 2026070900638021 on lots 3/5; DOB filing on lot 3 has 402 units. | Inspect the ZONE/AGMT images to separate building land on lot 3 from retained or shared lot 5. |
| `historical__B00604543` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3024940006;3024940010; change 2021-06-01–2022-02-14; action 95036;95030;92702. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00698117` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3051330014; change 2023-11-08; action 99953; related filing(s) B00698115. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `historical__321598400` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3004400001;3004400012;3004400021;3004400023;3004400024;3004400025;3004400026;3004400047;3004400048; change 2022-12-23; action 97615;97614. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00664860` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3020850001; change 2021-04-02–2023-03-10; action 98262;92267. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00588594` | Frozen DOF audit: incomplete earlier map or area; earlier lots 3001610001;3001610003;3001610062;3001610063;3001610064; change 2022-03-01–2022-09-02; action 96886;95254. | Need the missing dated tax map or recorded survey and its administrative area field. |
| `historical__B00587387` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3028850001; change 2021-12-13; action 94526. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00665570` | Primary DEC amendment: old lot 17 was subdivided into lots 16/17/47; the amended 563 Sackett BCP site retains lots 17/47 and removes 16. The frozen audit links B00600959. | Need both projects’ filed site plans or a development agreement; the BCP boundary establishes environmental scope, not the separate building footprints. |
| `historical__B00696389` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3017030014;3017030048;3017030049;3017030050;3017030051;3017030052;3017030053;3017030054; change 2023-10-27; action 99901;99900; link review: connection and distinct proposed buildings supported. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00698115` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3051330014; change 2023-11-08; action 99953; related filing(s) B00698117. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `post_policy__B01176928-I1` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3045860300; change 2024-05-01–2026-02-20; action 520143;136904; link review: connection and distinct proposed buildings supported. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00665500` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3030760018; change 2022-08-11; action 96727; related filing(s) 321594155. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `historical__321387478` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3020100001;3020100059; change 2020-06-19–2023-12-12; action 102897;90038;90037; related filing(s) 321384480. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `post_policy__B01325937-I1` | Frozen DOF audit: missing later parcel map. | Need the post-change DOF map/apportionment survey and a filed site plan tying the new lot boundary to the building. |
| `historical__B00600959` | Primary DEC package: the 2021 Fehringer survey and 2022 BCP application define a 38,499.76-sf environmental site from 35,000 sf of old lot 17 plus 3,500 sf of lot 49; the frozen audit links B00665570. | Need both projects’ filed site plans or a development agreement allocating that surveyed land between the 540 Degraw and 565 Sackett buildings. |
| `historical__321592200` | Frozen DOF audit: filing lot list differs from mapped site; earlier lots 3020580038;3020580047;3020580049;3020580050; change 2024-07-24; action 159710. | Need the original filing site plan and legal lot schedule to reconcile the filing list with mapped ground. |
| `post_policy__B01196476-I1` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3042230001;3042230006; change 2025-10-30; action 434541. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00601179` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3010100026; change 2024-05-21; action 142901. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `post_policy__B01225983-I1` | Primary documents: ZONE 2026010600961002 and AGMT 2026061900410001 place later lot 148 within the Highland premises before the cutoff; a 21-unit lot-148 filing appears only after cutoff. | Preserve the filing cutoff and document how common land is treated; root adjudicates the boundary. |
| `post_policy__B01297622-I1` | Primary document: easement 2026022500765005 defines new-building Parcel B as lots 340/341 and retained Parcel A as lot 342; parking on 342 is non-exclusive easement land. | Later lot 339 must be crosswalked within Parcel B; distinguish 44,200 legal-course area from mapped geometry. |
| `historical__B00646589` | Frozen DOF audit: other filing in transaction envelope; earlier lots 3072690001; change 2022-03-24; action 95481; related filing(s) B00775071. | Need a plan or legal schedule assigning transaction-envelope land between this filing and the named other filing. |
| `historical__321592825` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3037660001; change 2021-10-06–2024-03-26; action 128608;93861; related filing(s) 321590293;B00873882. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `historical__B08021996` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3045860001; change 2022-12-15; action 97551. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00608472` | Frozen DOF audit: source or reference-date disagreement; earlier lots 3014170008;3014170009; change 2022-04-27; action 95875;95874; link review: connection supported. | Need the original filing lot schedule/ZD1 and dated DOF map from the same reference date. |
| `historical__321595608` | Frozen DOF audit: incomplete earlier map or area; change 2021-01-08; action 91521;91506; related filing(s) 320912170; link review: connection supported; earlier companion outside window. | Need the missing dated tax map or recorded survey and its administrative area field. |
| `historical__B00656247` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3010530004;3010530020;3010530021;3010530023;3010530025;3010530026;3010530027;3010530078;3010530079;3010530086;3010530092;3010530127;3010530133;3010530134;3010530179; change 2025-01-07; action 210541. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__321590346` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3023860003;3023860004;3023860007; change 2021-04-26–2021-06-14; action 92768;92767;92440;92439. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00653212` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3032320001; change 2022-03-24; action 95473. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__321387290` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3014360028;3014360032;3014360036; change 2021-02-03; action 91739;91732. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00645685` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3004560013;3004560017;3004560023; change 2021-03-24–2023-12-06; action 101298;92151. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00621533` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3004620006;3004620008;3004620009;3004620042;3004620044; change 2022-01-25–2022-01-31; action 94904;94903;94878;94845;94839. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00698118` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3051350053; change 2024-06-07; action 147303; related filing(s) B00722009. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `post_policy__B01278364-I1` | Frozen DOF audit: missing later parcel map; earlier lots 3004340001; change 2026-09-14; action 687745; related filing(s) B01410529; link review: internal connection supported. | Need the post-change DOF map/apportionment survey and a filed site plan tying the new lot boundary to the building. |
| `historical__321600530` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3045860300; change 2021-11-19–2026-02-20; action 520143;136904;99105;97360;94315; related filing(s) 321600503;B00692150;B00923109;B00923376;B01176928;B01176982. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `historical__B00509455` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3022650014; change 2021-07-06; action 92987; related filing(s) B00492768;B00497202;B00497203;B00497204. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `historical__321594422` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3050650035;3050650036;3050650037;3050650038;3050650039;3050650093; change 2020-12-15–2021-09-21; action 93737;93733;91315. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00680820` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3017780055; related filing(s) 321180155. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `historical__321600362` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3064710008;3064710113; change 2024-07-29; action 160105; related filing(s) 321384756. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `historical__B00781447` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3001670016; change 2025-03-27; action 272940; related filing(s) B00814498;B01127732. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `post_policy__B01206874-I1` | Primary document: DEVR 2026060300664002 pp. 2–5, 48, 51 assigns the 99-unit building to lot 133 and retained church uses to lots 1/33. | DOF has no current recorded LotArea; keep the 7,237.85 legal-course calculation labeled as calculated. |
| `post_policy__B01320823-I1` | Primary documents: AGMT 2026030200076003 defines Developer Parcel lot 71 (formerly 7+71); ZONE 2026032600651001 shows lots 6/19/23 as separate retained-rights parcels. | The older 46-unit filing remains a filing-scope question; do not add retained neighbors to physical ground. |
| `post_policy__B01327363-I1` | Primary document: easement 2025121500836001 separates planned-building lot 34 from existing-building lot 28; access/ramp rights do not transfer lot-28 ground. | Initial ZD1 and predecessor job 320911233 status are still needed to classify the filing relationship. |
| `historical__B00722009` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3051350053; change 2024-06-07; action 147303; related filing(s) B00698118. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `historical__B00560420` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3035870001;3035870027; change 2024-02-28–2024-07-31; action 160120;119303. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__321590293` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3037660001; change 2021-10-06–2024-03-26; action 128608;93861; related filing(s) 321592825;B00873882. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `historical__321595733` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3027420004;3027420005;3027420009;3027420032; change 2021-07-26; action 93159;93157. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__321594155` | Frozen DOF audit: other filing in transaction envelope; earlier lots 3030760022;3030760040; change 2019-11-10–2022-08-11; action 96727;87575; related filing(s) B00665500. | Need a plan or legal schedule assigning transaction-envelope land between this filing and the named other filing. |
| `historical__321598883` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3034000035;3034000063;3034000068; change 2021-07-23; action 93151;93146. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__B00588575` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3051070088;3051070097;3051070101; change 2023-06-22; action 99078;99070; related filing(s) B00591617. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `post_policy__B01391270-I1` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3033140070; change 2026-01-22; action 498143; related filing(s) B00878475. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `historical__B00789072` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3051050014; change 2025-06-27; action 340540. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__321592709` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3012800028;3012800029;3012800030; change 2023-03-08; action 98189;98182. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__321386077` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3030610010;3030610025; change 2022-01-27; action 94859;94858. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |
| `historical__321387913` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3011920085/3011920095; change 2021-12-30; actions 94678/94677. | Need the 2021 apportionment survey or deed schedules allocating the earlier two-lot land to the 1 Sullivan Place building and residual land. |
| `historical__321600380` | Frozen DOF audit: shared earlier land or other filing; earlier lots 3020940001;3020940035; change 2021-12-03–2021-12-06; action 94456;94445; related filing(s) 321583238. | Need a site/ZD1 or recorded development agreement separating the observed building ground from the named shared or other filing land. |
| `historical__321954364` | Frozen DOF audit: partial earlier parcels require allocation; earlier lots 3007830001; change 2019-07-18; action 85861. | Need a dated survey, deed schedule, ZD1, or site plan allocating the earlier parcel among the observed building and residual land. |

## Round five: Charles Place and Broadway predecessor-filing relationships

This round compares the two older BIS new-building jobs with the live DOB NOW filing families, permit records, certificate-of-occupancy indexes, and the project's read-only refiling rules. It leaves Housing Database units and filing dates unchanged.

### Charles Place: 321590541 and B01320823-I1

The official legacy DOB permit dataset contains nine permit rows for job 321590541. It issued the original foundation permit June 3, 2022 and the initial entire-new-building permit July 25, 2025. Under Lefko Capital Group, DOB renewed the entire-building permit on May 6 and May 13, 2026 and renewed the foundation permit June 12, 2026, all expiring May 5, 2027. These dates overlap the newer 99-unit filing: B01320823-I1 was filed November 20, 2025, approved June 18, 2026, and first permitted July 9, 2026. Both use BIN 3428696, block 3183 lot 71, and Lefko Capital Group appears as owner on the current records. The old job proposes five stories and 46 units; the new job proposes eleven stories and 99 units.

The overlapping active permit records establish **administrative coexistence of two job numbers**, not physical coexistence of two finished buildings. No old or new row explicitly calls B01320823 a replacement, amendment, or continuation of 321590541. None of the 19 saved DOB NOW family rows for B01320823 names 321590541. Conversely, the old job's foundation and permit descriptions refer only to 321590541. The legacy and DOB NOW certificate-of-occupancy datasets return no rows for either the two job identifiers or BIN 3428696. That absence does not prove noncompletion; it only means these public CO indexes supply no issued-CO cross-reference.

The reviewed recorded agreement remains physical-scope evidence rather than filing-role evidence. Agreement 2026030200076003 defines Developer Parcel lot 71, formerly lots 7 and 71, for one or more new buildings, but contains no DOB job number and does not say whether the five-story design was abandoned or folded into the eleven-story design. The missing decisive record is an approved B01320823 zoning/site plan or DOB administrative filing statement that identifies existing construction from 321590541, together with a superseding, withdrawal, or amendment notation if DOB made one. Public Open Data and the recorded instruments inspected here do not supply it.

### Broadway: 320911233 and B01327363-I1

The official legacy permit dataset contains 30 permit rows for job 320911233. The older hotel/residential job received foundation permits beginning October 2018, an entire-new-building permit in January 2020, and repeated renewals. Its latest entire-building and foundation renewals were issued October 24, 2025 and expire October 24, 2026. The new 99-unit filing followed on December 11, 2025 on the same BIN 3063559 and lot 34. Its initial description explicitly requests assignment to the same examiner as job 320911233. Later filing B01327363-S9 states that it performs **selective partial demolition of existing slab on grade and non-bearing concrete columns/walls** in conjunction with B01327363-I1.

Those facts support reuse or redesign of physical work associated with the older project more strongly than simple same-lot proximity: the new filing itself points DOB to the old job, and the new filing includes selective demolition of existing concrete work. They still do not say that all work under 320911233 was superseded, nor whether any approved old scope survives as a phase of the current project. The October 2025 old-job renewal also does not prove a second building; it predates the new filing by seven weeks and merely kept the old permit active through October 2026. The legacy and DOB NOW certificate-of-occupancy datasets return no rows for either job identifiers or BIN 3063559, which supplies no completion or replacement cross-reference.

Recorded easement 2025121500836001 uses a May 2018 Stonehill Taylor ground-construction plan for the Hotel Building, while the new filing uses Stonehill & Taylor and the same BIN. The agreement separates lot 34 from the neighboring lot-28 building but does not identify either DOB job or state a successor relationship. The most probative missing record remains B01327363's approved ZD1/site plan and any DOB superseding or amended-plan notation comparing it with 320911233. The indexed private copy was not accessed because it required payment, and no access restriction was bypassed.

### What the existing parent/refiling rules can decide

The automatic refiling rule in `tasks/construct_parent_cohorts/code/construct_parent_cohorts.R` is intentionally narrow. It requires an original DOB NOW filing marked **Filing Withdrawn**, a unique later non-withdrawn filing in the same sample, the same valid BIN, and exact normalized owner and applicant matches; it also stops on conflicting manual roles or cross-parent matches. Neither case qualifies. Both older jobs are legacy historical filings in a different sample, both remain coded `PERMIT ISSUED - ENTIRE JOB/WORK`, and neither is marked withdrawn. Broadway also changes the named owner, while Charles lacks the required explicit withdrawn status and cross-sample eligibility.

The manual `superseded_alternative` mechanism can encode an independently documented replacement, as it does for other reviewed cases, but it is a decision input rather than a generic inference from same lot, same BIN, permit overlap, or absence of a certificate of occupancy. Applying a consistent existing rule therefore leaves both relationships unresolved. Broadway has affirmative evidence of coordinated redesign/reuse; Charles has a common owner, BIN, parcel, and overlapping permits but no explicit cross-reference. Neither pair supports adding the old units to the current filing, and neither currently meets the project's documentary standard for marking the old filing superseded.

The unchanged official CO and permit responses are preserved in the Brooklyn source folder with exact query URLs, retrieval date, byte counts, and SHA-256 hashes in `sources.csv` and `sources.sha256`.
