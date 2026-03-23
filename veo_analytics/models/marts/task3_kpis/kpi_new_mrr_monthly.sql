/*
  Task 3 – KPI: Monthly New & Expansion MRR.

  Definition:
    New MRR       = MRR from CreateSubscription orders (net new customers)
    Expansion MRR = MRR from AddProduct orders (upsells on existing customers)
    Net New MRR   = New MRR + Expansion MRR

  Why it matters:
    The single most important SaaS revenue health metric. Separating new vs
    expansion MRR tells the team whether growth comes from acquisition or
    retention/upsell — each requiring different product and GTM responses.

  How to use:
    Monitor month-over-month. A declining new MRR with rising expansion MRR
    suggests top-of-funnel issues. Flat expansion with rising new MRR may
    indicate onboarding / product adoption gaps.

  Additional data needed for full picture:
    Churn/contraction MRR (subscription cancellations or downgrades) — not
    present in this dataset — is required to compute Net MRR accurately.
*/

select
    order_month,

    round(sum(case when order_action_type = 'CreateSubscription' then new_mrr else 0 end), 2)
        as new_mrr,

    round(sum(case when order_action_type = 'AddProduct' then new_mrr else 0 end), 2)
        as expansion_mrr,

    round(sum(new_mrr), 2)
        as net_new_mrr,

    count(distinct case when order_action_type = 'CreateSubscription' then clubhouse_id end)
        as new_customers,

    count(distinct case when order_action_type = 'AddProduct' then clubhouse_id end)
        as upsell_customers

from {{ ref('int_orders_enriched') }}
where new_mrr is not null
  and order_month is not null
group by order_month
order by order_month
