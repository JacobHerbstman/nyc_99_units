# Classify parent 485-x exposure

This production task assigns one categorical exposure status to every 6-plus-unit
historical and post-policy parent in the descriptive bunching sample:

- `exposed_ab`: a taxable rental opportunity plausibly able to choose rental
  Option A or B;
- `exposed_option_d`: a non-Manhattan homeownership opportunity plausibly able
  to choose Option D;
- `not_exposed`: an established hotel, ineligible Manhattan homeownership
  project, or other project established not to face the relevant 485-x choice;
- `unresolved`: available records do not support a defensible assignment.

The classification is an exposure screen, not a claim that the project applied
for or received 485-x. HPD registrations are high-confidence positive evidence.
Condominium offering plans and CPS-1 market-testing applications are
homeownership evidence when their address and timing match the proposal. An
accepted plan receives higher confidence than a filed but not-yet-accepted plan.
Attorney General no-action letters (condominium financing) are not treated as
evidence that the residential units are for sale.

Historical filing metadata come from the 23Q4 Housing Database and archived
parent-link fields: 23Q4 address, borough and ownership, the archived MapPLUTO
owner, and the historical filing description. The post-policy route retains
25Q4 Housing Database and DOB NOW metadata. A historical member missing from
the staged 23Q4 file stops the build rather than receiving later metadata.
Historical exposure does not use a later HPD 485-x registration as evidence of
the pre-policy proposal. For historical parents, an Attorney General plan must
have a recorded submission by January 12, 2024 to count as homeownership
evidence; accepted-plan confidence also requires acceptance by that
date. This is the latest 23Q4 Housing Database update date used as the
pre-adoption evidence cutoff. Post-policy plan and HPD rules are unchanged.

Private and nonprofit multifamily parents without conflicting evidence are
classified as plausible A/B rental opportunities with medium confidence. This
is the main substantive working rule approved for the first pass. Government
ownership other than a resolved manual case remains unresolved rather than
being silently treated as taxable or tax-exempt.

The manual review file `code/parent_exposure_manual_reviews.csv` is
authoritative and records sources, reasons, and dates. Unresolved and
low-confidence observations remain identified in the classification.

The Attorney General searches are the August 26, 2026 capture and the September
22, 2026 historical supplements for 2019–22 filings and linked 2023 companions,
published with checksums by `fetch_nys_ag_offering_plans`, which also records
how they were made. The build does not call the live service.

Saved Attorney General search evidence is attached to current parents through
sample, filing ID and the exact queried address. A filing can have searches for
more than one address across source snapshots; the current 23Q4 address selects
the applicable one. A changed parent ID does not discard a completed filing
search; an absent or changed query remains incomplete. Original search
snapshots are unchanged.

The saved AG searches were run in 2026. `ag_screen_complete` means each current
address query had a successful saved response; a historical filing without a
23Q4 address has an incomplete screen. This does not certify that the AG
database is a complete January 2024 archive. Historical
classification uses only dated pre-adoption plan evidence as specified above.
The current manual exposure overrides cover three post-policy parents; any
future historical override needs separately documented dated evidence.

The task first assembles the parent exposure universe from membership and recorded administrative sources (`parent_485x_exposure_universe.csv`), then classifies it.
