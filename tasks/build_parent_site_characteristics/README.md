# Build parent site characteristics

This task aggregates predetermined parcel characteristics to the linked
economic-parent level. It produces one historical panel and one post-policy
panel for composition adjustment in the current scale-and-shape analysis.

Historical characteristics come from each filing's leakage-safe lagged
MapPLUTO match. Post-policy characteristics use the fixed 23v3.1 MapPLUTO
snapshot. Lot area is summed across unique feature lots; FAR measures are
lot-area weighted. Proposed units are retained only as the parent outcome and
are never used to construct the site characteristics.

Parents with incomplete lot features or repeated nonmissing BIN rows remain in
the output with an explicit eligibility flag. Nothing is imputed. This task
does not estimate or score an individual parcel unit-count model.
