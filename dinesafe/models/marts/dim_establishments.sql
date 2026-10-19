-- One row per establishment (legacy and new IDs merged). Descriptive attributes come
-- from the establishment's most recent record, preferring the new ID system; inspection
-- history is summarised from fct_inspections.

with records as (

    select * from {{ ref('int_inspection_records') }}

),

inspections as (

    select * from {{ ref('fct_inspections') }}

),

id_map as (

    select * from {{ ref('int_establishment_id_map') }}

),

latest_attributes as (

    select
        establishment_id,
        establishment_name,
        address,
        street_address,
        unit,
        postal_code,
        forward_sortation_area,
        phone,
        latitude,
        longitude
    from records
    qualify row_number() over (
        partition by establishment_id
        order by is_from_legacy_id, inspection_date desc, snapshot_date desc, record_id
    ) = 1

),

legacy_ids as (

    select
        canonical_establishment_id as establishment_id,
        max(establishment_id)      as legacy_establishment_id
    from id_map
    where is_merged_into_new_id
    group by 1

),

history as (

    select
        establishment_id,
        count(*)                                                as inspection_count,
        min(inspection_date)                                    as first_inspection_date,
        max(inspection_date)                                    as last_inspection_date,
        arg_max(inspection_status, inspection_date)             as last_inspection_status,
        count(*) filter (where inspection_status = 'Conditional Pass')
                                                                as conditional_pass_count,
        count(*) filter (where inspection_status = 'Closed')    as closure_count,
        sum(infraction_count)                                   as infraction_count,
        sum(crucial_count)                                      as crucial_infraction_count,
        sum(total_amount_fined)                                 as total_amount_fined
    from inspections
    group by 1

)

select
    latest_attributes.establishment_id,
    legacy_ids.legacy_establishment_id,
    latest_attributes.establishment_name,
    latest_attributes.address,
    latest_attributes.street_address,
    latest_attributes.unit,
    latest_attributes.postal_code,
    latest_attributes.forward_sortation_area,
    latest_attributes.phone,
    latest_attributes.latitude,
    latest_attributes.longitude,
    history.inspection_count,
    history.first_inspection_date,
    history.last_inspection_date,
    history.last_inspection_status,
    history.conditional_pass_count,
    history.closure_count,
    history.infraction_count,
    history.crucial_infraction_count,
    history.total_amount_fined

from latest_attributes
left join legacy_ids using (establishment_id)
left join history using (establishment_id)
