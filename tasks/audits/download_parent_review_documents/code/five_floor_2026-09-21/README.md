# Five remaining floor allocations, September 21, 2026

The literal official NYC DOF property-description query is in `../five_floor.make`.
It requests block 3466 successor lots 30 and 58, the land and gross-floor fields,
building count/class, and tax year. The unchanged JSON is published to
`output/onderdonk_floor_2026-09-21.json` after verifying `sources.sha256`.
The endpoint is mutable; the recorded extract is reused by ordinary builds.

There are two unique, nonmissing PARID keys and both rows say tax year 2028.
Lot 30 reports land and gross floor of 9,310; lot 58 reports both as 3,908.
Both classes are K1. NUM_BLDGS is blank for 30 and 1 for 58. Their total floor,
13,218, is 5,440 below frozen 2023 MapPLUTO BldgArea of 18,658 on predecessor
58, which was class K2 and two stories. These are later administrative rows,
not proof of how 2023 floor was distributed or when the difference arose.

The September 21-22 continuation adds HCR's corrected December 2018 Kingsbrook
drawings and December 21 addendum. Literal download URLs and checksums are in
the same Makefile and checksum file. Reviewed physical pages 1-9 of the drawings
include the north-campus building footprints and the floor schedule on page 9.
The four buildings sum to 214,280 gross square feet including 35,245 basement
square feet; 179,035 excludes the basements. The power plant is outside this
schedule. The addendum explicitly corrects the Leviton and LeFrak values in the
original RFP. The drawing cover describes owner-provided approximate plans;
these are not a new survey or proof of an unchanged 2023 assessment definition.

Two further checksum-pinned DEC documents were acquired on September 22:
`kingsbrook_phase_I_esa_2025.pdf` (June 24, 2025; 2,793 pages) and
`kingsbrook_rawp_2026.pdf` (June 1, 2026; 2,996 pages). The ESA's physical
pp. 10, 12–13, and 37 identify the earlier pavilions and the 11,600-square-foot
power plant with cellar. Its broader study site is not the current housing
boundary. RAWP pp. 21–23 identify the current phase; pp. 129–130 reproduce
BLD's July 23, 2021 survey, and pp. 131–132 give the Phase I legal courses.
The survey labels the west plant bay “1 story & mezzanine.” The audit records
a manual polygon tracing and uses the printed 460-foot frontage as its scale;
the drawing does not give the actual mezzanine area or a cellar partition.

The other original records were already acquired. The decision note at
`../../../audit_hdb_mappluto_condo_recovery/report/five_floor_decisions.md`
links their existing packets and records the reviewed pages. No primary PDF
or administrative dataset is rewritten by this review.
