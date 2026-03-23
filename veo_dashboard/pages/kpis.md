---
title: Task 3 — KPI Framework
---

# Task 3 · KPI Framework

Four core KPIs for the Monetisation (Ecommerce) and Revenue Platform (Subscription Engine) teams.

> **Note:** MRR values in this dataset are synthetic (randomised figures). Actual DKK pricing: Starter €39/mo · Team €62/mo · Club €102/mo · Enterprise €194/mo (annual billing). Add-ons scale with tier: Veo Analytics €34–€83/mo.

---

## KPI 1 · New Hardware Units + Attached Software MRR

**Why:** Cameras are the top of the subscription funnel. Every camera sold creates a subscriber. Tracking units alongside attached MRR reveals whether ecommerce converts hardware purchasers into the right subscription tier — a Starter attachment generates €39/mo recurring; a Club attachment generates €102/mo (2.6×).

```sql cams
select * from veo.camera_monthly
```

<BarChart
  data={cams}
  x=order_month
  y=cameras_sold
  title="KPI 1 · Camera Units Sold per Month"
  yAxisTitle="Units"
  colorPalette={["#2d6a4f"]}
  labels=true
/>

<LineChart
  data={cams}
  x=order_month
  y={["base_mrr","addon_mrr"]}
  title="KPI 1 · Software MRR Attached at Camera Purchase"
  yAxisTitle="€"
  seriesNames={["Base MRR","Add-on MRR"]}
  colorPalette={["#2d6a4f","#74c69d"]}
/>

**Tracking improvement needed:** Camera serial number / device ID to distinguish replacement units (existing subscribers) from new customers. Currently both look identical.

---

## KPI 2 · Net New MRR — New Customers vs Legacy Accounts

**Why:** This is the core SaaS health metric. The dataset contains two distinct MRR sources: **new customers** (camera-containing orders — first purchase) and **legacy accounts** (existing clubs renewing or expanding). Separating them reveals whether MRR growth is driven by acquisition or the existing base — critical for prioritising investment.

```sql mvl
select * from veo.mrr_new_vs_legacy
```

<BarChart
  data={mvl}
  x=order_month
  y={["new_customer_mrr","legacy_mrr"]}
  title="KPI 2 · Software MRR — New Customer vs Legacy Account"
  yAxisTitle="€"
  seriesNames={["New Customer MRR","Legacy Account MRR"]}
  colorPalette={["#1b4332","#74c69d"]}
/>

```sql mrr
select * from veo.monthly_mrr
```

<BarChart
  data={mrr}
  x=order_month
  y={["new_mrr","expansion_mrr","update_mrr"]}
  title="KPI 2b · Monthly MRR by Action Type"
  yAxisTitle="Software MRR (€)"
  seriesNames={["New Sub MRR","Expansion MRR","Upgrade MRR"]}
  colorPalette={["#1b4332","#40916c","#95d5b2"]}
/>

```sql ecom
select * from veo.ecommerce_share
```

<DataTable data={mrr} rows=13>
  <Column id=order_month title="Month"/>
  <Column id=new_mrr fmt=num0 prefix="€" title="New Sub MRR"/>
  <Column id=expansion_mrr fmt=num0 prefix="€" title="Expansion MRR"/>
  <Column id=update_mrr fmt=num0 prefix="€" title="Upgrade MRR"/>
  <Column id=organic_mrr fmt=num0 prefix="€" title="Organic MRR (excl. upgrades)"/>
  <Column id=clubs fmt=num0 title="Active Clubs"/>
</DataTable>

**⚠️ This KPI is currently a vanity metric.** Without cancellation data, "New Sub MRR" can show growth while the business is shrinking. If Veo acquires €100K in new MRR but loses €120K in the same month, this chart looks healthy while revenue contracts. We cannot reliably measure ROI on marketing or ecommerce spend — or make a credible case for channel investment — until `CancelSubscription` / `DowngradeProduct` events with MRR deltas are fed into `order_fct`.

---

## KPI 3 · Ecommerce Share of Orders and MRR (monthly)

**Why:** Directly measures whether the self-serve channel is gaining share — the strategic goal. Currently hovering at ~41–45% of known-channel orders and MRR, with no clear upward trend.

<LineChart
  data={ecom}
  x=order_month
  y={["ecom_order_share_pct","ecom_mrr_share_pct"]}
  title="KPI 3 · Ecommerce Share % — Orders vs MRR"
  yAxisTitle="%"
  seriesNames={["Order Share %","MRR Share %"]}
  colorPalette={["#2d6a4f","#95d5b2"]}
  yMin=30
  yMax=60
/>

<DataTable data={ecom} rows=13>
  <Column id=order_month title="Month"/>
  <Column id=total_orders fmt=num0 title="Total Orders"/>
  <Column id=ecom_orders fmt=num0 title="Ecom Orders"/>
  <Column id=ecom_order_share_pct fmt=num1 suffix="%" title="Ecom Order Share"/>
  <Column id=total_mrr fmt=num0 prefix="€" title="Total MRR"/>
  <Column id=ecom_mrr fmt=num0 prefix="€" title="Ecom MRR"/>
  <Column id=ecom_mrr_share_pct fmt=num1 suffix="%" title="Ecom MRR Share"/>
</DataTable>

**Tracking improvement needed:** Resolve the 11.4% null `order_is_ecommerce_order` flag — joinable via session or event data. Add UTM / acquisition source to distinguish organic self-serve from sales-assisted ecommerce.

