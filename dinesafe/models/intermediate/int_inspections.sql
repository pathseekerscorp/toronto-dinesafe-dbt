-- One row per inspection, rolled up from its records. Worst severity is derived from
-- the infractions themselves rather than the published summary sentence, which often
-- understates it (see docs/data_profile.md, finding 3).

with records as (

    select * from {{ ref('int_inspection_records') }}

)

select
    inspection_id,
    establishment_id,
    any_value(source_establishment_id)                      as source_establishment_id,
    bool_or(is_from_legacy_id)                              as is_from_legacy_id,
    inspection_date,
    max(inspection_status)                                  as inspection_status,
    max(inspection_summary)                                 as inspection_summary,

    count(*) filter (where is_infraction)                   as infraction_count,
    count(*) filter (where severity_code = 'C')             as crucial_count,
    count(*) filter (where severity_code = 'S')             as significant_count,
    count(*) filter (where severity_code = 'M')             as minor_count,
    count(*) filter (where severity_code = 'NA')            as not_applicable_count,

    case
        when bool_or(severity_code = 'C') then 'C'
        when bool_or(severity_code = 'S') then 'S'
        when bool_or(severity_code = 'M') then 'M'
        when bool_or(severity_code = 'NA') then 'NA'
    end                                                     as worst_severity_code,

    count(*) filter (where outcome is not null)             as court_outcome_count,
    coalesce(sum(amount_fined), 0)                          as total_amount_fined

from records
group by inspection_id, establishment_id, inspection_date
