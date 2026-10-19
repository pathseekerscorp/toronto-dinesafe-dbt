-- Guards against double-counting migrated history. When the city copied inspections
-- from a legacy ID to the new ID, both copies map to the same inspection_id. All of an
-- inspection's records should come from one published ID; records from two IDs mean
-- the legacy copy wasn't removed and the inspection's infractions are counted twice.

select
    inspection_id,
    count(distinct source_establishment_id) as source_ids
from {{ ref('int_inspection_records') }}
group by 1
having count(distinct source_establishment_id) > 1
