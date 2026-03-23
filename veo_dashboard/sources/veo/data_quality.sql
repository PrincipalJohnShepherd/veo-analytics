WITH fct AS (SELECT * FROM raw.order_fct),
     ord AS (SELECT * FROM raw.order_dim),
     club AS (SELECT * FROM raw.club_dim)
SELECT 'Camera rows with null MRR (expected)'              AS check_name,
       count(*) AS affected,
       round(count(*)*100.0/(SELECT count(*) FROM fct WHERE product_category='Camera'),1) AS pct_of_group
FROM fct WHERE product_category='Camera' AND "new_MRR"=''
UNION ALL
SELECT 'Base rows with null MRR (unexpected)', count(*),
       round(count(*)*100.0/(SELECT count(*) FROM fct WHERE product_category='Base'),1)
FROM fct WHERE product_category='Base' AND "new_MRR"=''
UNION ALL
SELECT 'Orders with unknown channel (null is_ecommerce)', count(*),
       round(count(*)*100.0/(SELECT count(*) FROM ord),1)
FROM ord WHERE order_is_ecommerce_order=''
UNION ALL
SELECT 'Base orders with null subscription length', count(*),
       round(count(*)*100.0/(SELECT count(*) FROM ord),1)
FROM ord WHERE order_subscription_length='' OR order_subscription_length='N/A'
UNION ALL
SELECT 'Fact rows orphaned (no matching club)', count(*),
       round(count(*)*100.0/(SELECT count(*) FROM fct),2)
FROM fct WHERE clubhouse_id NOT IN (SELECT replace(clubhouse_id,chr(65279),'') FROM club)
UNION ALL
SELECT 'Multi-line orders (>1 product per order)', count(*),
       round(count(*)*100.0/(SELECT count(DISTINCT order_id) FROM fct),1)
FROM (SELECT order_id FROM fct GROUP BY order_id HAVING count(*)>1)
ORDER BY affected DESC
