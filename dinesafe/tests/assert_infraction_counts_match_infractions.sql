-- Each inspection's infraction_count in fct_inspections should equal the number of
-- rows for that inspection in fct_infractions.

with counted as (

    select inspection_id, count(*) as infraction_rows
    from {{ ref('fct_infractions') }}
    group by 1

)

select
    inspections.inspection_id,
    inspections.infraction_count,
    coalesce(counted.infraction_rows, 0) as infraction_rows
from {{ ref('fct_inspections') }} as inspections
left join counted using (inspection_id)
where inspections.infraction_count <> coalesce(counted.infraction_rows, 0)
