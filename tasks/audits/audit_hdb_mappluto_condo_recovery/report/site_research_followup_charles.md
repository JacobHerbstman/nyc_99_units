# Charles Place and Broadway filing-role follow-up, September 20, 2026

This follow-up asks whether the earlier new-building jobs should be read as
additional constituent buildings or predecessor designs for the two 99-unit
post-policy filings. It changes no parent membership, dwelling counts, filing
dates, land measures, or production files. The physical ground conclusions in
`site_research_supervised.md` remain: assembled old lots 7+71 at Charles Place
(12,590 archival square feet) and lot 34 at Broadway (9,262 square feet).

## New original drawings and positive evidence

| Site | Page-level finding | Filing-role implication and limit |
| --- | --- | --- |
| Charles Place, old job 321590541 | The architect's six-page [ZD1](https://www.pincusco.com/wp-content/uploads/2025/08/ZD1A-ES945452535-2021_03_12-09_34_48.pdf), physical PDF page 1, names job 321590541, block 3183, tax lot 71, zoning lots 71 and 7, **46 proposed dwelling units**, and a **55-foot** proposed building. Page 2 draws one building at the Charles Place frontage within this corner zoning lot. The PDF was created March 11 and modified March 12, 2021; its printed architect-signature date is March 11, 2021. | This is an original design for the same assembled corner site later described in the 2026 development agreement. It is stronger than an address match. The drawing does not show the new 99-unit design or say whether any part of the five-story design was built, retained, or superseded. The plan-examiner signature field is blank in this copy. |
| Charles Place, new job B01320823-I1 | A signed one-page [AI1 form](https://www.pincusco.com/property-data/ZD1_B01320823_1.pdf), physical PDF page 1, names B01320823-I1, block 3183 lot 71, and says the ZD1 “will be uploaded once initial zoning analysis is reviewed” so it can correspond to revised drawings. The architect signed it November 19, 2025; the PDF was created that day, one day before the new job's recorded filing date. | The mirror's `ZD1_` filename is misleading: this is a dated explanation for the missing initial zoning diagram, not the later diagram or a site plan. It establishes only that the plan was deferred at initial filing. It cannot compare old and new building outlines. The `_2.pdf` URL returns identical bytes. |
| Broadway, new job B01327363-I1 | The architect's one-page [ZD1 zoning calculation sheet](https://www.pincusco.com/property-data/ZD1_B01327363_2.pdf), physical PDF page 1, visibly names DOB NOW project **B01327363-I1**. Its density table assigns **99 proposed dwelling units to lot 34**, lists three units each on three other zoning-lot components, and totals **108 dwelling units** across the larger zoning lot. The visible revision entry says “issued to DOB” on December 3, 2025; the PDF was created December 4, 2025. The footer's July 11 date is a drawing-origin date, not the filing date. | The visible sheet confirms the new proposal's 99-unit allocation to lot 34 but does not draw a building outline, identify how many buildings occupy lot 34, or visibly cross-reference old job 320911233. The extraction text contains `320911233-08` and older revision entries **under later white/overlaid title-block elements**; they are drafting residue, not visible assertions on the final drawing. The referenced Z-003 site plan and a DOB approval stamp are absent. |

The drawing also proposes a 125-foot building on Broadway, whereas the old
BIS main-job row proposes 277 feet. Likewise Charles's old drawing proposes
55 feet while the archived DOB NOW new-job row proposes 115 feet. These
different designs on the same identified building parcels weigh against simply
adding old and new proposed counts, but dimensions alone cannot determine
whether earlier foundation work was retained or whether an agency formally
closed either old job.

The original files are in the acquisition task's
`code/site_research_followup_2026-09-20_charles/`, with URLs and hashes in its
`sources.csv`. PincusCo hosts copies of architect drawings; it is not the DOB
record system. The copies should be checked against DOB's accepted plan set if
that set becomes accessible.

## Official filing records and counterevidence

The newly retrieved official [DOB BIS Job Application Filings API](https://data.cityofnewyork.us/resource/ic3t-wcy2.json)
response contains 14 rows for the two exact legacy jobs. For Charles Place,
job 321590541 document 01 has original pre-filing date **May 5, 2020**, 46
proposed units and five stories. Its later row still says **“PERMIT ISSUED -
ENTIRE JOB/WORK”**, with latest action **June 12, 2026** and owner Yaakov
Lefkowitz/Lefko Capital Group. Its SOE and foundation documents likewise have
permitted rows from July 2025. The saved permit-issuance snapshot in the
September 16 Brooklyn source folder includes an entire-building renewal on
May 6, 2026 and foundation-related renewal on June 12, 2026. These actions
predate the **July 8, 2026** panel cutoff. An active old permit is real
counterevidence to a claim of documented formal cancellation; it does not
prove that the old 46-unit design will be completed alongside the new one.

The September 16 official DOB NOW snapshot (`dob_now_all_round3.json`) records
new Charles filing B01320823-I1 on **November 20, 2025**, with an 11-story,
99-unit mixed-use building. It was approved **June 18, 2026**, before the
cutoff, while its first permit date is **July 9, 2026**, one day after the
cutoff. These are separate event dates. The 2026 agreement already inspected
in the supervised review assigns merged lot 71, formerly 7+71, as developer
land, but does not state the old job's legal disposition.

For Broadway, the fresh BIS document 01 row for job 320911233 shows original
pre-filing **February 21, 2018**, a **26-story**, 277-foot R-1 proposal, 256 in
the BIS proposed-dwelling-unit field, and status **“PERMIT ISSUED - ENTIRE
JOB/WORK”** with latest action **October 24, 2025**. Its foundation document
04 is likewise permitted. The 256 BIS field includes a hotel/residential job
and is not commensurate with the Housing Database's 21 Class A apartment
count. Neither number should be added to the 99-unit parent on this evidence.
The September 16 official DOB NOW snapshot in
`site_research_shared_filings_2026-09-16/dob_now_all_related_filings.json`
records B01327363-I1 filed **December 11, 2025**, describing a 12-story,
99-unit proposal and requesting the same development-hub examiner as
320911233. It remained in **Objections** as of its June 3, 2026 status date.
Its selective-demolition filing S9 was made **July 1, 2026**, but approval and
permit issuance were **July 14 and August 13**, after the cutoff. S9 says
existing slab and non-bearing concrete columns/walls would be partially
demolished for the new filing. That supports physical redesign of earlier
work, but does not identify exactly what was built under 320911233.

## Access and unresolved records

The fresh official DOB NOW API exact-family response, saved as
`dob_now_jobs.json`, was empty. Its separate `dob_now_b013_count.json` response
reported **zero B013-prefixed records in the entire current API**, despite
the preserved September 16 snapshots and the individual filing history.
Accordingly this is an API coverage anomaly, not a job-specific negative
finding. The public BIS job-detail request returned HTTP 403 on September 20;
the earlier public DOB NOW portal attempt preserved in the Brooklyn source
folder returned an access-denied page. Neither endpoint yielded the accepted
new plan set or an agency-issued cross-reference. No restriction was bypassed.

The evidence supports **predecessor-design treatment as the leading physical
interpretation** at both sites, especially given the old/new zoning drawings,
the official Broadway new-job description requesting the older examiner, and
the subsequent demolition filing. It does **not** supply
an official withdrawal, revocation, or statement that the later job formally
supersedes the older permit. Charles still needs the accepted B01320823 site
plan and any DOB cross-reference to 321590541. Broadway needs the accepted
B01327363 Z-003/site plan and DOB disposition of 320911233; the latter could
also specify how much of the old foundation was retained. The filing-role
flags should therefore remain for the supervising researcher to adjudicate.
