# DineSafe data profile

Profiled from `data/raw/dinesafe_2026-10-18.csv` (snapshot refreshed by the city on 2026-10-18).

## Shape

| Measure | Value |
|---|---|
| Rows | 122,305 |
| Columns | 18 |
| Inspections (`estId` + `inspectionDate`) | 82,013 |
| Establishments (`estId`) | 19,638 |
| Inspection date range | 2023-11-10 to 2026-10-17 |

## Grain

- **One row per infraction.** `unique_id` and `_id` are both unique per row.
- An inspection with no infractions still has one row, with `severity = 'None'` and
  `deficiencyDesc = 'None'`.
- **`estId` + `inspectionDate` identifies an inspection.** `inspectionStatus` is
  consistent within every inspection. There's no inspection ID column.
- No exact duplicate rows, but 85 inspections have more than one "no infraction" row.
  They collapse cleanly when aggregated to the inspection level.

## Columns

| Column | Meaning | Notes |
|---|---|---|
| `_id`, `unique_id` | Row identifiers | `unique_id` is a stable hash, so it's the better key |
| `estId` | Establishment ID | Two formats, see below |
| `oldEstId` | Legacy numeric ID | `'None'` when absent |
| `estName` | Establishment name | One name per `estId` throughout |
| `address` | Street, unit, postal code | Unit is literally `'None'` when absent (90,453 rows) |
| `inspectionStatus` | Inspection result | Pass 102,175 / Conditional Pass 19,603 / Closed 525 / Temporarily Not Operating 2 (rows, not inspections) |
| `phone` | Phone | `'None'` (10,942 rows) and `'0000000000'` (201) placeholders |
| `inspectionDate` | Inspection date | Clean ISO dates |
| `observation` | Inspection summary sentence | Doesn't reliably match the infractions, see below |
| `typeDesc` | Infraction description | 397 values |
| `deficiencyDesc` | Infraction category | 35 values across two coding schemes, see finding 9 |
| `severity` | Infraction severity | `M - Minor`, `S - Significant`, `C - Crucial`, `NA`, `None` |
| `OutcomeDate`, `OutcomeDesc`, `amountFined` | Court outcome | Populated on ~0.2% of rows |
| `latitude`, `longitude` | Location | All within Toronto (lat 43.59–43.84, lon −79.64 to −79.13) |

**There is no establishment type column** (e.g. restaurant vs. food truck). `typeDesc` is the
infraction type, not the establishment type.

## Data quality findings

1. **Text placeholders instead of nulls.** `'None'` appears in `oldEstId`, `phone`, `severity`,
   `deficiencyDesc`, `typeDesc`, `OutcomeDesc`, and inside `address`. Two addresses start with
   `'undefined'`. Staging should convert these to real nulls.
2. **Two establishment ID systems.** 3,469 establishments have numeric IDs (the legacy system,
   last seen 2025-11-07). 16,169 have 18-character alphanumeric IDs, which appear from 2023
   onwards. For numeric IDs, `estId = oldEstId`. Of the numeric IDs, 1,098 reappear as the
   `oldEstId` of a new-format ID, so **the same restaurant can appear under two IDs**, and its
   inspection history is split across them. No `oldEstId` maps to more than one new ID, so the
   link is clean.
3. **`observation` contradicts the infractions.** For example, 11,134 inspections are summarised
   as "minor infractions" but contain a Significant infraction. Treat `severity` as the source of
   truth and derive the worst severity per inspection.
4. **`NA` severity** (5,509 rows) covers administrative infractions such as no supervisor
   present, missing food handler training, or no licence. These are real infractions, not
   missing data.
5. **Inconsistent outcome labels.** `Conviction - Fined` and `Conviction: Fined` mean the same.
6. **Address variants within an inspection.** 227 inspections have the same establishment with
   formatting variants of its address (`A` vs `Unit-A`).
7. **Fines** range from $0 to $12,505 (median $150, total $158,792.50). 11 rows have a $0 fine.
8. **Postal codes** can be parsed from the end of `address` for 98% of rows, which enables
   area-level analysis by the first three characters of the postal code.
9. **Two infraction category schemes.** Until 2025-11-07, categories use a legacy scheme
   (`5C. Proper maintenance / washing of rooms…`, often truncated). From 2025-11-05 they use a
   current scheme (`05. MAINTENANCE / SANITATION OF NON-FOOD CONTACT SURFACES…`). The schemes
   don't map one-to-one. Administrative categories (`A.`, `B.`, `D.` or the uncoded
   `ADMINISTRATIVE REQUIREMENTS`) appear throughout and correspond exactly to the 5,509
   `NA`-severity rows.

## Modelling implications

- Staging: rename to snake_case, convert placeholders to nulls, split address into street,
  unit and postal code, standardise outcome labels, and parse severity into a code and a label.
- Intermediate: build an establishment crosswalk that maps legacy numeric IDs to their new ID,
  so each restaurant gets one canonical key.
- Marts: `dim_establishments`, `fct_inspections` (one row per `estId` + date, with infraction
  counts by severity and the worst severity), and optionally `fct_infractions`.
- Tests to add: `unique_id` unique; one status per inspection; severity and status accepted
  values; coordinates within Toronto bounds; fines ≥ 0; one new ID per `oldEstId`.
