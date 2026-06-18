-- FinanceHub — Shared data tables (cross-user sync)
-- Supabase Dashboard > SQL Editor da ishga tushiring

-- ── set_updated_at trigger (agar mavjud bo'lmasa) ─────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

-- ══════════════════════════════════════════════════════════════════
-- 1. TASKS (Vazifalar)
-- ══════════════════════════════════════════════════════════════════
create table if not exists public.app_tasks (
  id         text primary key,
  data       jsonb not null,
  dir        text,
  status     text,
  updated_at timestamptz default now()
);
alter table public.app_tasks enable row level security;
create policy "auth_all_tasks" on public.app_tasks using (auth.uid() is not null) with check (auth.uid() is not null);
drop trigger if exists trg_tasks_upd on public.app_tasks;
create trigger trg_tasks_upd before update on public.app_tasks for each row execute function public.set_updated_at();
create index if not exists idx_tasks_dir on public.app_tasks(dir);
create index if not exists idx_tasks_status on public.app_tasks(status);

-- ══════════════════════════════════════════════════════════════════
-- 2. TXNS (Kassa tranzaksiyalari)
-- ══════════════════════════════════════════════════════════════════
create table if not exists public.app_txns (
  id         text primary key,
  data       jsonb not null,
  dir        text,
  type       text,
  updated_at timestamptz default now()
);
alter table public.app_txns enable row level security;
create policy "auth_all_txns" on public.app_txns using (auth.uid() is not null) with check (auth.uid() is not null);
drop trigger if exists trg_txns_upd on public.app_txns;
create trigger trg_txns_upd before update on public.app_txns for each row execute function public.set_updated_at();
create index if not exists idx_txns_dir on public.app_txns(dir);

-- ══════════════════════════════════════════════════════════════════
-- 3. ORG (Departamentlar, Bo'limlar, Teamlar, Lavozimlar)
-- ══════════════════════════════════════════════════════════════════
create table if not exists public.app_org (
  id         text primary key,
  org_type   text not null, -- 'dept'|'bolim'|'team'|'lavozim'
  data       jsonb not null,
  dir        text,
  updated_at timestamptz default now()
);
alter table public.app_org enable row level security;
create policy "auth_all_org" on public.app_org using (auth.uid() is not null) with check (auth.uid() is not null);
drop trigger if exists trg_org_upd on public.app_org;
create trigger trg_org_upd before update on public.app_org for each row execute function public.set_updated_at();
create index if not exists idx_org_dir on public.app_org(dir);
create index if not exists idx_org_type on public.app_org(org_type);

-- ══════════════════════════════════════════════════════════════════
-- 4. CRM (Mijozlar)
-- ══════════════════════════════════════════════════════════════════
create table if not exists public.app_crm (
  id         text primary key,
  data       jsonb not null,
  dir        text,
  updated_at timestamptz default now()
);
alter table public.app_crm enable row level security;
create policy "auth_all_crm" on public.app_crm using (auth.uid() is not null) with check (auth.uid() is not null);
drop trigger if exists trg_crm_upd on public.app_crm;
create trigger trg_crm_upd before update on public.app_crm for each row execute function public.set_updated_at();
create index if not exists idx_crm_dir on public.app_crm(dir);

-- ══════════════════════════════════════════════════════════════════
-- 5. PIPELINE
-- ══════════════════════════════════════════════════════════════════
create table if not exists public.app_pipeline (
  id         text primary key,
  data       jsonb not null,
  dir        text,
  updated_at timestamptz default now()
);
alter table public.app_pipeline enable row level security;
create policy "auth_all_pipeline" on public.app_pipeline using (auth.uid() is not null) with check (auth.uid() is not null);
drop trigger if exists trg_pipeline_upd on public.app_pipeline;
create trigger trg_pipeline_upd before update on public.app_pipeline for each row execute function public.set_updated_at();
create index if not exists idx_pipeline_dir on public.app_pipeline(dir);

-- ══════════════════════════════════════════════════════════════════
-- 6. PAYROLL (dir bo'yicha - har yo'nalish uchun 1 qator)
-- ══════════════════════════════════════════════════════════════════
create table if not exists public.app_payroll (
  dir        text primary key,
  data       jsonb not null,
  updated_at timestamptz default now()
);
alter table public.app_payroll enable row level security;
create policy "auth_all_payroll" on public.app_payroll using (auth.uid() is not null) with check (auth.uid() is not null);
drop trigger if exists trg_payroll_upd on public.app_payroll;
create trigger trg_payroll_upd before update on public.app_payroll for each row execute function public.set_updated_at();

-- ══════════════════════════════════════════════════════════════════
-- 7. KASSA (dir bo'yicha)
-- ══════════════════════════════════════════════════════════════════
create table if not exists public.app_kassa (
  dir        text primary key,
  data       jsonb not null,
  updated_at timestamptz default now()
);
alter table public.app_kassa enable row level security;
create policy "auth_all_kassa" on public.app_kassa using (auth.uid() is not null) with check (auth.uid() is not null);
drop trigger if exists trg_kassa_upd on public.app_kassa;
create trigger trg_kassa_upd before update on public.app_kassa for each row execute function public.set_updated_at();

-- ══════════════════════════════════════════════════════════════════
-- 8. EMPLOYEE INVENTORY
-- ══════════════════════════════════════════════════════════════════
create table if not exists public.app_emp_inventory (
  id         text primary key,
  data       jsonb not null,
  dir        text,
  updated_at timestamptz default now()
);
alter table public.app_emp_inventory enable row level security;
create policy "auth_all_inv" on public.app_emp_inventory using (auth.uid() is not null) with check (auth.uid() is not null);
drop trigger if exists trg_inv_upd on public.app_emp_inventory;
create trigger trg_inv_upd before update on public.app_emp_inventory for each row execute function public.set_updated_at();
create index if not exists idx_inv_dir on public.app_emp_inventory(dir);

-- ══════════════════════════════════════════════════════════════════
-- Tekshirish
-- ══════════════════════════════════════════════════════════════════
select 'app_tasks'         as tbl, count(*) from public.app_tasks
union all select 'app_txns',         count(*) from public.app_txns
union all select 'app_org',          count(*) from public.app_org
union all select 'app_crm',          count(*) from public.app_crm
union all select 'app_pipeline',     count(*) from public.app_pipeline
union all select 'app_payroll',      count(*) from public.app_payroll
union all select 'app_kassa',        count(*) from public.app_kassa
union all select 'app_emp_inventory',count(*) from public.app_emp_inventory;
