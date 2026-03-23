# Veo Analytics

Interactive analytics dashboard built with dbt + DuckDB + Evidence.dev.

**Live dashboard:** https://veo.femente.com/

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose

## Quick start

### 1. Add the source data

Copy the three CSV files into `veo_analytics/seeds/`:

```
veo_analytics/seeds/
├── club_dim.csv
├── order_dim.csv       ← rename from "order_dim (1).csv"
└── order_fct.csv
```

### 2. Run

```bash
docker compose up --build
```

This runs two steps automatically:

1. **`analytics`** — loads the CSVs into DuckDB and runs all dbt models. Exits when done.
2. **`dashboard`** — waits for analytics, builds the Evidence.dev site, and serves it.

Open **http://localhost:3000** when the build completes (~2–3 min on first run).

### Subsequent runs (data unchanged)

```bash
docker compose up
```

No `--build` needed unless you change Python or Node dependencies.

### Rebuild the database only

```bash
docker compose run --rm analytics
```

### Rebuild the dashboard only

```bash
docker compose up dashboard
```

---

## Project layout

```
.
├── docker-compose.yml
├── veo_analytics/          # dbt + DuckDB pipeline
│   ├── models/
│   │   ├── staging/        # stg_club_dim, stg_order_dim, stg_order_fct
│   │   ├── intermediate/   # int_orders_enriched
│   │   └── marts/          # task1_eda / task2_insights / task3_kpis
│   ├── seeds/              # CSV source files (not committed — add manually)
│   ├── setup_db.py         # loads CSVs → DuckDB raw schema
│   ├── verify_models.py    # runs all dbt models directly in DuckDB
│   └── requirements.txt
└── veo_dashboard/          # Evidence.dev dashboard
    ├── pages/
    │   ├── index.md        # Overview
    │   ├── eda.md          # Task 1 — EDA
    │   ├── insights.md     # Task 2 — Insights
    │   └── kpis.md         # Task 3 — KPI Framework
    └── sources/veo/        # SQL queries served to the dashboard
```

---

## Local development (without Docker)

**Analytics** (Python 3.11+):

```bash
cd veo_analytics
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt
python setup_db.py
python verify_models.py
```

**Dashboard** (Node 20+):

```bash
cd veo_dashboard
npm install
npm run sources
npm run dev
```

Open http://localhost:3000.
