# Symmetric parent-cohort audit

This audit assigns an economic parent to its first observed filing and links
companion filings made within 365 days, including companions in another
calendar year. It does not re-estimate the no-notch model and never imputes an
unobserved companion.

The historical filing universe is the 2019--2023 leakage-safe HDB sample used
by the parent model. Historical links use the existing pre-filing lot,
same-BBL, explicit-reference, project-code, and corroborated exact-adjacency
evidence. The post filing universe is DOB NOW New Building filings observed
from 2024 through the current data snapshot. Post links use the analogous
filing-time evidence. A later-observed APPBBL change is retained as an audit
candidate but is not an automatic link.

Post exact adjacency is measured on the fixed 23v3.1 MapPLUTO geometry. Its
tax-lot files have a December 28, 2023 internal date, but this audit does not
claim a separately verified public release date. The vintage is used only as
a common pre-policy geometry reference, not as evidence about information
available to developers. Filing BBLs absent from that snapshot remain missing;
they are not imputed.

Each parent receives left- and right-window observability flags. The main post
comparison separates parents first filed in 2025 whose full 365-day window is
observed from later 2025 parents that are right-censored. Three January 2, 2025
parents lack a full backward support window and are reported separately. The
descriptive all-2025 result uses all companions observed by the data snapshot.
Parents first filed in 2024 are not relabeled as 2025 parents merely because
they contain a 2025 filing.

The audit records the identifier handoff needed for later model integration.
The HDB root job has zero overlap with the DOB NOW filing identifier ending in
`-I1`, which is the field used by the current production join. It matches 619
of 626 eligible 2025 HDB rows when joined to the DOB NOW root job instead. The
audit also reports disagreements between HDB Class A units and DOB proposed
dwelling units; it does not silently replace either measure or re-estimate the
model.
