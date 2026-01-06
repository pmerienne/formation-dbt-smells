{% macro capitalize_first_letter(col_name) %}
    upper(substring({{ col_name }}, 1, 1)) || lower(substring({{ col_name }}, 2))
{% endmacro %}
