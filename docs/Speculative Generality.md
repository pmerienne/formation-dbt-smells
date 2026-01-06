# Speculative Generality

## Signs and Symptoms

A **dbt project** contains **overly generic models, columns, parameters, or macros** designed for hypothetical future use cases rather than current, concrete requirements.

Typical smells in practice:

- Models with many nullable or unused columns like `payment_method`, `currency`, `environment`, “just in case”.
- One “universal” model handling multiple business scenarios that don’t exist yet.
- Macros with excessive parameters or branching logic (`if`, `case`) that are never (or barely) used.
- Abstract intermediate layers that are referenced by only one downstream model.
- Commented-out joins, metrics, or filters “for future use”.

## Reasons for the Problem

- Fear of schema changes or refactors later, leading to premature abstraction.
- Over-application of OOP design principles (interfaces, extensibility) to SQL/dbt.
- Teams trying to design a “perfect” data model upfront instead of evolving it incrementally.
- Misunderstanding dbt’s strength: **cheap refactoring with clear lineage and version control**.

## Treatment

Rule of thumb: **Model what exists today, not what might exist tomorrow.**

- Remove unused columns, joins, and parameters.
- Prefer **specific, concrete models** over generic “one-size-fits-all” models.
- Introduce new columns, dimensions, or abstractions **only when at least one real downstream use exists**.
- Split models when speculative branches start to appear (“this will be used later…”).
- Keep macros minimal; extract complexity only after duplication appears.

## Payoff

- Simpler SQL that is easier to read and review.
- Clearer lineage: every column and model has a reason to exist.
- Faster onboarding for new team members.
- Less cognitive overhead when changing or debugging models.
- Easier evolution when real requirements actually appear.

## When to Ignore

- You are building a **shared, contract-driven dataset** with known, imminent consumers and agreed future fields.
- Regulatory or contractual requirements force you to expose a broader schema upfront.
- A macro or abstraction is already reused across multiple models or packages.

In short: ignore only when the future is **certain**, not speculative.

## Exemple

### ❌ Smelly version

```sql
-- models/intermediate/int_orders_time_grain.sql
select
    order_id,
    order_date,
    date_trunc('day', order_date) as order_day,
    date_trunc('week', order_date) as order_week,
    date_trunc('month', order_date) as order_month,
    date_trunc('quarter', order_date) as order_quarter,
    date_trunc('year', order_date) as order_year,
    amount
from {{ ref('stg_orders') }}
```

```sql
-- models/marts/fct_daily_sales.sql
select
    order_day,
		sum(amount) as total_sales
from {{ ref('int_orders_time_grain') }}
group by order_day
```

💩 Smells here: Only **daily reporting** exists today, yet five extra date columns are materialized

### ✅ Refactored version

```sql
-- models/intermediate/int_orders_time_grain.sql
select
    order_id,
    order_date,
    amount
from {{ ref('stg_orders') }}
```

```sql
-- models/marts/fct_daily_sales.sql
select
		DATE_TRUNC('day', order_date) AS order_day,
		SUM(amount) AS total_sales
FROM {{ ref('int_orders_time_grain') }}
GROUP BY order_day
```

✅ Now multiple marts can responsibly own their grain ⇒ there’s no muda anymore