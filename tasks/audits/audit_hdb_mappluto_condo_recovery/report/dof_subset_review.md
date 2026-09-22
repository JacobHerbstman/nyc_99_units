# Land-area discrepancies in twelve randomly selected flagged parents

Updated September 21 after the Godwin/Kimberly merger. The selected IDs remain
fixed; this comparison uses their current parent definitions and production areas.

Among ten cases with a usable mapped-parcel comparison, mean recorded area is
50,153.7 square feet and mean comparison area is 33,345.5 square feet: a decrease
of **16,808.2 square feet per parent, or 33.5% of the original mean**. Six areas
decrease, three increase, and the implemented Godwin area agrees. The mean absolute difference is 23,000.8 square
feet; the median absolute percentage difference is 55.4%.

These are **footprint comparisons**. Godwin's reviewed allocation is now adopted;
the other comparisons retain their stated provisional status. We compare the current production area with the sum
of published PLUTO 25v4 `LotArea` values for the mapped filing parcels, checked
against DOF transaction histories and dated maps. For the ten comparisons,
PLUTO and the saved DOF geometry (September 15, plus Godwin lot 88 on September 21) agree on more than 99.99% of their union.
PLUTO derives its geography from DOF, so that agreement is a consistency check
between releases, not independent confirmation. It does not establish the land
available at the initial filing date or the full economic development site.
The [subsequent measurement check](dof_area_validation.md) uses assessment
history, printed dimensions, and recorded boundary descriptions.

The draw uses seed 20260915 after sorting the 166 composition-eligible flagged
parents by ID: nine historical and three post-policy parents, sampled separately.
Eleven have a partial lot-change flag, compared with 149 of the 166 overall.
Two of the twelve remain unresolved and are excluded from the averages, leaving
eight historical and two post-policy comparisons. This small conditional sample
does not provide a reliable average correction for all 166 or a borough effect.

| Parent address | Production sq. ft. | Mapped filing parcels sq. ft. | Change |
| --- | ---: | ---: | ---: |
| 1701 Purdy Street | 32,350 | 39,507 | +22.1% |
| 393 Weirfield Street | 3,050 | 19,341 | +534.1% |
| 11 Gerry Street | 111,040 | 18,044 | −83.8% |
| 265 Lorimer Street | 45,129 | 34,411 | −23.7% |
| 94-15 Sutphin Boulevard | 60,138 | 30,071 | −50.0% |
| 1166 Fox Street | 2,500 | 10,015 | +300.6% |
| 2070 Chatterton Avenue | 60,979 | 21,133 | −65.3% |
| 2123 Glebe Avenue | 22,790 | 8,952 | −60.7% |
| Godwin/Kimberly | 18,441 | 18,441 | 0.0% |
| 1920 Turnbull / 1933 Lafayette | 145,120 | 133,540 | −8.0% |
| 565 Sackett Street | 38,500 | Unresolved project extent | — |
| 10 Noble / 41 Oak | 252,780 | Full tax-lot versus onshore site area | — |

The percentage change in the mean is
`100 × (33,345.5 / 50,153.7 − 1) = −33.5%`. This differs from averaging each
parent's percentage change, which gives **+56.5%** because Weirfield and Fox start
with very small production areas. The median signed percentage change is −15.9%.
The historical mean falls 46.3% across eight comparisons; the post-policy mean
falls 7.1% across two. Neither subsample is large enough to characterize its period.

The substantive problems are visible in the maps. Gerry inherits the complete
old lot even though its filing parcel occupies only the western portion. Its
DOF dimensions give approximately `(28.33 + 152.12) × 200 / 2 = 18,045` square
feet, consistent with PLUTO's 18,044. Fox uses an old 2,500-square-foot parcel
number that was retained after a merger and reapportionment; the mapped parcel
measures `100 × 100.15 = 10,015`. Weirfield also reuses a parcel number after a
merger and reapportionment. A BBL match alone therefore does not establish that
the land associated with that identifier is unchanged.

Sackett's September 2025 map assigns 12,500 square feet to filing lot 47. The
[March 2026 NYSDEC amendment](https://extapps.dec.ny.gov/data/DecDocs/C224222/Agreement.BCP.C224222.2026-03-18.Amendment_No3_Multiple_Changes_563%20Sackett%20Street.pdf)
describes lots 17 and 47 together after removing lot 16. DOF subsequently merges
47 into 17 in August 2026, after the July 8 endpoint. The parcel-only number is
not sufficient to assign a footprint to the original 300-unit filing. Noble's
proposed lot 10 is missing from the available maps. The June 2026 CB1 notice
explicitly documents a proposed division of lot 1 into lots 1/10 and a
173,834-square-foot site. Shoreline clipping explains the large difference
between its DOF and PLUTO geometries. These two parents remain outside the
averages while the original filing footprint and area definition are settled.

The output also records a diagnostic that distributes each earlier `LotArea`
attribute in proportion to polygon overlap. It is not the adopted comparison
area. At Godwin, the earlier lot's recorded area differs materially from its
polygon area; proportional allocation gives about 8,075 square feet, whereas
PLUTO records 12,541 for the mapped new parcel. Spatial matching alone therefore
does not repair every source attribute.

Reproduce with `make dof-subset-review`. The linear script is
`code/measure_dof_subset.R`; `code/dof_subset_review.csv` preserves the twelve
review notes, transaction IDs, exclusions, and map IDs. The outputs are
`output/dof_subset_comparison.csv`, `output/dof_subset_summary.csv`, and the
twelve-page `output/dof_subset_footprints.pdf`. The comparison table keeps
unresolved rows and their observed partial matches. Source bytes and download
rules belong to `download_parent_review_documents`; existing PLUTO archives
belong to `fetch_mappluto_archive`. Production panels, weights, and model fits
are unchanged by this review.
