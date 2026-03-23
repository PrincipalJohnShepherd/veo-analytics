WITH club AS (
    SELECT replace(clubhouse_id, chr(65279), '') AS clubhouse_id, country_name
    FROM raw.club_dim
),
fct AS (
    SELECT order_id, clubhouse_id,
           product_category,
           nullif(trim("new_MRR"), '')::double AS new_mrr,
           try_cast(unit_price    AS double) AS unit_price,
           try_cast(unit_quantity AS double) AS unit_quantity
    FROM raw.order_fct
),
enriched AS (
    SELECT f.*, coalesce(c.country_name, 'Unknown') AS country_name
    FROM fct f LEFT JOIN club c ON f.clubhouse_id = c.clubhouse_id
)
SELECT
    country_name,
    count(DISTINCT order_id)                                          AS orders,
    count(DISTINCT clubhouse_id)                                      AS clubs,
    round(sum(new_mrr), 0)                                            AS total_mrr,
    round(avg(new_mrr), 2)                                            AS avg_mrr_per_line,
    round(sum(unit_price * unit_quantity), 0)                         AS gross_value,
    round(sum(CASE WHEN product_category='Camera' THEN unit_quantity ELSE 0 END), 0) AS cameras_sold
FROM enriched
GROUP BY country_name
ORDER BY total_mrr DESC NULLS LAST
LIMIT 20
