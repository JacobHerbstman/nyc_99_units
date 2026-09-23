# 355 Exterior Street source packet

This folder preserves the primary records used to identify the ground for DOB job `210182069`. `sources.csv` records the public URL, acquisition date, byte count, SHA-256 hash, and source-specific dates for every file.

The DOB Virtual Job Folder did not expose its PDF bytes to command-line requests: the content servlet returned HTTP 403, and the in-app browser rendered a blank embedded document. The complete PD1 and ZD1 scans were therefore opened through the public DOB content servlet in a dedicated Safari window and saved with Safari's PDF `Save As` command on 2026-09-21. The saved files retain the DOB job number and scan code. The relevant content URLs are:

- PD1: `https://a810-bisweb.nyc.gov/bisweb/BSCANJobDocumentContentServlet?passjobnumber=210182069&scancode=ES079163428`
- ZD1: `https://a810-bisweb.nyc.gov/bisweb/BSCANJobDocumentContentServlet?passjobnumber=210182069&scancode=ES615641380`

The three exchange deeds were exported in full from the public ACRIS document viewer on 2026-09-21. The DEC remedial action work plan was downloaded directly from the agency file listing. The 2023 DOF map and the recorded zoning declaration are byte-identical copies of originals already acquired in the supervised Bronx source folders; their original acquisition dates remain in the register.

The simple area check for the part of old lot 38 conveyed by ACRIS document `2021091800077018` treats the short final road curve as its chord. Converting the eight stated courses to Cartesian coordinates gives approximately **3,284.88 square feet** and closes within 0.014 feet. This is a check on the legal description, not the adopted ground area. Adding that estimate to the 20v5 administrative areas of old lots 46, 47, and 100 gives 123,955.88 square feet, 3,683.88 above the later 120,272-square-foot lot. The old administrative areas and the legal reconfiguration therefore should not be treated as exact additive survey measurements.

