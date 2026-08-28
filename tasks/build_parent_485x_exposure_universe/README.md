# Build parent 485-x exposure universe

This task creates the parent-and-component ledger used to classify whether a
multifamily proposal was plausibly exposed to the 485-x rental options, the
homeownership option, neither, or cannot yet be resolved. It covers every
6-plus-unit historical and post-policy parent in the descriptive analysis
windows: historical cohorts from 2011–2022 and consistently DOB-linked recent
cohorts from 2023 through the current 2026 source end date. Six units is the
statutory minimum for the relevant 485-x options.

The output has one row per component filing. Addresses and ownership fields
come from the current DCP Housing Database where available, supplemented by
DOB NOW and the reviewed historical-link fields. It does not assign exposure;
it only makes the evidence universe explicit and unique before external or
manual evidence is joined.
