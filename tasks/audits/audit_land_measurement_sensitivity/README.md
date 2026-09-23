# Land-measurement sensitivity

Asks whether the unresolved parcel-boundary questions can change the reweighted
comparison. The sample is the reweighting benchmark in
`audit_scale_shape_splitting`: adopted rental parents with at least 50 units and
`composition_eligible`, 595 historical and 310 post-period parents. Boundary
flags and the alternative earlier-parcel areas come from `parent_site_scope.csv`
in `audit_parent_site_boundaries`.

Each scenario recalibrates the historical weights on the same moments (log lot
area, residential FAR, built FAR, borough) and reports the exact-99 and exact-198
excesses, the 100–149 cumulative deficit, multiple-constituent shares, and mean
parent units:

- `unweighted_historical`: no land adjustment.
- `production`: current characteristics; reproduces the saved benchmark weights.
- `drop_flagged_parents`: removes all flagged parents from both periods.
- `audit_candidate_area`: replaces lot area with the audit's earlier-parcel area
  for parents passing the boundary checks; FARs unchanged.
- `flagged_land_halved`, `flagged_land_doubled`: rescales flagged parents' lot
  area, holding earlier building floor fixed so built FAR moves inversely.

- `drop_implausible_sites`: removes parents, in both periods, whose permitted
  residential floor (lot area times the larger of residential and broad FAR)
  is under 150 square feet per proposed unit.
- `mergers_within_180_days`, `mergers_within_365_days`: use the earlier-parcel
  area only when every DOF change on the parent's lots was recorded within that
  many days after filing, in both periods, and keep only post-period parents
  observed for the full window before the September 15, 2026 DOF snapshot.
  `production_180_day_sample` and `production_365_day_sample` use production
  land on the same samples.

Housing units, filings, and membership are unchanged in every scenario. Run
`make` in `code/` after building the main panels and both source audits.
The output is `output/land_measurement_sensitivity.csv`.
