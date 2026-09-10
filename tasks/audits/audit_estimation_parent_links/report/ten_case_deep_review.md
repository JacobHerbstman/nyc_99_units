# Which buildings belong to the same development?

**September 10 correction:** automatic refiling detection now removes the six withdrawn/replacement double counts (368 units) previously flagged in five estimation parents, plus six additional pairs elsewhere in the retained universe. Original filing dates are preserved. See `output/refilings.csv`; older references to these duplicates being pending are superseded by this correction. Membership, phase and unit-vintage questions unrelated to refiling remain open.

The recorded documents strengthen the case for separating the three disputed pairs. They also support common development for the seven proposed companions, although some additions still need an address crosswalk or a consistent unit schedule. **Connection confidence and unit-count confidence are different.** Third Avenue illustrates this particularly clearly: a recorded statement groups all three properties under one owner, while administrative sources disagree on their units.

This is an agent-drafted research assessment of ten selected cases, reviewed September 9, 2026. It supplements the complete 76-parent casebook. The comparison uses the saved HDB 25Q4 and July 2026 DOB data, with later public records identified below. The September 9 manual source now applies seven accepted companions and three rejected links in production. The table below preserves the pre-change totals and research recommendations; the implementation and renewed review immediately below give the current treatment. No new estimates have been run. A common economic development does not by itself establish how a wage rule applies to its buildings.

| Case | Recorded parent | Proposed treatment | Confidence and remaining issue |
|---|---:|---|---|
| 767 / 769 East 232nd | 10 + 55 = 65 | Separate | Separate contemporaneous site record and different sponsors; ultimate affiliations not disproved |
| 1660 / 1674 Boone | 80 + 340 = 420 | Separate | Separate site plan, owner entity and contract parcels |
| 3367 Wilson / 3374 Boston | 60 + 97 = 157 | Separate provisionally | Separate title/site records; older overlapping names and collateral remain |
| Bergen / Wyckoff + 290 Bergen | 268 | Include fourth building; saved sum 367 | Strong parcel and ownership evidence |
| Butler / Third + 278 Butler | 190 | Include third building; saved sum 280 | Explicit reciprocal development-lot descriptions |
| Beach 30th + 139 Beach 29th | 156 | Strong candidate for 230 | Common sponsor and explicit reporting; finish 147/155 alias crosswalk |
| 35th Avenue / 42nd + 35-11 42nd | 166 | Include Building 2; saved sum 234 | Distinct 68-unit building independently documented |
| Third Avenue + 4137 Third | 198 | Include third property; reconcile units | Direct common ownership/zoning statement; 297 is not a verified decision-date total |
| Richmond Terrace + 8 Stuyvesant | 519 | Include third building; reconcile units | Clear common project; saved 799 conflicts with earlier programs |
| Wharf Drive + 3 West | 672 | Common site supported; reconcile building history | Saved 822 depends on unresolved 30 Wharf identity/count and phase history |

The sums in this table are arithmetic applied to saved records, not new approved unit schedules. Splitting an existing parent changes the number of opportunities and may change whether its individual buildings pass the estimation cutoff. Adding a companion may combine already-observed opportunities rather than add previously unobserved housing. Those downstream changes require a producer correction and rebuild, not a manual change to a plotted total.

## September 9 implementation and renewed review

`tasks/parent_opportunities_manual/output/` now owns the committed decisions. Its two-line Makefile requires these source files without generating them. Producers symlink them, validate exact filing IDs and enforce the final component relation for every acceptance and rejection, including indirect paths. Seven supported companions are included; the three disputed pairs are separated. Ordinary proximity/owner rules are unchanged. Historical accepted endpoints remain available even when land covariates are missing; this restores 3 West without inventing its land area or geometry.

Third Avenue now has three additive constituents, **99 + 99 + 99 = 297**, under the documented proposed-design measure. Three separate source rows identify the October plans and review date. The saved DOB I1 fields remain **98 + 97 + 99 = 294**. The constructor preserves those fields and checks the documented schedule against its selected units. This does not certify the first-filed or approved schedule. Other cases' unresolved alias, phase and unit questions remain open; adopting membership does not resolve them.

### East 232nd: separate, with substantially stronger personal-name evidence

