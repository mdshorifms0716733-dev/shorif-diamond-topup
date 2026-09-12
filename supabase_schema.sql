-- SHORIF DIAMOND TOPUP CENTER BD - full setup
-- Run this in Supabase SQL Editor. NEVER expose a service_role/secret key in frontend.

-- Profiles: players + admin
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'player',
  display_name text not null default 'Player',
  avatar_url text,
  created_at timestamptz not null default now()
);

-- Upgrade old installations that had only role=admin.
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check check (role in ('player','admin'));
alter table public.profiles add column if not exists display_name text not null default 'Player';
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists created_at timestamptz not null default now();
alter table public.profiles enable row level security;
drop policy if exists profiles_self_read on public.profiles;
drop policy if exists profiles_self_insert on public.profiles;
drop policy if exists profiles_self_update on public.profiles;
create policy profiles_self_read on public.profiles for select to authenticated using (id=auth.uid());
create policy profiles_self_insert on public.profiles for insert to authenticated with check (id=auth.uid() and role='player');
create policy profiles_self_update on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid() and role='player');
grant select,insert,update on public.profiles to authenticated;

-- Existing admin remains admin.
update public.profiles set role='admin' where id='0a17e9b4-617a-4ff2-9ea6-42912dbb2520';

create table if not exists public.site_settings (
 id integer primary key default 1 check(id=1),
 site_name text not null default 'Shorif Diamond Topup Center BD',
 owner_name text not null default 'MD Shorif', owner_role text not null default 'Admin Owner',
 payment_number text not null default '01781893290', nagad_number text not null default '01781893290',
 whatsapp_number text not null default '01781893290', support_email text not null default 'mdshorifms0716733@gmail.com',
 admin_photo_url text, notice_text text,
 hero_badge text, hero_title text, hero_text text, about_title text, about_text text, seo_description text
);
alter table public.site_settings add column if not exists nagad_number text not null default '01781893290';
alter table public.site_settings add column if not exists admin_photo_url text;
alter table public.site_settings add column if not exists notice_text text;
alter table public.site_settings enable row level security;
drop policy if exists settings_public_read on public.site_settings;
drop policy if exists settings_admin_write on public.site_settings;
create policy settings_public_read on public.site_settings for select to anon,authenticated using(true);
create policy settings_admin_write on public.site_settings for all to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')) with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
grant select on public.site_settings to anon,authenticated;
grant insert,update,delete on public.site_settings to authenticated;
insert into public.site_settings(id) values(1) on conflict(id) do nothing;

