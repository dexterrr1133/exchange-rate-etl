# Daily Exchange Rate ETL Pipeline

An automated ETL pipeline that fetches daily USD exchange rates, transforms them into a normalized relational format, and loads them into a Postgres database — with historical tracking, no manual intervention, and a live dashboard for monitoring trends and pipeline health.

**[View the live dashboard →](https://datastudio.google.com/reporting/2f35ce8c-722b-459b-bb2b-03a6e872244b)**

## Architecture

```
Scheduled Trigger (daily, 6 AM)
        │
        ▼
Frankfurter API (public, no auth) — fetch latest USD rates
        │
        ▼
Transform — flatten nested JSON into one row per currency
        │
        ▼
Supabase (PostgreSQL) — upsert into exchange_rates
        │
        ▼
latest_rates (view) — one row per currency, always current
        │
        ▼
Looker Studio — dashboard (trends, snapshot table, pipeline health)
```

## Why this design

- **Idempotent loads**: uses a unique constraint on `(date, base_currency, currency)`, so re-running the pipeline never creates duplicate rows.
- **No API key required**: Frankfurter is a free, keyless public API, so the pipeline runs with zero external account setup.
- **Historical tracking**: every day's rates are preserved (not overwritten), enabling trend analysis over time.
- **View-backed "latest" queries**: a `latest_rates` view (using `DISTINCT ON`) keeps the dashboard's snapshot table and scorecards simple.
- **Scale-normalized comparisons**: currencies span multiple orders of magnitude (e.g., IDR ~18,000 vs. EUR ~0.9 per USD), so the trend chart plots percentage change from a baseline rather than raw rate, keeping all currencies visually comparable on one chart.

## Tech Stack

- **n8n** — orchestration and scheduling
- **Frankfurter API** — exchange rate data source
- **Supabase (PostgreSQL)** — storage, views
- **Looker Studio** — dashboard and visualization

## Dashboard

Two pages:

- **Overview** — scorecards for key currencies (with period-over-period % change), a percentage-change trend chart (filterable by currency), a latest-rate snapshot table, and a pipeline health section (last run timestamp, total records collected).
- **Data Audit** — a records-per-day bar chart for spotting incomplete pipeline runs at a glance (each successful day should show a full bar), plus a searchable raw data table for manual verification.

## Setup

1. Create the `exchange_rates` table and `latest_rates` view using `schema.sql` in your Supabase project.
2. Import `exchange-rate-etl.json` into n8n.
3. Set the `SUPABASE_URL` environment variable in n8n.
4. Create a Supabase credential in n8n (Project URL + service role secret key).
5. Activate the workflow.
6. Connect Looker Studio to your Supabase Postgres instance (Connection Info → Session Pooler host, for IPv4 compatibility) to reproduce the dashboard, or use `schema.sql` as reference for building your own.

## Sample Queries

```sql
-- Track EUR/USD trend over the last 30 days
select date, rate
from exchange_rates
where currency = 'EUR'
order by date desc
limit 30;

-- Current rate for every tracked currency
select currency, rate
from latest_rates
order by rate desc;
```

## Possible Extensions

- Add a Slack/Telegram alert when a rate moves more than X% day-over-day
- Add a "days since last update" indicator with conditional formatting, so a broken pipeline is visually obvious instead of requiring someone to check the timestamp
- Expand to track multiple base currencies
