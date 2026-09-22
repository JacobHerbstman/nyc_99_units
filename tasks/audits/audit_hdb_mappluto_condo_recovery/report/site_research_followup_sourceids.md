# Four parcel-source discrepancies: follow-up evidence

This is an isolated source review. No audit classification, parent membership,
production area, unit count, or filing date was changed by this review. The unchanged PDFs,
raw JSON, URLs, and hashes are in the
[September 20 source acquisition](../../download_parent_review_documents/code/site_research_followup_2026-09-20_sourceids/README.md).
The area numbers below are DOF `LAND_AREA` attributes, not areas estimated
from drawn polygons.

| Parent and saved conflict | New primary evidence | Present interpretation |
| --- | --- | --- |
| `post_policy__B01325937-I1`, 964 Franklin: DOB 3011020063, HDB 3011920063; production 13,109 sq ft | NYC Planning's exact-address geocoder returns **Brooklyn 1192/63**; DOF's current map has no 1102/63. The [December 2025 recorded zoning instrument](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025120900296002), PDF pp. 2–4, describes and draws a **proposed new lot 63** with about **288 ft 5 in** of Franklin frontage, taking most of old lot 66; proposed new lot 66 retains about **58 ft** of frontage. | DOB block `1102` appears to be a typo, but the currently tabulated 13,109 sq ft is **old lot 63**, not the proposed development parcel. The original address and lot-number match do not establish the 259-unit building ground after subdivision. The companion `B01325938-I1` at 970 Franklin (117 units) may share the larger development; the recorded proposed map is the next boundary anchor, but a new parcel area is not printed. |
| `post_policy__Q01288509-I1`, 27-30 21 Street: DOB 4005390038, HDB 4005390037; production 2,500 sq ft | The 2023 DOF tax map shows lots 37 and 38 separately at **25 × 100 ft each**. The September 17, 2025 successor map shows **one 50 × 100-ft lot 37**, with no lot 38. DOF daily description gives lot 37 **5,000 sq ft**, and the exact address geocodes to 37. ACRIS deed 2025040701031001, dated April 4, 2025, indexes both old lots and names Prospectus Astoria LLC as grantee. | The October 6, 2025 filing's lot 38 is an obsolete pre-combination ID; HDB lot 37 is the successor. The mapped/recorded successor area is 5,000 sq ft, twice the current production value. The recorded map is a direct source for boundary and area; root should adjudicate the audit correction and the applicable reference-date area rule. |
| `post_policy__Q01254595-I1`, 35-53 41 Street: DOB 4006700004, HDB 4006700047; production 15,767 sq ft | The [recorded MIH declaration](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026082500424001) PDF p. 13 Exhibit A describes **block 670 lots 47 and 4 together** as 35-53 41 Street. Its attached HPD application, PDF p. 16, explicitly lists **DOB job Q01254595**, BIN 4835602, 330 total units, and both lots 47 and 4 as the location. DOF records lot 47 as **15,767** and lot 4 as **10,020 sq ft**. | This is a literal recorded job-to-two-lot site crosswalk. The documented 35-53 property is **25,787 sq ft** in summed DOF recorded lot area. The declaration does not separately state a building footprint, but it defines both lots as the premises for this one 330-unit MIH project; root should adjudicate the area correction under the existing parent-ground rule. |
| `post_policy__Q01337462-I1`, 910 Onderdonk: DOB 4034660030, HDB 4034660058; production 13,218 sq ft | The [recorded zoning-lot agreement](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026050800329001) PDF p. 3 defines **lot 30** as Onderdonk Suites LLC's Developer Land and says its proposed building is on that land. Its architect's certificate p. 27 calls **block 3466 lot 30** the Development Site; p. 29 Exhibit D prints **9,309.60 sq ft** for Developer Lot 30. The [companion ZONE](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026050800329002) p. 3 describes separate new lot 58 on Myrtle Avenue. | The 910 Onderdonk building ground is lot 30, not the 13,218-sq-ft sum of lot 30 and residual lot 58. DOF rounds lot 30 to **9,310 sq ft**. Lot 23 contributes transferred rights; residual lot 58 shares the zoning context but is not described as this building's Developer Land. The chart's 44.60 is a development-rights allocation subject to modification under its note 3, not an actual DOB unit count or a reason to change the saved 62 administrative units. |

