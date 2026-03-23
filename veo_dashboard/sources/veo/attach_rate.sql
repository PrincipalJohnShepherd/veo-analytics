WITH ord AS (
    SELECT replace(order_id, chr(65279), '') AS order_id,
           CASE WHEN order_is_ecommerce_order = 'true'  THEN true
                WHEN order_is_ecommerce_order = 'false' THEN false
                ELSE NULL END AS order_is_ecommerce_order
    FROM raw.order_dim
),
fct AS (
    SELECT order_id,
           product_category,
           date_trunc('month', try_cast(order_created_at AS timestamp)) AS order_month,
           order_action_type
    FROM raw.order_fct
),
order_products AS (
    SELECT f.order_id, f.order_month, o.order_is_ecommerce_order,
           max(CASE WHEN f.product_category = 'Base'   THEN 1 ELSE 0 END) AS has_base,
           max(CASE WHEN f.product_category = 'Add-on' THEN 1 ELSE 0 END) AS has_addon,
           max(CASE WHEN f.product_category = 'Camera' THEN 1 ELSE 0 END) AS has_camera
    FROM fct f LEFT JOIN ord o ON f.order_id = o.order_id
    WHERE f.order_action_type = 'CreateSubscription'
      AND f.order_month IS NOT NULL
    GROUP BY f.order_id, f.order_month, o.order_is_ecommerce_order
)
SELECT
    order_month,
    count(*)                                                                                  AS new_subscriptions,
    sum(CASE WHEN has_addon=1 OR has_camera=1 THEN 1 ELSE 0 END)                             AS with_attachment,
    round(sum(CASE WHEN has_addon=1 OR has_camera=1 THEN 1 ELSE 0 END)*100.0/count(*), 1)    AS attach_rate_pct,
    round(sum(CASE WHEN order_is_ecommerce_order=true AND (has_addon=1 OR has_camera=1) THEN 1 ELSE 0 END)*100.0
          / nullif(sum(CASE WHEN order_is_ecommerce_order=true THEN 1 ELSE 0 END), 0), 1)    AS ecom_attach_rate_pct,
    round(sum(CASE WHEN order_is_ecommerce_order=false AND (has_addon=1 OR has_camera=1) THEN 1 ELSE 0 END)*100.0
          / nullif(sum(CASE WHEN order_is_ecommerce_order=false THEN 1 ELSE 0 END), 0), 1)   AS direct_attach_rate_pct
FROM order_products
GROUP BY order_month
ORDER BY order_month
