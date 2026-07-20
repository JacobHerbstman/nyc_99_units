# Production exact-99 parent reconciliation

This audit reconciles every exact-99 parent in the preferred production
estimate. The production sample is now the completed 2025 first-filing cohort,
using the symmetric 365-day parent rule. It contains 10 exact-99 parent totals,
not the 27 exact-99 observations from the superseded calendar-year model.

The earlier 27-observation investigation remains preserved in the developer
opportunity casebook. It is still useful evidence about filings and possible
project links, but it is not the current estimation sample: some observations
belong to 2024 parents, some are in right-censored late-2025 cohorts, and some
are absorbed into larger multi-filing parent totals.

The reconciliation reports, for each current exact-99 parent:

- every constituent DOB filing and root job;
- the conservative production classification and every accepted link reason;
- the earlier broad-parent classification, accepted broad links, and
  review-only proposed links with their exact reasons;
- filing, approval, first-permit, and status information;
- HDB and DOB unit agreement;
- gross construction area, stories, site features, and square feet per unit;
- the fitted no-notch probabilities and conditional size quantiles; and
- any existing external evidence plus the legal record still needed.

The model probabilities condition on observed site characteristics. They are
not posterior probabilities that an individual parent was caused by 485-x.
Permit issuance is an administrative timing proxy, not statutory commencement.
Legal 485-x site and rental eligibility remain unvalidated without HPD and
project records. No companion or unit count is imputed.

All 10 current exact-99 parents are single-filing parents under the production
rule, and HDB and DOB agree on their parent totals. The earlier broad rule
absorbs two: `B01178945` joins a repeated-99 parent and `X01201390` joins a
parent with another filing. Two otherwise unlinked parents have review-only
candidate links. None has legally validated 485-x site status in the records
currently available.

Run `make` from `code/`.
