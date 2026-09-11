-- Shorif Diamond Topup Center BD: secure admin foundation
-- Run this in Supabase SQL Editor.
-- First create the Admin user in Authentication > Users.
-- Then replace ADMIN_USER_UUID below with that user's UUID.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin' check (role in ('admin'))
);
alter table public.profiles enable row level security;
create policy "profiles_self_read" on public.profiles
for select to authenticated using (id = auth.uid());

create table if not exists public.site_settings (
  id integer primary key default 1 check (id = 1),
  site_name text not null default 'Shorif Diamond Topup Center BD',
  owner_name text not null default 'Shorif',
  owner_role text not null default 'Owner & Top-Up Manager',
  payment_number text not null default '01781893290',
  whatsapp_number text not null default '01781893290',
  support_email text not null default 'mdshorifms0716733@gmail.com',
  hero_badge text,
  hero_title text,
  hero_text text,
  about_title text,
  about_text text,
  seo_description text
);
alter table public.site_settings enable row level security;
create policy "settings_public_read" on public.site_settings
for select to anon, authenticated using (true);
create policy "settings_admin_write" on public.site_settings
for all to authenticated
using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
insert into public.site_settings (id) values (1) on conflict (id) do nothing;

create table if not exists public.packages (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  diamonds text not null,
  price text not null,
  active boolean not null default true,
  sort_order integer not null default 0
);
alter table public.packages enable row level security;
create policy "packages_public_read" on public.packages
for select to anon, authenticated
using (active = true or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy "packages_admin_write" on public.packages
for all to authenticated
using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  package_id uuid references public.packages(id),
  uid text not null,
  game_code text not null,
  customer_name text not null,
  customer_phone text not null,
  status text not null default 'pending'
    check (status in ('pending','processing','completed','cancelled'))
);
alter table public.orders enable row level security;
create policy "orders_public_create" on public.orders
for insert to anon, authenticated with check (true);
create policy "orders_admin_read" on public.orders
for select to authenticated
using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy "orders_admin_update" on public.orders
for update to authenticated
using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

-- After creating the Admin user, run:
-- insert into public.profiles (id, role) values ('ADMIN_USER_UUID_HERE','admin');