Two nearby jobs deserve separate membership awareness. `B01325938-I1` at 970
Franklin Avenue has the same named developer as 964 Franklin and files on
block 1192 lot 66. The recorded instrument proposes new boundaries for lots
63 and 66, so the present DOF map cannot by itself separate their final ground;
this review does not adjudicate a shared economic parent. `Q01254580-I1` at 35-42 41 Street
is a separate same-developer Site B filing across the street on **block 669
lot 36**, not block 670 lot 47.

For **27-30 21 Street**, the saved audit's site-wide other-filing inventory
matches only lead job `Q01288509` to the old 37/38 envelope and marks no other
live filing there. Its Housing Database address, 27-28 21 Street, and its DOB
address, 27-30 21 Street, both geocode to successor lot 37. The broader nearby
screen lists only `Q01363971` at 18-44 26 Road (188.7 metres away; different
owner and lot) and `Q01374880` at 22-10 Astoria Boulevard (134.7 metres away;
different owner and lot). Neither competes for old 37/38 ground. A current
block-539 DOB NOW API request returns zero even though the saved lead filing
exists, so that requery cannot expand the no-companion conclusion beyond the
saved audit's dated source set. On the available screen, the full 5,000-square-
foot successor lot has no identified competing filing.

## Remaining recorded-scan questions

The public ACRIS indexes identified the following scans. Another agent exported
the 41 Street declaration, Onderdonk zoning agreement and companion ZONE, and
Franklin ZONE through the ACRIS viewer; unchanged copies were visually inspected
and retained in the acquisition folder. Direct ACRIS page retrieval from this
computer returned the City Register bandwidth notice.

- **41 Street:** [ZONE 2025111900056002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025111900056002), dated November 3, 2025, is indexed against both lots 4 and 47. The later declaration supplies the direct job and premises crosswalk; the earlier ZONE may add a drawing but is no longer necessary to identify both lots as the declared site.
- **Onderdonk:** [deed 2026042200396001](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2026042200396001), dated March 27, 2026, is indexed against lots 30 and 58. The subsequently recorded zoning agreement and companion ZONE identify developer ground as lot 30 and residual lot 58 as a separately described parcel. The deed could clarify the acquisition history but is no longer needed to identify the described Development Site.
- **21 Street:** [development-rights instrument 2025082000373003](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025082000373003), dated August 15, 2025, indexed against both old lots; the tax maps already give a clear successor boundary.
- **Franklin:** the [recorded ZONE 2025120900296002](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentDetail?doc_id=2025120900296002), dated December 8, 2025, establishes a proposed repartition of lots 63 and 66. A final recorded parcel-area statement or a reliable area calculation from the survey is still needed for the 259-unit site and its relation to the 117-unit companion.

Four exact organization-name searches of the official City Planning ZAP
project API returned no package for these sites. This leaves the specific
ACRIS instruments and DOB filing plans as the useful next targets; it is not a
general proof that no City Planning record exists.

## Root adjudication: the 41st Street companion is accepted

The subsequent ACRIS joint-loan record 2026082500424009 supplies primary
confirmation. PDF pages 33–34 name Q01254595-I1 and Q01254580-I1 in the
environmental schedules; pages 1–4 identify both borrowers and all three
parcels. Page 35 records their joint August 2025 financing, before the two
October filings. The developer's Elara portfolio page identifies one 429-unit
project. The root accepts the 330+99 parent with 39,003 square feet, counting
Site A's 25,787 and Site B's archival 13,216 once. This supersedes the open
companion recommendation above. It is recorded in the audit membership table;
production implementation remains pending.
