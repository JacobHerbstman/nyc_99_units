# Parent floor-space adjustment audit

This audit asks whether mature 2025 exact-99 parent projects preserve the gross
building area that similar projects would have used without the 100-unit
notch. It aggregates DOB total construction floor area across the same
symmetric parents used by the preferred no-notch model.

The historical gross-area model uses 2021--22 parents because the staged DOB
NOW extract does not cover gross construction area for the 2019--20 parent
cohorts. It predicts log total construction area from project units, lot area,
residential and built FAR, borough, zoning group, and prior site use. The audit
scores each mature 2025 parent at its observed units. For exact-99 parents, it
also constructs an affected-buncher scenario using the preferred no-notch
model's estimated range of projects induced to move from above 100 to 99. It
does not treat the center of an unconditional predicted distribution as the
project's no-notch unit count.

The scored comparison requires HDB and DOB initial-filing parent unit totals to
agree because the floor-area measure comes from DOB. Disagreement rows are
counted in the model diagnostics and excluded rather than corrected. All mature
exact-99 parents satisfy this agreement rule in the current snapshot.

The resulting ratios distinguish two descriptive margins. Conditional on a
project being an affected buncher, observed area near its predicted area at the
affected no-notch size is consistent with reduced dwelling density and a
retained gross envelope. Less observed area is consistent with physical
downsizing. These are scenario comparisons, not causal classifications or
parent-specific estimates of latent no-notch units.

The main figure first compares each 2025 parent's observed gross area with the
historical model prediction at its observed unit count. It then reports the
model-implied area change from the affected no-notch size to 99. Keeping these
objects separate prevents a general 2025 prediction residual from being called
a notch-induced floor-area response.

## Current findings

The area model uses 187 historical parents. Its in-sample R-squared is 0.665.
When either training year is held out, the correlation between predicted and
observed log area is 0.765--0.804 and the median absolute prediction error is
20--23 percent. The log-unit coefficient is 0.840 in the pooled model and
0.830--0.886 in the single-year fits.

The 22 mature exact-99 parents have a median observed-to-predicted area ratio
of 0.880 when they are evaluated as 99-unit projects. The corresponding median
is 0.898 among other 50--150-unit parents. Exact-99 projects therefore do not
have unusually large gross envelopes conditional on their observed units.

Conditional on an exact-99 parent being drawn from the no-notch model's
affected 100--130.8-unit range, its mean no-notch size is 113.3 units. The
historical area-unit relationship implies that a 99-unit design uses 89.5
percent as much gross area as that counterfactual design, a 10.5 percent
reduction. This favors partial physical downsizing over a fixed-envelope
interpretation, but the comparison is model-based and cannot distinguish
residential area from other gross floor space. Only three exact-99 parents have
public Option B registrations, so the HPD-confirmed subset is descriptive only.

DOB total construction floor area includes common, mechanical, parking, and
nonresidential space. It is not residential floor area or apartment size. HPD
matches are public prospective registrations, not final Eligible Site
determinations. Run the task from `code/` with `make`.
