# Historical withdrawn-job source review, September 22, 2026

**Final adopted cohort rule.** The first screen below was exploratory, not the
final unresolved count. The rebuilt historical cohort now marks **34 archived
withdrawn predecessors** (734 source Class A units) as alternatives to **30
successor applications** among 2019–2022 filings. The automatic rule requires
the same existing historical parent component, valid archived BIN, BBL, exact
address, a single nonwithdrawn survivor, later survivor filing date, and an
entire filing span of at most 365 days. Several withdrawn versions may point
to that one survivor. The survivor need not appear in the active-only CSV:
inactive-inclusive source proposals are retained under Jacob's all-proposals
choice. The observed predecessor and successor filing dates are preserved;
neither `DateLstUpd` nor later DOB status data are used to invent a withdrawal
date. The role is an **archived alternative**, not a dated claim that withdrawal
preceded the successor application.

The separate reviewed West 48th Street decision marks
`M00536051` → `M00580473` as one more withdrawn predecessor (158 source units)
despite its changed BIN and address; the [case evidence](historical_collision_roles_2026-09-22.md)
supports one proposed housing building. `B00775071` at 773 Neptune Avenue is
a separately reviewed **nonresidential** filing: its conflicting 189-unit HDB
field remains visible in source data but is nonadditive to residential outcomes.
Neither exception expands the automatic same-building rule.

The four address-mismatch pairs from the exploratory screen remain outside
that rule. Both records in each pair are currently additive source proposals
within one parent; each parent has one archived duplicate-BIN flag and remains
composition-ineligible pending building-level review. The archived predecessors
are all `9. Withdrawn`. The later source statuses are three `5. Completed
Construction` and one `1. Filed Application`:

| Withdrawn → later job | Archived units | Later 23Q4 status | Current parent |
|---|---:|---|---|
| `420667282` → `421133320` | 58 → 60 | Completed Construction | `historical__420667282` (118 additive units) |
| `440667020` → `Q00555969` | 121 → 78 | Filed Application | `historical__440667020` (199 additive units) |
| `X00618402` → `X00710727` | 26 → 26 | Completed Construction | `historical__X00618402` (52 additive units) |
| `X00639521` → `X00694049` | 50 → 90 | Completed Construction | `historical__X00639521` (140 additive units) |

These four are **not** the old “15 remaining” count. Of those 15 exploratory
pairs, the adopted parent-aware rule incorporates the seven shared-successor
pairs and four inactive-successor pairs. Further review of the four changed-
address pairs could change their roles, but the present code does not silently
collapse them.

The DCP 23Q4 inactive-inclusive archive has 2432 new-building jobs filed in 2019–2022 with at least six proposed Class A units and valid seven-digit BINs; 119 are marked `9. Withdrawn`. The source-only screen finds 38 withdrawn-job pairs with a later nonwithdrawn job on the same BIN, filed within 365 days. The CSV preserves both jobs' BBLs, addresses, proposed units, descriptions, statuses, and last-update dates.

- Unique active successor, same BIN, same BBL, exact address: **23 pairs**.
- Shared successor (more than one withdrawn predecessor): **7 pairs**.
- Changed address or lot: **4 pairs**.
- Successor itself absent from the active file: **4 pairs**.

At the exploratory stage, the strict group suggested one building's alternative applications as observed by 23Q4: DCP defines BIN as the building identifier, and the same archived parcel and address plus a unique active successor corroborated it. The other 15 screened pairs were initially held for review, especially the three shared-successor clusters. The final parent-aware rule and its resolved count are stated above. The archived `Job_Status` establishes that an earlier application was withdrawn by this vintage; it does not establish when withdrawal occurred or that it preceded the later filing. `DateLstUpd` is the last DOB-record update, not the withdrawal date.

The CSV is a candidate screen, not a rebuilt parent sample. Other withdrawn
jobs may lack a same-BIN successor, and this screen alone does not establish
an economic parent link. Same-BIN matches can contain source errors, so the
adopted rule additionally requires membership in one existing parent and
the exact archived parcel and address. The archive's `Ownership` field is an
ownership category, not an owner identity; prefiling PLUTO owner
corroboration is outside the source-only screen. The active-only archive was
used to label successor status in this exploratory CSV, not to remove
withdrawn or inactive-survivor proposals from the adopted source universe.

Sources: [DCP 23Q4 archive](https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/housing-database/nychousingdb_23q4_csv.zip), SHA-256 `ba204b240053f2477241d46eb9f4f4b11a15907484009e21264914c8cff1d45e`; embedded `Housing_Database_Data_Dictionary.xlsx`, sheets `Dataset Information` and `Column Information` (BIN, ClassAProp, Job_Status, DateFiled, DateLstUpd, inactive-file definitions). The exploratory CSV uses only this saved archive. CSV rows: 38; key: `(withdrawn_job, later_job)`; CSV MD5: `5418c9ef8fb6c183c32cb30b4af46cb0`. Final-role counts above use the rebuilt `symmetric_parent_membership.parquet` and reviewed `historical_filing_roles.csv`.

The [source-screen CSV](../output/historical_refiling_source_review_2026-09-22.csv) is generated by `review_historical_refilings.R` and saved with its standard data report. This narrative records the subsequent adjudication and is maintained separately.
