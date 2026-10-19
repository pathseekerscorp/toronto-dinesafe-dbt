-- Staging records keyed to the canonical establishment and to an inspection.
-- When the city migrated to its new ID system it copied history across, so many
-- inspections appear under both a restaurant's legacy ID and its new ID on the same
-- date. For those, keep only the new-ID copy (the city's current system of record).
-- Legacy-ID inspections with no new-ID copy are kept.

with records as (

    select * from {{ ref('stg_dinesafe__inspection_records') }}

),

id_map as (

    select * from {{ ref('int_establishment_id_map') }}

),

keyed as (

    select
        records.*,
        records.establishment_id                as source_establishment_id,
        id_map.canonical_establishment_id
    from records
    inner join id_map using (establishment_id)

),

deduplicated as (

    select *
    from keyed
    -- false sorts before true, so new-ID records win when both IDs have the inspection
    qualify dense_rank() over (
        partition by canonical_establishment_id, inspection_date
        order by is_legacy_establishment_id
    ) = 1

)

select
    record_id,
    md5(canonical_establishment_id || '|' || inspection_date::varchar) as inspection_id,
    canonical_establishment_id                                         as establishment_id,
    source_establishment_id,
    is_legacy_establishment_id                                         as is_from_legacy_id,
    * exclude (
        record_id,
        establishment_id,
        source_establishment_id,
        canonical_establishment_id,
        is_legacy_establishment_id,
        legacy_establishment_id
    )

from deduplicated
