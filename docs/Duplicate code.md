# Duplicate Code

## Signs and Symptoms

In a project, **the same transformation logic appears in multiple models** (often copy-pasted with no variations), for example:

- The same `CASE` mapping (countries, channels, plan tiers) repeated across marts.
- The same “cleaning” steps (trim/upper/coalesce/casts) repeated in several staging or mart models.
- The same “latest record” / dedup logic (window functions) duplicated across multiple downstream models.
- Multiple models independently re-implement the same join + derived columns instead of reusing an intermediate model.

## Reasons for the Problem

- **Parallel work + copy/paste**: different people implement similar logic without noticing it already exists elsewhere
- **No clear layering**: transformations that should live in *staging* or *intermediate* get scattered across marts. dbt explicitly recommends pushing “always wanted” transformations upstream to keep code DRY.
- **Underused dbt reuse mechanisms**: Not using **macros/Jinja** for repeated expressions and patterns

## Treatment

Pick the right “extraction” technique depending on what’s duplicated:

- **Same expression repeated** (e.g., mapping / parsing / bucketing): Extract to a **macro** (parameterized, reusable logic).
- **Same subquery / join / enriched dataset repeated**: Extract to an **intermediate model** (`int_*`) and `ref()` it.
- **Entity-specific cleaning repeated downstream**: Move it into the entity’s **staging model** (`stg_*`) as the single entry point.

Rule of thumb: **Macros for repeated expressions; intermediate models for repeated datasets; staging for canonical entity cleanup.**

## Payoff

- **One change, one place**: fixes and new rules don’t require hunting through multiple marts.
- **More consistent metrics & dimensions** (fewer “almost the same” definitions).
- **Cleaner lineage**: downstream marts read like composition, not re-implementation.
- Often **less compute** (dbt staging guidance explicitly calls out avoiding repeated transformations)

## When to Ignore

- The duplication is **truly one-off** and unlikely to repeat again (extracting would add more abstraction than value).
- The logic must intentionally diverge (e.g., the *same* concept defined differently per business domain), and forcing reuse would hide important differences.

## Exemple

### ❌ Smelly version

```sql
-- models/marts/dim_customers.sql
select
  c.customer_id,
  case
    when upper(trim(c.country)) in ('FR','FRANCE') then 'FR'
    when upper(trim(c.country)) in ('UK','UNITED KINGDOM','GB') then 'GB'
    else upper(trim(c.country))
  end as country_code,
  lower(trim(c.email)) as email_normalized
from {{ ref('stg_customers') }} c
```

```sql
-- models/marts/fct_orders.sql
select
  o.order_id,
  o.customer_id,
  -- 💩 same logic duplicated again
  case
    when upper(trim(c.country)) in ('FR','FRANCE') then 'FR'
    when upper(trim(c.country)) in ('UK','UNITED KINGDOM','GB') then 'GB'
    else upper(trim(c.country))
  end as customer_country_code,
  lower(trim(c.email)) as customer_email_normalized,
  o.amount
from {{ ref('stg_orders') }} o
join {{ ref('stg_customers') }} c   on o.customer_id = c.customer_id
```

💩 Two marts both normalize the same fields (country + email)

### ✅ Refactored version

```sql
-- macros/normalize_country.sql
{% macro normalize_country(country_expr) -%}
  case
    when upper(trim({{ country_expr }})) in ('FR','FRANCE') then 'FR'
    when upper(trim({{ country_expr }})) in ('UK','UNITED KINGDOM','GB') then 'GB'
    else upper(trim({{ country_expr }}))
  end
{%- endmacro %}
```

```sql
-- macros/normalize_email.sql
{% macro normalize_email(email_expr) -%}
  lower(trim({{ email_expr }}))
{%- endmacro %}
```

```sql
-- models/staging/stg_customers.sql
select
  c.customer_id,
  {{ normalize_country('c.country') }} as country,
  {{ normalize_email('c.email') }} as email
from {{ ref('stg_customers') }} c
```

```sql
-- models/marts/dim_customers.sql
select
  c.customer_id,
	c.country,
  c.email
from {{ ref('stg_customers') }} c
```

```sql
-- models/marts/fct_orders.sql
select
  o.order_id,
  o.customer_id,
  c.country as customer_country_code,
  c.email as customer_email_normalized,
  o.amount
from {{ ref('stg_orders') }} o
join {{ ref('stg_customers') }} c on o.customer_id = c.customer_id
```