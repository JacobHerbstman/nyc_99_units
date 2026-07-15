# Audit Opportunity Classification Design

Audits the current mechanical capacity rule and observed-project prediction-score tiers before either is promoted into production exposure construction.

This task does not estimate downstream sales regressions, does not create a production opportunity-lot score, and does not modify the frozen opportunity-lot task. It is a diagnostic bridge between:

- the HDB-MapPLUTO training panel, where actual proposed Class A unit counts are observed;
- the frozen MapPLUTO opportunity-lot universe, where only lot and zoning capacity are observed;
- the audit-only candidate prediction scores from `fit_candidate_prediction_models`.

The main capacity rule under review is:

```text
capacity_units_850 = allowed residential square feet / 850
```

The 850 sqft/unit number is a transparent gross-area bridge from square feet to units. It is not a source fact. The audit compares it against 650, 750, and 1000 sqft/unit alternatives and checks how each rule classifies observed HDB projects.

Outputs are CSV and Markdown diagnostics only:

- capacity-rule summaries and frozen-lot sensitivity counts;
- HDB capacity-threshold confusion tables;
- HDB capacity-bin outcome tables;
- model-score tercile/quartile performance tables;
- example rows from top/bottom score bins and capacity-rule classification errors;
- a short research-understanding checklist for the classification decision.
