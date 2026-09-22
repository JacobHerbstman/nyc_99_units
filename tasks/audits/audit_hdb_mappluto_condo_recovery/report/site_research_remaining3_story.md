# 1580 Story Avenue: remaining-site source follow-up

**Parent:** `historical__220700873`, DOB job `220700873`, frozen filing date **2019-06-05**, frozen administrative count **562 units**.

## Adjudicated result

The source record now supports **203,910 square feet** as reconstructed physical ground for 1580 Story Avenue: later block 3627 lots **1** (151,992 square feet) and **10** (51,918 square feet), counted once. This replaces the erroneous frozen 18v2beta lot-1 area of 553,463 square feet and is narrower than the complete 276,732-square-foot pre-split ownership parcel. The 203,910-square-foot allocation is reconstructed from post-filing instruments; it does not backdate successor-lot ownership to June 2019.

Root adjudicated the physical-ground flag clear at **203,910 square feet**. Preserve the frozen reference parcel's **zero pre-existing building area**, **R6**, **residential FAR 2.43**, and parking-facility use. The later successor parcels independently report the same zero building area, R6 district, residential FAR, and use.

## Direct parcel and address evidence

The earlier [January 2019 deed](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2019012100162007), preserved and hashed in the batch-10 Bronx acquisition folder, conveyed the entire then-lot 1. Its legal courses on physical pp. **5–6** enclose approximately **276,732.6 square feet**, matching 19v2's recorded 276,732 square feet. That deed establishes the pre-filing ownership parcel, but not the eventual building-specific allocation.

The [September 2019 zoning-lot declaration](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2019092700468002) is dated **2019-09-24** and recorded **2019-09-27**. Physical p. **3** treats lots 1, 35, 20, 30, 40, and 50 as one zoning lot; physical pp. **5–12** describe tentative successor lots 1, 10, 25, 35, and 45, and physical p. **13** diagrams the subdivision. Its DOB N.B./ALT field is blank. It establishes the subdivision vintage but its broad zoning envelope is not building ground.

The [April 2020 transfer deed](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2020042000191001), dated **2020-04-07** and recorded **2020-04-23**, says on physical p. **2** that Boynton Properties conveys part of the land it obtained from Soundview. Physical pp. **5–6** give the legal descriptions for lots **45** and **25**, transferring those side parcels to Lafayette-Morrison HDFC.

The simultaneously recorded [second amendment to the easement and right-of-first-refusal agreement](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2020042000191003) is explicit on physical p. **3**: Boynton and Soundview retain new lots **1, 10, 35, and 36** as the “New Flatlands Parcel” and release lots **25, 28, 42, and 45** to the HDFC. Physical pp. **23–30** preserve the retained-land description and exceptions. The agreement also limits the aggregate obligation to 607 parking spaces on the four-lot New Flatlands Parcel. It does not allocate spaces to job `220700873` or among those four lots.

The [October 2020 zoning-lot declaration](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2020102600056002), dated **2020-10-13** and recorded **2020-11-16**, supplies the decisive allocation within that retained property. Physical p. **9** assigns **1580 Story Avenue to lots 1 and 10**. The same page assigns lots 35 and 36 to a separate, unnamed Boynton Avenue address, while physical p. **11** assigns lots 1 and 10 to Boynton Properties LLC and lots 35 and 36 to the separately named Boynton Properties 2 LLC. The diagram on physical p. **10** shows those parcels separately. Thus the agreement's shared parking rights do not add lots 35 and 36 to 1580 Story's physical ground.

The printed legal courses in the 2020 declaration corroborate the administrative areas. Physical p. **3** gives a six-course description for lot 1; reconstructing it closes within **0.01 foot** and yields **151,991.72 square feet**. Physical pp. **3–4** give an eight-course description for lot 10; it closes within **0.01 foot** and yields **51,920.39 square feet**. Their course-derived sum is **203,912.11 square feet**, only **2.11 square feet** above the 21v1 administrative sum of **203,910**. The minor difference is consistent with bearings and distances printed to seconds and hundredths of a foot. The adjudicated value uses the administrative successor-lot sum.

## Earlier characteristics and temporal caveat

The staged MapPLUTO releases provide a stable pre-existing condition despite the bad 18v2beta area field:

| release and lot | lot area | building area | built FAR | residential FAR | zoning | land use |
|---|---:|---:|---:|---:|---|---|
| 18v2beta, old lot 1 | 553,463 | 0 | 0 | 2.43 | R6 | 10 |
| 19v2, old lot 1 | 276,732 | 0 | 0 | 2.43 | R6 | 10 |
| 21v1, lot 1 | 151,992 | 0 | 0 | 2.43 | R6 | 10 |
| 21v1, lot 10 | 51,918 | 0 | 0 | 2.43 | R6 | 10 |

The official DOB BIS Jobs API snapshot retrieved **2026-09-21** still identifies job `220700873` at **1580 Story Avenue**, with pre-filing date **2019-06-05**. Its current document-01 record has since been amended to 1,124 proposed units and was approved in 2025. That live record does not revise the frozen initial 562-unit count used by this audit; it only shows that the same legacy job continued after filing.

The shared parking agreement is a property-rights envelope, not proof that all four retained lots were physical ground for this building. The only interpretive step in the adopted 203,910-square-foot allocation is to follow the recorded declaration's exact 1580 Story address assignment rather than expand ground to every parcel that could participate in shared parking obligations. Nothing in the reviewed instruments certifies a legal wage-assessment unit or establishes that the successor lots existed as separate owned parcels on the June 2019 filing date.

## Acquisition record

Original ACRIS exports and the raw DOB API response are preserved in `tasks/audits/download_parent_review_documents/code/site_research_remaining3_2026-09-21_story/`. `sources.csv` records literal public URLs, document dates, retrieval date, byte counts, page counts, and SHA-256 hashes. OCR and page renders used for review remained in system temporary storage and were not added to the source folder.
