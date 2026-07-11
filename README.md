# Daily Exchange Rate ETL Pipeline

An automated ETL pipeline that fetches daily USD exchange rates, transforms them into a normalized relational format, and loads them into a Postgres database — with historical tracking and no manual intervention required.

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
Supabase (PostgreSQL) — create
```

## Why this design

- **Idempotent loads**: uses a unique constraint on `(date, base_currency, currency)`, so re-running the pipeline never creates duplicate rows — safe to retry on failure.
- **No API key required**: Frankfurter is a free, keyless public API, so the pipeline runs with zero external account setup.
- **Historical tracking**: every day's rates are preserved (not overwritten), enabling trend analysis over time.

## Tech Stack

- **n8n** — orchestration and scheduling
- **Frankfurter API** — exchange rate data source
- **Supabase (PostgreSQL)** — storage

## Setup

1. Create the `exchange_rates` table using `schema.sql` in your Supabase project.
2. Import `exchange-rate-etl.json` into n8n.
3. Set the `SUPABASE_URL` environment variable in n8n.
4. Create an HTTP Header Auth credential named "Supabase Service Role Header" with your Supabase service role key.
5. Activate the workflow.

## Sample Query

```sql
-- Track EUR/USD trend over the last 30 days
select date, rate
from exchange_rates
where currency = 'EUR'
order by date desc
limit 30;
```

## Possible Extensions

- Add a Slack/Telegram alert when a rate moves more than X% day-over-day
- Build a small dashboard (Power BI / Google Sheets) on top of the table
- Expand to track multiple base currencies
