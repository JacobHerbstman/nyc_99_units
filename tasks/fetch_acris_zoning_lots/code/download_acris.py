"""Save ACRIS zoning-lot documents and the lots they list from NYC Open Data.

documents: Real Property Master (bnx9-e6tj) rows of zoning lot descriptions
(ZONE) and development-rights transfers (DEVR) dated from 2012. parcels: Real
Property Legals (8h5j-fqxa) rows of those documents, requested in batches of
document IDs from the saved documents capture. Socrata returns at most 50,000
rows per request; pages are requested in a stable :id order. The manifest
records each request's URL, row count and SHA-256.
"""

import csv
import hashlib
import io
from pathlib import Path
import subprocess
import sys
import tempfile
from urllib.parse import urlencode

table, destination = sys.argv[1], Path(sys.argv[2])
master = "https://data.cityofnewyork.us/resource/bnx9-e6tj.csv"
legals = "https://data.cityofnewyork.us/resource/8h5j-fqxa.csv"
document_fields = ["document_id", "record_type", "crfn", "recorded_borough", "doc_type", "document_date",
                   "recorded_datetime", "modified_date", "good_through_date"]
parcel_fields = ["document_id", "record_type", "borough", "block", "lot", "easement", "partial_lot",
                 "air_rights", "subterranean_rights", "property_type", "good_through_date"]
page_size = 50000

def receive(endpoint, parameters):
    query = urlencode(parameters)
    raw = subprocess.check_output([
        "curl", "--fail", "--location", "--silent", "--show-error",
        "--retry", "3", "--connect-timeout", "30", "--max-time", "300", f"{endpoint}?{query}",
    ])
    rows = list(csv.reader(io.StringIO(raw.decode("utf-8"))))
    return rows[0], rows[1:], (len(rows) - 1, hashlib.sha256(raw).hexdigest(), f"{endpoint}?{query}")

if table == "documents":
    fields = document_fields
    requests = [(master, {"$select": ",".join(fields),
                          "$where": "doc_type in ('ZONE','DEVR') AND document_date >= '2012-01-01'",
                          "$order": ":id"})]
else:
    fields = parcel_fields
    with open(sys.argv[3], newline="") as handle:
        ids = sorted({row["document_id"] for row in csv.DictReader(handle)})
    requests = [(legals, {"$select": ",".join(fields),
                          "$where": "document_id in (" + ",".join(f"'{d}'" for d in ids[i:i + 150]) + ")",
                          "$order": ":id"}) for i in range(0, len(ids), 150)]

with tempfile.TemporaryDirectory(dir=destination.parent) as temporary:
    pending = Path(temporary) / destination.name
    manifest = []
    with open(pending, "w", newline="") as output:
        writer = csv.writer(output)
        writer.writerow(fields)
        for endpoint, parameters in requests:
            offset = 0
            while True:
                header, body, record = receive(endpoint, {**parameters, "$limit": page_size, "$offset": offset})
                if header != fields:
                    raise RuntimeError(f"Unexpected columns: {header}")
                writer.writerows(body)
                manifest.append((offset, *record))
                if len(body) < page_size:
                    break
                offset += page_size
    manifest_name = destination.stem + "_manifest.csv"
    with open(Path(temporary) / manifest_name, "w", newline="") as handle:
        csv.writer(handle).writerows([("offset", "rows", "sha256", "url"), *manifest])
    print(f"Saved {sum(m[1] for m in manifest)} rows in {len(manifest)} requests")
    (Path(temporary) / manifest_name).replace(destination.parent / manifest_name)
    pending.replace(destination)
