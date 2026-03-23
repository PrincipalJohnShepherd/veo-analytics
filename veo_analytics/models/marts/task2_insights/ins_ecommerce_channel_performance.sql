/*
  Task 2 – Insight: Ecommerce vs direct channel performance.

  Why it matters: The product group's primary goal is to grow revenue through
  self-service / e-commerce. This model compares channel split by MRR, order
  volume, avg order value, and product mix — revealing whether the ecommerce
  channel is performing at par with (or better than) direct sales.

  Key data quality note: ~11% of orders have a NULL is_ecommerce_order flag —
  these are kept as a separate "Unknown" segment so they don't distort either
  channel's figures.
*/

select
    case
        when order_is_ecommerce_order = true  then 'Ecommerce'
        when order_is_ecommerce_order = false then 'Direct'
        else 'Unknown'
    end                                             as channel,

    count(distinct order_id)                        as total_orders,
    count(distinct clubhouse_id)                   as distinct_clubs,
    count(*)                                        as total_line_items,

    round(sum(new_mrr), 2)                         as total_new_mrr,
    round(avg(new_mrr), 2)                         as avg_mrr_per_order,
    round(sum(unit_price * unit_quantity), 2)      as total_gross_value,

    -- Product mix within channel
    round(
        sum(case when product_category = 'Base'   then 1 else 0 end) * 100.0 / count(*), 1
    )                                               as pct_base,
    round(
        sum(case when product_category = 'Add-on' then 1 else 0 end) * 100.0 / count(*), 1
    )                                               as pct_addon,
    round(
        sum(case when product_category = 'Camera' then 1 else 0 end) * 100.0 / count(*), 1
    )                                               as pct_camera,

    -- Payment method mix
    round(
        sum(case when order_payment_type = 'Credit Card' then 1 else 0 end) * 100.0 / count(*), 1
    )                                               as pct_credit_card

from {{ ref('int_orders_enriched') }}
group by order_is_ecommerce_order
order by total_new_mrr desc nulls last
