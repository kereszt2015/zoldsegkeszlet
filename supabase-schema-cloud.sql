-- ZöldségKészlet CLOUD 2.0 - Supabase schema
-- Futtasd ezt a Supabase SQL Editorban.

create table if not exists public.workspaces (
  id text primary key,
  name text not null,
  owner_id uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.workspace_members (
  workspace_id text not null references public.workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'viewer',
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table if not exists public.business_snapshots (
  workspace_id text primary key references public.workspaces(id) on delete cascade,
  payload jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id)
);

alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.business_snapshots enable row level security;

drop policy if exists workspaces_select on public.workspaces;
create policy workspaces_select on public.workspaces
for select using (exists (select 1 from public.workspace_members m where m.workspace_id = id and m.user_id = auth.uid()));

drop policy if exists workspaces_insert on public.workspaces;
create policy workspaces_insert on public.workspaces
for insert with check (owner_id = auth.uid());

drop policy if exists members_select on public.workspace_members;
create policy members_select on public.workspace_members
for select using (user_id = auth.uid() or exists (select 1 from public.workspace_members m where m.workspace_id = workspace_members.workspace_id and m.user_id = auth.uid() and m.role in ('owner','admin')));

drop policy if exists members_insert_self on public.workspace_members;
create policy members_insert_self on public.workspace_members
for insert with check (user_id = auth.uid());

drop policy if exists snapshots_select on public.business_snapshots;
create policy snapshots_select on public.business_snapshots
for select using (exists (select 1 from public.workspace_members m where m.workspace_id = business_snapshots.workspace_id and m.user_id = auth.uid()));

drop policy if exists snapshots_insert on public.business_snapshots;
create policy snapshots_insert on public.business_snapshots
for insert with check (exists (select 1 from public.workspace_members m where m.workspace_id = business_snapshots.workspace_id and m.user_id = auth.uid() and m.role in ('owner','admin','editor')));

drop policy if exists snapshots_update on public.business_snapshots;
create policy snapshots_update on public.business_snapshots
for update using (exists (select 1 from public.workspace_members m where m.workspace_id = business_snapshots.workspace_id and m.user_id = auth.uid() and m.role in ('owner','admin','editor')))
with check (exists (select 1 from public.workspace_members m where m.workspace_id = business_snapshots.workspace_id and m.user_id = auth.uid() and m.role in ('owner','admin','editor')));
