# Construct historical parent links

This task builds leakage-safe filing-pair evidence for the 2019–2023
enhanced-parent model. It extracts owner, lot-history, coordinate, and explicit
project-reference fields from the historical MapPLUTO snapshot available at
each filing date. It then identifies filing pairs within one year and records
the conservative link signals used by the parent construction.

The task produces two analytical datasets: filing-level link fields and
candidate filing pairs. Coverage summaries and alternative grouping rules
remain in `tasks/audits/audit_historical_parent_link_feasibility`.
