# Symmetric parent-cohort audit

This audit summarizes and checks the production parent membership. Upstream,
an economic parent is assigned to its first observed filing and may include
linked companion filings made within 365 days, including another calendar
year. This task does not reconstruct parents or estimate a counterfactual; it
impute an unobserved companion.

The historical parent anchors are the 2011--2023 leakage-safe HDB sample. The
linkage universe begins in 2010 so the 365-day lookback for 2011 anchors is
observed. Historical links use the existing pre-filing lot,
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

The production construction joins the HDB root job to the DOB NOW root job. Of
626 eligible 2025 HDB rows, 624 match the unfiltered DOB initial-filing file;
619 remain in the filtered parent crosswalk. The five filtered omissions have
fewer than six DOB proposed units, and the two unmatched HDB roots are retained
without an imputed DOB value.

HDB Class A units are the primary post-period measure. The audit carries DOB
initial-filing units separately and produces a parallel exact-99 path file, so
classification disagreements remain visible. For DOB-only post filings outside
the HDB estimation universe, the HDB-priority descriptive measure uses the
observed DOB value rather than dropping the filing. Neither measure imputes an
unobserved companion or unit count.
