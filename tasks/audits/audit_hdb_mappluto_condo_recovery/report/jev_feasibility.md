# Jev for the development-site evidence review

September 20, 2026. Feasibility review and proposed questions; no Jev requests submitted.

Jev is a promising reader of specific statements in our saved documents. It could help identify which parcels support a building, which land remains with another use, and whether a filing explicitly replaces another. The complete decision about a parent's land still combines those statements with parcel geometry, filing coverage, dates, and our research definition.

## What the existing projects teach us

In `aldermanic_privilege/tasks/audits/permit_jev_review`, the broad match-approval experiment accepted 64 proposals among 191 answered test cases; the source review supported 61. Errors included selecting five townhouses' measurements for one permitted house and leaving incompatible floor areas unresolved. Narrow permit-statement questions performed better. The latest 19-history annotation trial recovered all 19 original counts after code separated later annotations, but still mistook an expanded property's 17 homes for the earlier six-home coverage at model confidence 0.98–0.99. These references are Codex source readings, not independent human ground truth. See that task's README, “September 19 results and decision” and “later-note check.”

In `nyc_court_case`, separating an applicant's agreement from its timing corrected a known compound-question error. The selected acceptance follow-up matched 13 of 14 pre-recorded expectations, leaving one unresolved. A subsequent test on other reports exposed missed Council attribution and definition differences. The records also show why rejecting one selected passage cannot establish absence from the full document. See `logbook/2026-09-19-jev-acceptance.md`, `2026-09-19-jev-transfer.md`, and `2026-09-19-jev-checks.md` in that project.

