-- Create a table to store user feedback
create table if not exists public.app_feedback (
  enrollment text not null primary key, -- One vote per user, identified by enrollment
  liked boolean not null,               -- true = Liked, false = Disliked
  message text,                         -- Optional message (required if Disliked in UI logic)
  created_at timestamptz default now()
);

-- Enable RLS
alter table public.app_feedback enable row level security;

-- Allow anyone to insert (authenticated or not, logic handled in app)
-- Ideally restrict to authenticated users matching the enrollment
create policy "Enable insert for all users" on public.app_feedback
for insert with check (true);

-- Allow Admin to select all
create policy "Enable select for all users" on public.app_feedback
for select using (true);
