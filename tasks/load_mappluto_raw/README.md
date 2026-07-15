# Load MapPLUTO Raw

Reads downloaded MapPLUTO release files and writes raw cached lot tables.

This task normalizes field names and preserves release-level lot records for
staging. It does not make modeling choices. Delimited archives are read as
character data with incomplete rows filled but not imputed. This handles one
known corrupt source record in the Queens 13v1 file (BBL 4104830066), whose
trailing fields contain an embedded null and two missing columns.
