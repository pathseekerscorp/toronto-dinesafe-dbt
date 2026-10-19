"""Download the latest DineSafe CSV from the City of Toronto Open Data portal.

Looks up the dataset through the CKAN API, picks the most recently updated
CSV resource, and saves it as a dated snapshot in data/raw/, e.g.
data/raw/dinesafe_2026-10-18.csv (dated by when the city last refreshed it).

Usage:
    python scripts/download_dinesafe.py           # skip if snapshot exists
    python scripts/download_dinesafe.py --force   # re-download anyway
"""

import argparse
import csv
import json
import sys
import urllib.request
from pathlib import Path

CKAN_BASE = "https://ckan0.cf.opendata.inter.prod-toronto.ca/api/3/action"
PACKAGE_ID = "dinesafe"
RAW_DIR = Path(__file__).resolve().parent.parent / "data" / "raw"
EXPECTED_COLUMNS = {"_id", "estId", "estName", "inspectionDate", "severity"}


def get_latest_csv_resource() -> dict:
    url = f"{CKAN_BASE}/package_show?id={PACKAGE_ID}"
    with urllib.request.urlopen(url, timeout=60) as resp:
        package = json.load(resp)["result"]

    csvs = [
        r for r in package["resources"]
        if r["format"].upper() == "CSV" and r.get("last_modified")
    ]
    if not csvs:
        sys.exit("No CSV resources found in the DineSafe package.")
    return max(csvs, key=lambda r: r["last_modified"])


def download(url: str, dest: Path) -> None:
    tmp = dest.with_suffix(".csv.part")
    with urllib.request.urlopen(url, timeout=300) as resp, open(tmp, "wb") as f:
        while chunk := resp.read(1024 * 1024):
            f.write(chunk)
    tmp.rename(dest)


def summarise(path: Path) -> None:
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        header = next(reader)
        rows = sum(1 for _ in reader)

    missing = EXPECTED_COLUMNS - set(header)
    if missing:
        sys.exit(f"Downloaded file is missing expected columns: {sorted(missing)}")

    size_mb = path.stat().st_size / 1_000_000
    print(f"{path.name}: {rows:,} rows, {len(header)} columns, {size_mb:.1f} MB")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--force", action="store_true", help="re-download even if the snapshot exists")
    args = parser.parse_args()

    resource = get_latest_csv_resource()
    snapshot_date = resource["last_modified"][:10]
    dest = RAW_DIR / f"dinesafe_{snapshot_date}.csv"

    print(f"Latest resource: {resource['name']} (updated {resource['last_modified']})")
    if dest.exists() and not args.force:
        print(f"Already have {dest.name}; use --force to re-download.")
    else:
        RAW_DIR.mkdir(parents=True, exist_ok=True)
        print(f"Downloading to {dest.relative_to(RAW_DIR.parent.parent)} ...")
        download(resource["url"], dest)

    summarise(dest)


if __name__ == "__main__":
    main()
