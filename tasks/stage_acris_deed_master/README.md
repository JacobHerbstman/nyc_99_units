# Stage ACRIS DEED Master

Stages the fetched standard `DEED` rows from the ACRIS Real Property Master table. The output is a narrow document-level parquet used for exact DOF sale to ACRIS document candidate links.

This task does not decide whether a document is a valid opportunity-site sale. Legal-record confirmation happens downstream.
