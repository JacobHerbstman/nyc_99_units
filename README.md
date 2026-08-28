# NYC 99 Units

This repository studies developer responses to the 100-unit threshold in New
York City's 485-x housing tax incentive. The current empirical work measures
the distribution of proposed project sizes in a plausible rental-opportunity
sample and tests whether linked economic parents are split across multiple
filings or buildings. The unit of observation is the linked parent proposal,
not an individual filing.

The current analysis is descriptive and design-based. It does not treat an
individual parcel-size prediction, a structural cost estimate, a land-price
event study, or the condo-tenure panel as a headline result.

## Current workflow

Run `make` from a task's `code/` folder. Task Makefiles are the dependency
graph; generated inputs are symlinks to named upstream outputs.

The current empirical path is:

```text
DCP Housing Database + DOB NOW + historical MapPLUTO
  -> construct historical and post-policy filing link fields
  -> construct linked parent cohorts
  -> build the 6-plus-unit exposure universe
  -> classify plausible 485-x A/B rental opportunities
  -> analyze exact parent-size distributions
  -> analyze scale, shape, and multi-filing composition

HPD 485-x registrations + DOB NOW
  -> link registrations to DOB jobs
  -> verify observed multi-filing configurations

linked parent cohorts + predetermined MapPLUTO characteristics
  -> build parent site characteristics
  -> reweight the historical distribution to the post-period site mix
```

The main empirical compilation is
`tasks/analyze_485x_scale_shape_splitting/output/pdf/scale_shape_splitting_figure_guide.pdf`.
The underlying count and normalized-density figures are produced by
`tasks/analyze_parent_unit_distribution/`.

## Production tasks

Top-level tasks are limited to source acquisition/staging, canonical linkage
and parent datasets, predetermined site characteristics, and the two current
analysis tasks. In particular:

- `construct_parent_cohorts` defines historical and post-policy economic
  parents and preserves reviewed linkage decisions.
- `build_parent_485x_exposure_universe` assembles the parent-level information
  used for the rental-opportunity screen.
- `link_hpd_485x_registrations` produces the canonical HPD-to-DOB link without
  depending on a unit-count prediction model.
- `build_parent_site_characteristics` aggregates predetermined parcel traits
  used for composition adjustment; it does not predict project unit counts.
- `analyze_parent_unit_distribution` produces the raw, annualized, and
  normalized parent-size distributions.
- `analyze_485x_scale_shape_splitting` produces the current scale, shape,
  reweighting, and multi-filing results.

## Audits

`tasks/audits/` contains validation, manual review, sensitivity analysis, and
the deliberately non-headline condo branch. The exposure classification stays
there because it combines source-based rules with an explicit manual-review
ledger. The condo panel and Attorney General search also stay there because
recent cohorts are right-censored and the evidence is not yet strong enough
for the main empirical design.

Earlier parcel-prediction, structural no-notch, cost-calibration, land-price,
and ACRIS/DOF exploration was removed from the active tree during the August
2026 cleanup. It remains recoverable from Git history at commit `1374dda`.

## Builds

- `make` builds the current framework PDF and empirical figure guide.
- `make paper` compiles the draft paper separately. The draft is not the
  dependency root for the current empirical outputs yet.
- `make source-registry` validates source metadata.

Raw and manually acquired data live under `data_raw/<source>/<vintage>/` and
must not be edited. Do not edit generated task outputs directly.
