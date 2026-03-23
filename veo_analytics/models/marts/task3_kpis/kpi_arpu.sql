/*
  Task 3 – KPI: Monthly Average Revenue Per User (ARPU).

  Definition:
    ARPU = Total New MRR in month / Distinct active clubhouses in month
    (where "active" = placed at least one order with MRR in that month)

  Why it matters:
    ARPU tracks whether revenue is growing faster or slower than the customer
    base. Rising ARPU indicates successful upsell/pricing improvement. Flat
    ARPU with growing customers suggests commoditisation risk.

  How to use:
    Segment by channel and subscription length to see whether ecommerce or
    annual customers have higher ARPU — informs pricing page and packaging
    decisions.

  Improvement suggestions:
    True ARPU should be calculated on a full active subscriber base (not just
    orders in a given month). This requires a subscription state table tracking
    active/inactive status per club per month — not currently available.
*/

select
    order_month,

    count(distinct clubhouse_id)                as active_clubs,
    round(sum(new_mrr), 2)                     as total_new_mrr,

    round(
        sum(new_mrr) / nullif(count(distinct clubhouse_id), 0),
        2
    )                                           as arpu,

    -- ARPU by subscription length (proxy for commitment level)
    round(
        sum(case when order_subscription_length = '12 Months' then new_mrr else 0 end)
        / nullif(count(distinct case when order_subscription_length = '12 Months' then clubhouse_id end), 0),
        2
    )                                           as arpu_annual,

    round(
        sum(case when order_subscription_length = '1 Month' then new_mrr else 0 end)
        / nullif(count(distinct case when order_subscription_length = '1 Month' then clubhouse_id end), 0),
        2
    )                                           as arpu_monthly

from {{ ref('int_orders_enriched') }}
where new_mrr is not null
  and order_month is not null
group by order_month
order by order_month
