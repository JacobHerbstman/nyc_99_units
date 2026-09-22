# Flatbush land and earlier floor: adopted September 21, 2026

The 441-unit historical parent `historical__321595145` now uses **12,603 square
feet of land** and **39,929.757 square feet of estimated earlier building floor**.
Jacob explicitly approved the flagged estimate after considering its uniform-density
assumption and the weighting sensitivity. The remaining five held land cases and
the broader review inventory are unchanged.

## What is measured and what is estimated

NYCIDA's May 12, 2020 minutes, physical PDF pp. 41 and 49, identify a
12,603-square-foot tower ground lease separately from the school ground.
Later MapPLUTO records the same tower area. The earlier production match to
lot 23 alone supplied only 1,198 square feet; the parcel number was reused for
a different boundary after subdivision.

The 18v2_1 administrative records contain:

| Earlier lot | Recorded land | Recorded building floor | Tower allocation |
| --- | ---: | ---: | --- |
| 18 | 12,240 | 35,580 | 61.3821169% of mapped land overlaps |
| 23 | 1,198 | 2,450 | Entire lot |
| 24 | 3,093 | 15,640 | Entire lot |

The reviewed floor estimate is **2,450 + 15,640 + 35,580 ×
0.613821169178864 = 39,929.757**. Excluded floor is 13,740.243;
built FAR is 39,929.757 / 12,603 = **3.168274**. The mapped overlap ratio
comes from the existing official parcel overlay; the recorded land areas and
polygon areas are distinct measurements.

NYC ECF's February 2018 DEIS Part 2, physical PDF p. 118, describes lot 18's
three-story building with frontages on Flatbush Avenue and State Street.
Part 3, physical p. 1 (Figure 8-5), photographs it and distinguishes the
neighboring two-story lot-23 and five-story lot-24 buildings. This supports a
roughly uniform-height approximation. It does **not** prove equal floor density
across lot 18 or measure the exact partition through the earlier building.

The reasonable objection to adoption was that it introduces an estimated
covariate where a measured allocation was unavailable. The approved choice
keeps the project with a transparent approximation. A plan establishing a more
precise partition could replace it later. No unit count, date, or parent link
is changed, and frozen residential FAR 10 and commercial prior use are preserved.

## Consequences for weighting

The bounded sensitivity keeps all parents, outcomes, and calibration moments
fixed. It changes only Flatbush's land and earlier floor:

| Floor allocation on corrected land | Built FAR | Reweighted historical share at 99 | Weighted historical mean units |
| --- | ---: | ---: | ---: |
| None of lot 18's floor | 1.43537 | 1.355248% | 151.3958 |
| Adopted proportional allocation | 3.16827 | 1.354308% | 151.4872 |
| All of lot 18's floor | 4.25851 | 1.353476% | 151.5662 |

The extreme allocations span **0.001772 percentage points** in the reweighted
99-unit share and **0.1704 units** in the weighted historical mean. These are
sensitivity bounds, not plausible equally likely measurements or statistical
confidence intervals. The former small-parcel match yielded a 1.354249% share
and 151.7519 mean units. The floor uncertainty and the land correction therefore
have distinct effects; neither changes the observed 99-unit share.

## Sources and reproduction

- [NYCIDA May 2020 minutes](https://publicmarkets.nyc/sites/default/files/2020-08/IDA%20Board%20of%20Directors%20Meeting%20Minutes%20May%2012%202020.pdf), pp. 41 and 49.
- [ECF DEIS Part 2](https://infohub.nyced.org/docs/default-source/default-document-library/deis__ecf_80_flatbush_avenue_part2.pdf), p. 118.
- [ECF DEIS Part 3](https://infohub.nyced.org/docs/default-source/default-document-library/deis__ecf_80_flatbush_avenue_part3.pdf), p. 1.
- Saved archive rows and geometry: `site_research_covariates_2026-09-21_campus/` in the document acquisition task.

The existing manual source table supplies the accepted allocation and
`built_floor_area_estimated = TRUE`. The site-characteristics producer and
canonical parent panel carry that flag. Main code contains no Flatbush branch.
Root `make flatbush-floor-review` builds the main panel, retrieves the pinned
DEIS PDFs, and writes the four-scenario sensitivity table and its SaveData report.
Root `make`, `make pure-notch-pilot`, and `make logbook` refresh their consumers.
