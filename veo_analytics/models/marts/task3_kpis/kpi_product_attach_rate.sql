/*
  Task 3 – KPI: Product attach rate (monthly).

  Definition:
    Attach rate = orders containing ≥1 Add-on or Camera line item alongside Base
                  / total CreateSubscription orders

  Why it matters:
    A higher attach rate means customers are buying richer bundles, which
    increases ARPU and reduces churn (customers with more products are stickier).
    For the monetisation team, this is a leading indicator of product mix health
    and the effectiveness of cross-sell surfaces in the ecommerce checkout.

  How to use:
    Segment by channel (ecommerce vs direct) to see if ecommerce checkout
    effectively surfaces add-ons. A low attach rate on ecommerce relative to
    direct suggests a product opportunity for bundle prompting.

  Additional data needed:
    Session/funnel data to see where customers drop off before adding add-ons.
*/

with order_products as (
    select
        order_id,
        order_month,
        order_is_ecommerce_order,
        -- Does this order have a Base product?
        max(case when product_category = 'Base'   then 1 else 0 end) as has_base,
        -- Does it also have an Add-on?
        max(case when product_category = 'Add-on' then 1 else 0 end) as has_addon,
        -- Does it also have a Camera?
        max(case when product_category = 'Camera' then 1 else 0 end) as has_camera
    from {{ ref('int_orders_enriched') }}
    where order_action_type = 'CreateSubscription'
      and order_month is not null
    group by order_id, order_month, order_is_ecommerce_order
)

select
    order_month,

    count(*)                                                                as total_new_subscriptions,

    sum(case when has_addon = 1 then 1 else 0 end)                        as subscriptions_with_addon,
    sum(case when has_camera = 1 then 1 else 0 end)                       as subscriptions_with_camera,
    sum(case when has_addon = 1 or has_camera = 1 then 1 else 0 end)      as subscriptions_with_any_attach,

    round(
        sum(case when has_addon = 1 or has_camera = 1 then 1 else 0 end) * 100.0 / nullif(count(*), 0),
        2
    )                                                                       as attach_rate_pct,

    round(
        sum(case when order_is_ecommerce_order = true
                  and (has_addon = 1 or has_camera = 1) then 1 else 0 end) * 100.0
        / nullif(sum(case when order_is_ecommerce_order = true then 1 else 0 end), 0),
        2
    )                                                                       as ecommerce_attach_rate_pct

from order_products
group by order_month
order by order_month
