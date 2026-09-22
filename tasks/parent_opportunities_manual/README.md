# Manual parent-opportunity decisions

The CSVs in `output/` are hand-researched source data, committed to Git. They are not generated files. The two-line Makefile declares them as required inputs and never recreates a missing decision table. Restore missing source files from version control.

`pair_decisions.csv` records sample, exact filing IDs, accept/reject, reason, source and review date. Pair orientation follows the producer's filing-date/job ordering. Acceptance establishes common economic development, not wage-law treatment or certification of units. Historical accepted endpoints remain in the linkage universe even if their land covariates are missing. Ordinary automatic-link rules are unchanged.

`unit_decisions.csv` retains documentary unit evidence for comparison only; it does not override administrative counts. Third Avenue's 99 per building and Boyland's 86+28 agree with the Housing Database. Turnbull's HDC schedule describes 228 apartments, while both administrative sources report 91 dwelling units. Following Jacob's September 10 clarification, selected units retain the existing Housing Database priority with DOB fallback. External schedules remain separate evidence even when they disagree. Source dates are distinguished from review dates.

The existing 37 shared-site reviews and three superseded-filing decisions are preserved in `post_parent_reviews.csv` and `post_parent_filing_roles.csv`. Their migration changes no decisions. The September 9 additions accept the seven researched companions and reject the three disputed pair links. Wilson/Boston is adjudicated separate in the baseline; ultimate beneficial independence is not certified. The September 10 additions merge the four same-date Astoria Cove filings in both linkage routes and reject the neighboring LCOR/BFC Coney Island link. Remaining schedule/alias issues are stated in the reasons; estimation remains on hold.

Downstream tasks symlink these files in `input/`. The parent producer validates identifiers, duplicate/reversed pairs, allowed decisions, explicit unit definitions, and whether each accepted/rejected pair has the requested final component relation. Its standard reports describe generated membership and links. No script fabricates these manual source tables or edits a generated dataset in place.

`historical_filing_roles.csv` records two source-role decisions for the inactive-inclusive 23Q4 archive. B00775071 at 773 Neptune is nonresidential: its archived description specifies a house of worship, and the later DOB record identifies an institutional building with zero dwelling units. M00536051 is a withdrawn alternative to M00580473 on the same West 48th/49th Street lot. The identical archived program and the City's single-building environmental assessment support that relationship; the assessment does not explicitly crosswalk both job IDs. The parent producer retains the recorded units, status, original filing date, replacement date, and evidence basis while counting only additive residential filings. The West 48th Street land decision follows the earlier parent anchor, `historical__M00536051`.

The September 21 decisions combine Bedford Square's four filings into one
877-unit parent and Starhill's two filings into one 570-unit parent.
`site_lot_decisions.csv` records the reviewed parcel allocations, including
those developments, Dupont, Eagle/West, Exterior, and Story Avenue. Its key is
`(sample, parent_id, reference_bbls)`. Each row
names the expected constituent jobs, source MapPLUTO vintage and area, included
ground, excluded building floor area, and documentary basis. The
`build_parent_site_characteristics` task applies the table and preserves the
earlier parcel's zoning. Complete ground is 177,520.79 square feet at Bedford,
70,063 at Starhill, and 20,901 at Dupont. Retained buildings are excluded from
the prior-density calculation. Later boundary evidence is distinguished from
ownership or a survey at the original filing date. These sources are production
inputs; the main pipeline has no dependency on audit outputs.

The remaining three September 21 sites are implemented at 106,018 square feet
for Eagle/West, 120,272 for Exterior, and 203,910 for Story. A semicolon-separated
reference set records Exterior's four contributing earlier parcels together.
Its documented combined area requires no internal allocation because all four
parcels share both FAR measures; the producer checks this and preserves their
individual lot count. The source table records later boundary evidence and
excludes retained neighboring buildings. Housing units and dates are unchanged.

The next September 21 application combines five additional developments:
Godwin/Kimberly, GO Broome, Woodside, Motto, and Elara. Each accepted pair is
applied together with its complete land characteristics. Additional reviewed
land corrections use the same table; no address-specific branches are added to
the producer. The audit's `mergers_and_23_review.md` records the application
inventory and cases held for Jacob's judgment. Uncertain source conflicts and
building allocations are not silently filled with land-share prorations.

Flatbush's September 21 follow-up adopts 12,603 square feet of tower ground and
39,929.757 square feet of estimated earlier building floor. The estimate assigns
61.3821% of old lot 18's administrative floor to the tower, plus all floor on old
lots 23 and 24. Jacob explicitly approved the uniform-floor-density assumption.
`built_floor_area_estimated` identifies this approximation in the source table,
site characteristics, and canonical parent panel; FALSE means no such adopted
floor allocation estimate, not that all other measurements have been verified.
The subsequent approval applies East 125th (42,540 ground; 50,836.28 estimated
floor), St. James/Jerome (17,775 ground; 3,650 later administrative floor proxy),
and Onderdonk (9,310 ground; 13,141.62 estimated floor). All three carry the same
estimate flag. St. James's excluded-floor field is the accounting residual
needed to retain the parcel-specific proxy, not a measured church-floor total.
The source reasons state the assumptions and preserve the frozen zoning.
The September 22 approval adds Jamaica (39,349.5 ground; 40,342.49 estimated
floor) and Kingsbrook (105,382 ground; 226,059.00 estimated gross floor including
cellars). Jamaica allocates frozen parcel totals with shop plans and building
depths. Kingsbrook sums HCR pavilion schedules and an estimated share of the
power plant; the cellar footprint and half-bay mezzanine are explicit
assumptions. Both carry the estimate flag. Kingsbrook’s excluded-floor field
is an accounting residual used to retain that documented measurement substitute,
not a measured retained-campus floor total. All 23 reviewed land corrections
are now applied. On September 22, Jacob also approved GO Broome’s official
zero-floor record after June 2019 demolition. Its 4,600-square-foot deduction
is an archive-error correction, explicitly distinguished from floor retained
outside the development. Lot 37 is vacant and lot 75 is parking, preserving
the parent’s mixed prior-use category. This documented zero carries no estimate flag.

Jamaica's housing land uses six contributing earlier parcels. Old lots 89 and
94, with 23,175 square feet of ground and 17,220 of floor, are wholly outside
the residential boundary. The audit retains all eight associated parcels to
show that exclusion; the production source counts six and starts from their
88,365 ground and 52,593 floor before applying the approved allocation.

The September 22 Wallabout follow-up applies 39,323 square feet to the three
cohort buildings. Three rows allocate the recorded successor areas across
old 18v2_1 lots 37/41/122 by mapped overlap, preserving their different FARs.
All three old lots record zero floor. This is an approximate zoning allocation;
its basis is explicit in `area_basis` and `review_basis`. Earlier lot 23 is
outside the boundary. Later lot 37 is the separate 251 Wallabout site and has
a different boundary from earlier lot 37. Housing units and links are unchanged.
