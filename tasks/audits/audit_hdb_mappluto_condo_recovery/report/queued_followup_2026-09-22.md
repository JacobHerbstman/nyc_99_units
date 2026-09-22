# Queued cases: evidence, implementation, and remaining work

The five cases were not five decisions awaiting the researcher. Wallabout
needed a calculation using saved evidence. Livingston needed a source-vintage
check and has now exposed a consequential historical-outcome problem. The
other three still need documentary interpretation; no request for an
unsupported numerical choice is warranted.

## Livingston: historical dates were paired with later outcomes

The main historical route reads HDB **25Q4**, assigns cohorts by initial filing
date, and retains that release's Class A proposed units and lot identifiers.
It does not freeze either field before 485-x. The membership field
`source_end_date` is the latest initial filing date in the linkage universe,
not the date of the Housing Database release.

DCP's official **23Q4** archive supplies the following comparison:

| DOB job | Address | Initial filing | 23Q4 units | 25Q4 units | 23Q4 lot | 25Q4 lot |
| --- | --- | --- | ---: | ---: | --- | --- |
| B00781447 | 370 Livingston | 2022-09-28 | 144 | 99 | 16 | 22 |
| B00814498 | 372 Livingston | 2023-01-26 | 105 | 99 | 16 | 16 |
| B01127732 | 362 Livingston | 2024-11-04 | Not yet filed | 99 | — | 16 |

These are the city's ClassAProp fields, not counts substituted from news
coverage. The 23Q4 descriptions explicitly name the adjoining building under
a separate application in both directions. The first two filings are 120 days
apart and share the same contemporaneous lot. They support one historical
two-building proposal totaling 249 in that release. Current historical
candidate construction instead sees lots 22 and 16; its earlier-lot recovery
is flagged as using a later transaction. It does not parse street-number
references as job-number references, so the pair remains unlinked.

The recorded declaration 2026010400010003, p16, reproduces an April 28, 2025
HPD application for B00781447 with 99 units and 485-x Option B. This establishes
the later design's intended program, not the exact amendment date or causation.
The newly saved January 2025 zoning instrument 2025021001245002, p2, explicitly
draws 362/370/372 on tentative lots 16/22/26 as one zoning lot under 372
Livingston LLC. P4 describes the outer ground of earlier lots 16/26. It does
not allocate earlier building floor or prove the 2022 proposal's boundary.

**Consequence:** current 99 cannot be presented as an observed pre-policy
choice. This is a failure to align outcome vintage with the comparison, not
a dispute between two sources describing the same date. The unit-source
correction should be implemented consistently with historical membership and
coverage, rather than manually replacing this one number. This follow-up
documents that correction's scope; production units and links are still
unchanged. The historical counterfactual requires this correction before
further estimation.

## Extent of the vintage issue

`compare_hdb_unit_vintages.R` compares the current canonical historical
constituents with both the active and inactive-inclusive 23Q4 files by unique
DOB job. It holds current selection and membership fixed; this is a diagnostic,
not a reconstructed historical sample or a policy-effect estimate.

| Universe | Current filings | Matched in 23Q4, including inactive | Changed counts | Parents containing a changed count |
| --- | ---: | ---: | ---: | ---: |
| Canonical historical panel | 1,904 | 1,902 | 225 | 218 |
| Current historical weighting sample | 592 | 591 | 109 | 106 |

The active-file-only comparison matches 1,878 and finds 220 changed filings.
The additional file accounts for five further changes and 24 additional
matches. All six current historical exact-99 constituents match the active
23Q4 release. Four were different sizes:

| Address | 23Q4 | Current panel |
| --- | ---: | ---: |
| 370 Livingston Street | 144 | 99 |
| 130 Lafayette Street | 104 | 99 |
| 19 East 198 Street | 64 | 99 |
| 1405 Vyse Avenue | 54 | 99 |

The other two were 99 in both releases. A difference can reflect a design
amendment, corrected administrative reporting, or both. The snapshot comparison
alone does not date each change or identify a policy response. A pre-policy
reconstruction also needs consistent treatment of inactive records and the
two unmatched current filings; filling them from a later release silently
would restore the same problem. The weighting sample currently includes one
of those unmatched filings: 114 Snediker Avenue, B00755555, currently 200 units.
The other is 11-17 Bay Park Place, Q00478133, currently 22. Both have current
DOB records agreeing with HDB, but those later records do not establish what
was observed before the policy.

