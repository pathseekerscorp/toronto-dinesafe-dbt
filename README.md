# Toronto DineSafe Analytics

A dbt + DuckDB project modelling the City of Toronto's DineSafe restaurant inspection data.

## Setup

Requires Python 3.12 and [uv](https://docs.astral.sh/uv/).

```bash
uv venv --python 3.12 .venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

## Get the data

```bash
python scripts/download_dinesafe.py
```

Downloads the latest DineSafe CSV from [Toronto Open Data](https://open.toronto.ca/dataset/dinesafe/)
and saves a dated snapshot to `data/raw/` (e.g. `dinesafe_2026-10-18.csv`). The city publishes a
rolling window of recent inspections, so keeping dated snapshots builds up history over time.
Use `--force` to re-download a snapshot that already exists.

## Project layout

```
data/raw/   downloaded source files (not committed)
scripts/    data download and load scripts
```
