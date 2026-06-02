# Proposal Summary

## Paper

Working title: "Who Pays for Housing Regulation? Evidence from New York City's 485-x Tax Incentive."

The project studies the 485-x Affordable Neighborhoods for New Yorkers tax incentive. The relevant notch is at 100 residential units: projects below 100 units face the modest-rental requirements, while projects at or above 100 units face more stringent affordability and construction wage requirements.

## Core Question

Who bears the cost of the threshold? The proposal distinguishes two channels:

- Capitalization: parcels that would otherwise support projects just above 100 units sell for less after 485-x.
- Avoidance: developers change projects to avoid the threshold through 99-unit filings, delays, larger units, or adjacent split projects.

## Empirical Design

Observed unit count is endogenous because 99 units may itself be the avoidance response. The proposed design uses pre-policy information to estimate ex ante exposure to the notch. For each parcel, use pre-2024 donor projects on similar lots to simulate feasible unit counts absent 485-x. Exposure is the simulated probability that a parcel would naturally support a project just above the 100-unit threshold, controlling flexibly for predicted capacity.

## Data Priorities

- DCP Housing Database for project unit counts, filing/permit dates, and completion status.
- PLUTO or MapPLUTO for lot area, zoning, existing built area, geography, and geometry.
- ACRIS for sale prices, transaction timing, ownership histories, and arms-length transaction filters.
- DOB BIS and DOB NOW job filings for applicant, owner, architect, filing timing, and project linkage checks.
- HPD 485-x program and registration materials for explicit benefit-seeking projects.

## Early Audit Questions

- Does the DCP Housing Database reproduce the reported rise in 50-99 unit proposed buildings?
- How stable are unit counts across DOB filings, DCP Housing Database records, and later permits or completions?
- Which ACRIS document types and party roles best identify arms-length land transactions?
- Are apparent adjacent 99-unit filings linked by owner, applicant, architect, lender, filing date, or acquisition history?
- Is MapPLUTO release timing sufficient for pre-policy parcel characteristics, or are historical releases needed for baseline capacity?
