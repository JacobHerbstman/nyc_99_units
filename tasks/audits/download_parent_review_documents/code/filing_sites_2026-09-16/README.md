# DOB filing-site fields and dated Flatbush records

`bis_site_fields.json` preserves fields read from 17 public DOB BIS application
pages on September 16, 2026. These filings belong to 14 historical parents in
the parcel audit. They were selected to investigate missing physical-base
identifiers and implausibly small land measurements; this is not a random
sample or a complete review of the 166 flagged parents.

The file is a structured browser transcription, **not a JSON download supplied
by DOB**. Each observation retains its job number, address, source URL, and
observation date. The browser extraction read the displayed text in Section 12
(zoning lot numbers and zoning lot area) and Section 17 (original tax lots being
merged/reapportioned and tentative tax lots). Page job numbers were checked
against requested jobs. Five-digit lot strings are preserved. Blank original
lot fields and `Not Provided` zoning lists remain missing information.

The pages show current application details and can incorporate amendments.
Their fields are not proof of what was on the initial filing form. Original
tax-lot lists also do not prove that the full area of every listed lot was
assigned to the residential building. The audit joins the listed lot numbers
to the filing's block from the Housing Database. That assumes the printed
numbers refer to the filing block; full zoning diagrams are needed where a
site crosses blocks. Shared zoning lists are flagged, not treated as authority
to merge parents or duplicate the full zoning area across filings.

Direct public-page HTTP requests returned 403. The browser allowed the initial
17 reads, then denied subsequent access. No authenticated or restricted source
was used. There is no automated acquisition recipe for this transcription;
the committed file is the reproducible input. A future refresh must retain a
new dated capture and compare changes explicitly. `compare_bis_site_lots.R`
consumes this file through a local symlink and writes comparison datasets.

## Flatbush supporting records

`../filing_sites.make` downloads three official PDFs into the acquisition
task's `output/` using literal URLs, validates that they are PDFs, and publishes
only completed transfers. Ordinary builds reuse the saved files. The companion
`sources.sha256` records the September 16 fingerprints of these PDFs and the
JSON transcription (the PDFs live in `output/`, not this source folder).

- **NYCIDA, May 12, 2020 board minutes**, PDF page 41: the residential tower's
  leased site is 12,603 square feet and the school site is 26,981 square feet.
  Page 49 identifies these as block 174, lots 23 and 13 respectively. Source:
  <https://publicmarkets.nyc/sites/default/files/2020-08/IDA%20Board%20of%20Directors%20Meeting%20Minutes%20May%2012%202020.pdf>.
- **DOF tax map effective December 9, 2008**, used through January 7, 2020:
  <https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/30017420081209172959>.
  Shows the earlier, small lot 23 alongside lots 18 and 24.
- **DOF tax map effective February 12, 2020**, used through September 8, 2021:
  <https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/30017420200212111425>.
  Shows the larger replacement lot 23 and adjacent school lot 13.

The frozen DOF transaction data identify merger 88954 and apportionment 88955
on February 12, 2020. They drop and recreate lot 23 with a different boundary.
Condominium declaration 93764 subsequently connects the tower's base lot 23
to its condominium records. These transactions explain why joining an old
map on the same lot number retrieves the wrong footprint.

DOB job 321595145 displays original lots 18, 23, and 24, tentative lot 23,
and a larger zoning site of 61,399 square feet. Its earliest listed zoning
drawing is dated April 6, 2020 (scan ES424524337); the viewer wrapper loaded
but the embedded scan did not. The original drawing was **not inspected**.
The filing lists zoning-exhibit CRFNs 2020000111750, 2020000111751,
2019000354353, and 2019000354354. These remain leads for documenting allocation
within the shared site, rather than inspected boundary instruments.

All captured areas remain comparison evidence. This source record authorizes
no replacement of production areas, parent links, units, or weights.
