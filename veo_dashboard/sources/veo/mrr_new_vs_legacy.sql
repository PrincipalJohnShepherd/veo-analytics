/*
  Splits total software MRR by customer type:
  - New customer MRR: from orders that include a Camera (first purchase event)
  - Legacy MRR: from orders without a Camera (existing club, camera pre-dates dataset)

  Includes all action types (CreateSubscription, AddProduct, UpdateProduct)
  attributed to whether the ORDER contained a camera.
*/
WITH order_has_camera AS (
    SELECT order_id,
           max(CASE WHEN product_category='Camera' THEN 1 ELSE 0 END) AS has_camera
    FROM raw.order_fct
    GROUP BY order_id
),
fct AS (
    SELECT f.order_id,
           f.product_category,
           nullif(trim(f."new_MRR"), '')::double AS new_mrr,
           date_trunc('month', try_cast(f.order_created_at AS timestamp)) AS order_month,
           f.order_action_type,
           ohc.has_camera
    FROM raw.order_fct f
    LEFT JOIN order_has_camera ohc ON f.order_id = ohc.order_id
)
SELECT
    order_month,
    round(sum(CASE WHEN has_camera=1 AND product_category!='Camera' THEN new_mrr ELSE 0 END), 0) AS new_customer_mrr,
    round(sum(CASE WHEN has_camera=0 THEN new_mrr ELSE 0 END), 0)                                 AS legacy_mrr,
    round(sum(CASE WHEN product_category!='Camera' THEN new_mrr ELSE 0 END), 0)                   AS total_software_mrr,
    -- camera hardware revenue (new customers only — hardware is one-time)
    round(sum(CASE WHEN product_category='Camera'
                   THEN try_cast("unit_price" AS double)*try_cast("unit_quantity" AS double)
                   ELSE 0 END), 0)                                                                 AS camera_hardware_rev
FROM (
    SELECT f.order_id, f.product_category,
           nullif(trim(f."new_MRR"), '')::double AS new_mrr,
           f."unit_price", f."unit_quantity",
           date_trunc('month', try_cast(f.order_created_at AS timestamp)) AS order_month,
           ohc.has_camera
    FROM raw.order_fct f
    LEFT JOIN order_has_camera ohc ON f.order_id = ohc.order_id
) t
WHERE order_month IS NOT NULL
GROUP BY order_month
ORDER BY order_month
