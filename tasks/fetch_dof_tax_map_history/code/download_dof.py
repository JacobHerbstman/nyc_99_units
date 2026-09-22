"""Save complete public DOF ArcGIS tables, retaining the original JSON bytes."""

import csv
import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from urllib.parse import urlencode
import zipfile

url, destination, expected_sha256 = sys.argv[1:]
destination = Path(destination)
records = []

# ArcGIS requires pagination. One helper handles the repeated HTTP request;
# the table URL remains visible in the Makefile.
def receive(name, parameters, archive):
    address = url + ("/query?" if name != "schema.json" else "?") + urlencode(parameters)
    raw = subprocess.check_output([
        "curl", "--fail", "--location", "--silent", "--show-error",
        "--retry", "3", "--connect-timeout", "30", "--max-time", "180", address,
    ])
    data = json.loads(raw)
    if "error" in data:
        raise RuntimeError(data["error"])
    # Fixed ZIP metadata makes the archive hash depend on source bytes.
    archive.writestr(zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0)), raw,
                     compress_type=zipfile.ZIP_DEFLATED)
    records.append((name, address, len(raw), hashlib.sha256(raw).hexdigest()))
    return data

with tempfile.TemporaryDirectory(dir=destination.parent) as temporary:
    pending = Path(temporary) / "snapshot.zip"
    with zipfile.ZipFile(pending, "w") as archive:
        schema = receive("schema.json", {"f": "json"}, archive)
        oid = next(f["name"] for f in schema["fields"] if f["type"] == "esriFieldTypeOID")
        before = receive("ids_before.json", {
            "f": "json", "where": "1=1", "returnIdsOnly": "true",
        }, archive)["objectIds"]
        page_size = schema.get("standardMaxRecordCount", schema["maxRecordCount"])
        obtained = []
        for offset in range(0, len(before), page_size):
            page = receive(f"page_{offset:07d}.json", {
                "f": "json", "where": "1=1", "outFields": "*",
                "returnGeometry": "false", "resultType": "standard",
                "orderByFields": oid, "resultRecordCount": page_size,
                "resultOffset": offset,
            }, archive)
            rows = page["features"]
            if len(rows) != min(page_size, len(before) - offset):
                raise RuntimeError("Incomplete DOF page")
            obtained.extend(row["attributes"][oid] for row in rows)
            print(destination.name, offset + len(rows), "/", len(before), flush=True)
        after = receive("ids_after.json", {
            "f": "json", "where": "1=1", "returnIdsOnly": "true",
        }, archive)["objectIds"]
        if sorted(before) != sorted(obtained) or sorted(after) != sorted(obtained):
            raise RuntimeError("DOF membership changed during download; snapshot not published")
        if len(set(obtained)) != len(obtained):
            raise RuntimeError("Duplicate DOF object identifiers")
        manifest = io.StringIO()
        writer = csv.writer(manifest)
        writer.writerow(("file", "url", "bytes", "sha256"))
        writer.writerows(records)
        archive.writestr(zipfile.ZipInfo("sources.csv", (1980, 1, 1, 0, 0, 0)),
                         manifest.getvalue(), compress_type=zipfile.ZIP_DEFLATED)
    if hashlib.sha256(pending.read_bytes()).hexdigest() != expected_sha256:
        raise RuntimeError("DOF has changed. Restore the recorded raw snapshot from the replication package, "
                           "or deliberately record a new vintage and checksum.")
    pending.replace(destination)
