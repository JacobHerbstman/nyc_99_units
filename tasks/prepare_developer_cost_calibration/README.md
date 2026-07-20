# Prepare developer cost-calibration targets

This production task translates the preferred exact-99 bunching moment into
the no-notch parent-size distribution needed for developer cost calibration.
It takes expected parent mass starting at 100 units until it exhausts the 9.62
excess-parent target, allowing a fractional final unit bin. The resulting
weights reproduce the preferred affected mean and frontier exactly.

The target table records the bunching mass, affected mean counterfactual size,
frontier, and the corresponding unit difference above 99. The weights table
records how that mass is distributed across counterfactual parent sizes.

These are behavioral calibration inputs, not cost or welfare estimates. The
`sample_equivalent_units_above_bunch_point` field is the unit difference implied
by the one-for-one bunching mapping within the completed-2025 estimation sample.
It must not be labeled realized lost housing: unresolved splitting, eligibility,
commencement, and entry responses can change that interpretation.

The next calibration stage requires external inputs on the 100-unit labor-cost
notch and the cost of legal or physical splitting, including duplicate common
areas and lost economies of scale. Run `make` from `code/`.
