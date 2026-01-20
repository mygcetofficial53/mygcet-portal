-- 1. Polls Table
create table if not exists public.polls (
  id uuid default gen_random_uuid() primary key,
  question text not null,
  options jsonb not null, -- Array of strings e.g. ["Yes", "No"]
  is_active boolean default true,
  created_at timestamptz default now()
);

-- 2. Poll Votes Table
create table if not exists public.poll_votes (
  id uuid default gen_random_uuid() primary key,
  poll_id uuid references public.polls(id) on delete cascade,
  enrollment text not null, -- User identifier
  option_index int not null, -- Index of the selected option
  created_at timestamptz default now(),
  unique(poll_id, enrollment) -- One vote per user per poll
);

-- 3. App Settings Table (for Maintenance Mode)
create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz default now()
);

-- Insert default maintenance mode setting
insert into public.app_settings (key, value)
values ('maintenance_mode', '{"is_enabled": false, "message": "App is under maintenance"}'::jsonb)
on conflict (key) do nothing;

-- 4. Update Notifications Table (Add target_branch)
do $$
begin
  if not exists (select 1 from information_schema.columns where table_name = 'notifications' and column_name = 'target_branch') then
    alter table public.notifications add column target_branch text; -- Null means "All"
  end if;
end $$;

-- Policies (RLS)

-- Polls: Everyone reads, Admin writes
alter table public.polls enable row level security;
create policy "Read polls" on public.polls for select using (true);
create policy "Admin all polls" on public.polls for all using (true) with check (true); -- Simplify for now, ideally restrict

-- Votes: Authenticated users insert own vote
alter table public.poll_votes enable row level security;
create policy "Read votes" on public.poll_votes for select using (true);
create policy "Insert vote" on public.poll_votes for insert with check (true);

-- Settings: Everyone reads, Admin writes
alter table public.app_settings enable row level security;
create policy "Read settings" on public.app_settings for select using (true);
create policy "Admin settings" on public.app_settings for all using (true) with check (true);
