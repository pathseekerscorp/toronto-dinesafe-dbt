# Toronto DineSafe Analytics

A dbt + DuckDB project modelling the City of Toronto's DineSafe restaurant inspection data.

## Data

[DineSafe](https://open.toronto.ca/dataset/dinesafe/) is Toronto Public Health's food safety
inspection programme, published daily on the City of Toronto Open Data portal. Each row is one
infraction found during an inspection; inspections with no infractions get a single row with
severity `None`. The current snapshot has about 122,000 rows covering 82,000 inspections of
19,600 establishments since November 2023.

A few columns from the data (the full data has 18 columns):

| estName | inspectionDate | inspectionStatus | typeDesc | severity | OutcomeDesc | amountFined |
|---|---|---|---|---|---|---|
| THE FLOWER CAKE CAFE | 2024-09-04 | Pass | None | None | None | |
| CHAOSHAN BEEF HOT POT | 2026-06-16 | Pass | FAIL TO MAINTAIN HANDWASHING STATIONS (LIQUID SOAP AND… | S - Significant | None | |
| TRIPPETT CHILD CARE CENTRE | 2024-09-13 | Conditional Pass | FAIL TO ENSURE EQUIPMENT SURFACE SANITIZED AS NECESSARY | M - Minor | None | |
| GOURMET KITCHEN | 2023-12-01 | Conditional Pass | Fail to protect against harbouring of pests - Sec. 13(1… | S - Significant | Conviction - Fined | 580 |
| The Jerk Box | 2024-12-04 | Closed | Food premise maintained in manner permitting health haz… | C - Crucial | Conviction - Fined | 6250 |

- **Preview the data:** [`data/sample/dinesafe_sample.csv`](data/sample/dinesafe_sample.csv)
  has 33 rows from 10 complete inspections, chosen to cover every status and severity.
- **Get the full data:** the raw files aren't committed. Run the scripts below to download the
  latest snapshot, which takes a few seconds.
- **Data quality notes:** see [`docs/data_profile.md`](docs/data_profile.md).

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

## Load into DuckDB

```bash
python scripts/load_dinesafe.py
```

Rebuilds the `raw.dinesafe` table in `data/dinesafe.duckdb` from every snapshot in `data/raw/`.
Columns are loaded as text exactly as published, plus `_snapshot_date`, `_source_file` and
`_loaded_at` metadata columns. Typing and cleaning happen in dbt.

## Run dbt

```bash
cd dinesafe
dbt debug              # check the connection
dbt source freshness   # warn if the latest snapshot is more than 3 days old
```

The dbt profile lives in `dinesafe/profiles.yml` (no secrets; it points at `data/dinesafe.duckdb`),
so run dbt from inside the `dinesafe/` folder. Models are built into three schemas:
`staging` and `intermediate` (views) and `marts` (tables).

```bash
dbt deps               # install dbt packages (first run only)
dbt build              # build all models and run all tests
```

## Models

| Layer | Model | Grain |
|---|---|---|
| Staging | `stg_dinesafe__inspection_records` | One cleaned, typed record per infraction (or per clean inspection) |
| Intermediate | `int_establishment_id_map` | One row per published establishment ID, mapped to a canonical ID |
| Intermediate | `int_inspection_records` | Records keyed to canonical establishments, with migrated duplicates removed |
| Intermediate | `int_inspections` | One row per inspection |
| Marts | `dim_establishments` | One row per establishment (18,540) |
| Marts | `fct_inspections` | One row per inspection (79,244) |
| Marts | `fct_infractions` | One row per infraction (74,543) |
| Marts | `rpt_inspections_by_area` | One row per postal area (first three characters of the postal code) |

The main modelling challenge is the city's November 2025 system migration: 1,098 establishments
appear under both a legacy and a new ID, with 2,769 inspections duplicated across the two.
The intermediate layer merges them; see [`docs/data_profile.md`](docs/data_profile.md) for details.

## Data quality tests

`dbt build` runs 78 tests alongside the models (using [dbt_utils](https://github.com/dbt-labs/dbt-utils)):

- **Keys and relationships:** primary keys are unique and not null at every layer; every
  inspection and infraction points to a real establishment and inspection.
- **Valid values and ranges:** statuses and severities from known lists, coordinates within
  Toronto, Toronto-format postal codes, non-negative fines, no future inspections.
- **Business rules:** closures always involve a crucial infraction, passes never do, and
  severity counts add up to the infraction count.
- **Reconciliation:** infraction counts match between `fct_inspections` and `fct_infractions`,
  the area report accounts for every inspection and dollar fined, and merging legacy IDs
  never loses an inspection or double-counts one.

Three tests are set to **warn** rather than fail, because the source data has a handful of
known exceptions: court outcomes dated before the inspection (3), a conviction with no fine
recorded (1), and conditional passes with only minor infractions (6).

Rows behind any failing or warning test are saved to the `test_failures` schema in DuckDB,
one table per test, so they can be inspected directly.

## Project layout

```
data/raw/   downloaded source files (not committed)
data/sample/ small committed sample for previewing the data
scripts/    data download and load scripts
docs/       data profile and design notes (see docs/data_profile.md)
dinesafe/   dbt project (models/staging, models/intermediate, models/marts)
```
