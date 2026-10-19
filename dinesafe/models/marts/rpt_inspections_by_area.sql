-- Inspection outcomes by forward sortation area (the first three characters of the
-- postal code, roughly a neighbourhood). Establishments without a postal code are
-- grouped under a null area. Rates are shares of inspections; small areas are noisy,
-- so filter on inspection_count when ranking.

with inspections as (

    select * from {{ ref('fct_inspections') }}

),

establishments as (

    select establishment_id, forward_sortation_area
    from {{ ref('dim_establishments') }}

)

select
    establishments.forward_sortation_area,
    count(distinct inspections.establishment_id)                    as establishment_count,
    count(*)                                                        as inspection_count,
    count(*) filter (where inspections.is_conditional_pass)         as conditional_pass_count,
    count(*) filter (where inspections.is_closed)                   as closure_count,
    count(*) filter (where inspections.worst_severity_code = 'C')   as inspections_with_crucial_count,
    round(avg(inspections.is_conditional_pass::int), 4)             as conditional_pass_rate,
    round(avg(inspections.is_closed::int), 4)                       as closure_rate,
    round(avg((inspections.worst_severity_code = 'C')::int), 4)     as crucial_infraction_rate,
    round(avg(inspections.infraction_count), 2)                     as avg_infractions_per_inspection,
    sum(inspections.total_amount_fined)                             as total_amount_fined

from inspections
inner join establishments using (establishment_id)
group by 1
