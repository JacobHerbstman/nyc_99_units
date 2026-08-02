# Prepare developer cost-calibration targets

This production task translates the preferred exact-99 bunching moment into
the no-notch parent-size distribution needed for developer cost calibration.
For each cohort specification, it takes expected parent mass starting at 100
units until it exhausts the exact-99 excess-parent target, allowing a fractional
final unit bin. The preferred 180-day target is 21.14 parents; the conservative
completed-365-day sensitivity is 9.62. The resulting weights reproduce each
affected mean and frontier exactly.

The target table records the bunching mass, affected mean counterfactual size,
frontier, and the corresponding unit difference above 99. The weights table
records how that mass is distributed across counterfactual parent sizes. A
`preferred_specification` field distinguishes the main 180-day row from the
completed-cohort sensitivity.

These are behavioral calibration inputs, not cost or welfare estimates. The
`sample_equivalent_units_above_bunch_point` field is the unit difference implied
by the one-for-one bunching mapping within the stated estimation sample.
It must not be labeled realized lost housing: unresolved splitting, eligibility,
commencement, and entry responses can change that interpretation.

The next calibration stage requires external inputs on the 100-unit labor-cost
notch and the cost of legal or physical splitting, including duplicate common
areas and lost economies of scale. Run `make` from `code/`.
