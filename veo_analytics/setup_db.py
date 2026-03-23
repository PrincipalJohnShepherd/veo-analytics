"""
Pre-loads the three CSV files into veo_analytics.duckdb so that dbt can
reference them as source tables without needing `dbt seed`.

Run once before `dbt run`:
    python3 setup_db.py

Environment variables (used in Docker):
    DB_PATH   — path to the output .duckdb file (default: sibling of this script)
    DATA_DIR  — directory containing the CSV files (default: parent of this script)
"""

import duckdb
import os
import pathlib

DB_PATH  = pathlib.Path(os.environ.get("DB_PATH",  str(pathlib.Path(__file__).parent / "veo_analytics.duckdb")))
DATA_DIR = pathlib.Path(os.environ.get("DATA_DIR", str(pathlib.Path(__file__).parent.parent)))

TABLES = {
    "club_dim":  DATA_DIR / "club_dim.csv",
    "order_dim": DATA_DIR / "order_dim.csv",
    "order_fct": DATA_DIR / "order_fct.csv",
}

con = duckdb.connect(str(DB_PATH))

# Create a raw schema to hold the source tables
con.execute("CREATE SCHEMA IF NOT EXISTS raw")

for table_name, csv_path in TABLES.items():
    print(f"Loading {csv_path.name} → raw.{table_name} ...", end=" ", flush=True)
    con.execute(f"""
        CREATE OR REPLACE TABLE raw.{table_name} AS
        SELECT * FROM read_csv_auto('{csv_path}', header=true, all_varchar=true)
    """)
    count = con.execute(f"SELECT count(*) FROM raw.{table_name}").fetchone()[0]
    print(f"{count:,} rows loaded")

con.close()
print(f"\nDatabase written to: {DB_PATH}")
print("Now run:  dbt run --profiles-dir .")
