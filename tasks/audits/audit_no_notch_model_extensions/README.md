# No-Notch Model-Extension Audit

This audit asks whether the largest held-out unit-count errors share observable
characteristics that can improve or diagnose the simple no-notch model. It keeps
the original forward validation windows and compares eight deliberately modest
lognormal models:

- the existing simple baseline;
- broad zoning capacity;
- broad project ownership type;
- lot frontage and depth;
- prior site use interacted with broad capacity;
- a three-degree-of-freedom lot-area spline challenger;
- HDB-to-PLUTO address alignment; and
- address-by-capacity interactions.

`broad_zoning_capacity` uses the largest reported residential, commercial,
community-facility, or historical `MaxAllwFAR` value. It is not labeled
residential capacity. `MaxAllwFAR` is retained separately because pre-2013 PLUTO
used that combined field before the modern FAR fields became available.
Ownership is the broad DCP Housing Database classification, not developer
identity or a developer fixed effect.

Address alignment is observed at filing, but the filing address can itself
reflect the chosen building or split configuration. The two address models are
therefore diagnostic-only rather than preferred structural specifications.

The same models are estimated for six outcome/crosswalk designs:

- one HDB new-building filing using the current retrospective crosswalk;
- the same filing sample without APPBBL recoveries dated after filing;
- private for-profit filings under the current crosswalk;
- an all-period singleton feature-lot diagnostic; and
- provisional feature-BBL-by-filing-year site totals with each linkage rule.

The singleton definition uses future filings to diagnose measurement error and
is not a deployable sample rule. The site-year definition is also provisional:
it can combine distinct projects on one lot and is not a substitute for the
legal-site and parent-opportunity crosswalk.

Site totals are formed from every positive integer component filing and only
then subjected to the six-unit sample floor. The audit records whether a site
uses multiple lagged PLUTO vintages or lot-area values; its features come from
the earliest component filing in the estimation or test interval.

Repeated BINs within a site-year are flagged and excluded from site-year model
comparisons because a later filing can supersede an earlier one. They are not
silently deduplicated: HDB can retain two permitted records even when later DOB
evidence says one was withdrawn. This is another reason site-year aggregation
remains diagnostic until the root-job crosswalk is complete.

DOB proposed construction area, stories, applicant identity, and other
simultaneously chosen project outcomes are intentionally excluded. Run from
`code/` with `make`.

## Main audit result

No added structural covariate earns promotion to the local baseline. The
lot-area spline lowers all-filing mean RMSE by 5.9 percent but lowers the
50--150-unit mean by only 1.4 percent and loses to the baseline in five of ten
validation windows, especially recent ones. Broad capacity improves all-filing
RMSE in all ten windows but changes local mean RMSE by only 0.02 percent.
Ownership, lot geometry, and site-use interactions do not improve the local
model enough to justify the extra terms.

The strongest signal is instead the observation/crosswalk unit. Relative to an
individual-filing mean RMSE of 0.839, the singleton diagnostic is 0.729 and the
current-crosswalk provisional site-year outcome is 0.752. Address agreement is
also informative: reference-window RMSE is 0.713 for exact matches, 0.799 for
the same street but another address, and 0.917 for a different street. Because
address and site groupings can be affected by the developer's chosen filing
configuration, these results motivate crosswalk work rather than additional
structural conditioning variables.

`no_notch_reference_model_summary.txt` records the exact reference-window
formula, preprocessing constants and factor levels, followed by the verbatim R
output from `print(summary(model))`. The matching coefficient table and a
compact held-out residual decomposition are
`no_notch_reference_model_coefficients.csv` and
`no_notch_reference_residual_summary.csv`.

The preferred reference fit is an OLS regression on 2013--2020 filings:

```r
log_units ~ log_lotarea + residfar + builtfar +
  residfar_missing + filing_year_centered + borough + zone_detail +
  prior_site_use
```

The outcome is the log of integer proposed Class A units. The estimation sample
requires at least six units, positive lagged-PLUTO lot area, and the primary
leakage-safe HDB-to-PLUTO match. Missing `ResidFAR` is set to its training-sample
median and separately flagged. Categories with fewer than 30 training rows are
pooled into `other_rare`. The reference holdout is January 2021 through June 15,
2022. Distributional predictions use a rounded lognormal conditional on at
least six units, with the static i.i.d. normal shock scale estimated as
`sqrt(mean(residual^2))` in the training sample.
