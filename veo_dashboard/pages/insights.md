---
title: Task 2 — Insights
---

# Task 2 · Deriving Insights

Three prioritised insights for the product group responsible for Veo's self-service purchasing and subscription flows.

---

## Insight 1 · Seasonality is an operational risk as much as a revenue opportunity

Camera sales and new subscription MRR follow a consistent seasonal curve. European markets (UK, Germany, France) spike in **July–August** when football seasons start. Australia spikes in **February–March** (their autumn season). The US is steadiest, reflecting a wider mix of sports.

```sql cams
select * from veo.camera_monthly
```

<BarChart
  data={cams}
  x=order_month
  y={["base_mrr","addon_mrr","hardware_revenue"]}
  title="Monthly Revenue — Software MRR vs Hardware Sales"
  yAxisTitle="€"
  seriesNames={["Base MRR","Add-on MRR","Camera Hardware Rev"]}
  colorPalette={["#2d6a4f","#74c69d","#d8f3dc"]}
  labels=false
/>

<LineChart
  data={cams}
  x=order_month
  y=cameras_sold
  title="Camera Units Sold per Month — Concentrated Peak"
  yAxisTitle="Units Sold"
  colorPalette={["#1b4332"]}
/>

```sql country
select * from veo.revenue_by_country
```

<BarChart
  data={country}
  x=country_name
  y=total_mrr
  title="Total Software MRR by Country (Top 20)"
  yAxisTitle="€"
  swapXY=true
  colorPalette={["#40916c"]}
/>

### The risk framing

Revenue concentrated in a 6-week window creates operational scalability problems: fulfilment, onboarding, and support all spike together. A 10% conversion improvement in August is worth more revenue than the same improvement in December — but it also means a 10% conversion *failure* in August causes disproportionate damage.

The strategic question the data raises but cannot yet answer: **do off-season buyers have higher LTV or lower churn?** If a club that buys in May (deliberate, planned purchase) retains better than one that buys in August (peak-of-urgency impulse), the optimal strategy is not just "be ready for August" — it is **incentivising early-bird purchases in May/June** to smooth fulfilment load and potentially improve cohort quality.

### What's needed to validate

A renewal flag per order would allow direct LTV comparison between August cohorts and off-season cohorts. Country-level season calendars would enable market-specific pre-season campaign timing. Until then, test early-bird pricing in one market (e.g. Australia off-season) as a controlled experiment.

---

## Insight 2 · The Ecommerce ARPU gap is probably structural — but we need to rule out selection bias first

```sql ch
select * from veo.channel_summary
```

<DataTable data={ch}>
  <Column id=channel title="Channel"/>
  <Column id=total_orders fmt=num0 title="Orders"/>
  <Column id=total_mrr fmt=num0 prefix="€" title="Total MRR"/>
  <Column id=avg_mrr_per_line fmt=num2 prefix="€" title="Avg MRR/Line"/>
  <Column id=pct_base fmt=num1 suffix="%" title="% Base"/>
  <Column id=pct_addon fmt=num1 suffix="%" title="% Add-on"/>
  <Column id=pct_camera fmt=num1 suffix="%" title="% Camera"/>
</DataTable>

The product mix is **virtually identical across channels** — ~44% Base, ~34% Add-on, ~21% Camera. The ARPU gap is not about product selection.

```sql chperf
select * from veo.channel_performance
```

<BarChart
  data={chperf}
  x=order_action_type
  y=mrr
  series=channel
  title="MRR by Action Type and Channel — UpdateProduct is the Gap"
  yAxisTitle="€"
  colorPalette={["#2d6a4f","#74c69d","#d8f3dc"]}
/>

**Direct UpdateProduct MRR = €294K vs Ecommerce = €34K (8.5× gap).** The entire ARPU gap is explained by plan upgrades processed via account managers. For new subscriptions and add-on purchases, the channels are proportionally similar.

### The selection bias question

Before concluding "we need a self-serve upgrade button," we must ask whether Direct and Ecommerce customers are the same type of club. Large academies and professional clubs likely *require* an account manager for procurement and also have the budget for Enterprise-tier upgrades. Small community clubs buying self-serve may stay on Starter/Team not because the upgrade path is missing — but because the higher tier is out of reach.

