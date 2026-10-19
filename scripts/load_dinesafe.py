"""Load all DineSafe snapshots from data/raw/ into DuckDB.

Rebuilds raw.dinesafe in data/dinesafe.duckdb from every dinesafe_YYYY-MM-DD.csv
snapshot. Columns are loaded as text, unchanged from the source; typing and
cleaning happen in the dbt staging models. Each row is tagged with the
snapshot it came from so later models can keep the latest version of a row.

Usage:
    python scripts/load_dinesafe.py
"""

import sys
from pathlib import Path

import duckdb

PROJECT_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = PROJECT_DIR / "data" / "raw"
DB_PATH = PROJECT_DIR / "data" / "dinesafe.duckdb"
SNAPSHOT_GLOB = "dinesafe_*.csv"


def main() -> None:
    snapshots = sorted(RAW_DIR.glob(SNAPSHOT_GLOB))
    if not snapshots:
        sys.exit(f"No snapshots found in {RAW_DIR}. Run scripts/download_dinesafe.py first.")

    print(f"Loading {len(snapshots)} snapshot(s) into {DB_PATH.relative_to(PROJECT_DIR)}")

    with duckdb.connect(str(DB_PATH)) as con:
        con.execute("create schema if not exists raw")
        con.execute(
            """
            create or replace table raw.dinesafe as
            select
                * exclude (filename),
                regexp_extract(filename, 'dinesafe_(\\d{4}-\\d{2}-\\d{2})\\.csv$', 1)::date as _snapshot_date,
                regexp_extract(filename, '[^/]+$') as _source_file,
                current_timestamp as _loaded_at
            from read_csv(?, header = true, all_varchar = true, filename = true)
            """,
            [[str(p) for p in snapshots]],
        )

        rows = con.execute(
            """
            select _source_file, count(*)
            from raw.dinesafe
            group by 1
            order by 1
            """
        ).fetchall()

    for source_file, count in rows:
        print(f"  {source_file}: {count:,} rows")
    print(f"raw.dinesafe: {sum(c for _, c in rows):,} rows total")


if __name__ == "__main__":
    main()
