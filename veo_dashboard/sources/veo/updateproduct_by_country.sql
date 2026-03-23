/*
  UpdateProduct MRR split by country and channel.

  Tests whether the 8.5× Direct/Ecommerce UpdateProduct gap is a UI/UX problem
  (self-serve upgrade flow is missing) or a selection bias problem (large clubs with
  budget for tier upgrades disproportionately use Direct/Account Managers).

  If Ecommerce clubs in high-volume countries (US, UK, DE) have near-zero UpdateProduct
  MRR, but Direct clubs in the same countries have high UpdateProduct MRR, the gap is
  structural — we need a self-serve upgrade path. If Ecommerce clubs simply don't exist
  at the large-club end in those countries, it's a product-market-fit question.
*/
WITH ord AS (
    SELECT replace(order_id, chr(65279), '') AS order_id,
           CASE WHEN order_is_ecommerce_order='true'  THEN 'Ecommerce'
                WHEN order_is_ecommerce_order='false' THEN 'Direct'
                ELSE 'Unknown' END AS channel
    FROM raw.order_dim
),
clubs AS (
    SELECT replace(clubhouse_id, chr(65279), '') AS clubhouse_id,
           country_name
    FROM raw.club_dim
)
SELECT
    c.country_name,
    o.channel,
    count(DISTINCT f.order_id)                                  AS upgrade_orders,
    round(sum(nullif(trim(f."new_MRR"), '')::double), 0)        AS update_mrr,
    round(avg(nullif(trim(f."new_MRR"), '')::double), 0)        AS avg_mrr_per_order
FROM raw.order_fct f
LEFT JOIN ord o   ON f.order_id    = o.order_id
LEFT JOIN clubs c ON f.clubhouse_id = c.clubhouse_id
WHERE f.order_action_type = 'UpdateProduct'
  AND c.country_name IS NOT NULL
  AND o.channel IN ('Ecommerce', 'Direct')
GROUP BY c.country_name, o.channel
HAVING sum(nullif(trim(f."new_MRR"), '')::double) > 500
ORDER BY update_mrr DESC
LIMIT 40
