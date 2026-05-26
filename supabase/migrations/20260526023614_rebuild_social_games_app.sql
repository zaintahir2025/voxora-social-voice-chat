create extension if not exists pgcrypto;

drop trigger if exists on_auth_user_created on auth.users;

drop function if exists public.admin_list_profiles();
drop function if exists public.admin_list_profiles(int, text);
drop function if exists public.admin_set_user_blocked(uuid, boolean);

drop schema if exists app_private cascade;
create schema app_private;

delete from storage.objects
where bucket_id in ('avatars', 'covers', 'post-images');

drop table if exists public.call_signals cascade;
drop table if exists public.call_participants cascade;
drop table if exists public.call_sessions cascade;
drop table if exists public.game_invites cascade;
drop table if exists public.game_players cascade;
drop table if exists public.game_sessions cascade;
drop table if exists public.post_shares cascade;
drop table if exists public.post_likes cascade;
drop table if exists public.post_comments cascade;
drop table if exists public.posts cascade;
drop table if exists public.messages cascade;
drop table if exists public.conversation_members cascade;
drop table if exists public.conversations cascade;
drop table if exists public.friendships cascade;
drop table if exists public.room_meeting_notes cascade;
drop table if exists public.room_messages cascade;
drop table if exists public.room_participants cascade;
drop table if exists public.rooms cascade;
drop table if exists public.gift_transactions cascade;
drop table if exists public.gifts cascade;
drop table if exists public.coin_purchases cascade;
drop table if exists public.coin_packages cascade;
drop table if exists public.profiles cascade;

delete from auth.users;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  full_name text not null check (char_length(full_name) between 2 and 80),
  handle text not null unique check (handle ~ '^[a-z0-9._-]{3,24}$'),
  avatar_url text,
  cover_url text,
  bio text not null default '' check (char_length(bio) <= 280),
  interests text[] not null default '{}',
  status text not null default 'online' check (status in ('online', 'away', 'offline')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  addressee_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (requester_id <> addressee_id)
);

create unique index friendships_pair_idx
on public.friendships (least(requester_id, addressee_id), greatest(requester_id, addressee_id));

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  title text,
  is_group boolean not null default false,
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

create table public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  caption text not null default '' check (char_length(caption) <= 2200),
  image_url text,
  shared_post_id uuid references public.posts(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (image_url is not null or shared_post_id is not null)
);

