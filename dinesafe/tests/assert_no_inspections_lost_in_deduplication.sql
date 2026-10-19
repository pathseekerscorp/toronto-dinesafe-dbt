-- Removing duplicated legacy-ID inspections must never drop an inspection entirely:
-- every establishment + date in staging should still exist in int_inspections once
-- the establishment ID is mapped to its canonical ID.

with staged_inspections as (

    select distinct
        id_map.canonical_establishment_id as establishment_id,
        records.inspection_date
    from {{ ref('stg_dinesafe__inspection_records') }} as records
    inner join {{ ref('int_establishment_id_map') }} as id_map using (establishment_id)

)

select staged_inspections.*
from staged_inspections
anti join {{ ref('int_inspections') }} as inspections
    using (establishment_id, inspection_date)
