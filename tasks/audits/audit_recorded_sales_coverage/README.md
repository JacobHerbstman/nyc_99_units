# Recorded Sales Coverage Audit

This audit compares the reviewed ACRIS private-market opportunity-site sales layer
against an external recorded-sales denominator from NYC DOF annualized sales.

The task does not change any production sales outputs. It asks whether conservative
DOF sale candidates on non-Staten-Island opportunity BBLs are recovered in the
reviewed ACRIS event layer, and it surfaces the remaining high-priority misses for
manual review.

The first-pass denominator is deliberately narrow:

- frozen primary opportunity BBLs only;
- Manhattan, Bronx, Brooklyn, and Queens only;
- DOF annualized sale rows with valid BBLs, sale dates in the source year, and
  sale prices above the ACRIS low-price cutoff;
- no obvious condo, co-op, tax-class-1, or condo billing-lot unit churn records.

ACRIS matches require the same opportunity BBL and an event date within 14 days of
the DOF sale date. Price agreement is then used to classify whether the link is an
exact/close recovery, an excluded reviewed ACRIS transfer, or a price conflict.
