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

The task produces only the canonical response-level link. Parent-specific
summaries and threshold interpretations belong downstream, so this mechanical
link no longer depends on any parcel or parent unit-count prediction model.
