-- ============================================================
-- FINANCEHUB — Supabase Database Schema
-- Loyiha: FinanceHub Holding (5 yo'nalish)
-- ============================================================

-- ── FOYDALANUVCHILAR VA ROLLAR ──────────────────────────────
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  full_name text not null,
  role text not null check (role in ('owner', 'manager', 'staff')),
  direction text check (direction in ('cargo', 'logistics', 'exchange', 'procurement', 'holding', null)),
  created_at timestamptz default now()
);

-- Owner barcha yo'nalishlarni ko'radi
-- Manager o'z yo'nalishini ko'radi + kiritadi
-- Staff faqat kiritadi

alter table public.profiles enable row level security;

create policy "Foydalanuvchi o'z profilini ko'radi"
  on profiles for select using (auth.uid() = id);

create policy "Owner barcha profillarni ko'radi"
  on profiles for select using (
    exists (select 1 from profiles where id = auth.uid() and role = 'owner')
  );

-- ── CARGO ───────────────────────────────────────────────────
create table public.cargo_entries (
  id bigserial primary key,
  user_id uuid references profiles(id),
  entry_date date not null default current_date,
  client_name text not null,
  sku text not null,
  revenue_usd numeric(14,2) default 0,
  cogs_usd numeric(14,2) default 0,
  expense_usd numeric(14,2) default 0,
  margin_usd numeric(14,2) generated always as (revenue_usd - cogs_usd - expense_usd) stored,
  bank_balance_usd numeric(14,2) default 0,
  bank_balance_cny numeric(14,2) default 0,
  note text,
  source text default 'manual',  -- 'manual' | 'api' (tashqi saytdan)
  created_at timestamptz default now()
);

alter table public.cargo_entries enable row level security;

create policy "Cargo xodimlari o'z yozuvlarini ko'radi"
  on cargo_entries for select using (
    auth.uid() = user_id
    or exists (select 1 from profiles where id = auth.uid() and role = 'owner')
    or exists (select 1 from profiles where id = auth.uid() and role = 'manager' and direction = 'cargo')
  );

create policy "Cargo xodimlari kirita oladi"
  on cargo_entries for insert with check (
    exists (select 1 from profiles where id = auth.uid() and direction = 'cargo')
    or exists (select 1 from profiles where id = auth.uid() and role = 'owner')
  );

create policy "Cargo xodimlari o'zgartira oladi"
  on cargo_entries for update using (
    auth.uid() = user_id
    or exists (select 1 from profiles where id = auth.uid() and role = 'owner')
  );

-- ── LOGISTICS ───────────────────────────────────────────────
create table public.logistics_entries (
  id bigserial primary key,
  user_id uuid references profiles(id),
  entry_date date not null default current_date,
  client_name text not null,
  sku text not null,
  revenue_usd numeric(14,2) default 0,
  cogs_usd numeric(14,2) default 0,
  expense_usd numeric(14,2) default 0,
  margin_usd numeric(14,2) generated always as (revenue_usd - cogs_usd - expense_usd) stored,
  bank_balance_usd numeric(14,2) default 0,
  bank_balance_cny numeric(14,2) default 0,
  note text,
  source text default 'manual',
  created_at timestamptz default now()
);

alter table public.logistics_entries enable row level security;

create policy "Logistics ko'rish"
  on logistics_entries for select using (
    auth.uid() = user_id
    or exists (select 1 from profiles where id = auth.uid() and role = 'owner')
    or exists (select 1 from profiles where id = auth.uid() and role = 'manager' and direction = 'logistics')
  );

create policy "Logistics kiritish"
  on logistics_entries for insert with check (
    exists (select 1 from profiles where id = auth.uid() and direction = 'logistics')
    or exists (select 1 from profiles where id = auth.uid() and role = 'owner')
  );

-- ── EXCHANGE ────────────────────────────────────────────────
create table public.exchange_entries (
  id bigserial primary key,
  user_id uuid references profiles(id),
  entry_date date not null default current_date,
  rmb_to_usd_amount numeric(14,2) default 0,
  rmb_to_usd_rate numeric(8,4) default 0,
  usd_to_rmb_amount numeric(14,2) default 0,
  usd_to_rmb_rate numeric(8,4) default 0,
  spread_usd numeric(14,2) default 0,
  expense_usd numeric(14,2) default 0,
  net_profit_usd numeric(14,2) generated always as (spread_usd - expense_usd) stored,
  cash_balance_usd numeric(14,2) default 0,
  cash_balance_cny numeric(14,2) default 0,
  note text,
  created_at timestamptz default now()
);

alter table public.exchange_entries enable row level security;

create policy "Exchange ko'rish"
  on exchange_entries for select using (
    auth.uid() = user_id
    or exists (select 1 from profiles where id = auth.uid() and role = 'owner')
    or exists (select 1 from profiles where id = auth.uid() and role = 'manager' and direction = 'exchange')
  );

create policy "Exchange kiritish"
  on exchange_entries for insert with check (
    exists (select 1 from profiles where id = auth.uid() and direction = 'exchange')
    or exists (select 1 from profiles where id = auth.uid() and role = 'owner')
  );

-- ── PROCUREMENT ─────────────────────────────────────────────
create table public.procurement_entries (
  id bigserial primary key,
  user_id uuid references profiles(id),
  entry_date date not null default current_date,
  client_name text not null,
  product_category text not null,
  order_value_usd numeric(14,2) default 0,
  commission_rate numeric(5,4) default 0,
  commission_usd numeric(14,2) default 0,
  expense_usd numeric(14,2) default 0,
  net_profit_usd numeric(14,2) generated always as (commission_usd - expense_usd) stored,
  bank_balance_usd numeric(14,2) default 0,
  bank_balance_cny numeric(14,2) default 0,
  note text,
  source text default 'manual',
  created_at timestamptz default now()
);

