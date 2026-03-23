/*
  Corrected Add-on attach rate — new customers only (camera in order).

  The original attach_rate.sql counted Camera as "attachment" which is
  meaningless (you must buy a camera to subscribe). This model measures the
  true rate: how many new customers (camera order) also add a software add-on
  (Veo Live / Analytics / Player Spotlight) at time of first purchase.
*/
WITH ord AS (
    SELECT replace(order_id, chr(65279), '') AS order_id,
           CASE WHEN order_is_ecommerce_order='true'  THEN 'Ecommerce'
                WHEN order_is_ecommerce_order='false' THEN 'Direct'
                ELSE 'Unknown' END AS channel
    FROM raw.order_dim
),
new_customer_orders AS (
    SELECT f.order_id,
           date_trunc('month', try_cast(f.order_created_at AS timestamp)) AS order_month,
           o.channel,
           max(CASE WHEN f.product_category='Camera' THEN 1 ELSE 0 END) AS has_camera,
           max(CASE WHEN f.product_category='Add-on' THEN 1 ELSE 0 END) AS has_addon
    FROM raw.order_fct f
    LEFT JOIN ord o ON f.order_id = o.order_id
    WHERE f.order_action_type = 'CreateSubscription'
    GROUP BY f.order_id, f.order_created_at, o.channel
    HAVING max(CASE WHEN f.product_category='Camera' THEN 1 ELSE 0 END) = 1
)
SELECT
    order_month,
    count(*)                                                        AS new_customers,
    sum(has_addon)                                                  AS with_addon,
    round(sum(has_addon)*100.0 / count(*), 1)                      AS addon_attach_pct,
    round(sum(CASE WHEN channel='Ecommerce' AND has_addon=1 THEN 1 ELSE 0 END)*100.0
          / nullif(sum(CASE WHEN channel='Ecommerce' THEN 1 ELSE 0 END),0), 1) AS ecom_attach_pct,
    round(sum(CASE WHEN channel='Direct' AND has_addon=1 THEN 1 ELSE 0 END)*100.0
          / nullif(sum(CASE WHEN channel='Direct' THEN 1 ELSE 0 END),0), 1)    AS direct_attach_pct
FROM new_customer_orders
WHERE order_month IS NOT NULL
GROUP BY order_month
ORDER BY order_month
