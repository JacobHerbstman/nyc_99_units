# Broader site-review follow-up, September 20, 2026

This folder holds **newly retrieved** original City Planning PDFs for the GO
Broome review and a saved first-party architect page for Chatterton/Olmstead.
The retrieval used the publishers' literal URLs below. The PDF and HTML bytes
were saved unchanged. `go_broome_deis_site_plan_p13.png` is a rendered
inspection aid made from physical PDF page 13, not a separate source.

| Saved original | Publisher and URL | Pages inspected |
| --- | --- | --- |
| `go_broome_deis_ch1.pdf` | NYC Department of City Planning, [GO Broome DEIS Chapter 1](https://www.nyc.gov/assets/planning/download/pdf/applicants/env-review/go-broome/01-deis.pdf), downloaded September 20, 2026 | PDF pages 2–3, 13, 19–22 |
| `go_broome_cpc_200061a.pdf` | NYC City Planning Commission, [C 200061(A) ZSM decision](https://www.nyc.gov/assets/planning/download/pdf/about/cpc/200061a.pdf), downloaded September 20, 2026 | PDF pages 1–7, 35–36, 48 |
| `bruckner_heights_aufgang.html` | Aufgang Architects, [Bruckner Heights project page](https://www.aufgang.com/portfolio/bruckner-heights/), captured September 20, 2026 | HTML paragraph naming the two buildings, units, and shared amenities |

`sources.sha256` fingerprints the saved originals and the derived image. The
DEIS plan was rendered with `pdftoppm -f 13 -l 13 -scale-to 1800 -png
-singlefile`. The files support the source note in
`audit_hdb_mappluto_condo_recovery/report/site_research_followup_broader.md`.
The other cases there use previously saved originals, cited by exact path.
The two DOF Chatterton/Olmstead maps and assessment API response were already
saved and were re-inspected without duplicate copies.

An attempted download of DEC's 37 MB Site B RAWP timed out after 30 seconds.
The incomplete response was deleted; no RAWP page is treated as inspected.
The saved DEC Site B application remains the source for that case.
