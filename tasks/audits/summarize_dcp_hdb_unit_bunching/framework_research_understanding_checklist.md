# Framework Research Understanding Checklist

## Session Goal
- [x] Current research question: use the 99-unit response to learn how developers respond to the 485-x threshold and what crossing, redesign, and legal splitting costs rationalize those choices.
- [x] Current scope: developer behavior only; renter welfare, general equilibrium, and full social-welfare accounting are deferred.
- [x] Researcher restatement: first measure the wage differential and project-design response, then estimate pre-policy primitives and test whether the model can reproduce post-policy bunching and splitting.
- [ ] Mastery status: restated; minimal model and empirical objects now defined, parameter ownership still to be reviewed.

## Stage 1: What The Histogram Establishes
- [x] Current unit: a DCP Housing Database New Building filing, not yet an eligible site, permit, completion, or confirmed 485-x applicant.
- [x] Current descriptive fact: 55 exact 99-unit filings in 2025 versus 15 total in 2010--2023.
- [x] Preliminary filing-level mass balance: after scaling the pre-period shape to 2025's 50--94 volume, excess 95--99 mass is about 55 filings and missing 100--150 mass is about 56.
- [x] Site warning: 15 of the 55 exact-99 filings occur on six repeated BBLs; a legal-site reconstruction can materially change both masses.
- [ ] Reconstruct the statutory eligible-site/application unit before structural interpretation.
- [ ] Estimate a post-policy counterfactual distribution rather than treating raw pre-period annual counts as latent desired sizes.

## Stage 2: Minimal Developer Choice Model
- [x] The quadratic notch algebra in the framework is internally correct under its assumptions.
- [x] Start from four losses relative to the latent preferred design: cross the threshold, redesign to 99, legally split into sub-100 sites, or delay/exit.
- [x] The developer chooses the smallest loss: `min{crossing cost, redesign cost, splitting cost, delay/exit cost}`.
- [x] Use revealed-preference inequalities before point identification: a buncher reveals redesign is cheaper than crossing; a valid splitter reveals splitting is cheaper than the alternatives.
- [ ] Decide after the first cost audit whether the empirical goal is a bound/set or a point estimate.
- [ ] Separate the known statutory schedule from unknown labor hours, counterfactual compensation, redesign curvature, split fixed cost, and idiosyncratic choice shocks.
- [ ] Treat delay and exit only after the static filing/design model fails or the timing evidence requires dynamics.
- [x] A no-485-x project at 100+ does not appear to avoid the statutory construction-wage rule; the adopted Comptroller rule defines any otherwise eligible 100+ site as a Covered Site.
- [ ] Replace the two-option Modest-versus-Large comparison with the best below-threshold and best above-threshold value envelopes.

## Stage 3: Construction-Wage Notch
- [x] The 485-x rule is a compensation floor, not a mandate to hire union labor.
- [x] The 100--149-unit floor is $40.00 from July 2024, $41.00 from July 2025, and $42.03 from July 2026; the applicable rate follows when covered work occurs, not the filing date.
- [x] Qualifying hourly compensation combines cash wages and permitted supplements; up to half may be supplied as benefits, while payroll taxes do not satisfy the floor under the Comptroller FAQ.
- [x] Direct wage exposure is the trade-by-time sum of covered hours times the positive gap between the statutory floor and counterfactual qualifying compensation.
- [ ] Add payroll-tax, insurance, overtime, subcontractor-markup, compliance, and productivity effects to translate the payroll gap into the developer's bid-cost increment.
- [ ] Obtain credible counterfactual compensation for comparable sub-100 residential projects; aggregate BLS means are benchmarks, not the answer.
- [ ] Obtain project-level covered labor hours and occupational shares from certified payroll, contractor budgets, or a developer/GC data partnership.

