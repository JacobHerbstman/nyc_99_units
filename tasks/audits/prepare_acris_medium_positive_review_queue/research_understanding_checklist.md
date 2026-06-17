# Research Understanding Checklist

## Session Goal
- [x] Research question or task: resolve the remaining medium-positive ACRIS site-event ambiguity clusters one by one.
- [x] Why this matters: these rulings define the first-layer sale-event object before downstream market/private sale classification.
- [x] What changed in this session: all remaining medium-positive clusters were manually resolved, validated, and consumed by the production ACRIS site-event builder.

## Stage 1: Problem And Motivation
- [x] What problem existed? Same-date ACRIS documents can describe one sale, companion documents, a portfolio, or several distinct site events.
- [x] Why did it exist? ACRIS records legal documents, not already-clean economic transactions.
- [x] Why would a naive approach fail? Summing every document can overstate price, while collapsing every same-buyer/date packet can erase distinct site events.
- [x] What branches or competing approaches were considered? Sum document amounts, use a repeated amount once, use an externally confirmed total, keep separate document events, or leave unresolved.
- [ ] Mastery status: deferred during active review; user requested execution before another restatement checkpoint.

## Stage 2: Data Provenance And Raw Inputs
- [x] What are the raw data sources? ACRIS document, legal, and party rows for opportunity-site-linked BBLs.
- [x] Which source is primary vs validation/supporting? ACRIS is primary for deed documents and consideration; ChatGPT/browser external sources are validation and interpretation support.
- [x] What is the unit of observation? The raw unit is an ACRIS source document; the review output defines first-layer site-event decisions.
- [x] What is the sample window? The active queue is the unresolved `medium_positive_price` ambiguity set from the opportunity-site ACRIS recovery layer.
- [x] What do the key columns mean? `document_amt` is deed consideration, `percent_trans` is reported transfer percent, BBLs identify legal/opportunity lots, and warning codes flag ambiguity patterns.
- [ ] Mastery status: deferred during active review.

## Stage 3: Cleaning And Construction Logic
- [x] What rows were included or excluded? The queue includes unresolved medium-priority clusters with positive ACRIS amounts; resolved clusters are removed after manual-decision validation.
- [x] What transformations were mechanical? Queue ordering, sums, document counts, and allowed ruling templates are generated reproducibly.
- [x] What decisions were subjective? Event boundary, final price basis, and whether portfolio context implies one event or multiple site events.
- [x] What edge cases were handled explicitly? Zero-dollar companion deeds, different-amount same-date deeds, rights-complex documents, institutional transfers, preservation portfolios, and external price-basis conflicts.
- [x] What diagnostics check this stage? The manual-decision validator and queue rebuild check accepted ruling codes, uniqueness, and unresolved queue counts.
- [ ] Mastery status: deferred during active review.

## Stage 4: Joins, Crosswalks, And Manual Decisions
- [x] What entities were joined? ACRIS documents, legal BBL rows, party rows, opportunity BBL links, and manual review decisions.
- [x] What makes the join safe or unsafe? Safe construction requires preserving document IDs and BBL links; many-to-many expansion is not used as a shortcut for event coding.
- [x] Were many-to-many joins avoided? Current manual review appends decisions at the cluster level and rebuilds the queue through the existing audited task.
- [x] What manual overrides or review decisions exist? Each decision records ruling, event count, optional final price, source URLs or source names, notes, review method, and date.
- [x] How are unresolved cases represented? The medium-positive review queue now has zero unresolved rows after validation and rebuild.
- [ ] Mastery status: deferred during active review.

## Open Questions
- [x] For each remaining cluster: should documents collapse into one first-layer event, remain separate site events, or be coded another way?
- [x] For each collapsed event: is final price best measured by summed ACRIS deed consideration or by a documented external total?
- [ ] Sol Goldman edge case: downstream review should remember this is one positive 12 percent related-party/trust anchor with three zero-consideration companion/source deeds across non-contiguous BBLs.
- [ ] For each externally conflicted or special-context event: downstream market/private classification must treat institutional, preservation, public, HDFC, related-party, and portfolio context separately from this first-layer event construction.

## Quiz Log
| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-06-17 | Event boundary | deferred | User requested execution first | Ask for restatement after a review block |
| 2026-06-17 | Manual review completion | deferred | All remaining clusters resolved during execution | Review the seven resulting production events with the researcher |