create table public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.post_likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table public.post_shares (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

create table public.game_sessions (
  id uuid primary key default gen_random_uuid(),
  host_id uuid not null references public.profiles(id) on delete cascade,
  game_type text not null check (game_type in ('chess', 'ludo', 'cards')),
  mode text not null default 'friends' check (mode in ('friends', 'computer')),
  max_players int not null check (max_players between 2 and 4),
  invite_code text not null unique,
  status text not null default 'waiting' check (status in ('waiting', 'active', 'finished')),
  current_seat text,
  state jsonb not null default '{}'::jsonb,
  winner_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.game_players (
  game_id uuid not null references public.game_sessions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  seat text not null,
  display_color text,
  joined_at timestamptz not null default now(),
  primary key (game_id, user_id),
  unique (game_id, seat)
);

create table public.game_invites (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.game_sessions(id) on delete cascade,
  invited_by uuid not null references public.profiles(id) on delete cascade,
  invited_user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  unique (game_id, invited_user_id)
);

create table public.call_sessions (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  caller_id uuid not null references public.profiles(id) on delete cascade,
  call_type text not null check (call_type in ('audio', 'video')),
  status text not null default 'ringing' check (status in ('ringing', 'active', 'ended', 'missed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  ended_at timestamptz
);

create table public.call_participants (
  call_id uuid not null references public.call_sessions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'ringing' check (status in ('ringing', 'joined', 'left', 'declined')),
  joined_at timestamptz,
  primary key (call_id, user_id)
);

create table public.call_signals (
  id uuid primary key default gen_random_uuid(),
  call_id uuid not null references public.call_sessions(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid references public.profiles(id) on delete cascade,
  signal_type text not null check (signal_type in ('join', 'offer', 'answer', 'candidate', 'leave')),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index profiles_handle_idx on public.profiles (handle);
create index posts_recent_idx on public.posts (created_at desc, id desc);
create index comments_post_idx on public.post_comments (post_id, created_at);
create index messages_conversation_idx on public.messages (conversation_id, created_at);
create index conversations_updated_idx on public.conversations (updated_at desc);
create index game_sessions_status_idx on public.game_sessions (status, created_at desc);
create index game_sessions_invite_code_idx on public.game_sessions (invite_code);
create index call_sessions_conversation_idx on public.call_sessions (conversation_id, created_at desc);
create index call_signals_call_idx on public.call_signals (call_id, created_at);

create or replace function app_private.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
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
      and user_id = (select auth.uid())
  );
$$;

create or replace function app_private.is_game_player(target_game_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.game_players
    where game_id = target_game_id
      and user_id = (select auth.uid())
  );
$$;

create or replace function app_private.is_call_member(target_call_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.call_sessions c
    where c.id = target_call_id
      and app_private.is_conversation_member(c.conversation_id)
  );
$$;

create or replace function app_private.make_game_code()
returns text
language sql
volatile
as $$
  select upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
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
  base_handle := lower(regexp_replace(
    coalesce(new.raw_user_meta_data->>'handle', split_part(new.email, '@', 1), 'member'),
    '[^a-z0-9._-]',
    '',
    'g'
  ));

  if char_length(base_handle) < 3 then
    base_handle := 'member';
  end if;

  final_handle := left(base_handle, 24);
  if exists (select 1 from public.profiles where handle = final_handle) then
    final_handle := left(base_handle, 17) || '-' || substring(new.id::text from 1 for 6);
  end if;

  insert into public.profiles (
    id,
    email,
    full_name,
    handle,
    bio,
    interests
  )
  values (
    new.id,
    new.email,
    left(coalesce(new.raw_user_meta_data->>'full_name', 'Voxora Member'), 80),
    final_handle,
    left(coalesce(new.raw_user_meta_data->>'bio', ''), 280),
    coalesce(array_remove(string_to_array(new.raw_user_meta_data->>'interests', ','), ''), '{}')
  );

  return new;
end;
$$;

create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function app_private.touch_updated_at();

create trigger friendships_touch_updated_at
before update on public.friendships
for each row execute function app_private.touch_updated_at();

create trigger conversations_touch_updated_at
before update on public.conversations
for each row execute function app_private.touch_updated_at();

create trigger posts_touch_updated_at
before update on public.posts
for each row execute function app_private.touch_updated_at();

create trigger post_comments_touch_updated_at
before update on public.post_comments
for each row execute function app_private.touch_updated_at();

create trigger game_sessions_touch_updated_at
before update on public.game_sessions
for each row execute function app_private.touch_updated_at();

create trigger call_sessions_touch_updated_at
before update on public.call_sessions
for each row execute function app_private.touch_updated_at();

create trigger on_auth_user_created
after insert on auth.users
for each row execute function app_private.handle_new_user();

alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.posts enable row level security;
alter table public.post_comments enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_shares enable row level security;
alter table public.game_sessions enable row level security;
alter table public.game_players enable row level security;
alter table public.game_invites enable row level security;
alter table public.call_sessions enable row level security;
alter table public.call_participants enable row level security;
alter table public.call_signals enable row level security;

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on public.profiles, public.posts, public.post_comments, public.post_likes, public.post_shares to anon;

create policy "Profiles are visible"
on public.profiles for select using (true);
create policy "Users insert own profile"
on public.profiles for insert to authenticated
with check (id = (select auth.uid()));
create policy "Users update own profile"
on public.profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy "Friendships visible to participants"
on public.friendships for select to authenticated
using (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()));
create policy "Users request friends as self"
on public.friendships for insert to authenticated
with check (requester_id = (select auth.uid()));
create policy "Participants update friendship"
on public.friendships for update to authenticated
using (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()))
with check (requester_id = requester_id and (requester_id = (select auth.uid()) or addressee_id = (select auth.uid())));
create policy "Participants remove friendship"
on public.friendships for delete to authenticated
using (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()));

create policy "Conversation members view conversations"
on public.conversations for select to authenticated
using (app_private.is_conversation_member(id) or created_by = (select auth.uid()));
create policy "Users create conversations"
on public.conversations for insert to authenticated
with check (created_by = (select auth.uid()));
create policy "Members update conversations"
on public.conversations for update to authenticated
using (app_private.is_conversation_member(id) or created_by = (select auth.uid()))
with check (app_private.is_conversation_member(id) or created_by = (select auth.uid()));

create policy "Conversation members view members"
on public.conversation_members for select to authenticated
using (app_private.is_conversation_member(conversation_id) or user_id = (select auth.uid()));
create policy "Creators add members"
on public.conversation_members for insert to authenticated
with check (
  user_id = (select auth.uid())
  or exists (
    select 1 from public.conversations
    where id = conversation_id and created_by = (select auth.uid())
  )
);
create policy "Members can leave conversations"
on public.conversation_members for delete to authenticated
using (user_id = (select auth.uid()));

create policy "Messages visible to members"
on public.messages for select to authenticated
using (app_private.is_conversation_member(conversation_id));
create policy "Members send messages"
on public.messages for insert to authenticated
with check (sender_id = (select auth.uid()) and app_private.is_conversation_member(conversation_id));

create policy "Posts are visible"
on public.posts for select using (true);
create policy "Users create own posts"
on public.posts for insert to authenticated
with check (author_id = (select auth.uid()));
create policy "Users edit own posts"
on public.posts for update to authenticated
using (author_id = (select auth.uid()))
with check (author_id = (select auth.uid()));
create policy "Users delete own posts"
on public.posts for delete to authenticated
using (author_id = (select auth.uid()));

create policy "Comments are visible"
on public.post_comments for select using (true);
create policy "Users create own comments"
on public.post_comments for insert to authenticated
with check (author_id = (select auth.uid()));
create policy "Users edit own comments"
on public.post_comments for update to authenticated
using (author_id = (select auth.uid()))
with check (author_id = (select auth.uid()));
create policy "Comment authors and post owners delete comments"
on public.post_comments for delete to authenticated
using (
  author_id = (select auth.uid())
  or exists (
    select 1 from public.posts
    where id = post_id and author_id = (select auth.uid())
  )
);

create policy "Likes are visible"
on public.post_likes for select using (true);
create policy "Users like as self"
on public.post_likes for insert to authenticated
with check (user_id = (select auth.uid()));
create policy "Users remove own likes"
on public.post_likes for delete to authenticated
using (user_id = (select auth.uid()));

create policy "Shares are visible"
on public.post_shares for select using (true);
create policy "Users share as self"
on public.post_shares for insert to authenticated
with check (user_id = (select auth.uid()));
create policy "Users remove own shares"
on public.post_shares for delete to authenticated
using (user_id = (select auth.uid()));

create policy "Signed in users view games"
on public.game_sessions for select to authenticated using (true);
create policy "Users create hosted games"
on public.game_sessions for insert to authenticated
with check (host_id = (select auth.uid()));
create policy "Game players update games"
on public.game_sessions for update to authenticated
using (host_id = (select auth.uid()) or app_private.is_game_player(id))
with check (host_id = (select auth.uid()) or app_private.is_game_player(id));
create policy "Hosts delete games"
on public.game_sessions for delete to authenticated
using (host_id = (select auth.uid()));

create policy "Signed in users view game players"
on public.game_players for select to authenticated using (true);
create policy "Users join games as self"
on public.game_players for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (select 1 from public.game_sessions where id = game_id and status in ('waiting', 'active'))
);
create policy "Players leave own game"
on public.game_players for delete to authenticated
using (
  user_id = (select auth.uid())
  or exists (select 1 from public.game_sessions where id = game_id and host_id = (select auth.uid()))
);

create policy "Game invites visible to sender or receiver"
on public.game_invites for select to authenticated
using (invited_by = (select auth.uid()) or invited_user_id = (select auth.uid()));
create policy "Hosts invite friends"
on public.game_invites for insert to authenticated
with check (invited_by = (select auth.uid()));
create policy "Receivers update own invite"
on public.game_invites for update to authenticated
using (invited_user_id = (select auth.uid()))
with check (invited_user_id = (select auth.uid()));
create policy "Inviters remove invites"
on public.game_invites for delete to authenticated
using (invited_by = (select auth.uid()) or invited_user_id = (select auth.uid()));

create policy "Call sessions visible to conversation members"
on public.call_sessions for select to authenticated
using (app_private.is_conversation_member(conversation_id));
create policy "Members start calls"
on public.call_sessions for insert to authenticated
with check (caller_id = (select auth.uid()) and app_private.is_conversation_member(conversation_id));
create policy "Members update calls"
on public.call_sessions for update to authenticated
using (app_private.is_conversation_member(conversation_id))
with check (app_private.is_conversation_member(conversation_id));

create policy "Call participants visible to call members"
on public.call_participants for select to authenticated
using (app_private.is_call_member(call_id));
create policy "Users add own call participation"
on public.call_participants for insert to authenticated
with check (
  app_private.is_call_member(call_id)
  and (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.call_sessions
      where id = call_id and caller_id = (select auth.uid())
    )
  )
);
create policy "Users update own call participation"
on public.call_participants for update to authenticated
using (user_id = (select auth.uid()) and app_private.is_call_member(call_id))
with check (user_id = (select auth.uid()) and app_private.is_call_member(call_id));

