WITH fct AS (
    SELECT product_category,
           nullif(trim("new_MRR"), '')::double AS new_mrr,
           try_cast(unit_price    AS double) AS unit_price,
           try_cast(unit_quantity AS double) AS unit_quantity,
           order_id
    FROM raw.order_fct
)
SELECT
    product_category,
    count(*)                                   AS line_items,
    count(DISTINCT order_id)                   AS orders,
    round(sum(new_mrr), 0)                     AS total_mrr,
    round(avg(new_mrr), 2)                     AS avg_mrr_per_line,
    round(sum(new_mrr)*100.0 / sum(sum(new_mrr)) OVER (), 1) AS pct_of_mrr,
    round(sum(unit_price * unit_quantity), 0)   AS gross_value
FROM fct
GROUP BY product_category
ORDER BY total_mrr DESC NULLS LAST
