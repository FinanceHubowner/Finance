-- FinanceHub — hrm_employees table schema
-- Supabase Dashboard > SQL Editor da ishga tushiring

create table if not exists public.hrm_employees (
  id           text primary key,
  data         jsonb not null,
  dir          text,
  status       text default 'Ishlayapti',
  updated_at   timestamptz default now()
);

-- updated_at auto trigger
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists trg_hrm_updated_at on public.hrm_employees;
create trigger trg_hrm_updated_at
  before update on public.hrm_employees
  for each row execute function public.set_updated_at();

-- Row Level Security
alter table public.hrm_employees enable row level security;

create policy "auth_read_hrm" on public.hrm_employees
  for select using (auth.uid() is not null);

create policy "auth_insert_hrm" on public.hrm_employees
  for insert with check (auth.uid() is not null);

create policy "auth_update_hrm" on public.hrm_employees
  for update using (auth.uid() is not null);

create policy "auth_delete_hrm" on public.hrm_employees
  for delete using (auth.uid() is not null);

-- Indexes
create index if not exists idx_hrm_dir    on public.hrm_employees(dir);
create index if not exists idx_hrm_status on public.hrm_employees(status);

select count(*) from public.hrm_employees;
