create extension if not exists pgcrypto;

create schema if not exists app_private;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  full_name text not null default 'Voxora Member',
  handle text not null unique,
  avatar_url text,
  cover_url text,
  bio text not null default '',
  interests text[] not null default '{}',
  level int not null default 1 check (level >= 1),
  vip_tier text not null default 'Free' check (vip_tier in ('Free', 'Glow', 'Prime', 'Legend')),
  coins int not null default 0 check (coins >= 0),
  earnings int not null default 0 check (earnings >= 0),
  is_admin boolean not null default false,
  is_blocked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 3 and 80),
  topic text not null default 'General',
  description text not null default '',
  host_id uuid not null references public.profiles(id) on delete cascade,
  capacity int not null default 8 check (capacity between 2 and 20),
  is_live boolean not null default true,
  is_locked boolean not null default false,
  created_at timestamptz not null default now(),
  ended_at timestamptz
);

create table public.room_participants (
  room_id uuid not null references public.rooms(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'listener' check (role in ('host', 'speaker', 'listener')),
  muted boolean not null default true,
  speaking boolean not null default false,
  joined_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  primary key (room_id, user_id)
);

create table public.room_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  kind text not null default 'chat' check (kind in ('chat', 'system', 'gift')),
  created_at timestamptz not null default now()
);

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);

create table public.gifts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  label text not null,
  price int not null check (price > 0),
  accent text not null default '#0f766e',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.gift_transactions (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  gift_id uuid not null references public.gifts(id),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  coins int not null check (coins > 0),
  created_at timestamptz not null default now()
);

create table public.coin_packages (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  coins int not null check (coins > 0),
  amount_pkr int not null check (amount_pkr > 0),
  provider text not null default 'manual' check (provider in ('jazzcash', 'easypaisa', 'manual')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.coin_purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  package_id uuid not null references public.coin_packages(id),
  provider text not null check (provider in ('jazzcash', 'easypaisa', 'manual')),
  amount_pkr int not null check (amount_pkr > 0),
  coins int not null check (coins > 0),
  status text not null default 'pending' check (status in ('pending', 'completed', 'failed')),
  provider_reference text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create index profiles_handle_idx on public.profiles (handle);
create index rooms_live_idx on public.rooms (is_live, created_at desc);
create index room_messages_room_idx on public.room_messages (room_id, created_at);
create index messages_conversation_idx on public.messages (conversation_id, created_at);
create index coin_purchases_user_idx on public.coin_purchases (user_id, created_at desc);

create or replace function app_private.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function app_private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select is_admin from public.profiles where id = auth.uid()), false);
$$;

create or replace function app_private.is_conversation_member(target_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.conversation_members
    where conversation_id = target_conversation_id
      and user_id = auth.uid()
  );
$$;

create or replace function app_private.is_room_participant(target_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.room_participants
    where room_id = target_room_id
      and user_id = auth.uid()
  );
$$;

create or replace function app_private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  base_handle text;
  final_handle text;
begin
  base_handle := lower(regexp_replace(coalesce(new.raw_user_meta_data->>'handle', split_part(new.email, '@', 1), 'member'), '[^a-z0-9._]', '', 'g'));
  if char_length(base_handle) < 3 then
    base_handle := 'member';
  end if;

  final_handle := base_handle;
  if exists (select 1 from public.profiles where handle = final_handle) then
    final_handle := base_handle || '-' || substring(new.id::text from 1 for 6);
  end if;

  insert into public.profiles (
    id,
    email,
    full_name,
    handle,
    bio,
    interests,
    coins,
    is_admin
  )
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', 'Voxora Member'),
    final_handle,
    coalesce(new.raw_user_meta_data->>'bio', ''),
    coalesce(
      array_remove(string_to_array(new.raw_user_meta_data->>'interests', ','), ''),
      '{}'
    ),
    250,
    not exists (select 1 from public.profiles)
  );

  return new;
end;
$$;

create or replace function app_private.create_host_participant()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.room_participants (room_id, user_id, role, muted)
  values (new.id, new.host_id, 'host', false)
  on conflict (room_id, user_id) do nothing;
  return new;
end;
$$;

