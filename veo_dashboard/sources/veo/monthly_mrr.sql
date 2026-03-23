WITH fct AS (
    SELECT order_id, clubhouse_id, product_category,
           nullif(trim("new_MRR"), '')::double AS new_mrr,
           try_cast(order_created_at AS timestamp) AS order_created_at,
           date_trunc('month', try_cast(order_created_at AS timestamp)) AS order_month,
           order_action_type
    FROM raw.order_fct
)
SELECT
    order_month,
    round(sum(CASE WHEN order_action_type = 'CreateSubscription' THEN new_mrr ELSE 0 END), 2) AS new_mrr,
    round(sum(CASE WHEN order_action_type = 'AddProduct'         THEN new_mrr ELSE 0 END), 2) AS expansion_mrr,
    round(sum(CASE WHEN order_action_type = 'UpdateProduct'      THEN new_mrr ELSE 0 END), 2) AS update_mrr,
    round(sum(new_mrr), 2) AS total_mrr,
    -- exclude aug 2025 Sweden artefact for clean trend
    round(sum(CASE WHEN order_action_type IN ('CreateSubscription','AddProduct') THEN new_mrr ELSE 0 END), 2) AS organic_mrr,
    count(DISTINCT order_id)   AS orders,
    count(DISTINCT clubhouse_id) AS clubs
FROM fct
WHERE new_mrr IS NOT NULL
  AND order_month IS NOT NULL
GROUP BY order_month
ORDER BY order_month
