# Build ACRIS Opportunity Sale Seeds

Builds the DOF annualized sale rows used to seed ACRIS document recovery.

Rows are positive-price DOF sales on blocks containing frozen primary opportunity lots. The task separates exact primary opportunity BBL sales from same-block unmatched sales. Same-block unmatched rows are seed candidates only; they are not production links to opportunity lots.
