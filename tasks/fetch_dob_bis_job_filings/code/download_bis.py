"""Save the DOB BIS New Building initial applications from NYC Open Data.

Socrata returns at most 50,000 rows per request, so pages are requested in a
stable :id order and written to one CSV. The manifest records each page's URL,
row count and SHA-256.
"""

import csv
import hashlib
import io
from pathlib import Path
import subprocess
import sys
import tempfile
from urllib.parse import urlencode

destination = Path(sys.argv[1])
endpoint = "https://data.cityofnewyork.us/resource/ic3t-wcy2.csv"
fields = [
    "job__", "doc__", "borough", "block", "lot", "bin__", "house__", "street_name",
    "job_type", "job_status", "job_status_descrp", "pre__filing_date", "latest_action_date",
    "owner_type", "owner_s_business_name", "owner_s_first_name", "owner_s_last_name",
    "applicant_s_first_name", "applicant_s_last_name", "applicant_license__",
    "applicant_professional_title", "gis_latitude", "gis_longitude", "gis_nta_name",
    "community___board", "proposed_zoning_sqft", "existing_zoning_sqft",
    "total_construction_floor_area", "withdrawal_flag", "dobrundate",
]
page_size = 50000

with tempfile.TemporaryDirectory(dir=destination.parent) as temporary:
    pending = Path(temporary) / destination.name
    manifest = []
    with open(pending, "w", newline="") as output:
        writer = None
        offset = 0
        while True:
            query = urlencode({
                "$select": ",".join(fields),
                "$where": "job_type='NB' AND doc__='01'",
                "$order": ":id",
                "$limit": page_size,
                "$offset": offset,
            })
            raw = subprocess.check_output([
                "curl", "--fail", "--location", "--silent", "--show-error",
                "--retry", "3", "--connect-timeout", "30", "--max-time", "300",
                f"{endpoint}?{query}",
            ])
            rows = list(csv.reader(io.StringIO(raw.decode("utf-8"))))
            header, body = rows[0], rows[1:]
            if header != fields:
                raise RuntimeError(f"Unexpected columns: {header}")
            if writer is None:
                writer = csv.writer(output)
                writer.writerow(header)
            writer.writerows(body)
            manifest.append((offset, len(body), hashlib.sha256(raw).hexdigest(), f"{endpoint}?{query}"))
            if len(body) < page_size:
                break
            offset += page_size
    with open(Path(temporary) / "manifest.csv", "w", newline="") as handle:
        csv.writer(handle).writerows([("offset", "rows", "sha256", "url"), *manifest])
    total = sum(rows for _, rows, _, _ in manifest)
    print(f"Saved {total} rows in {len(manifest)} pages")
    (Path(temporary) / "manifest.csv").replace(destination.parent / "manifest.csv")
    pending.replace(destination)
