"""Save DOB demolition filings from NYC Open Data.

BIS demolition applications (job type DM, job application filings ic3t-wcy2)
and DOB NOW full demolitions (job application filings w9ak-ipjd). Socrata
returns at most 50,000 rows per request, so pages are requested in a stable :id
order and written to one CSV per system. The manifest records each page's URL,
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

system, destination = sys.argv[1], Path(sys.argv[2])
sources = {
    "bis": ("https://data.cityofnewyork.us/resource/ic3t-wcy2.csv", "job_type='DM'",
            ["job__", "doc__", "borough", "block", "lot", "bin__", "job_type", "job_status",
             "pre__filing_date", "latest_action_date", "dobrundate"]),
    "dob_now": ("https://data.cityofnewyork.us/resource/w9ak-ipjd.csv", "job_type='Full Demolition'",
                ["job_filing_number", "borough", "block", "lot", "bbl", "bin", "job_type",
                 "filing_status", "filing_date", "current_status_date"]),
}
endpoint, where, fields = sources[system]
page_size = 50000

with tempfile.TemporaryDirectory(dir=destination.parent) as temporary:
    pending = Path(temporary) / destination.name
    manifest = []
    with open(pending, "w", newline="") as output:
        writer = None
        offset = 0
        while True:
            query = urlencode({"$select": ",".join(fields), "$where": where, "$order": ":id",
                               "$limit": page_size, "$offset": offset})
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
    manifest_name = destination.stem + "_manifest.csv"
    with open(Path(temporary) / manifest_name, "w", newline="") as handle:
        csv.writer(handle).writerows([("offset", "rows", "sha256", "url"), *manifest])
    print(f"Saved {sum(rows for _, rows, _, _ in manifest)} rows in {len(manifest)} pages")
    (Path(temporary) / manifest_name).replace(destination.parent / manifest_name)
    pending.replace(destination)
