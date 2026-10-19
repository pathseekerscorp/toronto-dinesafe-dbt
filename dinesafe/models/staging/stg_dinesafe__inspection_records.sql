-- One row per DineSafe record: an infraction found during an inspection, or a single
-- "no infraction" row for a clean inspection. Renames, types and cleans the raw
-- columns; no business logic. See docs/data_profile.md for the issues handled here.

with source as (

    select * from {{ source('dinesafe', 'dinesafe') }}

),

-- raw.dinesafe holds every downloaded snapshot, and each snapshot repeats most of the
-- previous one. Keep the latest version of each record.
latest as (

    select *
    from source
    qualify row_number() over (partition by unique_id order by _snapshot_date desc) = 1

),

-- The source writes missing values as the text 'None' (and occasionally 'NA' or
-- 'undefined'); turn them into real nulls before typing.
nulled as (

    select
        * replace (
            nullif(trim(oldEstId), 'None')          as oldEstId,
            nullif(trim(phone), 'None')             as phone,
            nullif(trim(typeDesc), 'None')          as typeDesc,
            nullif(trim(deficiencyDesc), 'None')    as deficiencyDesc,
            nullif(trim(severity), 'None')          as severity,
            nullif(trim(OutcomeDesc), 'None')       as OutcomeDesc
        ),
        -- address is "<street> <unit> <postal code>", where unit and postal code may be 'None'
        regexp_extract(
            address,
            '^(.*) (\S+) ([A-Z][0-9][A-Z] [0-9][A-Z][0-9]|None)$',
            ['street', 'unit', 'postal_code']
        ) as address_parts

    from latest

),

renamed as (

    select
        -- ids
        unique_id                                               as record_id,
        estId                                                   as establishment_id,
        oldEstId                                                as legacy_establishment_id,
        regexp_matches(estId, '^[0-9]+$')                       as is_legacy_establishment_id,

        -- establishment
        trim(estName)                                           as establishment_name,
        trim(address)                                           as address,
        nullif(address_parts.street, '')                        as street_address,
        nullif(nullif(address_parts.unit, ''), 'None')          as unit,
        nullif(nullif(address_parts.postal_code, ''), 'None')   as postal_code,
        left(nullif(nullif(address_parts.postal_code, ''), 'None'), 3)
                                                                as forward_sortation_area,
        case when phone ~ '^0+$' then null else phone end       as phone,
        try_cast(latitude as double)                            as latitude,
        try_cast(longitude as double)                           as longitude,

        -- inspection
        try_cast(inspectionDate as date)                        as inspection_date,
        trim(inspectionStatus)                                  as inspection_status,
        trim(observation)                                       as inspection_summary,

        -- infraction
        severity is not null                                    as is_infraction,
        typeDesc                                                as infraction_description,
        -- Categories use two coding schemes: '5C.' until Nov 2025 and '05.' after, plus
        -- administrative codes ('A.', 'B.', 'D.' or no code) throughout. The schemes
        -- don't map one-to-one, so keep the code as published and label its scheme.
        nullif(regexp_extract(deficiencyDesc, '^(\d{1,2}[A-Z]?|[A-Z])\.\s', 1), '')
                                                                as infraction_category_code,
        coalesce(
            nullif(regexp_extract(deficiencyDesc, '^(?:\d{1,2}[A-Z]?|[A-Z])\.\s+(.*)$', 1), ''),
            deficiencyDesc
        )                                                       as infraction_category,
        case
            when deficiencyDesc is null then null
            when regexp_matches(deficiencyDesc, '^\d{2}\.\s') then 'current'
            when regexp_matches(deficiencyDesc, '^\d[A-Z]\.\s') then 'legacy'
            else 'administrative'
        end                                                     as infraction_category_scheme,
        case severity
            when 'M - Minor' then 'M'
            when 'S - Significant' then 'S'
            when 'C - Crucial' then 'C'
            when 'NA' then 'NA'
        end                                                     as severity_code,
        case severity
            when 'M - Minor' then 'Minor'
            when 'S - Significant' then 'Significant'
            when 'C - Crucial' then 'Crucial'
            when 'NA' then 'Not Applicable'
        end                                                     as severity,

        -- court outcome
        try_cast(OutcomeDate as date)                           as outcome_date,
        replace(OutcomeDesc, 'Conviction: Fined', 'Conviction - Fined')
                                                                as outcome,
        try_cast(amountFined as decimal(10, 2))                 as amount_fined,

        -- metadata
        _snapshot_date                                          as snapshot_date,
        _loaded_at                                              as loaded_at

    from nulled

)

select * from renamed
