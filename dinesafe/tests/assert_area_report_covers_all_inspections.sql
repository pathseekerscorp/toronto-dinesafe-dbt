-- The area report should account for every inspection and every dollar fined:
-- no inspection lost to a missing establishment or area.

with report as (

    select sum(inspection_count) as inspections, sum(total_amount_fined) as fines
    from {{ ref('rpt_inspections_by_area') }}

),

facts as (

    select count(*) as inspections, sum(total_amount_fined) as fines
    from {{ ref('fct_inspections') }}

)

select
    report.inspections as report_inspections,
    facts.inspections  as fact_inspections,
    report.fines       as report_fines,
    facts.fines        as fact_fines
from report, facts
where report.inspections <> facts.inspections
   or report.fines <> facts.fines
