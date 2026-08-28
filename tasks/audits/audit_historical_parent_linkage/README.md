# Historical parent-linkage audit

This audit evaluates whether symmetric parent construction is comparable across
the fully padded 2011--2022 historical cohorts. It does not choose the preferred
counterfactual window.

The cohort table reports parent counts, multi-filing shares, tail counts, and
accepted links by evidence channel. The signal-availability table shows whether
owner, description, explicit-reference, lot-history, and coordinate fields
change across filing years. The geometry-dependence table reconstructs parents
after withholding adjacency-only edges; this is a sensitivity, not an estimate
of linkage error. The review file contains every adjacency-only accepted edge
and the underlying timing, owner, filing-lot, unit, and description fields for
case-level inspection. A second review file collapses those edges to full
parents and flags exactly which merges change the 99-or-more tail or exact-99
mass when adjacency evidence is withheld.

Restoring pre-filing parcel geometry exposed 14 parents whose annual
99-or-more count changes when adjacency-only edges are withheld. Each is now
documented in `code/tail_relevant_parent_reviews.csv`; the generated validation
output fails the build if a reviewed parent disappears, changes cohort, or no
longer affects the tail. All 14 reviewed cases are retained as genuine
multi-filing developments. Separate reviewed overrides in the production
parent task reject three mechanical false-positive edges and add the later
Broadway Triangle phase edge.

Run `make` from `code/`.
