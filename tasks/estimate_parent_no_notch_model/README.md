# Estimate the enhanced-parent no-notch model

This task fits the preferred production model once. The outcome is the total
proposed units in an enhanced parent. The conditional location of log units is
linear in log lot area, residential FAR, built FAR, filing year, borough,
zoning group, and prior site use. Observed units are rounded and the likelihood
is truncated at six units. The model assumes one normally distributed i.i.d.
scale shock per parent.

The model is estimated on 2019–2023 enhanced parents and scored on 2025
enhanced parents. Outputs contain the exact fitted coefficients, parent scores,
the observed and fitted no-notch unit distributions, the two mass-balance
moments, their implied frontiers and mean counterfactual units, and the primary
counterfactual figure.

Alternative training periods, filing-level models, validation windows, and
placebos remain audit tasks.
