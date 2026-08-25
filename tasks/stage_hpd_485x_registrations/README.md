# Stage HPD 485-x registrations

This task converts the frozen HPD registration snapshot into a typed parquet
file with one row per submitted form response. It standardizes BINs, BBLs,
dates, unit counts, and DOB NOW or BIS job identifiers without collapsing
repeated submissions or assigning legal Eligible Sites.

Repeated-response handling and DOB linkage are intentionally left to the
registration-linkage audit.
