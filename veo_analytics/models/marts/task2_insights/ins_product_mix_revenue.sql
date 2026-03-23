/*
  Task 2 – Insight: Product mix and revenue contribution.

  Why it matters: Understanding the MRR split between Base, Add-on, and Camera
  (hardware) tells the team where subscription revenue comes from and how much
  revenue depends on hardware vs software. It also reveals the Add-on attach
  rate relative to Base subscriptions.

  Note: Camera rows have null new_MRR (hardware doesn't generate recurring
  revenue). We use unit_price × unit_quantity as a hardware revenue proxy.
*/

select
    product_category,
    count(*)                                            as total_line_items,
    count(distinct order_id)                           as distinct_orders,

    -- Software MRR (null for Camera)
    round(sum(new_mrr), 2)                            as total_new_mrr,
    round(avg(new_mrr), 2)                            as avg_mrr_per_line,
    round(
        sum(new_mrr) * 100.0 / sum(sum(new_mrr)) over (), 2
    )                                                  as pct_of_total_mrr,

    -- Hardware / gross order value proxy
    round(sum(unit_price * unit_quantity), 2)         as total_gross_value,

    -- Null MRR rate (should be ~100% for Camera, low for others)
    round(
        sum(case when new_mrr is null then 1 else 0 end) * 100.0 / count(*), 1
    )                                                  as pct_null_mrr

from {{ ref('int_orders_enriched') }}
group by product_category
order by total_new_mrr desc nulls last
