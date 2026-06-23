-- Business Plan tables
create table if not exists public.app_bp_plans (
  id text primary key, data jsonb not null, dir text,
  updated_at timestamptz default now()
);
alter table public.app_bp_plans enable row level security;
create policy "auth_bp_plans" on public.app_bp_plans using (auth.uid() is not null) with check (auth.uid() is not null);
drop trigger if exists trg_bp_plans_upd on public.app_bp_plans;
create trigger trg_bp_plans_upd before update on public.app_bp_plans for each row execute function public.set_updated_at();
create index if not exists idx_bp_plans_dir on public.app_bp_plans(dir);

create table if not exists public.app_bp_lines (
  id text primary key, data jsonb not null, dir text, plan_id text,
  updated_at timestamptz default now()
);
alter table public.app_bp_lines enable row level security;
create policy "auth_bp_lines" on public.app_bp_lines using (auth.uid() is not null) with check (auth.uid() is not null);
drop trigger if exists trg_bp_lines_upd on public.app_bp_lines;
create trigger trg_bp_lines_upd before update on public.app_bp_lines for each row execute function public.set_updated_at();
create index if not exists idx_bp_lines_dir on public.app_bp_lines(dir);
create index if not exists idx_bp_lines_plan on public.app_bp_lines(plan_id);

-- Budget (existing BUDGET_DATA sync)
create table if not exists public.app_budget (
  id text primary key, data jsonb not null, dir text,
  updated_at timestamptz default now()
);
alter table public.app_budget enable row level security;
create policy "auth_budget" on public.app_budget using (auth.uid() is not null) with check (auth.uid() is not null);

-- DC (Deb/Kred)
create table if not exists public.app_dc (
  id text primary key, data jsonb not null, dir text,
  updated_at timestamptz default now()
);
alter table public.app_dc enable row level security;
create policy "auth_dc" on public.app_dc using (auth.uid() is not null) with check (auth.uid() is not null);

-- Kontragents
create table if not exists public.app_kontragents (
  id text primary key, data jsonb not null, dir text,
  updated_at timestamptz default now()
);
alter table public.app_kontragents enable row level security;
create policy "auth_kontragents" on public.app_kontragents using (auth.uid() is not null) with check (auth.uid() is not null);

-- Check counts
select 'app_bp_plans' as tbl, count(*) from public.app_bp_plans
union all select 'app_bp_lines', count(*) from public.app_bp_lines
union all select 'app_budget', count(*) from public.app_budget
union all select 'app_dc', count(*) from public.app_dc
union all select 'app_kontragents', count(*) from public.app_kontragents;

-- Bank hisoblar (nomlangan bank kassalar)
CREATE TABLE IF NOT EXISTS app_bank_accounts (
  dir TEXT PRIMARY KEY,
  data JSONB DEFAULT '[]'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE app_bank_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "auth users" ON app_bank_accounts FOR ALL USING (auth.uid() IS NOT NULL);
