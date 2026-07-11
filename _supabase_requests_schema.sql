-- FinanceHub — requests table schema
-- Supabase Dashboard > SQL Editor da ishga tushiring

create table if not exists public.requests (
  id                text primary key,
  type              text not null check (type in ('expense','capex')),
  direction         text,
  dept              text,
  title             text not null,
  description       text,
  category          text,
  amount            numeric(14,2) default 0,
  vendor            text,
  requested_by      text,
  deadline          text,
  status            text default 'draft',
  approvals         jsonb default '[]'::jsonb,
  comments          jsonb default '[]'::jsonb,
  rejection_reason  text,
  approved_at       timestamptz,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now(),
  created_by        uuid references auth.users(id) on delete set null
);

-- updated_at auto trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists trg_requests_updated_at on public.requests;
create trigger trg_requests_updated_at
  before update on public.requests
  for each row execute function public.set_updated_at();

-- Row Level Security
alter table public.requests enable row level security;

-- Barcha autentifikatsiya qilingan foydalanuvchilar ko'ra oladi
create policy "auth_read_requests" on public.requests
  for select using (auth.uid() is not null);

-- Yangi so'rov yaratish
create policy "auth_insert_requests" on public.requests
  for insert with check (auth.uid() is not null);

-- Tasdiqlash / rad etish / yangilash
create policy "auth_update_requests" on public.requests
  for update using (auth.uid() is not null);

-- Faqat qoralama (draft) so'rovlarni o'chirish mumkin
create policy "auth_delete_draft_requests" on public.requests
  for delete using (auth.uid() is not null and status = 'draft');

-- Index for fast queries
create index if not exists idx_requests_direction on public.requests(direction);
create index if not exists idx_requests_status    on public.requests(status);
create index if not exists idx_requests_created   on public.requests(created_at desc);

-- ═══════════════════════════════════════════════════════════
--  EXCHANGE — HAMKORLAR
-- ═══════════════════════════════════════════════════════════
create table if not exists public.app_exch_partners (
  id          text primary key,
  name        text not null,
  phone       text,
  share_pct   numeric(5,2) default 0,
  note        text,
  created_at  timestamptz default now()
);

alter table public.app_exch_partners enable row level security;
create policy "auth_all_exch_partners" on public.app_exch_partners
  for all using (auth.uid() is not null);

-- ═══════════════════════════════════════════════════════════
--  EXCHANGE — TO'LOV KANALLARI
-- ═══════════════════════════════════════════════════════════
create table if not exists public.app_exch_channels (
  id          text primary key,
  type        text not null,   -- naqd, karta, xtransfer, pingpong, worldfirst, alipay, bank, boshqa
  name        text not null,
  partner_id  text references public.app_exch_partners(id) on delete set null,
  currencies  jsonb default '[]'::jsonb,
  balances    jsonb default '{}'::jsonb,
  note        text,
  created_at  timestamptz default now()
);

alter table public.app_exch_channels enable row level security;
create policy "auth_all_exch_channels" on public.app_exch_channels
  for all using (auth.uid() is not null);

create index if not exists idx_exch_channels_partner on public.app_exch_channels(partner_id);
create index if not exists idx_exch_channels_type    on public.app_exch_channels(type);

-- ═══════════════════════════════════════════════════════════
--  EXCHANGE — MIJOZLAR
-- ═══════════════════════════════════════════════════════════
create table if not exists public.app_exch_clients (
  id           text primary key,
  name         text not null,
  phone        text,
  passport     text,
  balance_usd  numeric(14,2) default 0,
  balance_cny  numeric(14,2) default 0,
  note         text,
  created_at   timestamptz default now()
);

alter table public.app_exch_clients enable row level security;
create policy "auth_all_exch_clients" on public.app_exch_clients
  for all using (auth.uid() is not null);

-- ═══════════════════════════════════════════════════════════
--  EXCHANGE — MIJOZ TRANZAKSIYALARI
-- ═══════════════════════════════════════════════════════════
create table if not exists public.app_exch_client_txns (
  id            text primary key,
  client_id     text references public.app_exch_clients(id) on delete cascade,
  type          text,           -- kirim, qaytarish, konversiya, xarajat
  amount_in     numeric(14,2) default 0,
  amount_out    numeric(14,2) default 0,
  currency_in   text,
  currency_out  text,
  rate          numeric(12,6) default 0,
  bank_rate     numeric(12,6) default 0,
  spread_profit numeric(14,2) default 0,
  channel_id    text references public.app_exch_channels(id) on delete set null,
  partner_id    text references public.app_exch_partners(id) on delete set null,
  date          date,
  note          text,
  created_at    timestamptz default now()
);

alter table public.app_exch_client_txns enable row level security;
create policy "auth_all_exch_client_txns" on public.app_exch_client_txns
  for all using (auth.uid() is not null);

create index if not exists idx_exch_clients_name    on public.app_exch_clients(name);
create index if not exists idx_exch_txns_client     on public.app_exch_client_txns(client_id);
create index if not exists idx_exch_txns_channel    on public.app_exch_client_txns(channel_id);
create index if not exists idx_exch_txns_partner    on public.app_exch_client_txns(partner_id);
create index if not exists idx_exch_txns_date       on public.app_exch_client_txns(date desc);

-- ═══════════════════════════════════════════════════════════
--  EXCHANGE — XARAJATLAR
-- ═══════════════════════════════════════════════════════════
create table if not exists public.app_exch_expenses (
  id          text primary key,
  category    text,
  amount      numeric(14,2) default 0,
  currency    text default 'USD',
  date        date,
  note        text,
  created_at  timestamptz default now()
);

alter table public.app_exch_expenses enable row level security;
create policy "auth_all_exch_expenses" on public.app_exch_expenses
  for all using (auth.uid() is not null);

-- Tekshirish
select
  (select count(*) from public.app_exch_clients)     as clients,
  (select count(*) from public.app_exch_client_txns) as txns,
  (select count(*) from public.app_exch_expenses)    as expenses,
  (select count(*) from public.requests)              as requests;
