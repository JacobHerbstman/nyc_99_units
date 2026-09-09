# Manual parent-opportunity decisions

The CSVs in `output/` are hand-researched source data, committed to Git. They are not generated files. The two-line Makefile declares them as required inputs and never recreates a missing decision table. Restore missing source files from version control.

`pair_decisions.csv` records sample, exact filing IDs, accept/reject, reason, source and review date. Pair orientation follows the producer's filing-date/job ordering. Acceptance establishes common economic development, not wage-law treatment or certification of units. Historical accepted endpoints remain in the linkage universe even if their land covariates are missing. Ordinary automatic-link rules are unchanged.

`unit_decisions.csv` records explicit proposed-unit adjudications. The three Third Avenue rows use the October 2025 plan's 99 units each. The constructor retains original HDB-priority and DOB-I1 fields and separately records and checks the documented schedule; these decisions do not certify initial or approved units. Source dates are distinguished from review dates.

The existing 37 shared-site reviews and three superseded-filing decisions are preserved in `post_parent_reviews.csv` and `post_parent_filing_roles.csv`. Their migration changes no decisions. The September 9 additions accept the seven researched companions and reject the three disputed pair links. Wilson/Boston is explicitly provisional and remains a pre-estimation review item. Remaining schedule/alias issues are stated in the reasons; estimation remains on hold.

Downstream tasks symlink these files in `input/`. The parent producer validates identifiers, duplicate/reversed pairs, allowed decisions, explicit unit definitions, and whether each accepted/rejected pair has the requested final component relation. Its standard reports describe generated membership and links. No script fabricates these manual source tables or edits a generated dataset in place.
