# Provisional parent no-notch audit

This audit applies one parent-link rule to every 2024--2026 DOB NOW New
Building job in the existing companion universe, not only to jobs connected to
an observed 99. Two jobs enter the same provisional parent when they are filed
within 365 days and share a filing BBL, a MapPLUTO lot-history group, a DOB
project reference, or the same owner within 100 meters. Connected components
define the provisional parents.

The rule produces 204 strong links and 1,158 provisional parents from 1,309 DOB
jobs. Among the 626 scoreable 2025 HDB filings, 619 match this DOB universe and
seven remain explicit unmatched singletons. The scoreable filings map into 563
provisional parents; 48 contain multiple scoreable filings and 30 contain
additional unscored companion units.

The universal job-to-parent membership and the 204 universal link edges are
saved separately from the 2025-scoreable membership so later timing audits can
use all 1,309 DOB jobs without reconstructing the parent rule downstream.

The companion search extends through 2026, so it can link filings on either
side of 2025. Late-2025 jobs do not yet have a complete 365-day forward window;
the universal groups remain provisional and potentially right-censored.

## Parent no-notch scale

For each frozen model, the audit independently draws each scoreable member's
rounded, six-plus-unit no-notch count and sums those draws within parent. Units
from unscored DOB companions are held fixed at their observed count. The main
run uses 20,000 draws and a fixed seed.

Provisional aggregation moves mixed and repeated-99 projects away from the
99-unit outcome. Under the preferred model, the median observed and predicted
parent totals are:

- 229.5 observed versus 312.5 predicted for parents with one 99 and other jobs;
- 198 observed versus 337.5 predicted for repeated-99 parents; and
- 99 observed versus 38 predicted for currently unlinked 99s.

The mechanical parent-total mass-balance frontier falls sharply. Matching the
parent-level exact-99 excess implies a frontier of 110 units under both frozen
models, compared with about 179 at the filing level. Under the preferred model,
the missing-100-plus moment implies 119 units rather than 254. Thus much of the
absurd filing-level frontier is an aggregation problem.

## Why this is not yet a parent structural model

The legal threshold does not apply to total parent units in the same way it
applies to an eligible site. A parent observed at 198 because it contains two
99-unit sites chose a split configuration; it did not bunch the entire parent
below 100. The parent-level frontier is therefore a diagnostic of scale and
mass accounting, not an estimate of the threshold cost.

The universal singleton sample contains 19 exact 99s. The 99-anchored casebook
contains 19 currently unlinked filings, seven filings with non-99 companions,
and 24 scored filings in repeated-99 parents. Two additional repeated-99 DOB
jobs lack leakage-safe MapPLUTO scores. Three HDB exact-99 records are not DOB
exact-99 initial filings: their DOB initial counts are 98, 97, and 79. These
source disagreements remain explicit rather than being silently reconciled.

Run the task from `code/` with `make`. The Makefile exposes the sample floor,
policy threshold, parent-link distance and time window, simulation draws, and
seed.
