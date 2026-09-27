"""Save a DOB permit extract from NYC Open Data.

Two extracts name the contractor that holds a building's work permit:
  bis_nb      DOB Permit Issuance (ipu4-2q9a): New Building permits on BIS
              New Building jobs, filed through 2020;
  now_gc      DOB NOW: Build - Approved Permits (rbx6-tga4): General
              Construction work permits on every DOB NOW job; consumers
              select New Building jobs by job filing number.
Socrata returns at most 50,000 rows per request, so pages are requested in a
stable :id order and written to one CSV. The manifest records each page's URL,
row count and SHA-256. Permittee phone numbers and owners' personal names and
addresses are not requested.
"""

import csv
import hashlib
import io
from pathlib import Path
import subprocess
import sys
import tempfile
from urllib.parse import urlencode

extract, destination = sys.argv[1], Path(sys.argv[2])
extracts = {
    "bis_nb": {
        "endpoint": "https://data.cityofnewyork.us/resource/ipu4-2q9a.csv",
        "where": "job_type='NB' AND permit_type='NB'",
        "fields": [
            "job__", "job_doc___", "job_type", "permit_type", "permit_subtype", "permit_sequence__",
            "permit_status", "filing_status", "filing_date", "issuance_date", "expiration_date",
            "job_start_date", "permittee_s_first_name", "permittee_s_last_name",
            "permittee_s_business_name", "permittee_s_license_type", "permittee_s_license__",
            "act_as_superintendent", "permittee_s_other_title", "superintendent_first___last_name",
            "superintendent_business_name", "site_safety_mgr_business_name", "owner_s_business_type",
            "owner_s_business_name", "borough", "block", "lot", "bin__", "bbl", "dobrundate",
        ],
    },
    "now_gc": {
        "endpoint": "https://data.cityofnewyork.us/resource/rbx6-tga4.csv",
        "where": "work_type='General Construction'",
        "fields": [
            "job_filing_number", "work_permit", "sequence_number", "tracking_number", "filing_reason",
            "work_type", "permit_status", "approved_date", "issued_date", "expired_date",
            "permittee_s_license_type", "applicant_license", "applicant_first_name", "applicant_last_name",
            "applicant_business_name", "filing_representative_business_name", "estimated_job_costs",
            "owner_business_name", "borough", "block", "lot", "bin", "bbl",
        ],
    },
}[extract]
page_size = 50000

with tempfile.TemporaryDirectory(dir=destination.parent) as temporary:
    pending = Path(temporary) / destination.name
    manifest = []
    with open(pending, "w", newline="") as output:
        writer = None
        offset = 0
        while True:
            query = urlencode({
                "$select": ",".join(extracts["fields"]),
                "$where": extracts["where"],
                "$order": ":id",
                "$limit": page_size,
                "$offset": offset,
            })
            raw = subprocess.check_output([
                "curl", "--fail", "--location", "--silent", "--show-error",
                "--retry", "3", "--connect-timeout", "30", "--max-time", "300",
                f"{extracts['endpoint']}?{query}",
            ])
            rows = list(csv.reader(io.StringIO(raw.decode("utf-8"))))
            header, body = rows[0], rows[1:]
            if header != extracts["fields"]:
                raise RuntimeError(f"Unexpected columns: {header}")
            if writer is None:
                writer = csv.writer(output)
                writer.writerow(header)
            writer.writerows(body)
            manifest.append((offset, len(body), hashlib.sha256(raw).hexdigest(), f"{extracts['endpoint']}?{query}"))
            if len(body) < page_size:
                break
            offset += page_size
    manifest_file = destination.parent / f"{destination.stem}_manifest.csv"
    with open(Path(temporary) / manifest_file.name, "w", newline="") as handle:
        csv.writer(handle).writerows([("offset", "rows", "sha256", "url"), *manifest])
    total = sum(rows for _, rows, _, _ in manifest)
    print(f"Saved {total} rows in {len(manifest)} pages")
    (Path(temporary) / manifest_file.name).replace(manifest_file)
    pending.replace(destination)
