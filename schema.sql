-- Off the Peg — full database schema
-- Run this once, in the Supabase SQL Editor, on a fresh project.
-- Everything here is idempotent-ish for a first run; it is NOT safe to
-- re-run on a database that already has this schema applied.
--
-- Before running this file:
--   1. Create the project in Supabase.
--   2. Storage → New bucket → name it exactly "item-photos" → leave
--      "Public bucket" UNCHECKED. This has to exist before the storage
--      policies at the bottom of this file will do anything useful.
--   3. Authentication → Providers → Email → enabled. Consider disabling
--      "Confirm email" too, since this is a single-user app and email
--      confirmation is just friction for signing yourself up.

-- ============================================================
-- TABLES
-- ============================================================

create table items (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid default auth.uid(),
  name text not null,
  category text not null,
  colour text,
  brand text,
  price numeric,
  season text,
  occasion text,
  notes text,
  favourite boolean default false,
  wear_count int default 0,
  last_worn timestamptz,
  created_at timestamptz default now(),
  status text not null default 'active' check (status in ('active','donated','sold','binned')),
  retired_at timestamptz,
  resale_value numeric,
  photo_path text
);

create table outfits (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid default auth.uid(),
  name text not null,
  wear_count int default 0,
  last_worn timestamptz,
  created_at timestamptz default now()
);

create table outfit_items (
  id uuid primary key default gen_random_uuid(),
  outfit_id uuid references outfits(id) on delete cascade,
  item_id uuid references items(id) on delete cascade
);

create table wear_log (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid default auth.uid(),
  item_id uuid references items(id) on delete cascade,
  outfit_id uuid references outfits(id) on delete set null,
  worn_at timestamptz default now()
);

create table settings (
  owner_id uuid primary key default auth.uid(),
  cull_unworn_days int default 90,
  cull_cpw_threshold numeric default 15,
  category_caps jsonb default '{}'::jsonb,
  updated_at timestamptz default now()
);

create table wishlist (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid default auth.uid(),
  name text not null,
  category text,
  price numeric,
  notes text,
  created_at timestamptz default now()
);

-- ============================================================
-- ROW LEVEL SECURITY — every table is scoped to its own owner_id.
-- outfit_items has no owner_id of its own, so its policy looks up
-- the parent outfit's owner_id instead.
-- ============================================================

alter table items enable row level security;
create policy "items_owner_access" on items for all
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

alter table outfits enable row level security;
create policy "outfits_owner_access" on outfits for all
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

alter table outfit_items enable row level security;
create policy "outfit_items_owner_access" on outfit_items for all
  using (auth.uid() = (select owner_id from outfits where outfits.id = outfit_items.outfit_id))
  with check (auth.uid() = (select owner_id from outfits where outfits.id = outfit_items.outfit_id));

alter table wear_log enable row level security;
create policy "wear_log_owner_access" on wear_log for all
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

alter table settings enable row level security;
create policy "settings_owner_access" on settings for all
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

alter table wishlist enable row level security;
create policy "wishlist_owner_access" on wishlist for all
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

-- ============================================================
-- TABLE GRANTS — RLS controls *which rows*, these grants control
-- whether the authenticated role can touch the table at all.
-- ============================================================

grant select, insert, update, delete on public.items to authenticated;
grant select, insert, update, delete on public.outfits to authenticated;
grant select, insert, update, delete on public.outfit_items to authenticated;
grant select, insert, update, delete on public.wear_log to authenticated;
grant select, insert, update, delete on public.settings to authenticated;
grant select, insert, update, delete on public.wishlist to authenticated;

-- ============================================================
-- STORAGE POLICIES — for the "item-photos" bucket created manually
-- in the dashboard before running this file. Files are stored under
-- a path like {user_id}/{item_id}.jpg, so access is scoped by folder.
-- ============================================================

create policy "item_photos_select_own"
  on storage.objects for select
  using (bucket_id = 'item-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "item_photos_insert_own"
  on storage.objects for insert
  with check (bucket_id = 'item-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "item_photos_update_own"
  on storage.objects for update
  using (bucket_id = 'item-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "item_photos_delete_own"
  on storage.objects for delete
  using (bucket_id = 'item-photos' and (storage.foldername(name))[1] = auth.uid()::text);