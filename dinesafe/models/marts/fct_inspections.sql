-- One row per inspection, with its result, infraction counts, worst severity and fines,
-- plus where it sits in the establishment's inspection history.

with inspections as (

    select * from {{ ref('int_inspections') }}

)

select
    inspection_id,
    establishment_id,
    inspection_date,
    inspection_status,
    inspection_status = 'Pass'                  as is_pass,
    inspection_status = 'Conditional Pass'      as is_conditional_pass,
    inspection_status = 'Closed'                as is_closed,

    infraction_count,
    crucial_count,
    significant_count,
    minor_count,
    not_applicable_count,
    worst_severity_code,
    case worst_severity_code
        when 'C' then 'Crucial'
        when 'S' then 'Significant'
        when 'M' then 'Minor'
        when 'NA' then 'Not Applicable'
    end                                         as worst_severity,

    court_outcome_count,
    total_amount_fined,

    row_number() over establishment_history     as inspection_sequence,
    lag(inspection_date) over establishment_history
                                                as previous_inspection_date,
    inspection_date - lag(inspection_date) over establishment_history
                                                as days_since_previous_inspection,
    lag(inspection_status) over establishment_history
                                                as previous_inspection_status,

    source_establishment_id,
    is_from_legacy_id

from inspections
window establishment_history as (partition by establishment_id order by inspection_date)