create or replace function app_private.prepare_coin_purchase()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  selected_package public.coin_packages%rowtype;
begin
  if new.user_id <> auth.uid() and not app_private.is_admin() then
    raise exception 'coin purchase user mismatch';
  end if;

  select * into selected_package
  from public.coin_packages
  where id = new.package_id and is_active = true;

  if not found then
    raise exception 'coin package unavailable';
  end if;

  new.provider := selected_package.provider;
  new.amount_pkr := selected_package.amount_pkr;
  new.coins := selected_package.coins;
  new.status := coalesce(new.status, 'pending');
  return new;
end;
$$;

create or replace function app_private.complete_coin_purchase()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'completed' and old.status <> 'completed' then
    update public.profiles
    set coins = coins + new.coins
    where id = new.user_id;
    new.completed_at := now();
  end if;
  return new;
end;
$$;

create or replace function app_private.prepare_gift_transaction()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  selected_gift public.gifts%rowtype;
  room_host uuid;
  sender_balance int;
begin
  if new.sender_id <> auth.uid() then
    raise exception 'gift sender mismatch';
  end if;

  select * into selected_gift
  from public.gifts
  where id = new.gift_id and is_active = true;

  if not found then
    raise exception 'gift unavailable';
  end if;

  select host_id into room_host
  from public.rooms
  where id = new.room_id and is_live = true;

  if room_host is null then
    raise exception 'room unavailable';
  end if;

  if not app_private.is_room_participant(new.room_id) then
    raise exception 'join the room before sending a gift';
  end if;

  select coins into sender_balance from public.profiles where id = new.sender_id for update;
  if sender_balance < selected_gift.price then
    raise exception 'insufficient coins';
  end if;

  new.receiver_id := room_host;
  new.coins := selected_gift.price;
  update public.profiles set coins = coins - selected_gift.price where id = new.sender_id;
  update public.profiles set earnings = earnings + selected_gift.price where id = room_host;

  insert into public.room_messages (room_id, sender_id, body, kind)
  values (new.room_id, new.sender_id, 'sent ' || selected_gift.name, 'gift');

  return new;
end;
$$;

create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function app_private.touch_updated_at();

create trigger conversations_touch_updated_at
before update on public.conversations
for each row execute function app_private.touch_updated_at();

create trigger on_auth_user_created
after insert on auth.users
for each row execute function app_private.handle_new_user();

create trigger on_room_created
after insert on public.rooms
for each row execute function app_private.create_host_participant();

create trigger coin_purchase_prepare
before insert on public.coin_purchases
for each row execute function app_private.prepare_coin_purchase();

create trigger coin_purchase_complete
before update on public.coin_purchases
for each row execute function app_private.complete_coin_purchase();

create trigger gift_transaction_prepare
before insert on public.gift_transactions
for each row execute function app_private.prepare_gift_transaction();

alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.room_participants enable row level security;
alter table public.room_messages enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.gifts enable row level security;
alter table public.gift_transactions enable row level security;
alter table public.coin_packages enable row level security;
alter table public.coin_purchases enable row level security;

grant usage on schema public to anon, authenticated;
grant usage on schema app_private to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on public.gifts, public.coin_packages to anon;

create policy "Profiles are visible to signed in users"
on public.profiles for select to authenticated using (true);
create policy "Users can update their own profile"
on public.profiles for update to authenticated
using (id = auth.uid() or app_private.is_admin())
with check (id = auth.uid() or app_private.is_admin());
create policy "Users can insert their own profile"
on public.profiles for insert to authenticated
with check (id = auth.uid());

create policy "Rooms are visible to signed in users"
on public.rooms for select to authenticated using (true);
create policy "Users can create hosted rooms"
on public.rooms for insert to authenticated
with check (host_id = auth.uid());
create policy "Hosts and admins manage rooms"
on public.rooms for update to authenticated
using (host_id = auth.uid() or app_private.is_admin())
with check (host_id = auth.uid() or app_private.is_admin());

create policy "Participants are visible to signed in users"
on public.room_participants for select to authenticated using (true);
create policy "Users join rooms as themselves"
on public.room_participants for insert to authenticated
with check (user_id = auth.uid());
create policy "Users, hosts, and admins update participants"
on public.room_participants for update to authenticated
using (
  user_id = auth.uid()
  or app_private.is_admin()
  or exists (select 1 from public.rooms where id = room_id and host_id = auth.uid())
)
with check (
  user_id = auth.uid()
  or app_private.is_admin()
  or exists (select 1 from public.rooms where id = room_id and host_id = auth.uid())
);
create policy "Users, hosts, and admins remove participants"
on public.room_participants for delete to authenticated
using (
  user_id = auth.uid()
  or app_private.is_admin()
  or exists (select 1 from public.rooms where id = room_id and host_id = auth.uid())
);

