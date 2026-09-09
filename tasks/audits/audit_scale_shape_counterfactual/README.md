# Scale-shape counterfactual audit

This task keeps diagnostics and robustness exercises outside the production
scale-shape task. It audits the parent and constituent panels, preserves the
190--205 parent case listing, reports the exploratory q-theta calculation, and
runs forward-placebo, leave-one-pre-year-out, and historical-window checks.

These outputs are evidence about the maintained counterfactual, not inputs to
the main empirical figure guide. Run the task from `code/` with `make`.
