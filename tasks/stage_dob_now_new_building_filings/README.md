# Stage DOB NOW initial New Building filings

This task reads the frozen DOB NOW extracts and writes a typed filing-history
table plus a table containing one row per initial filing. Amendment identifiers
can repeat in the source history; its observation is a source record, keyed by
source pull date and the retained source row number. It normalizes job numbers, dates, BBLs, unit counts,
and total construction floor area. The script fails if initial job numbers are
not unique.

The staged data retain two distinct lot identifiers. `filing_bbl` is constructed
from the filing's explicit borough, block, and lot fields. `reported_bbl` is the
separate BBL field supplied by the Open Data extract. `bbl_field_relation`
records whether the two agree, disagree by lot, block, or borough, or whether
one is missing. Downstream tasks must select the measure appropriate to the
linkage or construction question rather than coalescing them into an ambiguous
BBL.

`total_construction_floor_area` is the proposed project's gross construction
area reported by DOB. The source does not contain proposed residential floor
area, apartment size, bedroom count, or amenity space.
