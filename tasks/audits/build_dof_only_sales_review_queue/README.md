# DOF-Only Sales Review Queue

This audit task creates a structured review queue for high-priority DOF sales that
did not match the reviewed ACRIS private-market site-sale layer.

The queue is not a production outcome dataset. It exists to separate mechanical
coverage explanations from genuinely unresolved cases before any downstream sales
panel uses the reviewed private-market layer.

The task starts from `audit_recorded_sales_coverage` high-priority DOF-only rows
and attaches:

- same-date direct ACRIS deed evidence on the same BBL;
- classified ACRIS document status, party flags, and exclusion/warning codes;
- reviewed site-event status when those direct deed documents entered a reviewed
  event cluster;
- nearest reviewed same-BBL ACRIS event metadata from the coverage audit;
- repeated DOF borough/date/price cluster indicators.

The queue then assigns a mechanical preliminary review bucket and emits a compact
ChatGPT/manual review prompt per case. Final rulings should be tracked in a
separate manual decisions task, not edited into this generated queue.
