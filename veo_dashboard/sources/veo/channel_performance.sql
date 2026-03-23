WITH ord AS (
    SELECT replace(order_id, chr(65279), '') AS order_id,
           CASE WHEN order_is_ecommerce_order = 'true'  THEN true
                WHEN order_is_ecommerce_order = 'false' THEN false
                ELSE NULL END AS order_is_ecommerce_order
    FROM raw.order_dim
),
fct AS (
    SELECT order_id, product_category,
           nullif(trim("new_MRR"), '')::double AS new_mrr,
           try_cast(unit_price AS double)    AS unit_price,
           try_cast(unit_quantity AS double) AS unit_quantity,
           order_action_type
    FROM raw.order_fct
),
enriched AS (
    SELECT f.*, o.order_is_ecommerce_order,
           CASE WHEN o.order_is_ecommerce_order = true  THEN 'Ecommerce'
                WHEN o.order_is_ecommerce_order = false THEN 'Direct'
                ELSE 'Unknown' END AS channel
    FROM fct f LEFT JOIN ord o ON f.order_id = o.order_id
)
SELECT
    channel,
    order_action_type,
    count(DISTINCT order_id)               AS orders,
    round(sum(new_mrr), 0)                 AS mrr,
    round(avg(new_mrr), 2)                 AS avg_mrr,
    round(sum(unit_price * unit_quantity), 0) AS gross_value
FROM enriched
GROUP BY channel, order_action_type
ORDER BY channel, orders DESC
