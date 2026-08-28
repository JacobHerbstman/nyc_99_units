# Construct historical parent links

This task builds leakage-safe filing-pair evidence for historical parent
construction. The source universe begins in 2010 so a 365-day lookback can
determine whether a 2011 filing is a parent anchor. It extracts
owner, lot-history, coordinate, and explicit
project-reference fields from the historical MapPLUTO snapshot available at
each filing date. It then identifies filing pairs within one year and records
the conservative link signals used by the parent construction.

The task produces two analytical datasets: filing-level link fields and
candidate filing pairs. Coverage summaries and alternative grouping rules
remain in `tasks/audits/audit_historical_parent_link_feasibility`.