## Stage 4: Statutory Private-Cost Ledger
- [ ] Affordable-rent revenue gap.
- [ ] Construction-wage increment for covered work.
- [ ] Filing-fee increment.
- [ ] Incremental tax-benefit value favoring the Large tier.
- [ ] Fixed compliance, monitoring, M/WBE, financing, and enforcement-risk costs.
- [ ] Confirm every component at the eligible-site level and by expected construction/lease-up date.
- [ ] Model both statutory affordable-bedroom-mix branches (proportional mix or the family-size alternative), or use approved project workbooks.

## Stage 5: Building Design And Splitting
- [x] DOB NOW initial New Building filings contain proposed units, total construction floor area, stories, height, owner/applicant identifiers, dates, and status.
- [x] A preliminary 2025 filing-level check does not show exact-99 filings having unusually large gross square feet per unit relative to the few 100--150 filings; this is descriptive and not a matched counterfactual.
- [ ] Decompose the response into predicted building size and predicted unit density using pre-policy sites: `counterfactual units = counterfactual residential floor area / counterfactual square feet per unit`.
- [ ] Use approved plans, schedules of occupancy, or workbooks to measure residential floor area, bedroom mix, parking, elevators/cores, and amenity space; total construction floor area alone is insufficient.
- [ ] Define a valid split only when separate filings truly create separate eligible sites; multiple 99-unit filings on one tax lot may still form one 100+ covered site.
- [ ] Track initial filing, approved design, permit, commencement, amendments, and completion separately.

## Stage 6: Affordability Rent Path
- [x] Initial marketing band deducts three percentage points from the applicable AMI band.
- [x] Permitted rent is capped by the minimum of legal rent, comparable same-site market rent, and the AMI/utility-allowance cap.
- [ ] Simulate that minimum-cap path under rent stabilization; do not use unconstrained historical-growth perpetuities.
- [ ] Compare current NOI capitalization with finite-horizon discounted-cash-flow sensitivities.

## Stage 7: Behavioral Accounting
- [ ] Bunching/downscaling.
- [ ] Multiple-filing or site splitting.
- [ ] Larger-unit substitution at roughly fixed square footage.
- [ ] Delay from filing to commencement/permit/completion.
- [ ] Exit/nonconstruction.
- [ ] Keep project counts, dwelling units, and housing square footage as separate accounting units.

## Deferred Stage: Incidence And Welfare
- [ ] Developers and landowners: separate short-run developer quasi-rents from long-run land capitalization.
- [ ] Market renters: translate net units/square feet lost into rent and consumer-surplus effects using explicit demand/supply assumptions.
- [ ] Affordable renters: value restricted units actually created and the lottery/rent discount.
- [ ] Construction workers: wage gains net of employment displacement and real compliance costs.
- [ ] Fiscal authority: tax expenditure, administration, and any marginal cost of public funds.
- [ ] Total surplus: classify transfers separately from resource costs and avoid counting land capitalization twice.

## Open Research Decisions
- [ ] Can Comptroller commencement notices identify unit counts, dates, and PLA/CBA exclusions for all covered sites?
- [ ] Can certified payroll or contractor records identify the occupation-weighted counterfactual wage gap and covered hours?
- [ ] Can HPD registration/workbook/application data identify intended total units, restricted units, eligible sites, and actual 485-x take-up?
- [ ] What is the simplest credible counterfactual size distribution for 2025?
- [ ] Does the first-stage developer model need only a quadratic redesign cost, or separate building-size and unit-density costs?
- [ ] Are repeated 99-unit applications genuine legal splits, parent-lot reporting artifacts, or multiple covered buildings on one eligible site?

## Quiz Log
| Date | Stage | Question Type | Result | Follow-up Needed |
|---|---|---|---|---|
| 2026-07-09 | goal | researcher restatement | restated | Distinguish developer cost from renter and total welfare in final walkthrough. |
| 2026-07-09 | narrowed goal | researcher restatement | restated | Verify understanding of the four developer responses and which data distinguish them. |
