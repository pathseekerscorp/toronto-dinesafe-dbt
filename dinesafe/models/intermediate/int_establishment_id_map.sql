-- One row per establishment ID in the data, mapped to a single canonical ID.
-- The city moved to a new ID system in November 2025. New-format establishments
-- record their old numeric ID in legacy_establishment_id; when that old ID also
-- appears in the data, both IDs are the same restaurant and map to the new ID.

with records as (

    select distinct
        establishment_id,
        legacy_establishment_id,
        is_legacy_establishment_id
    from {{ ref('stg_dinesafe__inspection_records') }}

),

establishment_ids as (

    select distinct establishment_id, is_legacy_establishment_id
    from records

),

legacy_links as (

    select
        legacy_establishment_id as establishment_id,
        establishment_id        as canonical_establishment_id
    from records
    where not is_legacy_establishment_id
      and legacy_establishment_id in (
          select establishment_id from establishment_ids where is_legacy_establishment_id
      )

)

select
    establishment_ids.establishment_id,
    coalesce(legacy_links.canonical_establishment_id, establishment_ids.establishment_id)
        as canonical_establishment_id,
    establishment_ids.is_legacy_establishment_id,
    legacy_links.establishment_id is not null as is_merged_into_new_id

from establishment_ids
left join legacy_links using (establishment_id)
