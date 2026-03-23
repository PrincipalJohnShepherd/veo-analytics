/*
  New customers = CreateSubscription orders that include a Camera (first purchase).
  Legacy accounts = CreateSubscription orders without a Camera (camera predates dataset).

  You cannot buy a subscription without a camera — so sub-only orders are
  existing clubs whose original hardware purchase is outside this dataset's range.
*/
WITH order_has_camera AS (
    SELECT order_id,
           date_trunc('month', try_cast(order_created_at AS timestamp)) AS order_month,
           max(CASE WHEN product_category='Camera' THEN 1 ELSE 0 END) AS has_camera,
           max(CASE WHEN product_category='Add-on' THEN 1 ELSE 0 END) AS has_addon,
           sum(CASE WHEN product_category!='Camera'
                    THEN nullif(trim("new_MRR"), '')::double ELSE 0 END) AS sub_mrr
    FROM raw.order_fct
    WHERE order_action_type = 'CreateSubscription'
    GROUP BY order_id, order_created_at
)
SELECT
    order_month,
    sum(CASE WHEN has_camera=1 THEN 1 ELSE 0 END)               AS new_customers,
    sum(CASE WHEN has_camera=0 THEN 1 ELSE 0 END)               AS legacy_activations,
    round(sum(CASE WHEN has_camera=1 THEN sub_mrr ELSE 0 END),0) AS new_customer_mrr,
    round(sum(CASE WHEN has_camera=0 THEN sub_mrr ELSE 0 END),0) AS legacy_mrr,
    round(sum(sub_mrr),0)                                         AS total_create_sub_mrr
FROM order_has_camera
WHERE order_month IS NOT NULL
GROUP BY order_month
ORDER BY order_month
