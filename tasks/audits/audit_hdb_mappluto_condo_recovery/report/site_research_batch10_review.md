# Ten-parent review: 20 September 2026

**Implementation update, September 21:** The production source tables now apply Dupont’s land correction and combine Bedford Square and Starhill with their reviewed ground. The resulting three parents have 381, 877, and 570 units on 20,901, 177,520.79, and 70,063 square feet, respectively. The earlier parcel attributes supply zoning and existing floor area; retained Sears and Starhill buildings are excluded. The account below records the September 20 review before implementation. See [the implementation record](reviewed_parent_implementation.md) for rebuilt counts and checks.

The next ten current historical parents cover six development sites. The supervised review establishes physical ground for **seven current parents**, accepts the four Bedford Square filings as **one 877-unit economic development**, and leaves **three site allocations open**. Original agency records and recorded instruments support these decisions. Administrative housing counts and filing dates remain the measurements in the data.

| Current parent | Address | Units | Adopted ground, sq ft | Decision |
| --- | --- | ---: | ---: | --- |
| `historical__B00604543` | 16 Dupont Street | 381 | 20,901 | Ground supported; passes audit |
| `historical__B00698115` | 2201 Beverly Road | 296 | 43,413.10 | Ground supported; accepted Bedford Square merger pending |
| `historical__B00698117` | 2366 Bedford Avenue | 354 | 73,457.69 | Ground supported; same merger pending |
| `historical__B00698118` | 2363 Bedford Avenue | 132 | 35,247 | Ground supported; same merger pending |
| `historical__B00722009` | 158 Lott Street | 95 | 25,479 | Ground supported; same merger pending |
| `historical__210180819` | 1600 Macombs Road | 244 | 30,879 | Ground supported; accepted Starhill merger pending |
| `historical__210180828` | 1600 Grand Avenue | 326 | 39,184 | Ground supported; same merger pending |
| `historical__321387021` | 1 Eagle / 227 West / 27 Eagle | 745 | Open | Building, waterfront, and shared-access allocation needed |
| `historical__210182069` | 355 Exterior Street | 710 | Open | Broad zoning lot spans separate sites and state parcels |
| `historical__220700873` | 1580 Story Avenue | 562 | Open | Corrected ownership-parcel area does not allocate the building site |

These are reconstructed **observed development grounds**. A later recorded boundary or administrative area does not establish what the developer owned at the initial filing date. An economic-parent link does not establish a legal wage-assessment unit.

## Dupont

The June 2021 recorded development agreement defines conveyed lot-6 ground of **9,011** square feet and adjoining lot 10 at **11,890**, while retaining a separate **2,703-square-foot street strip**. The January 2022 NYC Office of Environmental Remediation fact sheet explicitly identifies 16 Dupont / Greenpoint Landing E1, its applicant, both lots, the proposed residential tower, and an outlined site map. Its rounded **20,900** square feet agrees with the **20,901** legal-description sum; later DOF records report **20,890**. The production area of **12,194** captures only an older lot-6 attribute. The adopted audit correction adds **8,707 square feet (71.4%)**.

See [the original OER notice, PDF pp. 159–160](../../download_parent_review_documents/output/nyc_cb1_2022-02-08_dupont_cleanup_notice.pdf), [recorded agreement, pp. 39, 45–46, 52](../../download_parent_review_documents/code/site_research_batch10_2026-09-20_north_brooklyn/dupont_development_rights_2021070601644010.pdf), and [North Brooklyn review](site_research_batch10_north_brooklyn.md).

## Bedford Square

The four filings arrived within **31 days** and total **877 units: 296 + 354 + 132 + 95**. The DEC remedial investigation describes one four-building residential redevelopment across the two former Sears parcels. The developer identifies all four observed addresses as buildings A–D. Later building-specific owners appear within the same DEC agreement. Together, this supports one economic development rather than four independent parents.

