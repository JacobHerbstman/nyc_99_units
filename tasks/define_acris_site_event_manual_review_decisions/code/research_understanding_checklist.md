# Research Understanding Checklist

## Session Goal
- [x] Research question or task: resolve high-risk ACRIS site-event ambiguities before building downstream sales panels.
- [x] Why this matters: repeated deeds, partial interests, and title-cleanup documents can overstate sale counts and dollars if handled mechanically.
- [x] What changed in this session: completed block 3 of the high-priority queue through 815 Burke Avenue, bringing validated manual decisions to 132 and leaving 0 high-priority clusters.

## Stage 1: Problem And Motivation
- [x] What problem existed? Same-site ACRIS packets can contain multiple deeds that are not obviously one market sale.
- [x] Why did it exist? ACRIS records legal instruments, not cleaned economic sale events.
- [x] Why would a naive approach fail? Summing every positive document can double count party-chain transfers; counting only the largest amount can miss true partial-interest components.
- [x] What branches or competing approaches were considered? Sum components, count repeated amount once, keep positive document events separate, or leave unresolved.
- [ ] Mastery status: in progress

## Stage 2: Data Provenance And Raw Inputs
- [x] What are the raw data sources? ACRIS documents, ACRIS legal rows, ACRIS parties, and external public/industry sources used only for manual adjudication.
- [x] Which source is primary vs validation/supporting? ACRIS is primary; ChatGPT-sourced links are validation/supporting evidence for ambiguous coding.
- [x] What is the unit of observation? The manual file is one row per review cluster; later event/incidence files may split clusters into economic events and BBL incidence rows.
- [ ] Mastery status: in progress

## Stage 3: Cleaning And Construction Logic
- [x] What transformations were mechanical? Review packets identify same-date/site repeated-BBL and partial-interest clusters.
- [x] What decisions were subjective? Whether a cluster is one sale, several sale legs, or unresolved after external review.
- [x] What edge cases were handled explicitly? Party chains, zero-consideration companion deeds, operating multifamily assets with companion title documents, non-site theater/right transfers, possible air-rights contamination, family-trust partial interests, broader-transaction subsets, public-record-only component packets, ground-lease / fee-interest recapitalizations, partial-interest JV equity packages, and incomplete public-record packets.
- [ ] Mastery status: in progress

## Stage 4: Joins, Crosswalks, And Manual Decisions
- [x] What manual overrides or review decisions exist? `acris_site_event_manual_review_decisions.csv` records the final ruling, event count, final price if supported, sources, confidence, and notes.
- [x] How are unresolved cases represented? `UNRESOLVED_AFTER_REVIEW` leaves event count and final price blank with a reason-coded `price_rule`.
- [ ] Mastery status: in progress

## Open Questions
- [ ] For public-record-only component packets, decide whether an upstream completeness audit can mechanically resolve possible missing same-date rows.
- [ ] Later downstream task must separate first-layer sale-event resolution from stricter private-market-site-sale classification.
- [x] High-priority queue is complete: 132 of 132 high-priority clusters have manual decisions.
- [ ] Next step is to rebuild the downstream first-layer site-event output and audit how these manual decisions change event counts, priced coverage, and unresolved exposure.
- [ ] Revisit conflict-flagged priced decisions before final private-market filtering, especially 34-22 35th Street, 350 West 38th/39th Street, 501 Third Avenue, 2030 Walton Avenue, Sandy Bergen/Bergen Avenue, and broader assemblage/footprint issues.
- [ ] Broader Savoy Park reconstruction remains unresolved: the five repeated 5.02M deeds should not be summed or collapsed until the full 315M preservation/acquisition transaction is reconstructed.
- [ ] Do not use Jujamcyn / 240-246 West 44th Street as a market site sale; it is a confirmed 5M non-site theater alleyway/stage-expansion rights transfer.

## Quiz Log
| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-06-13 | Stage 4 | Manual coding distinction | In progress | Revisit after current high-priority queue block |
