{% docs __overview__ %}
# Toronto DineSafe analytics

This project models the City of Toronto's [DineSafe](https://open.toronto.ca/dataset/dinesafe/)
food safety inspection data, published daily on the Toronto Open Data portal.

## Layers

- **Staging** (`stg_`): one cleaned, typed record per infraction, or per clean inspection.
  Text placeholders become nulls, addresses are split into street, unit and postal code,
  and labels are standardised.
- **Intermediate** (`int_`): merges establishments that appear under both a legacy and a new
  ID after the city's November 2025 system migration, removes the inspections the migration
  duplicated, and rolls records up to inspections.
- **Marts**: `dim_establishments`, `fct_inspections`, `fct_infractions` and the
  `rpt_inspections_by_area` summary, ready for analysis.

## Things to know about the data

- Each source row is one infraction; an inspection is identified by establishment and date.
- The published summary sentence often understates an inspection's worst infraction, so the
  models derive severity from the infractions themselves.
- Infraction categories use two coding schemes (legacy until November 2025, current after)
  that don't map one-to-one.
- The data covers a rolling window of recent inspections, not full history.

Use the lineage graph (bottom right) to see how models connect. The full data profile is in
`docs/data_profile.md` in the repository.
{% enddocs %}


{% docs col_establishment_name %}
Establishment name.
{% enddocs %}

{% docs col_address %}
Full address as published, including 'None' placeholders.
{% enddocs %}

{% docs col_street_address %}
Street number and name.
{% enddocs %}

{% docs col_unit %}
Unit, floor or building designation (e.g. Unit-F, Flr-2), if any.
{% enddocs %}

{% docs col_postal_code %}
Canadian postal code (e.g. M4A 1X1), if present.
{% enddocs %}

{% docs col_forward_sortation_area %}
First three characters of the postal code, a neighbourhood-level area (e.g. M4A).
{% enddocs %}

{% docs col_phone %}
Phone number, null when missing or a placeholder of zeros.
{% enddocs %}

{% docs col_latitude %}
Latitude of the establishment.
{% enddocs %}

{% docs col_longitude %}
Longitude of the establishment.
{% enddocs %}

{% docs col_inspection_date %}
Date of the inspection.
{% enddocs %}

{% docs col_inspection_status %}
Result of the inspection: Pass, Conditional Pass, Closed or Temporarily Not Operating.
{% enddocs %}

{% docs col_inspection_summary %}
Summary sentence published with the inspection. Unreliable: it often understates the most
severe infraction, so use severity instead.
{% enddocs %}

{% docs col_is_infraction %}
False for the single row recorded for an inspection with no infractions.
{% enddocs %}

{% docs col_infraction_description %}
Description of the infraction, citing the regulation breached.
{% enddocs %}

{% docs col_infraction_category_code %}
Category code as published, e.g. '05' (current scheme), '5C' (legacy scheme) or 'A'
(administrative). Null for the uncoded 'ADMINISTRATIVE REQUIREMENTS' category.
{% enddocs %}

{% docs col_infraction_category %}
Infraction category, without its code prefix. Legacy-scheme text is often truncated at source.
{% enddocs %}

{% docs col_infraction_category_scheme %}
Which category coding scheme the row uses: current, legacy or administrative. The city
switched from the legacy scheme to the current one in early November 2025; the two don't map
one-to-one.
{% enddocs %}

{% docs col_severity_code %}
M, S, C or NA. Null when there is no infraction.
{% enddocs %}

{% docs col_severity %}
Minor, Significant, Crucial or Not Applicable. Not Applicable is used for administrative
infractions such as no supervisor present or no licence.
{% enddocs %}

{% docs col_outcome_date %}
Date of the court outcome, if the infraction went to court.
{% enddocs %}

{% docs col_outcome %}
Court outcome, with the two spellings of "Conviction - Fined" merged.
{% enddocs %}

{% docs col_amount_fined %}
Fine in dollars, if any.
{% enddocs %}

{% docs col_snapshot_date %}
Date the city last refreshed the snapshot this record came from.
{% enddocs %}

{% docs col_loaded_at %}
When the record was loaded into DuckDB.
{% enddocs %}
