"""Save the official rows used in the two school-parcel boundary checks.

Run from this directory: python3 fetch_focus.py
The script writes raw API responses and a manifest with each exact URL and hash.
"""

import csv
import hashlib
import subprocess
from datetime import date
from pathlib import Path
from urllib.parse import urlencode


HERE = Path(__file__).resolve().parent
BASE = "https://data.cityofnewyork.us/resource/"

SHELL_DOCUMENTS = [
    "2022052000328001",  # Lot 50 deed.
    "2022052000544001",  # Lot 1 deed.
    "2022093000168001",  # Air-rights agreement.
    "2022093000197001",  # SAGE agreement.
]

BRONX_DOCUMENTS = [
    "2022081800392001",  # Residential lot 150 deed.
    "2022081800392002",  # School lot 160 deed.
    "2022081900245003",  # Owner/SCA agreement.
    "2022081900245004",  # Owner/SCA easement.
]

queries = []
for site, documents in [("shell", SHELL_DOCUMENTS), ("vancortlandt", BRONX_DOCUMENTS)]:
    in_clause = ",".join(f'"{document}"' for document in documents)
    for suffix, dataset, order in [
        ("legals", "8h5j-fqxa", "document_id,borough,block,lot"),
        ("master", "bnx9-e6tj", "document_id"),
        ("parties", "636b-3b5g", "document_id,party_type,name"),
    ]:
        queries.append(
            (
                f"{site}_acris_{suffix}_focus.json",
                BASE + dataset + ".json?" + urlencode(
                    {"$where": f"document_id in ({in_clause})", "$order": order, "$limit": 100}
                ),
            )
        )

queries.append(
    (
        "current_pluto_lots.json",
        BASE + "64uk-42ks.json?" + urlencode(
            {
                "$where": "bbl in (3072690001,3072690050,2032710150,2032710160,2032710175)",
                "$limit": 100,
            }
        ),
    )
)
queries.append(
    ("current_pluto_metadata.json", "https://data.cityofnewyork.us/api/views/64uk-42ks.json")
)

with (HERE / "sources.csv").open("w", newline="") as manifest:
    writer = csv.writer(manifest)
    writer.writerow(["file", "url", "accessed_date", "sha256", "bytes"])
    for filename, url in queries:
        content = subprocess.run(
            ["curl", "--location", "--fail", "--silent", "--show-error", "--max-time", "30", url],
            check=True,
            capture_output=True,
        ).stdout
        (HERE / filename).write_bytes(content)
        writer.writerow([filename, url, date.today().isoformat(), hashlib.sha256(content).hexdigest(), len(content)])

    document_files = [
        ("vancortlandt_residential_zd1.pdf", "https://www.pincusco.com/property-data/ZD1_X00757318_1.pdf"),
        (
            "vancortlandt_school_deed_2022081800392002.pdf",
            "https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022081800392002",
        ),
        (
            "vancortlandt_residential_deed_2022081800392001.pdf",
            "https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022081800392001",
        ),
        (
            "vancortlandt_agreement_2022081900245003.pdf",
            "https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022081900245003",
        ),
        (
            "neptune_school_deed_2022052000328001.pdf",
            "https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022052000328001",
        ),
        (
            "shell_residential_deed_2022052000544001.pdf",
            "https://a836-acris.nyc.gov/DS/DocumentSearch/DocumentImageView?doc_id=2022052000544001",
        ),
    ]
    for filename, url in document_files:
        if not (HERE / filename).exists():
            continue
        content = (HERE / filename).read_bytes()
        writer.writerow(
            [filename, url, date.today().isoformat(), hashlib.sha256(content).hexdigest(), len(content)]
        )
