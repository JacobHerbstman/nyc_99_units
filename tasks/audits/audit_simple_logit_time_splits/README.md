# Audit Simple Logit Time Splits

Audits whether a transparent ordinary logit with a small feature set can separate observed 50+ HDB New Building filings into low- and high-risk groups for proposed Class A units at or above 100.

This task is diagnostic only. It does not produce a production exposure score and does not score the frozen opportunity-lot sales universe.

The simple logit target is:

```text
y100 = classa_prop >= 100
```

The candidate sample is observed HDB New Building filings in the leakage-safe HDB-MapPLUTO panel with at least 50 proposed Class A units. The simple feature set mirrors the existing benchmark:

- log lot area;
- residential FAR;
- built FAR;
- borough;
- coarse zoning group;
- prior site use.

The audit fits the same model across several pre-specified train/test windows, including ordinary pre-policy validation windows and post-2022-06-15 transport windows. The post-deadline checks are explicitly labeled as transport checks because policy and market conditions may differ.

Outputs are CSV diagnostics only: window definitions, window status, train/test summary metrics, tercile/quartile score-bin performance, top-vs-bottom contrasts, and example rows from top and bottom terciles.

The current reference window is `train_2010_2020_test_2021_2022h1`. This trains on the full 2010-2020 pre-policy candidate sample and validates on 2021 through June 15, 2022. The choice prioritizes power while keeping validation before the 421-a deadline/regime break.
