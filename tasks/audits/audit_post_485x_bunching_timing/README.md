# Post-485-x bunching timing audit

This audit describes all initial DOB NOW New Building filings proposing
6--1,000 units from April 20, 2024 through July 8, 2026. It divides the window
into post-adoption 2024, the first and second halves of 2025, and observed 2026.
Counts are annualized using the exact calendar days in each period.

The filing-level figure is the main timing diagnostic. A second figure reports
eventual totals for provisional economic parents using the universal 365-day
link rule from `audit_provisional_parent_no_notch`. Parent cohorts are dated by
their first filing, but their totals include every linked companion observed
through July 8, 2026. They are therefore look-forward audit objects, not legal
485-x sites, and the 2026 cohorts are especially right-censored.

The audit also decomposes why the earlier provisional-parent frontier was near
110--119 units. Of the 53 exact-99 HDB filings in the 2025 score sample, only 19
remain exact-99 provisional parents. The other 34 move above 99 after related
jobs are combined. The decomposition separates repeated-99 parents, one-99
parents with other buildings, source-disagreement cases, and unlinked 99s, and
reports whether the relevant parent contains a 2024 or 2026 companion.
Because the 2024--26 window alone need not be the reason a filing moves, the
audit separately reports which universal link signals appear in the parents
that absorb the exact-99 filings. Signal counts overlap when a parent has more
than one kind of evidence.

## Findings

The filing-level 99 spike appears in every period:

| Filing period | All filings | Filings with 50--150 units | Exact 99 | Exact-99 share |
|---|---:|---:|---:|---:|
| April 20--December 2024 | 200 | 49 | 14 | 28.6% |
| January--June 2025 | 259 | 82 | 17 | 20.7% |
| July--December 2025 | 390 | 133 | 35 | 26.3% |
| January--July 8, 2026 | 379 | 157 | 40 | 25.5% |

The annualized number of exact-99 filings rises from 20.0 in post-adoption 2024
to 34.3 in the first half of 2025, 69.4 in the second half, and 77.2 in observed
2026. This is descriptive timing evidence. It does not establish that 485-x
caused the early post-adoption filings, which could reflect prior planning or
other administrative incentives.

The low provisional frontier is not mainly created by adding companion filings
from 2024 or 2026. Of the 34 exact-99 HDB filings removed from the exact-99 mass
by provisional aggregation, only two belong to parents with an observed member
outside 2025. The composition is:

- 24 exact-99 filings in nine repeated-99 parents;
- nine exact-99 filings in seven parents containing one 99 and other jobs;
- one HDB/DOB unit-disagreement filing in a multi-job parent; and
- 19 unlinked exact-99 filings that remain exact-99 parents.

Most of the removed 99s lie in parents linked by the broad universal evidence
rule: 30 are in parents with a same-owner-within-100-meters link, 25 with a
common MapPLUTO lot-history group, and 19 with a common filing BBL. These counts
overlap. The earlier 110--119 result therefore comes mainly from broad
same-year parent grouping and from holding unscored companion units fixed in
the simulation, not from lengthening the calendar window itself. It remains a
scale diagnostic rather than a legal-site structural frontier.

Run `make` from `code/`. The Makefile exposes the policy date, period breaks,
sample end, plot ranges, bunching point, and local comparison window.