create policy "Room messages are visible to signed in users"
on public.room_messages for select to authenticated using (true);
create policy "Participants can send room messages"
on public.room_messages for insert to authenticated
with check (sender_id = auth.uid() and app_private.is_room_participant(room_id));

create policy "Conversation visible to members"
on public.conversations for select to authenticated
using (app_private.is_conversation_member(id));
create policy "Users create conversations"
on public.conversations for insert to authenticated
with check (created_by = auth.uid());
create policy "Members update conversations"
on public.conversations for update to authenticated
using (app_private.is_conversation_member(id))
with check (app_private.is_conversation_member(id));

create policy "Members can view conversation members"
on public.conversation_members for select to authenticated
using (app_private.is_conversation_member(conversation_id));
create policy "Conversation creators add members"
on public.conversation_members for insert to authenticated
with check (
  user_id = auth.uid()
  or exists (select 1 from public.conversations where id = conversation_id and created_by = auth.uid())
);

create policy "Messages visible to conversation members"
on public.messages for select to authenticated
using (app_private.is_conversation_member(conversation_id));
create policy "Members can send messages"
on public.messages for insert to authenticated
with check (sender_id = auth.uid() and app_private.is_conversation_member(conversation_id));

create policy "Active gifts visible"
on public.gifts for select to authenticated using (is_active = true or app_private.is_admin());
create policy "Admins manage gifts"
on public.gifts for all to authenticated
using (app_private.is_admin())
with check (app_private.is_admin());

create policy "Users send their own gifts"
on public.gift_transactions for insert to authenticated
with check (sender_id = auth.uid());
create policy "Gift history for sender or receiver"
on public.gift_transactions for select to authenticated
using (sender_id = auth.uid() or receiver_id = auth.uid() or app_private.is_admin());

create policy "Active coin packages visible"
on public.coin_packages for select to authenticated using (is_active = true or app_private.is_admin());
create policy "Admins manage coin packages"
on public.coin_packages for all to authenticated
using (app_private.is_admin())
with check (app_private.is_admin());

create policy "Users create own coin purchases"
on public.coin_purchases for insert to authenticated
with check (user_id = auth.uid());
create policy "Users view own purchases"
on public.coin_purchases for select to authenticated
using (user_id = auth.uid() or app_private.is_admin());
create policy "Admins update purchases"
on public.coin_purchases for update to authenticated
using (app_private.is_admin())
with check (app_private.is_admin());

insert into public.gifts (name, label, price, accent) values
  ('Spark', 'SP', 25, '#0f766e'),
  ('Starwave', 'SW', 80, '#b45309'),
  ('Rose Beat', 'RB', 140, '#be123c'),
  ('Crown Cast', 'CC', 300, '#4338ca')
on conflict do nothing;

insert into public.coin_packages (name, coins, amount_pkr, provider) values
  ('Starter', 500, 250, 'jazzcash'),
  ('Social', 1500, 650, 'easypaisa'),
  ('Host Pack', 4000, 1500, 'jazzcash')
on conflict do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/png', 'image/jpeg', 'image/webp']),
  ('covers', 'covers', true, 8388608, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "Authenticated users read profile media"
on storage.objects for select to authenticated
using (bucket_id in ('avatars', 'covers'));
create policy "Users upload own avatar files"
on storage.objects for insert to authenticated
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users update own avatar files"
on storage.objects for update to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users upload own cover files"
on storage.objects for insert to authenticated
with check (bucket_id = 'covers' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Users update own cover files"
on storage.objects for update to authenticated
using (bucket_id = 'covers' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'covers' and (storage.foldername(name))[1] = auth.uid()::text);

alter table public.profiles replica identity full;
alter table public.rooms replica identity full;
alter table public.room_participants replica identity full;
alter table public.room_messages replica identity full;
alter table public.conversations replica identity full;
alter table public.conversation_members replica identity full;
alter table public.messages replica identity full;
alter table public.coin_purchases replica identity full;
alter table public.gift_transactions replica identity full;

alter publication supabase_realtime add table public.profiles;
alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.room_participants;
alter publication supabase_realtime add table public.room_messages;
alter publication supabase_realtime add table public.conversation_members;
alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.coin_purchases;
alter publication supabase_realtime add table public.gift_transactions;
