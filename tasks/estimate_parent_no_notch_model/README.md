# Estimate the parent no-notch model

This task fits the preferred production model once. The outcome is the total
proposed units in a symmetric parent cohort. The conditional location of log
units is linear in log lot area, residential FAR, built FAR, filing year, borough,
zoning group, and prior site use. Observed units are rounded and the likelihood
is truncated at six units. The model assumes one normally distributed i.i.d.
scale shock per parent.

The model is estimated on fully observed 2019--2022 cohorts. The main
specification scores 2025 cohorts after 180 days of observed follow-up and
requires a complete 365-day pre-filing linkage window. Parent construction
continues to add observed companions through day 365; no companion is imputed.
The completed-365-day cohort is retained as a conservative sensitivity. HDB
Class A units are primary, with DOB initial-filing units retained as a second
sensitivity.

Outputs contain the fitted coefficients, parent scores, the observed and
no-notch unit distributions, the two mass-balance moments, their implied
frontiers and mean counterfactual units, and counterfactual figures for the
preferred and completed-cohort specifications. Stable filenames without a
cohort suffix refer to the preferred 180-day specification.

Alternative training periods, filing-level models, validation windows, and
placebos remain audit tasks.
