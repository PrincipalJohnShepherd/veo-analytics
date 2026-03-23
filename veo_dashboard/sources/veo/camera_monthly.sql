WITH fct AS (
    SELECT product_category,
           try_cast(unit_price    AS double) AS unit_price,
           try_cast(unit_quantity AS double) AS unit_quantity,
           nullif(trim("new_MRR"), '')::double AS new_mrr,
           date_trunc('month', try_cast(order_created_at AS timestamp)) AS order_month
    FROM raw.order_fct
)
SELECT
    order_month,
    round(sum(CASE WHEN product_category = 'Camera' THEN unit_quantity ELSE 0 END), 0)            AS cameras_sold,
    round(sum(CASE WHEN product_category = 'Camera' THEN unit_price * unit_quantity ELSE 0 END), 0) AS hardware_revenue,
    round(sum(CASE WHEN product_category = 'Base'   THEN new_mrr ELSE 0 END), 0)                   AS base_mrr,
    round(sum(CASE WHEN product_category = 'Add-on' THEN new_mrr ELSE 0 END), 0)                   AS addon_mrr
FROM fct
WHERE order_month IS NOT NULL
GROUP BY order_month
ORDER BY order_month
