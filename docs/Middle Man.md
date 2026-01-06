# Middle Man

## Signs and Symptoms

A **dbt model** acts mainly as a **pass-through**, selecting columns from another model (or source) with little to no transformation, business logic, or aggregation.

Typical smells:

- A model is just `select * from {{ ref('another_model') }}` with minor renaming.
- A model exists only to wrap another model for “convenience” or naming, but adds no semantic meaning.
- Long chains of models where each layer only forwards columns (`A → B → C`) without clear responsibility.

In practice, the model is just an **unnecessary hop in the lineage graph**.

## Reasons for the Problem

- Over-layering: teams mechanically create *staging → intermediate → mart* even when one layer adds no value.
- Legacy refactors where logic was removed but the model remained.

## Treatment

**Remove or merge the middle-man model** so each model has a clear responsibility.

Guidelines:

- If a model adds **no transformations, no semantic renaming, and no reuse value** → delete it.
- If the model only exists to rename or expose columns → merge that logic into:
    - the upstream staging model (if entity-level), or
    - the downstream mart (if use-case-specific).
- Prefer **fewer, meaningful models** over many empty abstractions.

Rule of thumb: Every dbt model should answer “what new thing does this model define?”

## Payoff

- Simpler lineage graphs (easier to reason about and debug).
- Faster builds (fewer models to materialize).
- Less cognitive overhead for new contributors.
- Clearer ownership: each model has a reason to exist.

## When to Ignore

- The middle model is intentionally kept as a **stable contract / API boundary** (e.g., exposing a public model to BI tools).
- The model exists for **governance or access control** reasons (grants, masking, exposures).

## Exemple

### ❌ Smelly version

```sql
-- models/staging/stg_payments.sql
select
    payment_id,
    order_id,
    amount,
    status
from {{ source('app', 'payments') }}
```

```sql
-- models/intermediate/int_payments.sql
select *
from {{ ref('stg_payments') }}
```

```sql
-- models/marts/fct_payments.sql
select
    o.order_id,
    p.amount,
    p.status
from {{ ref('stg_orders') }} o
left join {{ ref('int_payments') }} p on o.order_id = p.order_id
```

💩 Here, `int_payments` simply delegates data access without transformation or any added value

### ✅ Refactored version

```sql
-- models/staging/stg_payments.sql
select
    payment_id,
    order_id,
    amount,
    status
from {{ source('app', 'payments') }}
```

```sql
-- 🗑️ deleted: models/intermediate/int_payments.sql
```

```sql
-- models/marts/fct_payments.sql
select
    o.order_id,
    p.amount,
    p.status
from {{ ref('stg_orders') }} o
left join {{ ref('stg_payments') }} p on o.order_id = p.order_id
```