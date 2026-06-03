# Fit Basic HDB MapPLUTO Regression

Audits a small transparent regression on the strict leakage-safe pre-deadline HDB-MapPLUTO sample.

This task is diagnostic. It does not create the production prediction model or score any land-value exposure universe.

The audit uses a deliberately simple feature split:

- `zone_detail`: groups `zonedist1` into low-density `R1_R5`, `R6`, `R7`, `R8_R10`, `C`, plain `M_non_slash`, and `MX_slash` for `M.../R...` hybrid districts.
- `prior_site_use`: uses MapPLUTO `unitsres` and `landuse` to separate existing residential units, vacant land, parking, commercial/industrial, mixed residential-commercial, public/transport/utility, missing land use, and other no-residential-unit sites.

The holdout audit trains on 2019-2020 rows and evaluates on 2021 through 2022-06-15. Numeric predictors in this holdout are standardized using training rows only.
