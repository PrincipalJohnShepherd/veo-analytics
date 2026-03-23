import duckdb

con = duckdb.connect('/Users/thomaskruger/Documents/Veo/test/veo_analytics/veo_analytics.duckdb')

def q(label, sql):
    print(f'\n=== {label} ===')
    print(con.execute(sql).fetchdf().to_string(index=False))

# 1. CreateSubscription: camera-attached (new) vs sub-only (legacy)
q("CREATE-SUB: New customer (w/ camera) vs Legacy account (no camera)", """
    SELECT
        has_camera,
        CASE WHEN has_camera=1 THEN 'New customer (camera in order)'
             ELSE 'Legacy account (no camera in dataset)' END as customer_type,
        count(*) as orders,
        round(count(*)*100.0/sum(count(*)) over(),1) as pct,
        round(sum(mrr),0) as total_mrr
    FROM (
        SELECT order_id,
            max(case when product_category='Camera' then 1 else 0 end) as has_camera,
            sum(case when product_category!='Camera' then nullif(trim("new_MRR"),'')::double else 0 end) as mrr
        FROM raw.order_fct
        WHERE order_action_type='CreateSubscription'
        GROUP BY order_id
    ) GROUP BY has_camera ORDER BY has_camera DESC
""")

# 2. Monthly: true new customers vs legacy activations
q("MONTHLY: True new customers (camera) vs Legacy sub activations", """
    WITH order_level AS (
        SELECT order_id,
            date_trunc('month', try_cast(order_created_at as timestamp)) as order_month,
            max(case when product_category='Camera' then 1 else 0 end) as has_camera,
            sum(case when product_category!='Camera' then nullif(trim("new_MRR"),'')::double else 0 end) as sub_mrr
        FROM raw.order_fct
        WHERE order_action_type='CreateSubscription'
        GROUP BY order_id, order_created_at
    )
    SELECT order_month,
        sum(case when has_camera=1 then 1 else 0 end) as new_customers,
        sum(case when has_camera=0 then 1 else 0 end) as legacy_activations,
        round(sum(case when has_camera=1 then sub_mrr else 0 end),0) as new_customer_mrr,
        round(sum(case when has_camera=0 then sub_mrr else 0 end),0) as legacy_mrr
    FROM order_level
    WHERE order_month IS NOT NULL
    GROUP BY order_month ORDER BY order_month
""")

# 3. Channel split for new vs legacy
q("CHANNEL: New vs Legacy customers by Ecommerce/Direct", """
    WITH ord AS (
        SELECT replace(order_id,chr(65279),'') as order_id,
            CASE WHEN order_is_ecommerce_order='true'  THEN 'Ecommerce'
                 WHEN order_is_ecommerce_order='false' THEN 'Direct'
                 ELSE 'Unknown' END as channel
        FROM raw.order_dim
    ),
    order_level AS (
        SELECT f.order_id, o.channel,
            max(case when f.product_category='Camera' then 1 else 0 end) as has_camera,
            sum(case when f.product_category!='Camera' then nullif(trim(f."new_MRR"),'')::double else 0 end) as sub_mrr
        FROM raw.order_fct f
        LEFT JOIN ord o ON f.order_id = o.order_id
        WHERE f.order_action_type='CreateSubscription'
        GROUP BY f.order_id, o.channel
    )
    SELECT channel,
        sum(case when has_camera=1 then 1 else 0 end) as new_customers,
        sum(case when has_camera=0 then 1 else 0 end) as legacy_activations,
        round(sum(case when has_camera=1 then sub_mrr else 0 end),0) as new_customer_mrr,
        round(sum(case when has_camera=0 then sub_mrr else 0 end),0) as legacy_mrr,
        round(sum(case when has_camera=1 then 1 else 0 end)*100.0/count(*),1) as pct_new
    FROM order_level
    GROUP BY channel ORDER BY new_customers DESC
""")

# 4. True new customer attach rate (camera orders only, per month)
q("TRUE NEW CUSTOMER ADDON ATTACH RATE (camera orders only)", """
    WITH new_orders AS (
        SELECT order_id,
            date_trunc('month', try_cast(order_created_at as timestamp)) as order_month,
            max(case when product_category='Camera' then 1 else 0 end) as has_camera,
            max(case when product_category='Add-on' then 1 else 0 end) as has_addon
        FROM raw.order_fct
        WHERE order_action_type='CreateSubscription'
        GROUP BY order_id, order_created_at
        HAVING max(case when product_category='Camera' then 1 else 0 end) = 1
    )
    SELECT order_month,
        count(*) as new_customers,
        sum(has_addon) as with_addon,
        round(sum(has_addon)*100.0/count(*),1) as addon_attach_rate_pct
    FROM new_orders
    WHERE order_month IS NOT NULL
    GROUP BY order_month ORDER BY order_month
""")

# 5. New customer attach rate by channel
q("NEW CUSTOMER ADDON ATTACH BY CHANNEL", """
    WITH ord AS (
        SELECT replace(order_id,chr(65279),'') as order_id,
            CASE WHEN order_is_ecommerce_order='true'  THEN 'Ecommerce'
                 WHEN order_is_ecommerce_order='false' THEN 'Direct'
                 ELSE 'Unknown' END as channel
        FROM raw.order_dim
    ),
    new_orders AS (
        SELECT f.order_id, o.channel,
            max(case when f.product_category='Camera' then 1 else 0 end) as has_camera,
            max(case when f.product_category='Add-on' then 1 else 0 end) as has_addon
        FROM raw.order_fct f
        LEFT JOIN ord o ON f.order_id = o.order_id
        WHERE f.order_action_type='CreateSubscription'
        GROUP BY f.order_id, o.channel
        HAVING max(case when f.product_category='Camera' then 1 else 0 end) = 1
    )
    SELECT channel,
        count(*) as new_customers,
        sum(has_addon) as with_addon,
        round(sum(has_addon)*100.0/count(*),1) as addon_attach_pct
    FROM new_orders
    GROUP BY channel ORDER BY new_customers DESC
""")

# 6. Legacy account MRR vs new customer MRR monthly trend
q("MRR SPLIT: New customer vs Legacy account revenue", """
    WITH ord AS (
        SELECT replace(order_id,chr(65279),'') as order_id,
            CASE WHEN order_is_ecommerce_order='true'  THEN 'Ecommerce'
                 WHEN order_is_ecommerce_order='false' THEN 'Direct'
                 ELSE 'Unknown' END as channel
        FROM raw.order_dim
    ),
    fct AS (
        SELECT order_id, product_category,
               nullif(trim("new_MRR"),'')::double as new_mrr,
               date_trunc('month', try_cast(order_created_at as timestamp)) as order_month,
               order_action_type
        FROM raw.order_fct
    ),
    order_has_camera AS (
        SELECT order_id,
            max(case when product_category='Camera' then 1 else 0 end) as has_camera
        FROM raw.order_fct
        GROUP BY order_id
    )
    SELECT f.order_month,
        round(sum(case when ohc.has_camera=1 and f.product_category!='Camera' then f.new_mrr else 0 end),0) as new_customer_mrr,
        round(sum(case when ohc.has_camera=0 then f.new_mrr else 0 end),0) as legacy_mrr,
        round(sum(case when f.product_category!='Camera' then f.new_mrr else 0 end),0) as total_software_mrr
    FROM fct f
    LEFT JOIN order_has_camera ohc ON f.order_id = ohc.order_id
    WHERE f.new_mrr IS NOT NULL AND f.order_month IS NOT NULL
    GROUP BY f.order_month ORDER BY f.order_month
""")

con.close()
