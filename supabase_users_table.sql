-- Create a table to store user profiles
create table if not exists public.users (
  id uuid default gen_random_uuid(),
  enrollment text not null primary key, -- Use enrollment as primary key to prevent duplicates
  name text,
  branch text,
  semester text,
  app_version text,
  last_login timestamptz default now(),
  created_at timestamptz default now()
);

-- Enable Row Level Security (RLS) - Optional, but good practice
alter table public.users enable row level security;

-- Create a policy that allows anyone to insert/update (since the app key is public)
-- For a real production app, you might want stricter policies.
create policy "Enable all access for all users" on public.users
for all using (true) with check (true);

-- Insert default app settings if not exists
create table if not exists public.app_settings (
    id serial primary key,
    key text unique not null,
    value jsonb not null
);

-- Insert default theme and maintenance config
insert into public.app_settings (key, value)
values 
  ('app_theme', '{"banner_text": "Welcome", "banner_visible": false, "theme_color": "0xFF3B82F6", "min_version": "1.0.0"}'),
  ('maintenance_mode', '{"is_enabled": false, "message": "App is under maintenance"}')
on conflict (key) do nothing;
