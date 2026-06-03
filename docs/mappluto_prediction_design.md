# MapPLUTO Prediction Design

## Decision

Use MapPLUTO/PLUTO as the core feature and risk-set source. Use DCP Housing Database records as labels, timing, and validation data.

Do not use a single 2010 MapPLUTO vintage as the main prediction specification. A 2010-only vintage is leakage-safe but too stale for projects filed many years later: it misses rezonings, lot mergers/splits, demolitions, changes in built FAR, changing neighborhood conditions, and lots that did not exist under the same BBL in 2010.

## Training Vintage Rule

For each pre-policy DCP HDB New Building project, link the project to the latest MapPLUTO/PLUTO release whose source vintage is safely before the HDB `date_filed`. If the exact source cutoff is ambiguous, lag the vintage rather than risk using fields updated after the project entered DOB processing.

The mature `nyc_court_case` MapPLUTO archive pipeline currently gives clean official DCP archived MapPLUTO releases beginning in 2018. That means the first leakage-safe version of the main model should train on HDB labels whose filing dates can be matched to a strictly pre-filing MapPLUTO vintage, likely 2018-2023 labels for now. Do not attach 2010-2017 HDB labels to later MapPLUTO releases in the main training sample.

A single early vintage, such as 2010 PLUTO if we can source it, can be useful as a sensitivity or for a narrower historical risk-set exercise. It should not be the main specification for predicting all later projects because it freezes parcels long before many relevant rezonings, lot changes, demolitions, and redevelopment opportunities occur.

The training label is from HDB:

- `classa_prop`
- `I(classa_prop >= 100)`

The predictors are strictly pre-filing MapPLUTO/PLUTO fields. Do not use HDB proposed floors, net units, certificate-of-occupancy units, permit dates, completion dates, job status, or any PLUTO fields from after filing.

## Exposure Universe

For the land-value test, define exposure using one frozen pre-adoption lot universe, not post-policy HDB filings. The first target universe should be the last clean MapPLUTO/PLUTO release before April 20, 2024, after confirming the release/source cutoff is pre-policy.

Score all plausibly developable lots in that frozen universe and define exposure as predicted units or `Pr(classa_prop >= 100)`. Do not update exposure with post-policy MapPLUTO, post-policy HDB filings, permits, completions, units, lot mergers/splits, or changed parcel characteristics.

## Vacant Lots

Vacant and underbuilt lots are central to the estimand. They should be included in the application universe when otherwise plausibly developable. Existing building variables should use their literal pre-policy values, with missingness indicators where needed.

Do not drop vacant lots simply because `yearbuilt`, `numfloors`, or current residential units are missing or zero.

## Conservative First Pass

1. Build a pre-policy HDB label file: New Building, valid `date_filed`, valid BBL, positive integer `classa_prop`, filed before April 20, 2024.
2. Build an as-of MapPLUTO link table: each HDB label gets a documented pre-filing MapPLUTO vintage.
3. Build strictly pre-filing lot features: lot area, zoning, residential/allowed FAR, existing built area, existing residential area, built FAR, residual capacity, existing units, number of buildings, floors, year built, land use, building class, lot type, landmark/special district flags, geography, and baseline assessment fields where valid.
4. Train transparent first-pass models on pre-policy projects. Start with linear/logistic or penalized logistic models; use tree/boosting models only as forecasting benchmarks.
5. Validate temporally within the as-of sample, for example train on earlier matched years and predict later pre-policy years. Once older PLUTO vintages are sourced, we can extend the validation window backward.
6. Define post-policy exposure once on the frozen pre-adoption lot universe.
7. Keep manipulation audits separate: after exposure is fixed, use post-policy HDB filings to ask whether high-exposure lots bunch at 99 or split across adjacent/same-owner projects.
