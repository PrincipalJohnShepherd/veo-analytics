import duckdb, re, pathlib

con = duckdb.connect('/Users/thomaskruger/Documents/Veo/test/veo_analytics/veo_analytics.duckdb')

MODELS_DIR = pathlib.Path('/Users/thomaskruger/Documents/Veo/test/veo_analytics/models')
MODELS = [
    ('staging/stg_club_dim.sql','stg_club_dim'),
    ('staging/stg_order_dim.sql','stg_order_dim'),
    ('staging/stg_order_fct.sql','stg_order_fct'),
    ('intermediate/int_orders_enriched.sql','int_orders_enriched'),
    ('marts/task1_eda/eda_table_overview.sql','eda_table_overview'),
    ('marts/task1_eda/eda_data_quality.sql','eda_data_quality'),
    ('marts/task1_eda/eda_value_distributions.sql','eda_value_distributions'),
    ('marts/task2_insights/ins_revenue_by_country.sql','ins_revenue_by_country'),
    ('marts/task2_insights/ins_ecommerce_channel_performance.sql','ins_ecommerce_channel_performance'),
    ('marts/task2_insights/ins_product_mix_revenue.sql','ins_product_mix_revenue'),
    ('marts/task2_insights/ins_mrr_trend_monthly.sql','ins_mrr_trend_monthly'),
    ('marts/task3_kpis/kpi_new_mrr_monthly.sql','kpi_new_mrr_monthly'),
    ('marts/task3_kpis/kpi_ecommerce_share.sql','kpi_ecommerce_share'),
    ('marts/task3_kpis/kpi_product_attach_rate.sql','kpi_product_attach_rate'),
    ('marts/task3_kpis/kpi_arpu.sql','kpi_arpu'),
]
schema_map = {n: f'main.{n}' for _,n in MODELS}
con.execute('CREATE SCHEMA IF NOT EXISTS main')
for rel, name in MODELS:
    sql = (MODELS_DIR / rel).read_text()
    sql = re.sub(r'\{\{[^}]*config[^}]*\}\}', '', sql, flags=re.DOTALL)
    sql = re.sub(r"\{\{\s*ref\(['\"](\w+)['\"]\)\s*\}\}", lambda m: schema_map.get(m.group(1), m.group(1)), sql)
    sql = re.sub(r"\{\{\s*source\(['\"]raw['\"],\s*['\"](\w+)['\"]\)\s*\}\}", lambda m: f'raw.{m.group(1)}', sql)
    con.execute(f'CREATE OR REPLACE VIEW main.{name} AS {sql}')

def q(label, sql):
    print(f'\n=== {label} ===')
    print(con.execute(sql).fetchdf().to_string(index=False))

q("PURCHASE BUNDLE TYPES", """
    SELECT has_camera, has_base, has_addon,
           count(*) as orders,
           round(count(*)*100.0/sum(count(*)) over(),1) as pct
    FROM (
        SELECT order_id,
            max(case when product_category='Camera' then 1 else 0 end) as has_camera,
            max(case when product_category='Base'   then 1 else 0 end) as has_base,
            max(case when product_category='Add-on' then 1 else 0 end) as has_addon
        FROM main.stg_order_fct GROUP BY order_id
    ) GROUP BY has_camera, has_base, has_addon ORDER BY orders DESC
""")

q("CAMERA + SUB PURCHASED TOGETHER vs SEPARATE", """
    SELECT
        sum(case when has_camera=1 and has_base=1 then 1 else 0 end) as cam_plus_sub_together,
        sum(case when has_camera=1 and has_base=0 then 1 else 0 end) as camera_only,
        sum(case when has_camera=0 and has_base=1 then 1 else 0 end) as sub_only,
        count(*) as total_orders
    FROM (
        SELECT order_id,
            max(case when product_category='Camera' then 1 else 0 end) as has_camera,
            max(case when product_category='Base'   then 1 else 0 end) as has_base
        FROM main.stg_order_fct GROUP BY order_id
    )
""")

q("MONTHLY CAMERA UNIT SALES + HARDWARE REVENUE vs SOFTWARE MRR", """
    SELECT order_month,
        round(sum(case when product_category='Camera' then unit_price*unit_quantity else 0 end),0) as camera_hardware_rev,
        round(sum(case when product_category='Camera' then unit_quantity else 0 end),0) as cameras_sold,
        round(sum(case when product_category='Base' then new_mrr else 0 end),0) as base_mrr,
        round(sum(case when product_category='Add-on' then new_mrr else 0 end),0) as addon_mrr
    FROM main.int_orders_enriched
    WHERE order_month IS NOT NULL
    GROUP BY order_month ORDER BY order_month
""")

q("TOP 5 COUNTRIES - MONTHLY CAMERA SALES", """
    SELECT order_month, country_name,
           sum(case when product_category='Camera' then unit_quantity else 0 end) as cameras,
           round(sum(case when product_category!='Camera' then new_mrr else 0 end),0) as mrr
    FROM main.int_orders_enriched
    WHERE country_name IN ('United States of America','United Kingdom','Sweden','Germany','Australia')
      AND order_month IS NOT NULL
    GROUP BY order_month, country_name
    ORDER BY order_month, cameras DESC
""")

q("ECOMMERCE vs DIRECT by ACTION TYPE", """
    SELECT
        case when order_is_ecommerce_order=true  then 'Ecommerce'
             when order_is_ecommerce_order=false then 'Direct'
             else 'Unknown' end as channel,
        order_action_type,
        count(distinct order_id) as orders,
        round(sum(new_mrr),0) as mrr
    FROM main.int_orders_enriched
    GROUP BY order_is_ecommerce_order, order_action_type
    ORDER BY channel, orders DESC
""")

q("SUBSCRIPTION LENGTH BY CHANNEL (Base orders only)", """
    SELECT
        case when order_is_ecommerce_order=true  then 'Ecommerce'
             when order_is_ecommerce_order=false then 'Direct'
             else 'Unknown' end as channel,
        coalesce(order_subscription_length,'NULL') as sub_length,
        count(*) as orders,
        round(count(*)*100.0/sum(count(*)) over(partition by order_is_ecommerce_order),1) as pct
    FROM main.int_orders_enriched
    WHERE product_category='Base'
    GROUP BY order_is_ecommerce_order, order_subscription_length
    ORDER BY channel, orders DESC
""")

q("ARPU: ANNUAL vs MONTHLY SUBSCRIBERS by COUNTRY (top 8)", """
    SELECT country_name,
        count(distinct clubhouse_id) as clubs,
        round(sum(new_mrr),0) as total_mrr,
        round(avg(new_mrr),2) as avg_mrr_per_line,
        sum(case when order_subscription_length='12 Months' then 1 else 0 end) as annual_lines,
        sum(case when order_subscription_length='1 Month'  then 1 else 0 end) as monthly_lines
    FROM main.int_orders_enriched
    WHERE product_category='Base' AND new_mrr IS NOT NULL
    GROUP BY country_name ORDER BY total_mrr DESC LIMIT 8
""")

q("NO PAYMENT ORDERS - what are they?", """
    SELECT order_action_type, product_category,
           count(*) as rows,
           round(avg(unit_price*unit_quantity),0) as avg_order_value
    FROM main.int_orders_enriched
    WHERE order_payment_type='No Payment Order'
    GROUP BY order_action_type, product_category
    ORDER BY rows DESC
""")

con.close()
