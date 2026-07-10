create table exchange_rates (
    id             uuid primary key default gen_random_uuid(),
    date           date not null,
    base_currency  text not null default 'USD',
    currency       text not null,
    rate           numeric not null,
    created_at     timestamptz not null default now(),
    unique (date, base_currency, currency)
);

create index idx_exchange_rates_date on exchange_rates (date desc);
create index idx_exchange_rates_currency on exchange_rates (currency);