Sources: [DCP archive](https://s-media.nyc.gov/agencies/dcp/assets/files/zip/data-tools/bytes/housing-database/nychousingdb_23q4_csv.zip),
[Livingston declaration](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2026010400010003),
[Livingston zoning description](https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2025021001245002).

## Wallabout: allocation completed and applied

The 2023 appraisal, pp289/320, and 2021 DOF map distinguish the three cohort
buildings from earlier 251 Wallabout. Their recorded ground totals 39,323.
Overlaying their 25v4 footprints on the common prefiling 18v2_1 map gives:

| Earlier lot | Allocated ground | Earlier residential FAR | Earlier recorded floor |
| --- | ---: | ---: | ---: |
| 37 | 2,507.69 | 4.0 | 0 |
| 41 | 18,342.52 | 4.2 | 0 |
| 122 | 18,472.79 | 6.0 | 0 |

Each successor's recorded area is allocated in proportion to its mapped
overlap with the earlier parcels. The ground total is administrative; its
division across zoning parcels is a GIS approximation. Earlier lot 23 is
outside the target footprint. Earlier and later lot 37 have different
boundaries: the later 32,000-square-foot lot belongs to separate 251 Wallabout.
The old-lot-37 allocation exceeds its recorded 2,500 by about eight square
feet because successor recorded areas and map areas differ slightly.

The production manual table applies these three rows through the existing
parcel builder. Land changes from 68,805 to **39,323**, residential FAR from
about 4.70 to **5.03**, and earlier floor remains zero. The common archive also
records vacant prior use. No estimated-floor flag is introduced. Only this
parent's covariates change; constituent data are identical to the prior build.

## The other outstanding cases

- **Broadway:** the saved new S9 explicitly concerns selective demolition of
  the existing frame associated with the new proposal. Formal withdrawal of
  the older hotel application is not necessary merely to establish the ground.
  The unresolved covariate is how much of the 112,041 square feet in the 2023
  assessment was actually standing in the unfinished structure. The new
  approved site/floor plans and dated construction evidence remain to be
  established. There is no supported numerical estimate to approve yet.
- **Rockaway III/IV:** the newly obtained 70-page recorded condominium plans
  are document 2022051300461002 / CRFN 2022000210978. Physical p5 identifies
  Building D at 1626 Village Lane; pp57–58 identify units 18/19/20, their
  cellar/first-floor plans, and residential limited common elements. These
  establish physical unit locations rather than the deed's ownership shares.
  First-floor area (40,288) and cellar area (52,604) are building areas, not
  the development's land total. The full outdoor/common-ground allocation and
  Phase IV boundary remain unfinished research.
- **310/322 Grand Concourse:** the July 2020 investigation pp6–7 fixes the
  combined ground at 29,609.6 and identifies the two buildings. P67 maps the
  earlier lot-10 boundary through the broader site; p63 and p67 show an older
  building extending across the depicted development boundary. This does not
  justify assigning all or none of old lot10's 9,200 recorded floor without
  reconciling the dated plan. The earlier-floor allocation remains unfinished.
- **Charles (separate from the five):** 12,590 ground and 1,100 floor are
  already applied. The old 46-unit and new 99-unit designs use the same land.
  The remaining filing-history question concerns whether the newer job
  continues or replaces the earlier proposal and what date represents that
  decision. Active old permits alone cannot settle this; the new approved
  plan connection remains unverified.

These are remaining evidence/implementation tasks. An estimated allocation
would become a researcher decision only after the measured alternatives and
its explicit assumptions were presented.

## Reproduction

Root `make dof-site-review` prepares the checksum-pinned 23Q4 archive and runs
the two short scripts through `queued_followup.make`. SaveData produces five
audit datasets and their reports. The production owner for Wallabout is
`tasks/parent_opportunities_manual/output/site_lot_decisions.csv`; production
does not read an audit output. Root `make` refreshes the main panels and plots.

The refreshed scope screen has 111 unresolved and 753 supported parents; only
Wallabout changes pass/flag status. The canonical panels remain 1,811 historical
and 907 post-policy parents. The weighting samples remain 554 and 310.
Wallabout's correction alone changes the weighted historical exact-99 share
from 1.3537427% to 1.3536772% and mean parent units from 151.3559 to 151.3804.
These retain the current unit-vintage rule and are not corrected historical
estimates. Calibration's maximum moment error is 6.47e-10; the existing
bootstrap has 493 successful draws and six calibration failures out of 499.
