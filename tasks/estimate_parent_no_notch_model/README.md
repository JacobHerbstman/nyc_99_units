# Estimate the parent no-notch model

This task fits the preferred production model once. The outcome is the total
proposed units in a symmetric 365-day parent cohort. The conditional location of log units is
linear in log lot area, residential FAR, built FAR, filing year, borough,
zoning group, and prior site use. Observed units are rounded and the likelihood
is truncated at six units. The model assumes one normally distributed i.i.d.
scale shock per parent.

The model is estimated on fully observed 2019–2022 cohorts. It is scored on
2025 cohorts whose complete 365-day companion window is observed. Later 2025
cohorts remain outside the production estimate because they are right-censored;
no companion is imputed. HDB Class A units are primary, with DOB initial-filing
units retained as a sensitivity.

Outputs contain the fitted coefficients, parent scores, the observed and
no-notch unit distributions, the two mass-balance moments, their implied
frontiers and mean counterfactual units, and the primary counterfactual figure.

Alternative training periods, filing-level models, validation windows, and
placebos remain audit tasks.