create policy "Call signals visible to sender recipient or call members"
on public.call_signals for select to authenticated
using (
  sender_id = (select auth.uid())
  or recipient_id = (select auth.uid())
  or (recipient_id is null and app_private.is_call_member(call_id))
);
create policy "Users send own call signals"
on public.call_signals for insert to authenticated
with check (sender_id = (select auth.uid()) and app_private.is_call_member(call_id));
create policy "Users clean own call signals"
on public.call_signals for delete to authenticated
using (sender_id = (select auth.uid()) or recipient_id = (select auth.uid()));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 5242880, array['image/png', 'image/jpeg', 'image/webp']),
  ('covers', 'covers', true, 8388608, array['image/png', 'image/jpeg', 'image/webp']),
  ('post-images', 'post-images', true, 15728640, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Authenticated users read profile media" on storage.objects;
drop policy if exists "Users upload own avatar files" on storage.objects;
drop policy if exists "Users update own avatar files" on storage.objects;
drop policy if exists "Users upload own cover files" on storage.objects;
drop policy if exists "Users update own cover files" on storage.objects;
drop policy if exists "Active users read profile media" on storage.objects;
drop policy if exists "Active users upload own avatar files" on storage.objects;
drop policy if exists "Active users update own avatar files" on storage.objects;
drop policy if exists "Active users upload own cover files" on storage.objects;
drop policy if exists "Active users update own cover files" on storage.objects;

create policy "Public media is readable"
on storage.objects for select to anon, authenticated
using (bucket_id in ('avatars', 'covers', 'post-images'));

create policy "Users upload own public media"
on storage.objects for insert to authenticated
with check (
  bucket_id in ('avatars', 'covers', 'post-images')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Users update own public media"
on storage.objects for update to authenticated
using (
  bucket_id in ('avatars', 'covers', 'post-images')
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id in ('avatars', 'covers', 'post-images')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Users delete own public media"
on storage.objects for delete to authenticated
using (
  bucket_id in ('avatars', 'covers', 'post-images')
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

alter table public.profiles replica identity full;
alter table public.friendships replica identity full;
alter table public.conversations replica identity full;
alter table public.conversation_members replica identity full;
alter table public.messages replica identity full;
alter table public.posts replica identity full;
alter table public.post_comments replica identity full;
alter table public.post_likes replica identity full;
alter table public.post_shares replica identity full;
alter table public.game_sessions replica identity full;
alter table public.game_players replica identity full;
alter table public.game_invites replica identity full;
alter table public.call_sessions replica identity full;
alter table public.call_participants replica identity full;
alter table public.call_signals replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.profiles;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.friendships;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.conversations;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.conversation_members;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.messages;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.posts;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.post_comments;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.post_likes;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.post_shares;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.game_sessions;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.game_players;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.game_invites;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.call_sessions;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.call_participants;
exception when duplicate_object or undefined_object then null;
end $$;
do $$
begin
  alter publication supabase_realtime add table public.call_signals;
exception when duplicate_object or undefined_object then null;
end $$;
