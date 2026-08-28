# Fetch NYS Attorney General offering-plan matches

This task queries the New York State Attorney General's public Real Estate
Finance Database for each component address in the full 6-plus-unit parent
exposure universe. It preserves both a one-row-per-query audit and one row per
returned offering plan, including the plan's submitted and accepted dates.

Queries run in deterministic Make-managed batches because the public search
service can time out during a full-universe pull. Completed batches remain
valid, while the combined outputs are written only after every address has a
successful response.

The results are evidence of condominium or cooperative tenure, not an automatic
parent match. The downstream exposure audit requires an address match and
checks the plan timing relative to the DOB proposal.
