WITH fct AS (
    SELECT order_id, clubhouse_id,
           product_category,
           nullif(trim("new_MRR"), '')::double AS new_mrr,
           try_cast(unit_price    AS double) AS unit_price,
           try_cast(unit_quantity AS double) AS unit_quantity,
           order_action_type
    FROM raw.order_fct
)
SELECT
    count(DISTINCT clubhouse_id)                                                        AS total_clubs,
    count(DISTINCT order_id)                                                            AS total_orders,
    round(sum(new_mrr), 0)                                                              AS total_software_mrr,
    round(sum(CASE WHEN product_category='Camera' THEN unit_quantity ELSE 0 END), 0)   AS total_cameras_sold,
    round(sum(CASE WHEN product_category='Camera' THEN unit_price*unit_quantity ELSE 0 END), 0) AS total_hardware_rev,
    round(avg(CASE WHEN new_mrr IS NOT NULL THEN new_mrr END), 2)                      AS overall_avg_mrr,
    round(sum(CASE WHEN order_action_type='CreateSubscription' THEN new_mrr ELSE 0 END), 0) AS total_new_sub_mrr,
    round(sum(CASE WHEN order_action_type='AddProduct' THEN new_mrr ELSE 0 END), 0)    AS total_expansion_mrr
FROM fct
