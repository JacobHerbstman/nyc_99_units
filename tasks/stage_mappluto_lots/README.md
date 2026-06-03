# Stage MapPLUTO Lots

Cleans raw MapPLUTO lot caches into canonical lot-level release tables with stable fields used by downstream prediction tasks.

The staged releases are the source of lot-level predictors. Downstream model tasks must still choose the correct as-of vintage before using these fields.