---

## KPI 4 · Add-on Attach Rate — New Customers Only (monthly)

**Why:** Highest-margin lever with no acquisition cost. The metric is scoped to **new customers only** (camera-containing CreateSubscription orders) measuring whether a *software* add-on (Veo Live / Analytics / Player Spotlight) was attached at checkout.

The rate sits at **~48–50%** — roughly half of all new customers leave the checkout without a software add-on.

```sql att
select * from veo.attach_rate_corrected
```

<LineChart
  data={att}
  x=order_month
  y={["addon_attach_pct","ecom_attach_pct","direct_attach_pct"]}
  title="KPI 4 · True Add-on Attach Rate — New Customers Only, Flat for 13 Months"
  yAxisTitle="Attach Rate %"
  seriesNames={["Overall","Ecommerce","Direct"]}
  colorPalette={["#1b4332","#40916c","#95d5b2"]}
  yMin=35
  yMax=65
/>

<DataTable data={att} rows=13>
  <Column id=order_month title="Month"/>
  <Column id=new_customers fmt=num0 title="New Customers"/>
  <Column id=with_addon fmt=num0 title="With Software Add-on"/>
  <Column id=addon_attach_pct fmt=num1 suffix="%" title="Overall Attach %"/>
  <Column id=ecom_attach_pct fmt=num1 suffix="%" title="Ecom Attach %"/>
  <Column id=direct_attach_pct fmt=num1 suffix="%" title="Direct Attach %"/>
</DataTable>

**Denominator bias:** Starter-plan customers cannot purchase add-ons. Reporting 48–50% against a denominator that includes Starter customers understates performance and makes checkout optimisation impossible to measure correctly. The fix is plan tier per order — until then, see the Addressable Attach Rate proxy in Insight 3. (2) Checkout funnel events showing whether the add-on offer was shown, clicked, or dismissed are required before any A/B test result is meaningful.

---

## KPI 5 (Bonus) · ARPU by Commitment Level

**Why:** Annual subscribers pay upfront and churn less. At Veo's actual pricing, the annual discount is significant (~37% vs monthly on Team). Tracking commitment level reveals whether the ecommerce checkout is driving long-term commitment or defaulting to monthly.

```sql arpu
select * from veo.arpu
```

<LineChart
  data={arpu}
  x=order_month
  y={["arpu","arpu_annual","arpu_monthly"]}
  title="KPI 5 · ARPU by Commitment Level"
  yAxisTitle="€"
  seriesNames={["Overall ARPU","Annual ARPU","Monthly ARPU"]}
  colorPalette={["#1b4332","#40916c","#95d5b2"]}
/>

<DataTable data={arpu} rows=13>
  <Column id=order_month title="Month"/>
  <Column id=active_clubs fmt=num0 title="Active Clubs"/>
  <Column id=total_mrr fmt=num0 prefix="€" title="MRR"/>
  <Column id=arpu fmt=num2 prefix="€" title="Overall ARPU"/>
  <Column id=arpu_annual fmt=num2 prefix="€" title="Annual ARPU"/>
  <Column id=arpu_monthly fmt=num2 prefix="€" title="Monthly ARPU"/>
</DataTable>

**Tracking improvement needed:** Fix the 75% null `order_subscription_length` for month-to-month subscriptions. A default value of `'1 Month'` for monthly billing orders would immediately make the largest subscriber cohort visible and make this KPI meaningful.

---

## Missing Efficiency KPIs

The current framework is volume-heavy. As Veo scales, efficiency metrics matter as much as unit counts. Two KPIs that cannot be built from the current data but should be defined now:

**CAC Payback Period by Channel** — If Ecommerce is truly "self-serve," its customer acquisition cost should be materially lower than Direct (no account manager time). If it isn't, growing the self-serve channel may be hurting margins, not helping them. This requires marketing spend and headcount cost data joined to acquisition channel.

**Hardware Margin % alongside Subscription Attach** — The camera (€1,300) is the top-of-funnel product. If cameras are priced at or near cost to drive subscription attachment, the unit economics only work if the attached subscription is retained. Tracking hardware margin alongside attached MRR and cohort retention would reveal whether Veo is "buying" subscribers with loss-leader hardware — and whether the 13-month dataset has enough churn signal to evaluate payback.

---

## Tracking Improvements Summary

| Priority | Fix | Impact |
|---|---|---|
| 🔴 Critical | Add `CancelSubscription` action type with MRR delta | Enables Net MRR — current growth metrics are unauditable without it |
| 🔴 Critical | Add plan tier (Starter/Team/Club/Enterprise) per order | Corrects attach rate denominator; enables tier mix and upgrade funnel |
| 🔴 Critical | Resolve 11% null `order_is_ecommerce_order` | Current ecommerce share figures exclude ~11% of orders — skews channel comparison |
| 🟠 High | Fix null `order_subscription_length` for monthly subs | Enables commitment level analysis and CAC payback |
| 🟠 High | Add marketing spend + CAC by channel | Enables efficiency KPIs; required to justify ecommerce channel investment |
| 🟡 Medium | Add checkout funnel events (add-on shown/dismissed) | Required to measure attach rate optimisation experiments |
| 🟡 Medium | Add renewal vs new-purchase flag | Enables LTV comparison between seasonal and off-season cohorts |
| 🟢 Low | Camera serial number for replacement tracking | Cleaner hardware funnel — separates new customers from re-orders |
