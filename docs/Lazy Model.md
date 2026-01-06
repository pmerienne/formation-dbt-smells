# Lazy Model

## Signs and Symptoms

A **dbt model** that *barely does anything useful* - it contains trivial logic, low transformation value, and is seldom referenced by other models in your DAG.

You’ll notice:

- Models that are simply `SELECT * FROM ref(...)` without enrichment, filtering, or business logic.
- Models that exist only to stage one or two columns and nothing more.
- Models rarely used as dependencies by other models (`downstream model count ≈ 0`).
- Models left over from previous iterations that no longer contribute meaningfully to your analytics workflows.

In other words, the model exists but doesn’t justify its existence given the cost of maintaining and testing it. [refactoring.guru](https://refactoring.guru/smells/lazy-class)

## Reasons for the Problem

A dbt model can become “lazy” for several reasons:

- Originally created for anticipated logic that never materialized.
- Refactoring upstream moved most useful logic elsewhere, leaving this model nearly empty.
- The model was introduced prematurely (speculative generality/premature optimization) and not populated with necessary transformations.
- Lack of clear modeling standards leads to irrelevant intermediates.

## Treatment

**Rule of thumb:** If a model adds negligible value by itself and does not encapsulate reusable logic, consider inlining it or removing it.

### Approaches

- **Collapse Layers →** Merge this model’s logic into its parent (use-case specific transformation) or downstream (common logic) model to reduce unnecessary DAG depth.
- **Delete and Reorganize →** If truly unused (surely a middle man), delete the model and update dependencies to point to the relevant source.

## Payoff

- **Simpler DAG:** Fewer nodes to understand and maintain; faster compilation.
- **Better performance:** Less unnecessary I/O and processing.
- **Improved clarity:** Every model has a clear purpose and transformation value.

## When to Ignore

- The model serves as **documentation** or logical separation of business concepts (e.g., splitting a domain into business entities even if transformation is minimal).
- It’s an intentionally *thin staging model* with standardized naming/formatting that other models rely on for clarity (even if simple).

In those cases, the simplicity may be justified for governance or business logic layering.

## Example

### ❌ Smelly Version

```sql
-- models/stg_customer.sql
select
    customer_id,
    first_name,
    last_name,
    country
from {{ source('app','customers') }}
```

```sql
-- models/stg_customer_enriched.sql
select
    customer_id,
    first_name,
    last_name,
		IF(country IS NULL, '', country) AS country
from {{ref('stg_customer') }}
```

💩 This model does almost nothing except reselect from staging

### ✅ Refactored version

```sql
-- models/stg_customer.sql
select
    customer_id,
    first_name,
    last_name,
		IF(country IS NULL, '', country) AS country
from {{ref('stg_customer_basic') }}
```

🗑️ delete `models/stg_customer_enriched.sql`