The shared lesson is to ask short, literal questions about named objects, preserve separate facts, and test on fresh sources. Shorter wording alone did not uniformly improve the Chicago results. TypeSafe recommends this decomposition and keeping control flow in ordinary code. [Workflow guidance](https://docs.typesafe.ai/concepts/how-to-build-with-system-one).

## What evidence is ready here

The three inventories cover the original 158 flagged parents. The current audit retains 153 unresolved after five priority cases cleared. Many inventory entries describe a missing plan or allocation document. Their summaries and earlier agent proposals are research notes, not substitutes for original evidence and not material to send as classifier inputs. The current adjudications are recorded separately in `site_research_supervised.md` and `code/parent_site_document_review.csv`.

All 21 original ACRIS PDFs in `download_parent_review_documents/code/site_research_supervisor_2026-09-16/` lack an extractable text layer: `pdftotext` returned no non-whitespace text across their 408 pages. This check concerns those 21 files, not every PDF in the project. Jev accepts text only. [Supported inputs](https://docs.typesafe.ai/concepts/state).

A temporary local OCR check rendered two PDF pages at 200 dpi and used Tesseract English OCR. Godwin agreement 2026071500691002, PDF page 4, produced 2,976 characters, including the explicit history of old lot 78 becoming current 78/79/88. North 8th agreement 2026060300664002, PDF page 48, produced 619 characters, including its four legal course lengths. Visual comparison confirmed those clauses and lengths. Godwin's handwritten July 9 date was garbled. This is a two-page feasibility check, not an OCR accuracy estimate; diagrams and small labels remain separate inspection work. The source PDFs were untouched, and the disposable text/images are under `/private/tmp/nyc_jev_ocr_feasibility/`.

## Proposed reading questions

Use one named parcel, building, or filing pair at a time. Supply the relevant original passage, its definitions and adjacent context, document ID, PDF page, and exact administrative identifiers. Several independent questions about that material can share one request. A model answer describes only the supplied evidence. [Question design](https://docs.typesafe.ai/primitives).

| Question | Proposed answers | Why it matters |
| --- | --- | --- |
| What does this text say about parcel P being building B's ground? | Assigned to B; explicitly separate from B; not stated; unclear or conflicting | Distinguishes building land from neighboring land in the same agreement. Include common land through a separate question about its assigned use. |
| Does this text grant development rights from parcel P to building B? | Yes; not stated; unclear or conflicting | Identifies floor-area rights without treating them as ground. |
| Does this text grant nonexclusive access over parcel P for building B? | Yes; not stated; unclear or conflicting | Records access independently of ownership or ground assignment. Other rights, such as structural support, retain their own source text. |
| What does this text say about new job A replacing old job B? | Explicit replacement; explicitly separate concurrent buildings; not stated; unclear or conflicting | A shared address, owner, examiner, or BIN alone cannot settle replacement. |
| Does this text describe buildings A and B as parts of the same development proposal? | Explicit common proposal; explicitly separate proposals; not stated; unclear or conflicting | Supplies linkage evidence. A shared zoning lot or easement by itself does not define an economic parent. |
| What does the highlighted square-foot quantity measure? | Ground area; building floor area; permitted floor area; transferred floor-area rights; other; unclear | Prevents a development-rights quantity from becoming a land-area measurement. Code supplies the literal number and exact source span. |

For example, the first question can stay this short:

```json
{
  "type": "choice",
  "instructions": "What does `source.text` say about `parcel` being the ground assigned to `building`?",
  "criteria": {
    "assigned": "The text assigns this ground to the named building through ownership or a ground lease.",
    "separate": "The text explicitly places this ground outside the named building's site and assigns it to another retained use.",
    "not_stated": "The text does not establish this parcel's ground assignment. Development rights or access alone do not establish it.",
    "unclear": "The relevant statement is conflicting, unreadable, or ambiguous about the named parcel or building."
  }
}
```

This is proposed wording, not a validated codebook. The input must identify both the parcel vintage and the building. Lot numbers can be reused for different physical land. Direct ownership of a neighboring parcel alone does not assign it to the focal building.

Retain original passage IDs and text with every answer. If a request contains several passages, ask a separate Choice over their IDs plus `none` for the supporting evidence. The label and evidence selection are independent answers; disagreement requires review. Selection of an existing page guarantees provenance, not that the page proves the claim. Missing text, incomplete source coverage, and API failures stay explicit. A passage that does not state replacement does not prove the earlier building coexists.

Arithmetic, date ordering, parcel unions, overlap, duplicate-land checks, and final square-foot calculations belong in code. The model can help identify what a number means; it should not compute the boundary or total. TypeSafe documents weaknesses with counting, dates, long distracting inputs, and indirect reasoning. [Jev 1.13 limitations](https://docs.typesafe.ai/model-jaggedness/jev-1.13).

## Proposed pilot and completion rule

1. Prepare page-linked OCR from the existing acquisition sources and retain the full source text. Start question development with the nine reviewed priority parents. Beach's separately retained homes, East 108th's access rights, Charles/Broadway's uncertain replacement, and 165th's missing residential plan are useful boundary cases. These are development examples, not a holdout test.
2. Freeze the questions and source-based expectations before requesting answers. Then review about 20 additional parents across the unresolved issue types. Keep shared sites and shared documents in the same sample group. Record expectations before viewing Jev answers, preserve ambiguous references, and describe them honestly as supervised AI-assisted readings unless Jacob independently codes them.
3. Measure each question separately: supported statements missed, unsupported statements accepted, unresolved answers, and source-page agreement. Include cases with explicit contrary evidence and cases with missing evidence. Review high-confidence errors. Test both whether the relevant page is found and whether its statement is read correctly; success on a hand-selected excerpt tests only the latter.
4. If the fresh comparison is useful, process the remaining inventory using the same questions. Cases missing decisive records stay on the acquisition list. Documented statements can shorten the supervisor's review; no confidence threshold alone clears the parent's land, filing, membership, or geometry flags. Existing manual decisions remain the source of accepted changes.

The useful output is a table of source-linked facts and remaining questions. For example, recognizing Godwin's old-lot history should not by itself merge the parents or change their land. At 165th, correctly recognizing the earlier commercial condominium should preserve the need for the residential plan. The fraction of all 158 cases this could resolve cannot yet be estimated.

## Minimal acquisition and replication

The two other projects call Jev through Vercel AI Gateway using `typesafe-ai/jev`. Chicago reads `AI_GATEWAY_API_KEY` from the process environment; the CPC task also reads its ignored root `.env` as text without executing it. This review inspected the mechanisms, not the credentials. Reuse that approach when implementing; never put a key in questions, saved requests, command text, or logs.

Keep this experiment in the existing audit. Preparation supplies public source text only, excluding previous decisions and research notes. An explicit acquisition command saves the exact questions, input passages, request hashes, raw responses, probabilities, reported model, and failures. Ordinary Make rebuilds the review from saved answers. No live calls are part of an ordinary build. Avoid copying the other projects' accumulated experiment machinery.

The direct TypeSafe API supports a versioned model ID, currently `jev-1.13.0`; the saved Gateway examples report an alias. Verify Gateway support before claiming a pinned version. Preserved responses reproduce our analysis even if a future live response changes. [Model reference](https://docs.typesafe.ai/models). Confidence summarizes the distribution over answer options and needs validation on our documents. [Confidence reference](https://docs.typesafe.ai/confidence).

This review changed documentation only. No classification, parent membership, land value, weight, or estimation input was changed.
