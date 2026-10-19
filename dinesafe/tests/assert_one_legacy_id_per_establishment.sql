-- Each canonical establishment should absorb at most one legacy ID. If two legacy IDs
-- ever map to the same new ID, dim_establishments would show only one of them.

select
    canonical_establishment_id,
    count(*) as merged_legacy_ids
from {{ ref('int_establishment_id_map') }}
where is_merged_into_new_id
group by 1
having count(*) > 1
