/*
  Task 3 – KPI: Ecommerce channel share of orders and MRR (monthly).

  Definition:
    Ecommerce share (orders) = ecommerce orders / total orders with known channel
    Ecommerce share (MRR)    = ecommerce MRR    / total MRR with known channel

  Why it matters:
    The strategic goal is to grow self-service revenue. This KPI tracks whether
    the ecommerce channel is gaining share — a proxy for operational scalability
    and reduced cost-of-sale.

  How to use:
    A rising ecommerce share indicates the self-serve funnel is improving.
    Stagnation despite investment signals friction in the checkout/onboarding
    flow that product teams should investigate.

  Improvement suggestions:
    - Tag each order with a UTM source or acquisition channel to distinguish
      organic self-serve from sales-assisted ecommerce.
    - Resolve the ~11% null is_ecommerce_order flag (possibly via session or
      event data join).
*/

select
    order_month,

    count(distinct order_id)                                        as total_orders,
    count(distinct case when order_is_ecommerce_order = true  then order_id end) as ecommerce_orders,
    count(distinct case when order_is_ecommerce_order = false then order_id end) as direct_orders,

    round(
        count(distinct case when order_is_ecommerce_order = true then order_id end) * 100.0
        / nullif(count(distinct case when order_is_ecommerce_order is not null then order_id end), 0),
        2
    )                                                               as ecommerce_order_share_pct,

    round(sum(new_mrr), 2)                                         as total_mrr,
    round(sum(case when order_is_ecommerce_order = true  then new_mrr else 0 end), 2) as ecommerce_mrr,

    round(
        sum(case when order_is_ecommerce_order = true then new_mrr else 0 end) * 100.0
        / nullif(sum(case when order_is_ecommerce_order is not null then new_mrr end), 0),
        2
    )                                                               as ecommerce_mrr_share_pct

from {{ ref('int_orders_enriched') }}
where order_month is not null
group by order_month
order by order_month
