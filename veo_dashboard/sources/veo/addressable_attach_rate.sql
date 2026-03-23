/*
  Addressable attach rate: exclude Starter-tier subscriptions from the denominator.
  Starter customers cannot purchase add-ons, so including them understates the true rate.

  Plan tier is not recorded in the data. We proxy using the unit_price of the Base
  subscription line. Annual pricing: Starter ≤€39/mo → we flag unit_price ≤ 50 as
  "Likely Starter". NOTE: unit_prices in this dataset are synthetic (randomised) —
  the percentages are illustrative of the methodology, not precise production figures.
*/
WITH ord AS (
    SELECT replace(order_id, chr(65279), '') AS order_id,
           CASE WHEN order_is_ecommerce_order='true'  THEN 'Ecommerce'
                WHEN order_is_ecommerce_order='false' THEN 'Direct'
                ELSE 'Unknown' END AS channel
    FROM raw.order_dim
),
order_lines AS (
    SELECT f.order_id,
           date_trunc('month', try_cast(f.order_created_at AS timestamp)) AS order_month,
           o.channel,
           f.product_category,
           try_cast(f.unit_price AS double) AS unit_price
    FROM raw.order_fct f
    LEFT JOIN ord o ON f.order_id = o.order_id
    WHERE f.order_action_type = 'CreateSubscription'
),
order_summary AS (
    SELECT order_id,
           order_month,
           channel,
           max(CASE WHEN product_category='Camera' THEN 1 ELSE 0 END) AS has_camera,
           max(CASE WHEN product_category='Add-on' THEN 1 ELSE 0 END) AS has_addon,
           max(CASE WHEN product_category='Base' THEN unit_price ELSE NULL END) AS base_price
    FROM order_lines
    GROUP BY order_id, order_month, channel
    HAVING max(CASE WHEN product_category='Camera' THEN 1 ELSE 0 END) = 1
),
classified AS (
    SELECT *,
           CASE WHEN base_price IS NULL OR base_price <= 50
                THEN 1 ELSE 0 END AS is_starter_proxy
    FROM order_summary
)
SELECT
    order_month,
    count(*)                                                          AS total_new_customers,
    sum(is_starter_proxy)                                            AS starter_proxy_count,
    count(*) - sum(is_starter_proxy)                                 AS addressable_count,
    round(sum(has_addon)*100.0 / count(*), 1)                        AS reported_attach_pct,
    round(
        sum(CASE WHEN is_starter_proxy=0 AND has_addon=1 THEN 1 ELSE 0 END)*100.0
        / nullif(sum(CASE WHEN is_starter_proxy=0 THEN 1 ELSE 0 END), 0)
    , 1)                                                              AS addressable_attach_pct
FROM classified
WHERE order_month IS NOT NULL
GROUP BY order_month
ORDER BY order_month
