# Production exact-99 parent reconciliation

This audit reconciles every exact-99 parent used by the preferred 2025
enhanced-parent model. Its main output has one row per production parent and
does not alter the production parent definition or re-estimate the no-notch
model.

The table combines five distinct objects without treating them as
interchangeable:

1. the conservative production parent used by the model;
2. the broader 2024--2026 universal parent sensitivity;
3. the symmetric 365-day cohort audit and its observability flags;
4. the DOB exact-99 casebook and candidate-pair evidence; and
5. the production model's conditional no-notch distribution.

Broad parent links are reported edge by edge with the filing-day difference,
distance, and every rule that creates the link. Review-only candidate pairs are
retained separately and never change the broad parent assignment. All
constituent filing, approval, permit, status, unit, floor-area, and story fields
come from the existing DOB crosswalk.

The model columns report the no-notch distribution conditional on observed
site characteristics. They are not posterior probabilities that a particular
observed 99-unit parent was caused by 485-x. The quantiles and probability bins
use the production model's rounded lognormal distribution conditional on at
least six units.

Legal 485-x site status and rental eligibility remain unvalidated unless an
external record establishes them. Permit issuance is reported as an
administrative timing proxy, not as statutory commencement.

## Findings

All 27 production exact-99 parents are single-filing parents in the current
model. The DOB root-job crosswalk and model score match all 27. Twenty-six also
match the DOB exact-99 casebook. The exception is `Q01338971`: HDB reports 99
units while the DOB initial filing reports 79, so it correctly remains outside
the DOB exact-99 casebook.

The broader 2024--2026 rule absorbs eight production observations into six
multi-filing candidate parents and leaves 19 singletons. The symmetric,
leakage-safe 365-day construction supports multi-filing links for five of those
eight observations, representing four distinct parents. Three observations
are linked only by the broader sensitivity:

- `B01178945`, the third 99-unit Bergen Street filing;
- `X01201390`, the 99-unit Godwin Terrace filing; and
- `X01223350`, the 99-unit Third Avenue filing.

The 19 remaining observations are singletons under both audit definitions.
Four have review-only nearby candidate pairs, including the high-priority
different-owner cases at 2258 Morris Avenue and 35-42 41 Street. These remain
unlinked.

Only 13 observations belong to fully observed symmetric 2025 cohorts. One
belongs to a parent first filed in 2024, and 13 belong to right-censored 2025
cohorts. The anchor-specific forward-window check likewise has 13 complete and
14 incomplete observations. No companion is imputed.

Nineteen anchor jobs have an approval date and 15 have a first-permit date.
Gross construction floor area and proposed stories are observed for all 27.
Gross square feet per HDB unit range from 464 to 1,644, with a median of 819.
This ratio includes common, commercial, and community-facility space and is not
net apartment size.

The no-notch model is highly heterogeneous across these cases. Six have a
conditional probability above one-half of at least 100 units without the
notch, while 12 have a probability below one-tenth. The 210-27 26 Avenue case
is an important outlier: its conditional median is 494 units and its 90th
percentile is 1,481, reflecting the very large site characteristics used by the
model. Its symmetric parent began with a 46-unit 2024 filing and totals 145
observed units, so it should not remain an exact-99 singleton in the symmetric
re-estimation.

No observation has a validated legal 485-x site or rental-eligibility status.

## Production integration issue

The reconciliation identifies one concrete reason the preferred production
panel understates parent aggregation. The production link construction carries
the DOB filing BBL but tests same-filing-BBL links using the HDB BBL. For
`B01186301`, HDB reports BBL `3003880020` while DOB reports filing BBL
`3003880019`. The symmetric audit therefore links `B01172199`, `B01186301`,
and the 70-unit `B01186327` on direct DOB filing-BBL evidence, while the
production panel leaves all three separate. All three are present in the
production universe and map to the same lagged MapPLUTO feature lot.

The other direct-evidence disagreements arise because a companion is outside
the calendar-year HDB production panel: one companion was filed in 2024, two
East 178 Street companions are absent from that panel, and two Myrtle Avenue
companions were filed in 2026. These are cohort and source-coverage issues, not
missing values that should be imputed. The three broad-only cases remain
sensitivities rather than production corrections.

Run `make` from `code/`. The Makefile exposes only the policy threshold because
all other paths and definitions are fixed features of this reconciliation.
