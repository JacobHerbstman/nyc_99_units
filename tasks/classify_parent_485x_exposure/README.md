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
Attorney General no-action letters are retained as financing evidence but are
not treated as evidence that the residential units are for sale.

Private and nonprofit multifamily parents without conflicting evidence are
classified as plausible A/B rental opportunities with medium confidence. This
is the main substantive working rule approved for the first pass. Government
ownership other than a resolved manual case remains unresolved rather than
being silently treated as taxable or tax-exempt.

The manual review file is authoritative and records sources, reasons, and dates.
Unresolved and low-confidence observations remain identified in the classification.
The exposure audit produces the review queue, including priorities near the policy thresholds.

The classification and manual-review ledger are canonical production inputs. Recorded Attorney General responses are checksum-verified snapshots loaded by this task; live searches and diagnostic review queues remain in audits. Standard saved-data report: `report/parent_485x_exposure.txt`.

Saved Attorney General search evidence is attached to current parents through sample, filing ID and the exact queried address. A changed parent ID does not discard a completed filing search; an absent or changed query remains incomplete. Original search snapshots are unchanged.

The task first assembles the parent exposure universe from membership and recorded administrative sources, then classifies it. `parent_485x_exposure_universe.csv` remains available to the final panel and audits. The assembly no longer has a separate task folder.
