-- Create a table for notifications
create table public.notifications (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  title text not null,
  message text not null,
  type text default 'info'::text, -- 'info', 'warning', 'success', 'event'
  is_active boolean default true,
  priority integer default 0
);


alter table public.notifications enable row level security;


create policy "Public notifications are viewable by everyone"
  on public.notifications for select
  using ( is_active = true );


create policy "Enable all access for all users"
  on public.notifications for all
  using ( true )
  with check ( true );