The [September 2, 2021 recorded lot statement](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2021090800775002), original PDF pages 2–3, covers block 4846 **lot 1 alone** for East 232 Builders LLC and identifies **Kol Zefi** in the notarization. The saved 767 application names that company and architect Jakov Saric/Node. The saved 769 application instead names **Young Bronx LLC / Ben Baum**, with Flavio Barros/CB Engineering, and lot 85. This is evidence beyond different LLC labels: different named people, architects and contemporary site boundaries. There is no affirmative joint-development evidence in the reviewed records. Keep separate with high confidence in the adjudication, while acknowledging that unrecorded ultimate affiliations cannot be disproved. The unusual 55-unit schedule at 769 remains a separate measurement issue.

### Boone: separate, supported by identified members and the neighboring contract

The [October 28, 2024 DEC application](https://extapps.dec.ny.gov/data/DecDocs/C203130/Application.BCP.C203130.2024-10-28.Complete%20BCP%20Application.pdf), PDF **page 62**, explicitly identifies **Moses Freund and Chaim Wiesenfeld** as Vaja Group LLC's current members and Moses Freund as its authorized representative. Vaja was seeking to purchase 1660, then owned by Omkar Properties. Its site plan concerns lot 1.

The [neighboring recorded purchase contract](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025040900379001), original pages 2–4, covers **lots 3 and 5**, at 1680 Boone and 1717 West Farms, with **AJ Boone LLC, c/o Apex Acquisitions 1 LLC**, as purchaser. It records an original May 14, 2024 contract with Raciv Corp, subsequently assigned to AJ Boone, and the April 4, 2025 agreement. This is not proof of a closed sale on April 4. Neither the parcels nor the identified development entities match 1660. Keep separate with high confidence. The contract does not reveal every ultimate owner of AJ Boone, so it is not an exhaustive beneficial-ownership comparison.

### Wilson/Boston: separate provisionally; common control is not settled

The [May 16, 2023 deed](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2023053000354001), original pages 2–3 and transfer forms, conveys current **lot 6** to Boston Wilson Partners LLC. Its schedule's reference to lots 4–7 is a **1926 subdivision description**, not four current tax lots. It must not be used to infer a contemporary combined project.

The [August 3, 2026 Boston zoning-lot statement](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026080500151002), original **page 2 diagram**, shows tentative lots 1 and 2 **inside current lot 1**, at the Boston/Bouck corner. It excludes Wilson's lot 6. Page 3 identifies Casuto Real Estate NY Inc's authorized signer as Vincent Caputo. The saved March/April filings also name different developers and architects: Cross Five Construction/Nicky Lumaj and Nikolai Katz for Wilson; Mordcha Walter and Boris Balkhiyev for Boston.

Together these support separate sites. They do **not** establish that the owners and filing developers lacked a joint agreement or common control in March–April 2026. The Boston document also postdates the July extract. The manual rejection is therefore explicitly **provisional**, and Wilson/Boston remains a pre-estimation issue. A contemporaneous development agreement or reliable ownership evidence connecting the title entities to the filing sponsors would resolve the remaining question more directly than additional adjacency searches.

The original case narratives follow as a dated record of the investigation. Statements about proposed additions or pending implementation there describe the earlier review, not the rebuilt dataset.

## 1. 767 and 769 East 232nd Street: evidence favors separate projects

The saved applications are X00640655 at **767, 10 units**, and X00521651 at **769, 55 units**, filed December 16 and December 13, 2021. They use different sponsors and architects: East 232 Builders / Node versus Young Bronx / CB Engineering. Their close filing dates and adjacency originally supplied the apparent connection.

The strongest new evidence is a **September 2, 2021 zoning-lot ownership statement**, recorded September 15 as CRFN 2021000365926. Its original image, page 2, identifies East 232 Builders and **block 4846, lot 1 alone**. It predates the saved applications and does not include 769's filing parcel, lot 85. The lot-1 index also records the May 2021 purchase by East 232 Builders and a January 2025 mortgage under that entity. [Recorded zoning statement](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2021090800775002).

The inspected deed for **lot 85**, dated August 29, 2017 and recorded September 20 as CRFN 2017000349348, transfers it from Dalton Johnson to YBX 4175 LLC for $200,000. ACRIS labels that parcel **4185 Barnes Avenue**; the link to this review is the saved filing BBL, not an exact street-address match. [Lot-85 deed](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2017091400572001).

A May 2023 permit article independently names Kol Zefi, East 232 Builders and Node for the 10-unit 767 proposal. Its publication date is not the initial filing date in our saved panel. [767 permit report](https://www.newyorkyimby.com/2023/05/permits-filed-for-767-east-232nd-street-in-wakefield-the-bronx.html).

**Recommendation:** separate the two buildings. This is evidence of distinct proposals, not proof that no ultimate affiliation exists. The 55-unit schedule at 769 also needs checking against drawings: inconsistent floor-area figures in permit reporting cannot resolve it. Do not infer that a suspicious unit count establishes a parent connection.

## 2. 1660 and 1674 Boone Avenue: separate contemporary development sites

The saved proposals differ substantially: **1660 has 80 units**, filed March 27, 2025, under Vaja / Moses Freund with Leandro Dickson; **1674 has 340**, filed June 6 under Andrew Sasson with GF55. Historical industrial-site connections do not settle their current organization.

The ACRIS index records the June 4, 2025 conveyance of **lot 1** from Omkar Properties to Boone Avenue Flats LLC for **$3.9 million** (CRFN 2025000158235), followed by a July 15 zoning statement under the buyer. That statement covers lot 1, indexed under the alias 1015 East 173rd Street. [1660 zoning record](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025071500857001).

The inspected 1660 zoning drawing, job **X01150558**, outlines lot 1 and the proposed eight-story building, with the neighboring building outside the boundary. This supplies physical site evidence beyond different owner names. [Zoning drawing, page 1](https://www.pincusco.com/property-data/ZD1_X01150558_1.pdf).

For 1674, an **April 4, 2025 memorandum of contract**, recorded April 22 as CRFN 2025000108701, identifies AJ Boone LLC, care of Apex Acquisitions 1 LLC, and **lots 3 and 5**. The original instrument lists those parcels and excludes lot 1. This is a contract record, not confirmation that the sale closed. [1674 contract memorandum](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025040900379001).

**Recommendation:** separate 80 and 340. The historical parcel connection is outweighed by the contemporary site and sponsor evidence. A contrary finding would need affirmative evidence that the two development entities share economic control or one coordinated project; none was recovered here.

## 3. 3367 Wilson Avenue and 3374 Boston Road: separate provisionally

Wilson's **60-unit** March 31, 2026 filing names Cross Five / Nicky Lumaj and Nikolai Katz. Boston's **97-unit** April 1 filing names Mordcha Walter and Boris Balkhiyev. One-day timing is weak evidence when the development teams differ.

A May 16, 2023 deed transfers **block 4734, lot 6** from 3388 Boston Road LLC to **Boston Wilson Partners LLC** for $2.95 million, recorded May 30 as CRFN 2023000132725. The parcel is indexed under the Boston Road frontage rather than Wilson's filing address. [Wilson parcel deed](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2023053000354001).

An **August 3, 2026** zoning declaration, recorded August 6 as CRFN 2026000221575, names **Casuto Real Estate of NY Inc** and **lot 1**, the 3374 Boston parcel. This is later than the July DOB capture and therefore corroborates a later separate site boundary, not necessarily the initial ownership arrangement. [Boston zoning record](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026080500151002).

Older index entries contain overlapping names and financing references, so these records do not prove unrelated ultimate owners. Nor does the difference between a title holder and the named DOB developer prove a contradiction: purchase contracts or development arrangements can precede conveyance.

**Recommendation:** separate provisionally, and retain an explicit unresolved-affiliation flag. No reviewed source identifies one current development spanning both filings. This conclusion is less definitive than Boone's documented separate site plan.

## 4. 290 Bergen Street: a well-supported fourth constituent

The current parent includes **270 Bergen, 99; 280 Bergen, 99; and 265 Wyckoff, 70**, totaling 268. Job **B01178945 at 290 Bergen** contributes another 99. Saved filings share Developing NY State, Katz and Hamish Whitefield; the candidate appears two days from its nearby anchor.

The August 2025 DEC amendment is unusually useful because it documents the actual parcel change. Page 1 states that **Bergen St Equity LLC acquired the whole site on April 1, 2024** and that the former parcels were reapportioned into **270 Bergen (lot 19), 280 Bergen (20), 290–298 Bergen (21), and 265 Wyckoff (57)**. Pages 2–3 identify Katz and Developing NYS; page 6 lists the four new parcels. The package contains the deed and tax-map exhibits. [DEC ownership and parcel amendment](https://extapps.dec.ny.gov/data/DecDocs/C224403/Agreement.BCP.C224403.2025-08-15.Amendment_No1_Change_Owner_Modify_Description.pdf).

This is substantially stronger than a broad environmental-site association: it names the contemporary owner and maps the old land into the four exact development parcels. **Recommendation: include 290 Bergen in the economic parent**, giving **99+99+99+70=367** using the saved counts. The amendment establishes membership, not an approved four-building unit schedule or wage classification.

A search also surfaced a community-created Open Data view containing a Bergen Wyckoff project identifier. It was not relied upon as independent HPD verification because its provenance and underlying rows were not fully checked.

## 5. 278 Butler Street: explicit descriptions identify the omitted lot

The parent currently contains **264 Butler and 176 Third Avenue, 95 units each**. The missing application, **B01372886 at 278 Butler**, has 90. All three were filed March 19, 2026 with the same sponsor and architect. Crucially, **all three descriptions identify development lots 21, 28 and 29**; 278 supplies lot 28. This is affirmative project language, not an inference from proximity.

The January 2025 revised DEC application provides the earlier assemblage history. It expands the cleanup application from the former 172 Third parcel to include **264 Butler**, under affiliated Goose entities. The attached site-access agreement identifies the relevant purchaser and volunteer relationship. The application pages identify the earlier lots 21 and 29; they are not a substitute for the later three-lot filing descriptions. [Revised application and site-access agreement](https://extapps.dec.ny.gov/data/DecDocs/C224410/Application.BCP.C224410.2025-01-06.Revised%20BCP%20Application.pdf).

August 2025 financing reporting describes Goose's acquisition/predevelopment borrowing and an earlier **180-unit, 14-story** concept. That differs from the subsequent three-building filings and should not be substituted for them. The report also uses broader address labels for the assemblage. [Financing report](https://commercialobserver.com/2025/08/gowanus-multifamily-project/).

**Recommendation:** include the third application: **95+95+90=280**. Membership is strongly supported. For a model of the initial choice, preserve the change from the earlier concept to the later applications rather than mixing their units or dates.

## 6. 139 Beach 29th Street: strong common-development evidence, with an alias gap

The current parent has **137 Beach 30th, 99**, and **147 Beach 30th, 57**. The missing **Q01177738 at 139 Beach 29th** has 74, with the same saved owner/applicant fields. The three recorded counts sum to **230**.

Commercial Observer's November 18, 2025 report expressly describes a three-building development by an Israel Hirsch affiliate: **137 Beach 30th (99), 155 Beach 30th (57), and 139 Beach 29th (74)**. It also reports concurrent purchases of the 137/109 Beach 30th and 139 Beach 29th sites through related purchaser names. [Three-building report](https://commercialobserver.com/2025/11/new-apartment-buildings-coming-far-rockaway-queens/).

The browser review found **ZAP project 2026Q0143, Beach 30th Street Waterfront Certification**, approved as N260174ZCQ. Its primary project brief explicitly describes **two buildings on one zoning lot at 137 and 155 Beach 30th**, with Beach Development 30th LLC as applicant. Its BBL list includes **4158220044**, used by the saved 147 filing. It does **not** itself certify all three buildings as one project. [City Planning project](https://zap.planning.nyc.gov/projects/2026Q0143).

**Recommendation:** retain 139 as a strongly supported economic companion, but finish the 147/155 address-to-job crosswalk before treating 230 as fully verified. Matching 57 units, sponsor, vicinity and a parcel in the planning application is persuasive, but the inspected webpage does not explicitly pair job Q01222315 with address 155. The linked DOB approval package failed to open in the browser; its contents were not assumed. This is a concrete remaining document gap.

## 7. 35-11 42nd Street: independently documented Building 2

The current parent contains **42-08 35th Avenue, 99**, and **35-17 42nd Street, 67**. The candidate **Q01332594 at 35-11 42nd Street** has 68. Saved records share Heartfelt Townhouse Build / Joel Weiss and JFA.

The January 29, 2026 City Record identifies **42-10 35th Avenue as Building 1, 35-11 42nd as Building 2, and 35-17 42nd as Building 3**, with separate OER project numbers. [City Record, printed pages 386–387](https://www.nyc.gov/assets/dcas/downloads/pdf/cityrecord/2026/cityrecord-01-29-26.pdf).

The browser review opened the actual **Building 2 OER repository**, project 26CVCP034Q / 26EHAN152Q, at **block 671, lot 10**. Its development summary describes a separate 16-story structure with **68 residential units**. The floor breakdown also adds to 68: 4 on floor 2, 20 on floors 3–6, 30 on 7–12, 8 on 13–14, and 6 on 15–16. The repository lists a January remedial plan, May approval and June remediation notice. [OER Building 2 repository](https://a002-epic.nyc.gov/app/workspace/39106/docrepository).

**Recommendation:** include Building 2, giving **99+67+68=234** in the saved data. This is a distinct building, not a second filing for one of the existing constituents. Retain the 42-08/42-10 alias issue in the plan crosswalk; building numbering and common sponsor support membership, while a shared legal wage assessment remains a different question.

## 8. Third Avenue: a documented three-99 plan, with conflicting administrative fields

The decisive new source is the **March 12, 2026 zoning-lot ownership statement**, recorded March 16 as CRFN 2026000074227. Its original image, page 3, identifies **lots 27, 31 and 35 in block 2923**, addresses **4137/4135, 4133 and 4121 Third Avenue**, and **4119 Third LLC as owner of all three**. This directly supports the three-property connection. [Recorded statement](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026031300731002).

The lot-27 title index also shows a **December 1, 2025 deed from 4137 Third LLC to 4119 Third LLC**, recorded December 4 as CRFN 2025000329360. That comes after the October filing. Together with the reported separate sale of 4121 in May 2026, the history shows why we should distinguish control when the proposal was made from later title and financing arrangements. The March statement verifies common ownership by that date; it does not independently settle every earlier affiliation.

**September 9 follow-up: the attached plans are stronger evidence than the portal summary.** The October 1, 2025 RAWP for 4121 and October 30, 2025 revised RAWP for 4133 both contain the same three-building plan on **PDF page 77 (Figure 3)**. It explicitly labels **4121, 4133 and 4137 as 15-story, 99-unit buildings** on tentative lots 35, 31 and 27. The unit schedule is independently checkable: **5 + 10 × 7 + 4 × 6 = 99 per building**, hence **297 planned units**. The drawings are embedded in environmental submissions; they are not shown as DOB-approved schedules. Their individual revision dates are not visible on these excerpted sheets. [4121 October RAWP](https://a002-epic.nyc.gov/api/files/a42e12f9-ce9f-f011-8274-005056b05749/download); [4133 revised October RAWP](https://a002-epic.nyc.gov/api/files/a7e7c9c4-b6b5-f011-827a-005056b05749/download).

The environmental reports are internally inconsistent. Their prose says **90 units per building**, but those October drawings say **99**. The older July 31, 2025 RAWP for 4137 contains a different plan on **PDF page 81** showing **three 13-story, 81-unit buildings**, while its prose says 15 stories and 90 units. This establishes conflicting versions within the documents; it does not prove the precise dates on which the developer revised the design. In particular, the OER webpage's 90 is not reliable evidence that the later program was reduced from 99. [4137 July RAWP](https://a002-epic.nyc.gov/api/files/80ea4186-4b6e-f011-826d-005056b05749/download).

The saved July 10, 2026 DOB extract has the following records:

| Address | Filing identifier | Filing date | Proposed units | Work description |
|---|---|---|---:|---|
| 4121 | X01223342-I1 | 2025-07-31 | 98 | New building |
| 4121 | X01223342-S5 | 2025-08-02 | 99 | Foundation |
| 4121 | X01223342-S6 | 2026-03-08 | 99 | Structural |
| 4133 | X01228107-I1 | 2025-10-24 | 97 | New building |
| 4133 | X01228107-S4 | 2026-03-09 | 99 | Structural |
| 4137 | X01223350-I1 | 2025-10-24 | 99 | New building |

These are filing dates attached to rows in a later snapshot, **not archived copies of every field as it stood on those dates**. The I1 label identifies filing type; it does not by itself establish an immutable initial-choice measure. All six saved rows have Objections status and missing approval dates. Supporting structural or foundation filings corroborate the 99 design, but should not mechanically override architectural filings in every project.

**Finding:** the three-property connection and a **99 + 99 + 99 proposed design** now have direct documentary support. The 90 prose does not defeat that evidence because the same submissions contain contrary drawings. The saved **98 + 97 + 99 = 294** I1 count remains an administrative-field discrepancy. We cannot honestly call 297 the exact first-filed or approved total without a dated authoritative dwelling-unit schedule. Preserve both source measures and this documentary adjudication; do not silently recode the raw I1 fields or select the maximum across filings. The two September 2026 remediation fact sheets concern cleanup, and do not settle a later approved apartment schedule.

## 9. 8 Stuyvesant Place: clearly part of River North; 799 is not the initial proposal

The saved parent includes **172 Richmond Terrace, 126**, and **178 Richmond Terrace, 393**. Job **S00661600 at 8 Stuyvesant** adds 280 in the saved data. The jobs share their February 1, 2022 filing date, Madison Realty Capital and FXCollaborative.

Contemporaneous February 3 reporting names the three exact jobs and gives **126 + 216 + 295 = 637 units**. The disagreement is concentrated in 178 Richmond and 8 Stuyvesant, rather than uncertainty over whether those buildings belong to River North. [Contemporaneous filing report](https://www.pincusco.com/madison-realty-capital-files-plans-for-three-buildings-for-a-total-of-637-units-in-staten-island/).

The city's **October 29, 2021 technical memorandum**, inspected in the browser, provides a further dated benchmark. Page 3 distinguishes the applicant's three-building development site from a separate neighboring development site. Table 1 on PDF page 5 describes a modified **625-unit** three-building program and removes the separate fourth building from the rezoning scenario. These are environmental/planning assumptions at that date, not an instruction to replace DOB units. [City technical memorandum](https://www.nyc.gov/assets/planning/download/pdf/applicants/env-review/liberty-towers/tech-memo.pdf).

**Recommendation:** include 8 Stuyvesant in the common parent, but hold the **799 = 126+393+280** sum from interpretation as the original decision. We have at least three distinct measured programs: the 2021 planning scenario, contemporaneous 2022 filing reporting, and the saved administrative records. Obtain the corresponding dated filing schedules before deciding which the model should measure. Do not add the independent neighboring development simply because it appeared in the same environmental analysis.

## 10. 3 West Street: common waterfront site supported; resolve 30 Wharf before summing

The saved parent is **7 Wharf Drive, 189**, plus **30 Wharf Drive, 483**. It is not a pair at 30 and 40 Wharf. Candidate **B00678680 at 3 West Street** has 150 and shares Halcyon / Lipa Friedman and February 22, 2022 timing with 7 Wharf. The saved link ledger accepts a connection in the DOB route that is absent from the historical route, so source coverage warrants a producer-level check.

The browser review found a **December 29, 2025 zoning declaration**, CRFN 2025000352730, listing M & H Realty and West Development entities. Its parcel schedule includes **lot 5 (3 West), lot 10 (7 Wharf), and lot 30**, along with several other block-2570 waterfront parcels. This independently supports common site membership, but the broader zoning lot does not identify one simultaneous financed phase. [Recorded waterfront zoning declaration](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025122900409002).

The unit problem is substantial. PincusCo associates the **same job B00680267** at 30 Wharf with **104 apartments**, and its property profile describes **nine stories**. Saved DOB/HDB instead describe **483 units and forty stories**. This may reflect revisions, address/building remapping, or an error in the secondary record. The review does not establish which explanation is correct. [30 Wharf job and property profile](https://www.pincusco.com/property/30-wharf-drive/).

**Recommendation:** recognize 3 West as a supported companion at the development-site level, but do not mechanically adopt **822 = 189+483+150** for estimation. First reconcile job, BIN, parcel, address and dated plan history for 30 Wharf and establish the relevant phase. The alternative 104 should not silently replace 483 either.

## What this changes for estimation

The three disputed links should no longer be described merely as awaiting an internet search: they now have recorded-document evidence favoring separation, strongest at Boone and less conclusive at Wilson/Boston. For the companions, Bergen, Butler and 42nd Street have particularly strong evidence for the proposed additions. Third Avenue and River North have strong membership evidence but unresolved unit timing. Beach has a specific remaining alias check; Wharf has a material building-history and phase question.

A defensible next production change would keep **membership evidence, the date of common control, physical-building identity, and the dated unit measure as separate fields**. The research supports those distinctions; it does not yet establish a universal decision date or legal organization classification. The existing all-parent audit remains the reference for the other 66 cases and the broader nearby screen.

The two automatic data reports retain the same 168 constituents and 1,238 nearby comparisons: this follow-up changes written assessments, not the underlying population. Browser records and links are identified case by case. Sources that could not be read are explicitly excluded from verified findings; an unsuccessful search is not treated as evidence that a link does not exist.

## 11. Why the seven companions were missed, and what should be automated

The reproducible trace is `output/companion_link_trace.csv`, generated by `code/trace_companions.R`. It checks the actual staged filing fields and the map vintage used in production. Each row compares the proposed companion with a named existing constituent. This is a bounded diagnosis of seven known cases, not a validation of a new citywide linkage rule.

| Companion | Verified failure in the current pipeline | Appropriate correction |
|---|---|---|
| 290 Bergen | Its filing lot 21 is absent from the 23v3.1 map. Its connection to old lot 19 is dated July 18, 2025, after filing, so the strict prefiling lot-history rule also refuses it. | Recover subdivision history and retain the dated common-project document as evidence; do not remove the date safeguard globally. |
| 278 Butler | Filing lot 28 is absent from that map. Existing descriptions name development lots 21, 28 and 29, but the linker only uses parsed job references and project codes, not this multi-lot development language. | Parse explicitly stated development-lot lists into candidate links, then check their meaning and block identifiers. The reviewed three-lot document supports this addition. |
| 139 Beach 29th | Filing lot 4158210050 is absent from the map; its reported lot 4158210046 differs. Shared ownership is present, but is insufficient under the current rule without exact touching. | Resolve the filing/reported-lot crosswalk and the project's address aliases; use the environmental project boundary as reviewed evidence. |
| 35-11 42nd | Filing lot 4006710010 is absent from the map. | Recover the subdivision crosswalk and use the documented common development. |
| 4137 Third | Both lot geometries exist, but the old map has a **7.239-metre gap** between lots 27 and 31, so exact touching is false. Same owner is true. | Use the dated three-building site plan and ownership statement. A map gap should trigger review, not automatically establish separate projects. |
| 8 Stuyvesant | It is already a same-owner nearby candidate with 172/178 Richmond, but that candidate flag is not an accepted link. There is no accepted exact-touch edge to those jobs. | Complete explicit candidate adjudication using the River North documents. No new search rule is needed to discover it. |
| 3 West | Raw HDB contains the filing and 150 units, but the selected prefiling map fails its lot match. Missing land area excludes it before historical linking. The alternate DOB route already links it to 7 Wharf. | Construct the membership universe before dropping filings for missing covariates, then resolve land area and phase/unit discrepancies separately. Do not lose a building from a parent's total merely because its land-area match failed. |

**Automation and manual review have different roles.** The broad nearby-filings audit already surfaced all seven. Code should automatically create that review queue, expose missing geometry and owner-supported candidates, and flag disagreements between the historical and DOB routes. Four missing map lots and one pre-link sample exclusion are data-coverage problems. Explicit multi-lot project language can also be parsed systematically. But common ownership plus proximity can connect independent projects, and historical shared lots can produce false links. The three disputed pairs are concrete reasons not to adopt that as an automatic acceptance rule.

For finalized production, use a small versioned pair-decision ledger with job IDs, accept/reject, source, effective date, and reason, applied through the producer. Such a ledger is reproducible manual research, not hand-editing an output. Test any improved automatic rule against both supported companions and the disputed negative cases; report its full set of changed components. Keep parent membership separate from availability of lot covariates and from the chosen unit-count vintage.

**Estimation remains on hold.** This follow-up establishes the seven mechanisms and the documentary three-99 design. It does not yet certify a finalized parent panel: the disputed pairs and companion decisions still need to enter the production producer, the remaining address/phase ambiguities need resolution, and all resulting parent totals need one declared measurement rule. The earlier review also left 1,101 nearby comparisons outside the 76-parent deep-review set unadjudicated and five filings without coordinates; a claim of complete citywide missed-link coverage would be premature.
