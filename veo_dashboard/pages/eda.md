---
title: Task 1 — Exploratory Data Analysis
---

# Task 1 · Exploratory Data Analysis

---

## Dataset Structure

| Table | Rows | Grain |
|---|---|---|
| `club_dim` | 34,953 | One row per customer (clubhouse) |
| `order_dim` | 44,080 | One row per order |
| `order_fct` | 86,303 | **One row per product line item** |

`order_fct` is at line-item grain — a single order creates 2–3 rows (Camera + Base + optionally Add-on).

---

## The New Customer / Legacy Account Split

> **Critical context:** You cannot buy a subscription without a camera. Therefore, any `CreateSubscription` order that contains *no camera line item* belongs to an **existing club whose original camera purchase predates this dataset**.

```sql bundles
select * from veo.bundle_types
```

<BarChart
  data={bundles}
  x=bundle_type
  y=orders
  title="Order Volume by Bundle Type"
  swapXY=true
  colorPalette={["#2d6a4f"]}
  labels=true
/>

<DataTable data={bundles}>
  <Column id=bundle_type title="Bundle"/>
  <Column id=orders fmt=num0/>
  <Column id=pct title="% of Orders" fmt=num1 suffix="%"/>
</DataTable>

Applying the new-customer lens:

| Bundle | Customer type | % |
|---|---|---|
| Camera + Sub + Add-on | ✅ New customer, full bundle | 19.8% |
| Camera + Sub | ✅ New customer, no add-on | 19.0% |
| Camera only | ✅ New customer (or replacement camera) | 2.8% |
| Sub only | 🔄 Legacy account — camera predates dataset | 33.5% |
| Sub + Add-on | 🔄 Legacy account expanding features | 13.7% |
| Add-on only | 🔄 Legacy account adding a feature | 10.7% |

**~41.6% of all orders relate to new customer acquisition. ~58.4% relate to managing the existing base.**

---

## Product Category Mix

```sql mix
select * from veo.product_mix
```

<DataTable data={mix}>
  <Column id=product_category title="Category"/>
  <Column id=line_items fmt=num0 title="Line Items"/>
  <Column id=total_mrr fmt=num0 prefix="€" title="Software MRR"/>
  <Column id=avg_mrr_per_line fmt=num2 prefix="€" title="Avg MRR/Line"/>
  <Column id=pct_of_mrr fmt=num1 suffix="%" title="% of MRR"/>
  <Column id=gross_value fmt=num0 prefix="€" title="Gross Value (incl. hardware)"/>
</DataTable>

> Camera rows are always null MRR — hardware doesn't generate recurring revenue. Camera revenue is tracked separately via `unit_price × unit_quantity`.

---

## Data Quality

```sql dq
select * from veo.data_quality
```

<DataTable data={dq}>
  <Column id=check_name title="Check"/>
  <Column id=affected fmt=num0 title="Affected Rows"/>
  <Column id=pct_of_group fmt=num1 suffix="%" title="% of Group"/>
</DataTable>

### Revised interpretation of data quality issues

| Issue | Revised understanding |
|---|---|
| **Camera MRR = 100% null** | Correct by design — hardware, not subscription |
| **75% null subscription length** | Month-to-month subs likely not assigned a term. The most committed cohort (annual) is visible (19%); the largest cohort (monthly) is invisible |
| **11.4% unknown channel** | Can't attribute these to ecommerce or direct — ecommerce share is understated |
| **33.5% sub-only CreateSub orders** | NOT a data quality issue — these are real legacy customers whose camera predates the dataset |
| **0 orphaned order_dim rows** | All order_fct orders have a matching order_dim record — join is clean |
| **321 orphaned club rows (0.37%)** | clubhouse_id in order_fct with no club_dim record — minor pipeline issue |

---

## What this data can and cannot answer

| Question | Feasible? | Gap |
|---|---|---|
| How many true new customers were acquired per month? | ✅ ~674–1,760/mo (camera orders) | — |
| What % of new customers buy an add-on at checkout? | ✅ ~48–50% | No plan tier to exclude Starter |
| Which markets acquire the most new customers? | ✅ | No sport type or season date |
| How many legacy accounts are active (vs churned)? | ❌ | No subscription state / churn events |
| What is customer lifetime value? | ❌ | No renewal or cancellation data |
| What is the Starter → Team upgrade rate? | ❌ | No plan tier in data |
| When did legacy accounts originally purchase? | ❌ | Camera purchase predates dataset |
