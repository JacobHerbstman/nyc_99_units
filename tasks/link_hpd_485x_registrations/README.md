# Link HPD 485-x registrations to DOB jobs

This task links every public HPD 485-x registration response to the staged DOB
NOW initial-filing panel. A reported DOB root job is preferred; a BIN is used
only when it identifies exactly one DOB root job. Conflicting and nonunique
identifiers remain unresolved.

Repeated HPD submissions are preserved. The output marks the latest response
for each matched or reported building key, and it records whether an Option B
registration reports fewer than 100 units. That flag is evidence of intended
sub-100 treatment, not evidence of final HPD approval or a legal Eligible Site
determination.

`link_hpd_485x_registrations.R` reads the registrations, matches them to DOB
jobs and writes `hpd_485x_registration_dob_links.csv`.
Parent-level summaries and threshold interpretations belong downstream. The
source snapshot comes from `fetch_hpd_485x_registrations`.
