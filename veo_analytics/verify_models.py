"""
Runs every dbt model's SQL directly in DuckDB to verify correctness.
Also acts as a fallback runner if dbt itself has environment issues.

Usage:
    python3 verify_models.py
"""

import duckdb
import os
import re
import pathlib

DB = pathlib.Path(os.environ.get("DB_PATH", str(pathlib.Path(__file__).parent / "veo_analytics.duckdb")))
MODELS_DIR = pathlib.Path(__file__).parent / "models"

con = duckdb.connect(str(DB))

# ── resolve {{ ref(...) }} and {{ source(...) }} Jinja refs ──────────────────
def resolve_jinja(sql: str, schema_map: dict) -> str:
    """Replace dbt Jinja refs with fully-qualified DuckDB table/view names."""
    # {{ ref('model_name') }}
    sql = re.sub(
        r"\{\{\s*ref\(['\"](\w+)['\"]\)\s*\}\}",
        lambda m: schema_map.get(m.group(1), m.group(1)),
        sql,
    )
    # {{ source('raw', 'table_name') }}
    sql = re.sub(
        r"\{\{\s*source\(['\"]raw['\"],\s*['\"](\w+)['\"]\)\s*\}\}",
        lambda m: f"raw.{m.group(1)}",
        sql,
    )
    return sql


# ── ordered model execution ──────────────────────────────────────────────────
MODELS = [
    # staging
    ("staging/stg_club_dim.sql",       "main", "stg_club_dim"),
    ("staging/stg_order_dim.sql",      "main", "stg_order_dim"),
    ("staging/stg_order_fct.sql",      "main", "stg_order_fct"),
    # intermediate
    ("intermediate/int_orders_enriched.sql", "main", "int_orders_enriched"),
    # task 1 eda
    ("marts/task1_eda/eda_table_overview.sql",       "main", "eda_table_overview"),
    ("marts/task1_eda/eda_data_quality.sql",          "main", "eda_data_quality"),
    ("marts/task1_eda/eda_value_distributions.sql",   "main", "eda_value_distributions"),
    # task 2 insights
    ("marts/task2_insights/ins_revenue_by_country.sql",          "main", "ins_revenue_by_country"),
    ("marts/task2_insights/ins_ecommerce_channel_performance.sql","main", "ins_ecommerce_channel_performance"),
    ("marts/task2_insights/ins_product_mix_revenue.sql",          "main", "ins_product_mix_revenue"),
    ("marts/task2_insights/ins_mrr_trend_monthly.sql",            "main", "ins_mrr_trend_monthly"),
    # task 3 kpis
    ("marts/task3_kpis/kpi_new_mrr_monthly.sql",      "main", "kpi_new_mrr_monthly"),
    ("marts/task3_kpis/kpi_ecommerce_share.sql",       "main", "kpi_ecommerce_share"),
    ("marts/task3_kpis/kpi_product_attach_rate.sql",   "main", "kpi_product_attach_rate"),
    ("marts/task3_kpis/kpi_arpu.sql",                  "main", "kpi_arpu"),
]

schema_map = {name: f"main.{name}" for _, _, name in MODELS}

con.execute("CREATE SCHEMA IF NOT EXISTS main")

errors = []
for rel_path, schema, view_name in MODELS:
    path = MODELS_DIR / rel_path
    sql = path.read_text()
    # strip {{ config(...) }} blocks
    sql = re.sub(r"\{\{[^}]*config[^}]*\}\}", "", sql, flags=re.DOTALL)
    sql = resolve_jinja(sql, schema_map)

    try:
        con.execute(f"CREATE OR REPLACE VIEW {schema}.{view_name} AS\n{sql}")
        count = con.execute(f"SELECT count(*) FROM {schema}.{view_name}").fetchone()[0]
        print(f"  ✓  {view_name:<45}  {count:>8,} rows")
    except Exception as e:
        print(f"  ✗  {view_name:<45}  ERROR: {e}")
        errors.append((view_name, e))

print()
if errors:
    print(f"FAILED: {len(errors)} model(s) had errors.")
else:
    print("All models verified successfully.")
    print()
    print("Sample outputs:")
    print()

    for view, label in [
        ("eda_data_quality",              "Task 1 – Data Quality"),
        ("ins_ecommerce_channel_performance", "Task 2 – Ecommerce vs Direct"),
        ("ins_product_mix_revenue",        "Task 2 – Product Mix"),
        ("kpi_new_mrr_monthly",            "Task 3 – Monthly MRR (last 6 months)"),
        ("kpi_arpu",                       "Task 3 – ARPU (last 6 months)"),
    ]:
        print(f"── {label} ──")
        try:
            if "monthly" in view or "arpu" in view:
                df = con.execute(
                    f"SELECT * FROM main.{view} ORDER BY order_month DESC LIMIT 6"
                ).fetchdf()
            else:
                df = con.execute(f"SELECT * FROM main.{view}").fetchdf()
            print(df.to_string(index=False))
        except Exception as e:
            print(f"  Could not query {view}: {e}")
        print()

con.close()
