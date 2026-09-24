# Bunching plots

Reads the canonical parent and constituent panels and produces the current citywide size distributions, filing CDFs, and configurations of parents containing 99-unit filings. `output/pdf/main_project_plots.pdf` collects the figures.

The constituent plots retain their existing denominators and observation windows. Parent plots show annualized counts and normalized shares; the preferred 50-plus share includes parents above 300 in its denominator. The 50–300 reproduction uses its explicitly narrower denominator.

Run `make` in `code/`. Reweighting, bootstrap inference, and exploratory decomposition figures belong to `tasks/audits/audit_scale_shape_splitting` and are not required here.
