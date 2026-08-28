# Parent-tail no-notch counterfactual audit

This audit rebuilds the no-notch unit-count counterfactual from the strict
invariant tail at 99 units. The first stage constructs the preferred historical
2017--2022 and mature-2025 symmetric-parent samples and checks their support before any
weighting model is estimated.

The maintained initial scope is conditional on the fixed set of observed 2025
parent opportunities. Entry, non-filing, and policy-induced splitting remain
outside this first counterfactual. Historical unit counts are untreated
outcomes. The 2025 unit count is used only to define membership in the
99-or-more target set and to calculate later observed moments.

The primary 2025 sample retains all usable parents with at least 180 observed
follow-up days; the realized minimum is 190 days. This choice maximizes the
post-policy sample. A complete 365-day right-side parent-linkage window is
reserved for a later sensitivity analysis.

All comparison variables come from the existing leakage-safe parent panels.
No `log1p` or related zero-handling transformation is used. Capacity and
redevelopment slack are retained in levels with explicit zero indicators until
their role in the weighting specification is reviewed.

Run `make` from `code/`. The current outputs document sample flow, exact counts
near the threshold, covariate support, and the historical and 2025 tail rows.
They also contain positive exponential calibration weights and their balance,
concentration, and cohort-composition diagnostics. The weights exactly balance
the target means of log lot area; capacity and slack in levels; residential and
built FAR; multi-lot status; zero-capacity and zero-slack indicators; and the
existing borough, zoning, and prior-use categories. They do not yet contain a
no-notch distribution estimate with sampling uncertainty.

The current point-estimate outputs apply the weights to the historical exact
unit counts from 99 through 149 and pool larger projects at 150+. They compare
the weighted no-notch and observed 2025 distributions, verify the c=99
excess-mass accounting identity, and keep the structural mass-allocation
frontier separate from the observed missing-mass diagnostic. Bootstrap
uncertainty and sensitivity specifications are not yet included.

The historical-window comparison reruns the same positive calibration for
2011--2022, 2014--2022, 2017--2022, and 2019--2022. Because MapPLUTO did not
publish `ResidFAR` in the 2011--2012 releases, this cross-window diagnostic uses
one common broad zoning-capacity measure: lot area times the maximum reported
residential, commercial, facility, or historical `MaxAllwFAR` field. This is a
comparability specification, not a claim that all of that floor area is
residential capacity. The preferred 2017--2022 estimator continues to use
residential capacity. Parent-level window weights are written separately so
individual high-leverage projects can be inspected directly.