alter table public.procurement_entries enable row level security;

create policy "Procurement ko'rish"
  on procurement_entries for select using (
    auth.uid() = user_id
    or exists (select 1 from profiles where id = auth.uid() and role = 'owner')
    or exists (select 1 from profiles where id = auth.uid() and role = 'manager' and direction = 'procurement')
  );

create policy "Procurement kiritish"
  on procurement_entries for insert with check (
    exists (select 1 from profiles where id = auth.uid() and direction = 'procurement')
    or exists (select 1 from profiles where id = auth.uid() and role = 'owner')
  );

-- ── HOLDING KASSA ────────────────────────────────────────────
create table public.holding_entries (
  id bigserial primary key,
  user_id uuid references profiles(id),
  entry_date date not null default current_date,
  dividend_in_usd numeric(14,2) default 0,
  dividend_from text,           -- qaysi yo'nalishdan
  loan_in_usd numeric(14,2) default 0,
  loan_in_from text,
  expense_out_usd numeric(14,2) default 0,
  expense_description text,
  transfer_out_usd numeric(14,2) default 0,  -- perebroska
  transfer_out_to text,          -- qaysi yo'nalishga
  transfer_in_usd numeric(14,2) default 0,
  transfer_in_from text,
  cash_balance_usd numeric(14,2) default 0,
  note text,
  created_at timestamptz default now()
);

alter table public.holding_entries enable row level security;

create policy "Holding ko'rish"
  on holding_entries for select using (
    auth.uid() = user_id
    or exists (select 1 from profiles where id = auth.uid() and role = 'owner')
    or exists (select 1 from profiles where id = auth.uid() and role = 'manager' and direction = 'holding')
  );

create policy "Holding kiritish"
  on holding_entries for insert with check (
    exists (select 1 from profiles where id = auth.uid() and direction = 'holding')
    or exists (select 1 from profiles where id = auth.uid() and role = 'owner')
  );

-- ── TASHQI API INTEGRATSIYA ──────────────────────────────────
-- Cargo moliyachisining saytidan avtomatik ma'lumot tortish uchun
create table public.api_integrations (
  id bigserial primary key,
  direction text not null,
  source_name text not null,       -- masalan: "Cargo Finance Site"
  api_url text not null,           -- endpoint URL
  api_key_hash text,               -- xavfsizlik uchun hash
  field_mapping jsonb,             -- ularning maydonlari → bizning maydonlarimiz
  last_sync_at timestamptz,
  is_active boolean default true,
  created_at timestamptz default now()
);

-- ── FOYDALI VIEW'LAR (HOLDING UCHUN) ────────────────────────
create view public.daily_summary as
select
  entry_date,
  'cargo' as direction,
  sum(revenue_usd) as revenue,
  sum(cogs_usd) as cogs,
  sum(expense_usd) as expense,
  sum(margin_usd) as profit
from cargo_entries
group by entry_date

union all

select
  entry_date,
  'logistics',
  sum(revenue_usd),
  sum(cogs_usd),
  sum(expense_usd),
  sum(margin_usd)
from logistics_entries
group by entry_date

union all

select
  entry_date,
  'exchange',
  sum(spread_usd),
  0,
  sum(expense_usd),
  sum(net_profit_usd)
from exchange_entries
group by entry_date

union all

select
  entry_date,
  'procurement',
  sum(commission_usd),
  0,
  sum(expense_usd),
  sum(net_profit_usd)
from procurement_entries
group by entry_date;

-- ── INDEKSLAR (TEZLIK UCHUN) ─────────────────────────────────
create index idx_cargo_date on cargo_entries(entry_date desc);
create index idx_logistics_date on logistics_entries(entry_date desc);
create index idx_exchange_date on exchange_entries(entry_date desc);
create index idx_procurement_date on procurement_entries(entry_date desc);
create index idx_holding_date on holding_entries(entry_date desc);
create index idx_cargo_client on cargo_entries(client_name);
create index idx_logistics_client on logistics_entries(client_name);
create index idx_procurement_client on procurement_entries(client_name);

-- ── CRM — MIJOZLAR BAZASI ────────────────────────────────────
create table public.clients (
  id bigserial primary key,
  company_name text not null,
  contact_person text,
  phone text,
  email text,
  city text,
  product_category text,
  direction text check (direction in ('cargo','logistics','exchange','procurement')),
  status text default 'Faol' check (status in ('VIP','Faol','Potentsial','Sovuq')),
  source text,
  ltv_usd numeric(14,2) default 0,
  deals_count integer default 0,
  last_deal_date date,
  notes text,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

alter table public.clients enable row level security;

create policy "Clients ko'rish"
  on clients for select using (
    exists (select 1 from profiles where id = auth.uid() and role in ('owner','manager'))
    or auth.uid() = created_by
  );

create policy "Clients kiritish"
  on clients for insert with check (auth.uid() is not null);

create policy "Clients tahrirlash"
  on clients for update using (
    auth.uid() = created_by
    or exists (select 1 from profiles where id = auth.uid() and role = 'owner')
  );

create index idx_clients_company on clients(company_name);
create index idx_clients_direction on clients(direction);
create index idx_clients_status on clients(status);
