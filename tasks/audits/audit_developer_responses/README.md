# Developer Response Audit

This audit is the first descriptive input to the static developer-choice model.
It produces four figures:

1. application-level and provisional site-level unit histograms;
2. total construction and proposed residential floor area versus units;
3. total construction square feet per dwelling unit versus units; and
4. distinct buildings and initial applications per provisional site.

The historical unit histogram uses the DCP Housing Database. Physical-design
figures use initial (`-I1`) DOB NOW New Building filings, because that source
reports proposed dwelling units and total construction floor area.

The main unit histogram follows the earlier bunching-audit style: separate
pre/post panels, free vertical scales, and five-unit gray bins over 50--150
units. A supplemental wide-range histogram preserves the provisional-site mass
at 198, 297, and 396 units.

## Measurement limits

A `BBL x filing year` group is a provisional tax-lot site, not a legally
validated 485-x eligible site. The statute can also group multiple eligible
multiple dwellings on a zoning lot when they are part of one application. Tax
lots can also change through subdivision or consolidation. The audit therefore
does not merge adjacent lots or call repeated 99-unit filings a confirmed legal
split.

DOB NOW does not report proposed residential floor area, apartment sizes,
bedroom mix, or amenity space. The second figure makes the residential-area gap
visible. The third figure uses total construction square feet per dwelling unit
and labels it as a gross construction measure, not apartment size.

Run the task from `code/` with `make`. The Makefile exposes all sample years and
unit-count display ranges as scalar analytical choices.
