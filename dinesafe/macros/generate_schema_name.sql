{#
    Use a model's custom schema name as-is (e.g. "staging") instead of dbt's default
    of prefixing it with the target schema (e.g. "main_staging"). This is a
    single-developer local project, so there are no per-developer schemas to keep apart.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
