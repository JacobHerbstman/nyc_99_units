# Build ACRIS Recovered Sale Events

Builds conservative document-level recovered sale events from exact DOF-to-ACRIS DEED candidates and ACRIS legal-property records.

Production recovery requires:
- the candidate ACRIS document's legals contain the DOF sale BBL;
- the same ACRIS document's legals contain at least one frozen primary opportunity BBL;
- the DOF sale record has exactly one legally confirmed candidate document;
- linked DOF rows imply one event date and one event price.
