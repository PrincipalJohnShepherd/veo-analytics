---
title: Veo — Analytics Overview
---

# Veo Order Analytics
**Product Analyst Assignment · March 2026 · Synthetic data**

Three datasets: **34,953 clubs · 44,080 orders · 86,303 line items** · Jan 2025 – Jan 2026

> **Key framing:** You cannot buy a subscription without a camera. So any `CreateSubscription` order *without* a camera belongs to a legacy account whose hardware purchase predates this dataset. All "new customer" metrics below use camera-containing orders as the proxy for first purchase.

---

```sql summary
select * from veo.summary_kpis
```

<BigValue data={summary} value=total_clubs       title="Total Clubs"       fmt=num0/>
<BigValue data={summary} value=total_cameras_sold title="Cameras Sold"      fmt=num0/>
<BigValue data={summary} value=total_software_mrr title="Total Software MRR" fmt=num0 prefix="€"/>
<BigValue data={summary} value=total_hardware_rev  title="Hardware Revenue"  fmt=num0 prefix="€"/>

---

## New Customers vs Legacy Accounts

```sql ctype
select * from veo.customer_type_monthly
```

<BarChart
  data={ctype}
  x=order_month
  y={["new_customers","legacy_activations"]}
  title="Monthly CreateSubscription — True New Customers vs Legacy Accounts"
  yAxisTitle="Orders"
  seriesNames={["New Customers (camera in order)","Legacy Accounts (camera predates dataset)"]}
  colorPalette={["#1b4332","#95d5b2"]}
/>

Legacy accounts consistently outnumber new customers (~58% vs 42% of CreateSubscription orders). The business is not purely driven by new acquisition — managing the existing base matters as much as winning new logos.

## Monthly Software MRR — New vs Legacy

```sql mvl
select * from veo.mrr_new_vs_legacy
```

<BarChart
  data={mvl}
  x=order_month
  y={["new_customer_mrr","legacy_mrr"]}
  title="Software MRR — New Customer vs Legacy Account"
  yAxisTitle="€"
  seriesNames={["New Customer MRR","Legacy Account MRR"]}
  colorPalette={["#1b4332","#74c69d"]}
/>

---

## Three Headline Findings

<Alert status="info">
**1 · The add-on attach rate is ~48–50% — and has been flat for 13 months.**
Half of all new customers (those buying a camera) leave the checkout without a software add-on (Veo Live / Analytics / Spotlight). This has never moved, which means it reflects organic demand — not deliberate optimisation.
</Alert>

<Alert status="warning">
**2 · Legacy accounts are 58% of new subscription orders and drive a comparable share of MRR.**
Sub-only CreateSubscription orders are existing clubs whose camera predates the dataset. They represent a large, undertracked renewal and expansion base — yet there is no churn data to monitor them.
</Alert>

<Alert status="positive">
**3 · Season-start (Aug) is 3× December — and both new and legacy accounts peak together.**
The football calendar drives purchasing for both cohorts simultaneously, suggesting clubs buy (or re-activate) in bulk before the season regardless of when their camera was bought.
</Alert>

---

*[EDA](/eda) · [Insights](/insights) · [KPIs](/kpis)*
