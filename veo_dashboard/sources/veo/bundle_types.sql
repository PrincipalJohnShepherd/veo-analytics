WITH fct AS (
    SELECT order_id, product_category FROM raw.order_fct
),
order_products AS (
    SELECT order_id,
           max(CASE WHEN product_category='Camera' THEN 1 ELSE 0 END) AS has_camera,
           max(CASE WHEN product_category='Base'   THEN 1 ELSE 0 END) AS has_base,
           max(CASE WHEN product_category='Add-on' THEN 1 ELSE 0 END) AS has_addon
    FROM fct GROUP BY order_id
)
SELECT
    CASE
        WHEN has_camera=1 AND has_base=1 AND has_addon=1 THEN 'Camera + Sub + Add-on'
        WHEN has_camera=1 AND has_base=1 AND has_addon=0 THEN 'Camera + Sub'
        WHEN has_camera=0 AND has_base=1 AND has_addon=1 THEN 'Sub + Add-on'
        WHEN has_camera=0 AND has_base=1 AND has_addon=0 THEN 'Sub only'
        WHEN has_camera=0 AND has_base=0 AND has_addon=1 THEN 'Add-on only'
        WHEN has_camera=1 AND has_base=0                 THEN 'Camera only'
        ELSE 'Other'
    END AS bundle_type,
    count(*) AS orders,
    round(count(*)*100.0/sum(count(*)) OVER (), 1) AS pct
FROM order_products
GROUP BY bundle_type
ORDER BY orders DESC