The recorded west-block deed descriptions separate the two new building sites from the retained **53,905.83-square-foot Sears parcel**. The two residential sites total **116,870.79 square feet**. On the east block, DOF's dated subdivision expressly names both DOB jobs and partitions the complete old lot 53 into the two observed building lots. For the combined parent, the adopted earlier-reference convention counts that whole old east lot at **60,650 square feet once**. Combined ground is therefore **177,520.79 square feet**. The later east administrative areas sum to **60,726**, a **76-square-foot measurement-vintage difference**; it does not leave site coverage unresolved. The sum of all four later allocations is **177,596.79** and is retained as a comparison.

See [the DEC investigation, pp. 13–14](../../download_parent_review_documents/output/bedford_beverly_rir_2023-10-26.pdf), [recorded easement/deed descriptions, pp. 3–4, 13–14](../../download_parent_review_documents/output/bedford_beverly_recorded_ee_2024-12-20.pdf), and [Flatbush review](site_research_batch10_flatbush.md). The three accepted link edges and the ground convention are recorded in `code/parent_site_membership_review.csv`. Combining the filings will reduce the parent count by three without changing constituent counts or aggregate housing units; that implementation remains pending.

## Starhill

The original March 2022 zoning declaration describes the combined ground and partitions it into the two phase lots. Its diagram explicitly excludes neighboring lots **129 and 162**. Together with the documented joint **570-unit** two-building development, it supports reconstructed development ground of **30,879 + 39,184 = 70,063 square feet**, measured in the later administrative records. The 19v2 attributes are unreliable here: old lot 134 reports 42,600 despite a roughly 65,608-square-foot polygon, and lot 160 was not separately recorded in that vintage. The documented ground allocation is accepted; it is not labeled a February 2020 survey measurement.

See [the original declaration, pp. 3–9](../../download_parent_review_documents/code/site_research_batch10_2026-09-20_bronx/starhill_zoning_2022031800654005.pdf) and [Bronx review](site_research_batch10_bronx.md). The existing accepted two-filing merger and these land allocations must be applied together.

## Three allocations remain open

**Eagle:** the three filings match the 745-unit Site D, but recorded ownership and the broader zoning lot include waterfront and access land serving other sites. The area fields also disagree across vintages. The specific missing evidence is the Subparcel D allocation instrument or the filed development-site drawing. A broad zoning lot is insufficient.

**Exterior:** the newly inspected zoning declaration describes **seven parcels**, including separate 355 and 399 properties and four state-owned parcels. It names no DOB job in its blank job field. DEC separately documents the 355 and 399 cleanup sites. The approved site plan for job `210182069` is needed to assign the 710-unit proposal's ground; neither the whole zoning lot nor the cleanup boundary settles that question.

**Story:** the January 2019 deed defines the complete northern ownership parcel. Its courses imply approximately **276,733 square feet**, agreeing with the 19v2 area and contradicting the earlier **553,463** attribute. The building-specific allocation remains open because the parcel later split into several lots. The required evidence is the 2019 approved site/zoning plan for job `220700873`, or an equivalent original allocation exhibit.

These are explicit missing assignments, not missing online project descriptions. The case notes identify the original documents already inspected and the remaining records.

## Audit result and reproduction

The boundary source table contains **39 rows**, seven more than before this batch. The membership table contains **11 pairwise decisions**, representing seven accepted development groups and two unresolved pairs. Twenty current parents have pending membership review or implementation. The full audit has **135 unresolved of 873 parents**, down from 136: Dupont clears, while the six current Bedford Square/Starhill parents retain the pending merger flags. There are **738 passing parents**, of which **259** have candidate areas differing from production by more than one square foot.

Run root `make dof-site-review`. The existing linear audit applies the source tables; no project-specific calculation branch was added. Four decisive public documents have concrete download rules in `download_parent_review_documents/code/site_research_batch10.make`; the other evidence snapshots retain exact URLs, extraction dates, and SHA-256 values in the three batch source registers. ACRIS originals were exported manually through the public viewer. All **91 source files** were hash-checked. The parent panel, constituent panel, canonical membership, and calibration weights match their pre-batch SHA-256 values. Land and membership decisions remain in the audit pending coherent implementation.
