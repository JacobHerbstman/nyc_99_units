# School-parcel boundary sources, acquired 2026-09-20

This folder supports the two-case note
[`site_research_followup_schools.md`](../../../audit_hdb_mappluto_condo_recovery/report/site_research_followup_schools.md).
It does not feed the production panel or change reviewed parent decisions.

`fetch_focus.py` retrieves the cited City Register ACRIS index rows and
the DCP PLUTO parcel rows through NYC Open Data, saving the raw API response
bytes. Run `python3 fetch_focus.py` from this folder to refresh them and
regenerate `sources.csv`. The manifest gives the exact URL, acquisition date,
byte count, and SHA-256 for each saved source. The ACRIS index is a finding
aid; the image exports of original deed instruments are decisive for legal
parcel descriptions.

The deed PDFs are ACRIS browser **Save All** exports of the City Register
TIFF images, acquired on 2026-09-20. They are PDF renderings of the
recorded instruments, not native text PDFs; page numbers in the note
refer to these exported PDFs. The residential ZD1 is the direct architect
PDF served from the URL in the manifest. Its plan dates and its acquisition
date are different facts.

The [SCA supplemental environmental
study](https://www.nyc.gov/assets/bronxcb8/pdf/2022/Proposed-PS_160-VCPS-BX-EAF-Supp-Report-rev-61622.pdf)
was accessible through the web reader. Direct download from the official
host returned HTTP 403 on 2026-09-20, so it is linked and quoted with page
references in the note but no local original or hash is claimed here.

## Independent area check from the Brooklyn deed courses

The two Brooklyn deed Schedule A descriptions (PDF p. 3 of each export)
describe complementary parcels. For residential lot 1, the Shell Road
and opposite east-side courses are parallel, 284.57 and 241.61 feet long.
The 205.17-foot cross-course meets Shell Road at 90° 06′ 42.1″. Its
trapezoid area is

`(284.57 + 241.61) / 2 × 205.17 × sin(90° 06′ 42.1″) = 53,978.07 square feet`.

This independently reproduces current PLUTO's **53,978-square-foot** lot 1
area to its reported whole-square-foot precision. Neither deed actually
prints an area, and deed dimensions are rounded to hundredths of a foot.

For school lot 50, put the Neptune/West 6th Street corner at `(0, 0)`.
Schedule A moves 78.50 feet west; its 241.61-foot north course makes an
interior angle of 78° 03′ 57″ with the Neptune line. The next 73.94-foot
east course turns 89° 53′ 17.9″ right, the supplement of the printed
90° 06′ 42.1″ interior angle. The resulting four vertices, in feet,
are approximately `(0, 0)`, `(-78.50, 0)`, `(-28.538, 236.388)`, and
`(43.833, 221.239)`. The shoelace area is **17,615.93 square feet**;
the implied final side length is **225.5395 feet**, matching the deed's
printed 225.54 feet. This independently agrees with current PLUTO's
**17,615-square-foot** lot 50 within one square foot, well inside the
precision of the deed's rounded courses. It does not make the current
parcel areas the 2021 historical filing area.
