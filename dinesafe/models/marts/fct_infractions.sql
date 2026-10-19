-- One row per infraction found during an inspection. Clean inspections (no infractions)
-- have no rows here; see fct_inspections for those.

with records as (

    select * from {{ ref('int_inspection_records') }}

)

select
    record_id                   as infraction_id,
    inspection_id,
    establishment_id,
    inspection_date,
    severity_code,
    severity,
    infraction_category_scheme,
    infraction_category_code,
    infraction_category,
    infraction_description,
    outcome,
    outcome_date,
    amount_fined

from records
where is_infraction
