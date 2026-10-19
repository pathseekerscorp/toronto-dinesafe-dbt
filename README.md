# Toronto DineSafe Analytics

A dbt + DuckDB project modelling the City of Toronto's DineSafe restaurant inspection data.

## Setup

Requires Python 3.12 and [uv](https://docs.astral.sh/uv/).

```bash
uv venv --python 3.12 .venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

## Project layout

```
data/raw/   downloaded source files (not committed)
scripts/    data download and load scripts
```
