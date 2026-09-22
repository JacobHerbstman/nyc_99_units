# DOF parcel coverage, September 15, 2026

**166 of the 877 parents currently used for weighting still have a parcel-review
flag after the citywide DOF pass.** The other 711 pass this administrative screen.
Passing the screen establishes a coherent candidate parcel set; it does not
independently verify the development boundary, ownership before the policy, or
the legal wage-assessment unit.

| Current weighting sample | Parents | No remaining screen flag | Need review |
| --- | ---: | ---: | ---: |
| Historical, 2019–2022 | 561 | 441 | 120 |
| Post-policy, 2025–July 8, 2026 | 316 | 270 | 46 |
| Total | 877 | 711 | 166 |

We also include the 18 otherwise eligible parents currently excluded by the
composition/identifier requirements. Four pass the DOF screen and 14 have a
flag. **The broader review therefore contains 895 parents, with 180 flagged.**
Passing the parcel screen does not remove another reason for excluding a parent.

## What remains

The following reasons are mutually exclusive, using the priority stated in
`trace_parent_parcels.R`. The coverage file retains every underlying flag,
including overlapping issues and the two historical parents spanning reference
vintages.

| Primary reason | Current 877 | Broader 895 | What DOF leaves unresolved |
| --- | ---: | ---: | --- |
| Parent covers only part of a lot-change transaction | 149 | 155 | Which part of the earlier land belongs to this parent |
| Candidate lot absent from its reference PLUTO release | 5 | 13 | Earlier identity, proposed lot number, or reference-map coverage |
| Several condominium base lots | 3 | 3 | How much of the condominium land belongs to the proposed development |
| Other physical change | 5 | 5 | Boundary edit or incomplete lot action set |
| Unexplained HDB–DOB lot disagreement | 4 | 4 | Which administrative parcel identifier describes the site |
| Total | 166 | 180 | |

These are review flags, not 180 confirmed errors or 180 cases requiring manual
adjudication. The largest group is suited to a systematic comparison of parcel
geometry and dated maps. A transaction can split one old lot into two new lots
while our parent names only one. Adding the whole old lot would then count land
belonging to the other new lot. The code retains the uncertainty.

The four administrative disagreements concern 473 West 165 Street, 35-53 41
Street, 27-30 21 Street, and 5-20 46 Road. For example, DOB names Queens block
670 lot 4 for 35-53 41 Street; HDB names lot 47. Neither a shared condominium
base nor a fully covered DOF transaction establishes their equivalence in this
extract. The audit does not select a winner.

## What the automatic reconstruction finds

Among the currently included parents that pass the screen, **257 have a different
candidate land area from production: 196 historical and 61 post-policy parents.**
One additional historical parent outside the current weighting sample also has
a different area. This shows that full parcel recovery matters well beyond the
five conspicuous stacks of 99s. These candidate areas have not been adopted as
final characteristics; the main panels, weights, and model results were not
rewritten by this audit.

| Previously examined parent | General DOF rule returns | Reference land area | Remaining parcel issue |
| --- | --- | ---: | --- |
| Wyckoff/Bergen | Old lots 19, 42, 51 | 50,692 sq. ft. | No flag from this screen |
| 4121/4133/4137 Third Avenue | Old lots 27, 30, 31, 35, 135 | 22,247 sq. ft. | No flag from this screen |
| Bruckner/Brook/East 132nd | Lots 1, 34, 38 | 28,700 sq. ft. | No flag concerning the combined land footprint |
| Sullivan/Empire | Filing lots 20, 25, 28, 30 | Incomplete | Proposed lots absent from the reference map and completed DOF lineage |
| Jamaica/165th Street | Six condominium base lots plus 98 and 99 | 111,540 sq. ft. associated with the site | Extent of the six residential proposals within this land |

Wyckoff's transaction 303740 recovers the three old lots. Third Avenue's
transaction 474542 recovers all five, including the 108-square-foot lot 135.
The code contains no project-specific BBL, parent ID, address, or acceptance
table. These are checks against previously inspected evidence, not cleaning
exceptions. Bruckner's result concerns the combined land area and does not
verify the proposed internal lot boundaries or separate wage assessment.

## Sources and calculation

`fetch_dof_tax_map_history` owns nine frozen citywide source tables, comprising
1,589,845 source rows. The ZIPs preserve 484 unmodified API responses, including
schema, page, and ID-list responses, with exact URLs and SHA-256 hashes. The
headers identify 39,777 transactions. The source task also saves the current
condominium/base/unit relationships, dated map index, and complete application
tracker. Its README documents the public URLs and replication snapshot.

The two R scripts perform the following operations:

1. Collapse identical transaction metadata and check that each transaction has
   one description and timestamp. Join the complete lot-action rows to that
   description with a checked many-to-one join.
2. Represent each event as explicit old and new parcel sets. Affected lots occur
   in both sets; Dropped lots occur in the old set and New lots in the new set.
   Use explicit New/Dropped actions even under a generic DOF editor label.
   Separate timestamps order edits occurring on the same date.
3. Expand condominium identifiers through DOF base-lot relationships. PLUTO 25v4
   condominium numbers link terminated billing lots to their DOF history. These
   are retrospective identifier links; covariates still come from the earlier
   reference release. Multiple-base sites retain a scope flag.
4. Trace each parent backward through the relevant transaction chain. Reverse
   an event only when the parent's parcel set covers its complete new-lot set.
   Keep partial or incomplete events flagged. A historical parent's reference
   release remains filing-specific; post-policy parents use PLUTO 23v3.1, whose
   recorded availability date is December 28, 2023.
5. Join the resulting parcels to that reference PLUTO release and count each
   parcel once per parent and vintage. Compare DOB and HDB identifiers using
   the condominium aliases and fully reversed events. Attach matching
   application IDs and dated reference-map IDs for further review.

Condominium unit identifiers can be associated with several base lots or
different historical configurations. The audit retains those associations as
a set and flags multiple-base scope rather than selecting one arbitrarily.
Three malformed source link identifiers remain in the cleaned link table with
`valid_bbl = FALSE`; they cannot match a filing. The application tracker's free
text contains malformed identifiers as well as ranges. The parser extracts
complete BBLs and valid same-block ranges; application links are supporting
evidence and never authorize a footprint change.

## Reproduce and inspect

From the repository root:

```sh
make dof-parcel-audit
```

- `output/dof_parent_coverage.csv`: one row per reviewed parent, including
  addresses, candidate BBLs, area comparisons, all flags, transaction IDs,
  application IDs, and dated map IDs.
- `output/dof_parent_parcels.parquet`: one row per parent, reference vintage,
  and candidate parcel, with the matched PLUTO characteristics.
- `output/dof_coverage_summary.csv`: the mutually exclusive counts above.

Open a dated DOF map using
`https://propertyinformationportal.nyc.gov/pdf/home/index/map_library/<map ID>`.
The full map index and source application table are local audit inputs.

Verification covered all source hashes and ID sets, unique join keys, the
previously examined parcel sets, unchanged builds, and regeneration of missing
actual outputs under GNU Make 3.81 with `-j4`. A temporary two-page HTTP fixture
verified successful acquisition and preservation of the previous snapshot on
an ArcGIS error or checksum mismatch. Reports are SaveData side effects, never
Make targets. No estimation was run. The source ZIPs must accompany a replication
package because the live DOF service is mutable.
