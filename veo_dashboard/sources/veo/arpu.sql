WITH ord AS (
    SELECT replace(order_id, chr(65279), '') AS order_id,
           NULLIF(order_subscription_length, 'N/A') AS sub_length
    FROM raw.order_dim
),
fct AS (
    SELECT order_id, clubhouse_id,
           nullif(trim("new_MRR"), '')::double AS new_mrr,
           date_trunc('month', try_cast(order_created_at AS timestamp)) AS order_month,
           order_action_type
    FROM raw.order_fct
),
enriched AS (
    SELECT f.*, o.sub_length
    FROM fct f LEFT JOIN ord o ON f.order_id = o.order_id
)
SELECT
    order_month,
    count(DISTINCT clubhouse_id)                                                 AS active_clubs,
    round(sum(new_mrr), 0)                                                       AS total_mrr,
    round(sum(new_mrr) / nullif(count(DISTINCT clubhouse_id), 0), 2)             AS arpu,
    round(sum(CASE WHEN sub_length='12 Months' THEN new_mrr ELSE 0 END)
          / nullif(count(DISTINCT CASE WHEN sub_length='12 Months' THEN clubhouse_id END),0), 2) AS arpu_annual,
    round(sum(CASE WHEN sub_length IS NULL THEN new_mrr ELSE 0 END)
          / nullif(count(DISTINCT CASE WHEN sub_length IS NULL THEN clubhouse_id END),0), 2)     AS arpu_monthly
FROM enriched
WHERE new_mrr IS NOT NULL AND order_month IS NOT NULL
GROUP BY order_month
ORDER BY order_month