The data below segments UpdateProduct MRR by country and channel. If Ecommerce clubs in major markets (UK, US, DE) exist but generate near-zero upgrade MRR while Direct clubs in the same markets do not — that is a UI/UX gap. If Ecommerce clubs simply don't appear at the enterprise end in those countries, it is a customer-mix problem.

```sql upd
select * from veo.updateproduct_by_country
```

<DataTable data={upd}>
  <Column id=country_name title="Country"/>
  <Column id=channel title="Channel"/>
  <Column id=upgrade_orders fmt=num0 title="Upgrade Orders"/>
  <Column id=update_mrr fmt=num0 prefix="€" title="UpdateProduct MRR"/>
  <Column id=avg_mrr_per_order fmt=num0 prefix="€" title="Avg MRR/Order"/>
</DataTable>

### Recommendation

If the table above shows **Ecommerce upgrade orders exist** in the top countries but with materially lower avg MRR per order, the intervention is a self-serve tier upgrade flow. If Ecommerce upgrade orders are near zero in countries where Direct is high, the intervention is in the sales handoff — identifying ecommerce clubs that hit a usage threshold and routing them to an account manager.

### What's needed to validate

Reason codes on UpdateProduct events (price change, tier upgrade, seat expansion) and a club-size signal (number of users, footage volume) to properly separate large-club vs small-club cohorts.

---

## Insight 3 · The reported 48–50% attach rate includes customers who cannot buy add-ons

The attach rate measures how many **new customers** (camera-containing CreateSubscription orders) also add a software feature (Veo Live / Analytics / Player Spotlight) at checkout.

```sql att
select * from veo.attach_rate_corrected
```

<LineChart
  data={att}
  x=order_month
  y={["addon_attach_pct","ecom_attach_pct","direct_attach_pct"]}
  title="Reported Add-on Attach Rate — New Customers Only"
  yAxisTitle="Attach Rate %"
  seriesNames={["Overall","Ecommerce","Direct"]}
  colorPalette={["#1b4332","#40916c","#95d5b2"]}
  yMin=35
  yMax=65
/>

The rate sits at **~48–50%** and has not moved in 13 months. Ecommerce and Direct perform identically — this is organic demand, not deliberate optimisation.

### The denominator problem

Starter-plan customers (€39/mo) **cannot purchase add-ons**. They are in the denominator of the 48–50% figure, which means we are reporting a lower number than what is actually achievable. If 30% of new customers are on Starter, the 50% rate may actually represent ~70% of the addressable market already buying — a very different picture.

The query below proxies plan tier from `unit_price` (Starter ≤€50 threshold). **Note: unit_prices in this dataset are synthetic — treat these percentages as illustrating the methodology, not as production figures.**

```sql addr
select * from veo.addressable_attach_rate
```

<DataTable data={addr}>
  <Column id=order_month title="Month"/>
  <Column id=total_new_customers fmt=num0 title="Total New Customers"/>
  <Column id=starter_proxy_count fmt=num0 title="Likely Starter (excl.)"/>
  <Column id=addressable_count fmt=num0 title="Addressable (Team+)"/>
  <Column id=reported_attach_pct fmt=num1 suffix="%" title="Reported Rate"/>
  <Column id=addressable_attach_pct fmt=num1 suffix="%" title="Addressable Rate"/>
</DataTable>

The gap between *Reported Rate* and *Addressable Rate* is the size of the denominator bias. With real plan tier data, this is a single query. Until then, adding plan tier per order is the highest-priority data fix.

### The opportunity at actual pricing (€, annual billing)

| Add-on | Team | Club | Enterprise |
|---|---|---|---|
| Veo Live | €20/mo | €35/mo | €50/mo |
| Veo Analytics | €34/mo | €45/mo | €83/mo |
| Player Spotlight | €43/mo | €56/mo | ~€83/mo |

A **5pp lift** in addressable attach rate at peak season (~800 new Team+ customers in August) adds **~€640 MRR/month** at blended Team-tier pricing, compounding on renewal. On Club-tier customers, the same lift is worth 2–3× more.

### Why it matters

Add-ons are the highest-margin lever with no acquisition cost and no hardware. The flat rate over 13 months confirms this has never been actively tested. Before investing in checkout optimisation, establish the correct denominator — otherwise we cannot measure whether interventions work.
