WITH ord AS (
    SELECT replace(order_id, chr(65279), '') AS order_id,
           CASE WHEN order_is_ecommerce_order = 'true'  THEN true
                WHEN order_is_ecommerce_order = 'false' THEN false
                ELSE NULL END AS order_is_ecommerce_order
    FROM raw.order_dim
),
fct AS (
    SELECT order_id,
           nullif(trim("new_MRR"), '')::double AS new_mrr,
           date_trunc('month', try_cast(order_created_at AS timestamp)) AS order_month
    FROM raw.order_fct
),
enriched AS (
    SELECT f.*, o.order_is_ecommerce_order
    FROM fct f LEFT JOIN ord o ON f.order_id = o.order_id
)
SELECT
    order_month,
    count(DISTINCT order_id)                                                                        AS total_orders,
    count(DISTINCT CASE WHEN order_is_ecommerce_order=true  THEN order_id END)                      AS ecom_orders,
    count(DISTINCT CASE WHEN order_is_ecommerce_order=false THEN order_id END)                      AS direct_orders,
    round(sum(new_mrr), 0)                                                                          AS total_mrr,
    round(sum(CASE WHEN order_is_ecommerce_order=true  THEN new_mrr ELSE 0 END), 0)                AS ecom_mrr,
    round(sum(CASE WHEN order_is_ecommerce_order=false THEN new_mrr ELSE 0 END), 0)                AS direct_mrr,
    round(count(DISTINCT CASE WHEN order_is_ecommerce_order=true THEN order_id END)*100.0
          / nullif(count(DISTINCT CASE WHEN order_is_ecommerce_order IS NOT NULL THEN order_id END),0), 1) AS ecom_order_share_pct,
    round(sum(CASE WHEN order_is_ecommerce_order=true THEN new_mrr ELSE 0 END)*100.0
          / nullif(sum(CASE WHEN order_is_ecommerce_order IS NOT NULL THEN new_mrr END),0), 1)      AS ecom_mrr_share_pct
FROM enriched
WHERE order_month IS NOT NULL
GROUP BY order_month
ORDER BY order_month
