# Research Understanding Checklist

## Session Goal
- [x] Research question or task: build the first ACRIS layer that maps deed documents to site-event records.
- [x] Why this matters: later sale and land-value analyses should not double-count document fragments as separate economic transfers.
- [x] What changed in this session: added a production site-event layer with event, event-document, and event-BBL incidence outputs.

## Stage 1: Problem And Motivation
- [x] What problem existed? ACRIS can have several deed documents for one site transaction, and some packets need manual review.
- [x] Why did it exist? ACRIS records legal documents, not researcher-defined economic sale events.
- [x] Why would a naive approach fail? Counting documents directly can overcount both events and dollars.
- [x] What branches or competing approaches were considered? Keep unreviewed clusters mechanical, collapse only positive unreviewed clusters, or preserve every review-cluster packet as unresolved.
- [ ] Mastery status: pending user restatement.

## Stage 2: Data Provenance And Raw Inputs
- [x] What are the raw data sources? Classified ACRIS deed documents, ACRIS review packets, and manual review decisions.
- [x] Which source is primary vs validation/supporting? ACRIS documents are primary; manual review decisions resolve ambiguous ACRIS packets.
- [x] What is the unit of observation? Source documents upstream; final outputs are event rows, event-document rows, and event-BBL incidence rows.
- [ ] Which key columns are reliable, fragile, missing, or ambiguous?
- [ ] Mastery status: pending user restatement.

## Stage 3: Cleaning And Construction Logic
- [x] What rows were included or excluded? All classified deed documents are mapped to exactly one final event-document bridge row.
- [x] What transformations were mechanical? Documents outside any review cluster keep exact-duplicate mechanical grouping.
- [x] What decisions were subjective? Completed manual review clusters define curated event counts and prices.
- [x] What edge cases were handled explicitly? Unreviewed clusters are preserved as unresolved placeholders with missing final price.
- [x] What diagnostics check this stage? The build stops unless documents map to exactly one event, reviewed documents leave mechanical events, manual event counts match reviewed counts or placeholders, and unreviewed clusters carry no final price.
- [ ] Mastery status: pending user restatement.

## Stage 4: Joins, Crosswalks, And Manual Decisions
- [x] What entities were joined? Classified documents, review cluster membership, and manual decisions.
- [x] What makes the join safe or unsafe? Review document membership must be unique by document_id; event-document bridge must be unique by document_id.
- [x] Were many-to-many joins avoided? The script validates one-document-to-one-event coverage.
- [x] What manual overrides or review decisions exist? 132 completed review clusters currently replace mechanical grouping.
- [x] How are unresolved cases represented? 200 unreviewed clusters become unresolved cluster-placeholder rows with no final price.
- [ ] Mastery status: pending user restatement.

## Open Questions
- [ ] Should the remaining positive-price unreviewed clusters receive manual review before downstream market-sale classification?
- [ ] Should multi-event manual rulings later move to a task-local manual event-component CSV if this pattern grows?

## Quiz Log
| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