create table if not exists public.packages (
 id uuid primary key default gen_random_uuid(), title text not null, diamonds text not null, price text not null,
 active boolean not null default true, sort_order integer not null default 0
);
alter table public.packages enable row level security;
drop policy if exists packages_public_read on public.packages;
drop policy if exists packages_admin_write on public.packages;
create policy packages_public_read on public.packages for select to anon,authenticated using(active=true or exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy packages_admin_write on public.packages for all to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')) with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
grant select on public.packages to anon,authenticated;
grant insert,update,delete on public.packages to authenticated;

-- Orders now belong to a player when logged in; anonymous orders are still allowed.
create table if not exists public.orders (
 id uuid primary key default gen_random_uuid(), created_at timestamptz not null default now(),
 user_id uuid references auth.users(id) on delete set null, package_id uuid references public.packages(id),
 order_code text, uid text not null, game_code text not null default '', customer_name text not null,
 customer_phone text not null default '', transaction_id text not null default '',
 status text not null default 'pending' check(status in('pending','processing','completed','cancelled'))
);
alter table public.orders add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.orders add column if not exists order_code text;
alter table public.orders add column if not exists transaction_id text not null default '';
alter table public.orders alter column game_code set default '';
alter table public.orders alter column customer_phone set default '';
create unique index if not exists orders_order_code_unique on public.orders(order_code) where order_code is not null;
alter table public.orders enable row level security;
drop policy if exists orders_public_create on public.orders;
drop policy if exists orders_admin_read on public.orders;
drop policy if exists orders_admin_update on public.orders;
drop policy if exists orders_player_read on public.orders;
create policy orders_public_create on public.orders for insert to anon,authenticated with check(user_id is null or user_id=auth.uid());
create policy orders_admin_read on public.orders for select to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy orders_admin_update on public.orders for update to authenticated using(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')) with check(exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy orders_player_read on public.orders for select to authenticated using(user_id=auth.uid());
grant insert on public.orders to anon,authenticated;
grant select,update on public.orders to authenticated;

-- Secure public order tracking: only safe tracking fields, no UID/name/TrxID.
create or replace function public.track_order(p_order_code text)
returns table(order_code text,status text,created_at timestamptz,package_title text,diamonds text,price text)
language sql security definer set search_path=public as $$
 select o.order_code,o.status,o.created_at,p.title,p.diamonds,p.price
 from public.orders o left join public.packages p on p.id=o.package_id
 where o.order_code=p_order_code limit 1;
$$;
revoke all on function public.track_order(text) from public;
grant execute on function public.track_order(text) to anon,authenticated;

-- Storage buckets
insert into storage.buckets(id,name,public) values('admin-photos','admin-photos',true) on conflict(id) do update set public=true;
insert into storage.buckets(id,name,public) values('player-avatars','player-avatars',true) on conflict(id) do update set public=true;

-- Admin photo policies
 drop policy if exists admin_photo_upload on storage.objects; drop policy if exists admin_photo_update on storage.objects; drop policy if exists admin_photo_delete on storage.objects; drop policy if exists admin_photo_public_read on storage.objects;
create policy admin_photo_upload on storage.objects for insert to authenticated with check(bucket_id='admin-photos' and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy admin_photo_update on storage.objects for update to authenticated using(bucket_id='admin-photos' and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy admin_photo_delete on storage.objects for delete to authenticated using(bucket_id='admin-photos' and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));
create policy admin_photo_public_read on storage.objects for select to public using(bucket_id='admin-photos');

-- Player avatar policies. File path must start with the logged-in user's UUID.
drop policy if exists player_avatar_upload on storage.objects; drop policy if exists player_avatar_update on storage.objects; drop policy if exists player_avatar_delete on storage.objects; drop policy if exists player_avatar_public_read on storage.objects;
create policy player_avatar_upload on storage.objects for insert to authenticated with check(bucket_id='player-avatars' and (storage.foldername(name))[1]=auth.uid()::text);
create policy player_avatar_update on storage.objects for update to authenticated using(bucket_id='player-avatars' and (storage.foldername(name))[1]=auth.uid()::text);
create policy player_avatar_delete on storage.objects for delete to authenticated using(bucket_id='player-avatars' and (storage.foldername(name))[1]=auth.uid()::text);
create policy player_avatar_public_read on storage.objects for select to public using(bucket_id='player-avatars');

-- Seed all packages if the table is empty.
insert into public.packages(title,diamonds,price,sort_order)
select * from (values
('25💎','25 Diamonds','25',1),('50💎','50 Diamonds','40',2),('115💎','115 Diamonds','80',3),('240💎','240 Diamonds','160',4),('355💎','355 Diamonds','240',5),('480💎','480 Diamonds','320',6),('505💎','505 Diamonds','350',7),('610💎','610 Diamonds','400',8),('725💎','725 Diamonds','480',9),('850💎','850 Diamonds','560',10),('965💎','965 Diamonds','640',11),('1015💎','1015 Diamonds','680',12),('1090💎','1090 Diamonds','720',13),('1240💎','1240 Diamonds','800',14),('1355💎','1355 Diamonds','880',15),('1480💎','1480 Diamonds','960',16),('1595💎','1595 Diamonds','1040',17),('1720💎','1720 Diamonds','1120',18),('1850💎','1850 Diamonds','1200',19),('1965💎','1965 Diamonds','1270',20),('2090💎','2090 Diamonds','1360',21),('2205💎','2205 Diamonds','1440',22),('2330💎','2330 Diamonds','1520',23),('2530💎','2530 Diamonds','1600',24),('3140💎','3140 Diamonds','2000',25),('3770💎','3770 Diamonds','2400',26),('5060💎','5060 Diamonds','3200',27),('6300💎','6300 Diamonds','4000',28),('10120💎','10120 Diamonds','6400',29),('Weekly Lite','Weekly Lite','50',30),('Weekly','Weekly','160',31),('Monthly','Monthly','770',32),('Level Up','Level Up','420',33)
) as v(title,diamonds,price,sort_order)
where not exists(select 1 from public.packages);
