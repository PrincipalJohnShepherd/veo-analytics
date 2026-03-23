/*
  Task 2 – Insight: Monthly MRR trend split by action type.

  Why it matters: Separating New MRR (CreateSubscription) from Expansion MRR
  (AddProduct) shows whether growth is driven by new customer acquisition vs
  upselling existing customers — critical context for a self-service product
  team optimising the funnel.
*/

with monthly as (
    select
        order_month,
        order_action_type,
        round(sum(new_mrr), 2)          as new_mrr,
        count(distinct order_id)        as orders,
        count(distinct clubhouse_id)   as clubs
    from {{ ref('int_orders_enriched') }}
    where new_mrr is not null
      and order_month is not null
    group by order_month, order_action_type
),

pivoted as (
    select
        order_month,
        sum(case when order_action_type = 'CreateSubscription' then new_mrr  else 0 end) as new_subscription_mrr,
        sum(case when order_action_type = 'AddProduct'         then new_mrr  else 0 end) as expansion_mrr,
        sum(case when order_action_type = 'UpdateProduct'      then new_mrr  else 0 end) as update_mrr,
        sum(new_mrr)                                                                      as total_mrr,
        sum(orders)                                                                       as total_orders,
        sum(clubs)                                                                        as total_clubs
    from monthly
    group by order_month
)

select
    order_month,
    new_subscription_mrr,
    expansion_mrr,
    update_mrr,
    total_mrr,
    total_orders,
    total_clubs,
    -- Month-over-month growth
    round(
        (total_mrr - lag(total_mrr) over (order by order_month))
        * 100.0 / nullif(lag(total_mrr) over (order by order_month), 0),
        2
    ) as mrr_mom_pct_change
from pivoted
order by order_month
