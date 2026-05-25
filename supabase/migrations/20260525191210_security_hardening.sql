create extension if not exists pgcrypto;

create table if not exists app_private.user_roles (
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('admin')),
  granted_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (user_id, role)
);

insert into app_private.user_roles (user_id, role)
select id, 'admin'
from public.profiles
where is_admin = true
on conflict do nothing;

create table if not exists app_private.rate_limits (
  user_id uuid not null references public.profiles(id) on delete cascade,
  action text not null,
  window_start timestamptz not null,
  request_count int not null default 1 check (request_count > 0),
  primary key (user_id, action, window_start)
);

create index if not exists rate_limits_window_idx
on app_private.rate_limits (window_start);

revoke all on app_private.user_roles from anon, authenticated;
revoke all on app_private.rate_limits from anon, authenticated;

create or replace function app_private.is_admin()
returns boolean
language sql
stable
security definer
set search_path = app_private, public
as $$
  select exists (
    select 1
    from app_private.user_roles
    where user_id = (select auth.uid())
      and role = 'admin'
  );
$$;

create or replace function app_private.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select (select auth.uid()) is not null
    and coalesce(((select auth.jwt())->>'is_anonymous')::boolean, false) = false
    and exists (
      select 1
      from public.profiles
      where id = (select auth.uid())
        and is_blocked = false
    );
$$;

create or replace function app_private.is_conversation_member(target_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select target_conversation_id is not null
    and exists (
      select 1
      from public.conversation_members
      where conversation_id = target_conversation_id
        and user_id = (select auth.uid())
    );
$$;

create or replace function app_private.is_room_participant(target_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select target_room_id is not null
    and exists (
      select 1
      from public.room_participants
      where room_id = target_room_id
        and user_id = (select auth.uid())
    );
$$;

create or replace function app_private.is_room_host(target_room_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select target_room_id is not null
    and exists (
      select 1
      from public.rooms
      where id = target_room_id
        and host_id = (select auth.uid())
    );
$$;

create or replace function app_private.game_players_contain(players jsonb, user_id uuid)
returns boolean
language plpgsql
stable
as $$
declare
  uid text := user_id::text;
begin
  if players is null or user_id is null then
    return false;
  end if;

  if players->>'white' = uid or players->>'black' = uid then
    return true;
  end if;

  if exists (
    select 1
    from jsonb_each_text(players)
    where value = uid
  ) then
    return true;
  end if;

  if jsonb_typeof(players->'order') = 'array' then
    return exists (
      select 1
      from jsonb_array_elements_text(players->'order') as value
      where value = uid
    );
  end if;

  return false;
end;
$$;

create or replace function app_private.is_game_player(target_game_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, app_private
as $$
  select target_game_id is not null
    and exists (
      select 1
      from public.game_sessions
      where id = target_game_id
        and app_private.game_players_contain(players, (select auth.uid()))
    );
$$;

create or replace function app_private.voice_room_id_from_topic(target_topic text)
returns uuid
language plpgsql
stable
as $$
declare
  raw_id text;
begin
  raw_id := substring(target_topic from '^voice-room-([0-9a-fA-F-]{36})$');
  if raw_id is null then
    return null;
  end if;

  return raw_id::uuid;
exception
  when others then
    return null;
end;
$$;

create or replace function app_private.check_rate_limit(
  action_name text,
  max_count int,
  window_seconds int
)
returns boolean
language plpgsql
volatile
security definer
set search_path = app_private, public
as $$
declare
  current_user_id uuid := (select auth.uid());
  current_window timestamptz;
  current_count int;
begin
  if current_user_id is null then
    return true;
  end if;

  current_window := to_timestamp(
    floor(extract(epoch from clock_timestamp()) / window_seconds) * window_seconds
  );

  insert into app_private.rate_limits (user_id, action, window_start, request_count)
  values (current_user_id, action_name, current_window, 1)
  on conflict (user_id, action, window_start)
  do update
    set request_count = app_private.rate_limits.request_count + 1
  returning request_count into current_count;

  if random() < 0.01 then
    delete from app_private.rate_limits
    where window_start < clock_timestamp() - interval '2 days';
  end if;

  return current_count <= max_count;
end;
$$;

create or replace function app_private.require_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = app_private, public
as $$
declare
  action_name text := tg_argv[0];
  max_count int := tg_argv[1]::int;
  window_seconds int := tg_argv[2]::int;
begin
  if not app_private.check_rate_limit(action_name, max_count, window_seconds) then
    raise exception 'rate limit exceeded for %', action_name
      using errcode = 'P0001';
  end if;

  return new;
end;
$$;

create or replace function app_private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
declare
  base_handle text;
  final_handle text;
  suffix int := 0;
  make_admin boolean;
begin
  perform pg_advisory_xact_lock(hashtext('voxora:first-admin'));

  base_handle := lower(
    regexp_replace(
      coalesce(new.raw_user_meta_data->>'handle', split_part(new.email, '@', 1), 'member'),
      '[^a-z0-9._-]',
      '',
      'g'
    )
  );

  if char_length(base_handle) < 3 then
    base_handle := 'member';
  end if;

  base_handle := substring(base_handle from 1 for 30);
  final_handle := base_handle;

  while exists (select 1 from public.profiles where handle = final_handle) loop
    suffix := suffix + 1;
    final_handle := substring(base_handle from 1 for 22) || '-' || substring(new.id::text from 1 for 6);
    if suffix > 1 then
      final_handle := substring(final_handle from 1 for 27) || '-' || suffix::text;
    end if;
  end loop;

  make_admin := not exists (
    select 1
    from app_private.user_roles
    where role = 'admin'
  );

  insert into public.profiles (
    id,
    email,
    full_name,
    handle,
    bio,
    interests,
    is_admin
  )
  values (
    new.id,
    new.email,
    left(coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 'Voxora Member'), 80),
    final_handle,
    left(coalesce(new.raw_user_meta_data->>'bio', ''), 500),
    coalesce(
      (select array_agg(left(trim(value), 40))
       from unnest(array_remove(string_to_array(new.raw_user_meta_data->>'interests', ','), '')) with ordinality as t(value, ord)
       where trim(value) <> ''
         and ord <= 8),
      '{}'
    ),
    make_admin
  );

  if make_admin then
    insert into app_private.user_roles (user_id, role)
    values (new.id, 'admin')
    on conflict do nothing;
  end if;

  return new;
end;
$$;

create or replace function app_private.guard_profile_update()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
declare
  current_user_id uuid := (select auth.uid());
begin
  if current_user_id is null then
    return new;
  end if;

  if new.id is distinct from old.id
    or new.email is distinct from old.email
    or new.created_at is distinct from old.created_at then
    raise exception 'immutable profile field update rejected';
  end if;

  if new.is_admin is distinct from old.is_admin then
    raise exception 'admin role cannot be changed through profiles';
  end if;

  if app_private.is_admin() then
    return new;
  end if;

  if old.id <> current_user_id or new.id <> current_user_id then
    raise exception 'profile ownership mismatch';
  end if;

  if new.level is distinct from old.level
    or new.is_blocked is distinct from old.is_blocked then
    raise exception 'profile security field update rejected';
  end if;

  new.full_name := left(trim(new.full_name), 80);
  new.handle := lower(regexp_replace(trim(new.handle), '[^a-z0-9._-]', '', 'g'));
  new.bio := left(coalesce(new.bio, ''), 500);
  new.interests := coalesce(new.interests, '{}');

  if char_length(new.full_name) < 2 then
    raise exception 'display name is too short';
  end if;

  if new.handle !~ '^[a-z0-9._-]{3,30}$' then
    raise exception 'invalid handle';
  end if;

  if array_length(new.interests, 1) > 8 then
    raise exception 'too many interests';
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_guard_profile_update on public.profiles;
create trigger profiles_guard_profile_update
before update on public.profiles
for each row execute function app_private.guard_profile_update();

create or replace function app_private.guard_room_write()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
declare
  current_user_id uuid := (select auth.uid());
begin
  if current_user_id is null then
    return new;
  end if;

  if not app_private.is_active_user() and not app_private.is_admin() then
    raise exception 'active account required';
  end if;

  if tg_op = 'INSERT' then
    if new.host_id <> current_user_id then
      raise exception 'room host mismatch';
    end if;

    if not app_private.check_rate_limit('room_create', 10, 3600) then
      raise exception 'room creation rate limit exceeded';
    end if;
  else
    if new.id is distinct from old.id
      or new.host_id is distinct from old.host_id
      or new.created_at is distinct from old.created_at then
      raise exception 'immutable room field update rejected';
    end if;
  end if;

  new.title := left(trim(new.title), 80);
  new.topic := left(trim(coalesce(new.topic, 'General')), 40);
  new.description := left(coalesce(new.description, ''), 500);
  new.capacity := greatest(2, least(coalesce(new.capacity, 200), 500));

  if char_length(new.title) < 3 then
    raise exception 'room title is too short';
  end if;

  return new;
end;
$$;

drop trigger if exists rooms_guard_room_write on public.rooms;
create trigger rooms_guard_room_write
before insert or update on public.rooms
for each row execute function app_private.guard_room_write();

create or replace function app_private.guard_room_participant_write()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
declare
  current_user_id uuid := (select auth.uid());
  target_room public.rooms%rowtype;
  participant_count int;
  current_user_is_room_host boolean;
begin
  if current_user_id is null then
    return new;
  end if;

  if not app_private.is_active_user() and not app_private.is_admin() then
    raise exception 'active account required';
  end if;

  select *
  into target_room
  from public.rooms
  where id = new.room_id
  for update;

  if not found then
    raise exception 'room unavailable';
  end if;

  current_user_is_room_host := target_room.host_id = current_user_id;

  if tg_op = 'INSERT' then
    if new.user_id <> current_user_id and not app_private.is_admin() then
      raise exception 'room participant user mismatch';
    end if;

    if not target_room.is_live or target_room.is_locked then
      raise exception 'room is not accepting participants';
    end if;

    select count(*)
    into participant_count
    from public.room_participants
    where room_id = new.room_id;

    if participant_count >= target_room.capacity then
      raise exception 'room is full';
    end if;

    if new.user_id = target_room.host_id then
      new.role := 'host';
      new.muted := false;
    else
      new.role := 'listener';
      new.muted := true;
    end if;

    new.speaking := false;
    new.joined_at := coalesce(new.joined_at, now());
    new.last_seen_at := now();
    return new;
  end if;

  if new.room_id is distinct from old.room_id
    or new.user_id is distinct from old.user_id
    or new.joined_at is distinct from old.joined_at then
    raise exception 'immutable room participant field update rejected';
  end if;

  if app_private.is_admin() or current_user_is_room_host then
    new.last_seen_at := least(coalesce(new.last_seen_at, now()), now() + interval '5 minutes');
    return new;
  end if;

  if old.user_id <> current_user_id then
    raise exception 'room participant ownership mismatch';
  end if;

  new.role := old.role;
  new.last_seen_at := least(coalesce(new.last_seen_at, now()), now() + interval '5 minutes');
  return new;
end;
$$;

drop trigger if exists room_participants_guard_write on public.room_participants;
create trigger room_participants_guard_write
before insert or update on public.room_participants
for each row execute function app_private.guard_room_participant_write();

create or replace function app_private.guard_room_message_insert()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
declare
  current_user_id uuid := (select auth.uid());
begin
  if current_user_id is null then
    return new;
  end if;

  if not app_private.is_active_user() then
    raise exception 'active account required';
  end if;

  if new.sender_id <> current_user_id then
    raise exception 'room message sender mismatch';
  end if;

  if not app_private.is_room_participant(new.room_id) then
    raise exception 'join the room before sending messages';
  end if;

  if new.kind <> 'chat' and not app_private.is_admin() then
    raise exception 'system room messages require admin';
  end if;

  if not app_private.check_rate_limit('room_message', 30, 60) then
    raise exception 'room message rate limit exceeded';
  end if;

  new.body := left(trim(new.body), 1000);
  if char_length(new.body) < 1 then
    raise exception 'empty room message rejected';
  end if;

  return new;
end;
$$;

drop trigger if exists room_messages_guard_insert on public.room_messages;
create trigger room_messages_guard_insert
before insert on public.room_messages
for each row execute function app_private.guard_room_message_insert();

create or replace function app_private.guard_conversation_insert()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
begin
  if (select auth.uid()) is null then
    return new;
  end if;

  if not app_private.is_active_user() then
    raise exception 'active account required';
  end if;

  if new.created_by <> (select auth.uid()) then
    raise exception 'conversation creator mismatch';
  end if;

  if not app_private.check_rate_limit('conversation_create', 20, 3600) then
    raise exception 'conversation creation rate limit exceeded';
  end if;

  return new;
end;
$$;

drop trigger if exists conversations_guard_insert on public.conversations;
create trigger conversations_guard_insert
before insert on public.conversations
for each row execute function app_private.guard_conversation_insert();

create or replace function app_private.guard_conversation_member_insert()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
begin
  if (select auth.uid()) is null then
    return new;
  end if;

  if not app_private.is_active_user() then
    raise exception 'active account required';
  end if;

  if not exists (
    select 1
    from public.conversations
    where id = new.conversation_id
      and created_by = (select auth.uid())
  ) then
    raise exception 'only the conversation creator can add members';
  end if;

  if not app_private.check_rate_limit('conversation_member_add', 50, 3600) then
    raise exception 'conversation member rate limit exceeded';
  end if;

  return new;
end;
$$;

drop trigger if exists conversation_members_guard_insert on public.conversation_members;
create trigger conversation_members_guard_insert
before insert on public.conversation_members
for each row execute function app_private.guard_conversation_member_insert();

create or replace function app_private.guard_direct_message_insert()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
begin
  if (select auth.uid()) is null then
    return new;
  end if;

  if not app_private.is_active_user() then
    raise exception 'active account required';
  end if;

  if new.sender_id <> (select auth.uid()) then
    raise exception 'direct message sender mismatch';
  end if;

  if not app_private.is_conversation_member(new.conversation_id) then
    raise exception 'conversation membership required';
  end if;

  if not app_private.check_rate_limit('direct_message', 60, 60) then
    raise exception 'direct message rate limit exceeded';
  end if;

  new.body := left(trim(new.body), 2000);
  if char_length(new.body) < 1 then
    raise exception 'empty direct message rejected';
  end if;

  return new;
end;
$$;

drop trigger if exists messages_guard_insert on public.messages;
create trigger messages_guard_insert
before insert on public.messages
for each row execute function app_private.guard_direct_message_insert();

create or replace function app_private.guard_meeting_note_write()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
begin
  if (select auth.uid()) is null then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if not app_private.is_active_user() then
      raise exception 'active account required';
    end if;

    if new.author_id <> (select auth.uid()) then
      raise exception 'meeting note author mismatch';
    end if;

    if not app_private.is_room_participant(new.room_id) then
      raise exception 'room participation required';
    end if;

    if not app_private.check_rate_limit('meeting_note', 20, 60) then
      raise exception 'meeting note rate limit exceeded';
    end if;
  else
    if new.id is distinct from old.id
      or new.room_id is distinct from old.room_id
      or new.author_id is distinct from old.author_id
      or new.note_type is distinct from old.note_type
      or new.created_at is distinct from old.created_at then
      raise exception 'immutable meeting note field update rejected';
    end if;
  end if;

  new.body := left(trim(new.body), 1200);
  if char_length(new.body) < 1 then
    raise exception 'empty meeting note rejected';
  end if;

  return new;
end;
$$;

drop trigger if exists room_meeting_notes_guard_write on public.room_meeting_notes;
create trigger room_meeting_notes_guard_write
before insert or update on public.room_meeting_notes
for each row execute function app_private.guard_meeting_note_write();

create or replace function app_private.guard_game_session_write()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
begin
  if (select auth.uid()) is null then
    return new;
  end if;

  if not app_private.is_active_user() then
    raise exception 'active account required';
  end if;

  if tg_op = 'INSERT' then
    if new.host_id <> (select auth.uid()) then
      raise exception 'game host mismatch';
    end if;

    if not app_private.is_room_participant(new.room_id) then
      raise exception 'room participation required';
    end if;

    if not app_private.check_rate_limit('game_create', 20, 3600) then
      raise exception 'game creation rate limit exceeded';
    end if;

    return new;
  end if;

  if new.id is distinct from old.id
    or new.room_id is distinct from old.room_id
    or new.host_id is distinct from old.host_id
    or new.game_type is distinct from old.game_type
    or new.created_at is distinct from old.created_at then
    raise exception 'immutable game field update rejected';
  end if;

  if not (
    app_private.is_admin()
    or app_private.is_room_host(old.room_id)
    or app_private.game_players_contain(old.players, (select auth.uid()))
    or (
      new.players is distinct from old.players
      and app_private.is_room_participant(old.room_id)
      and app_private.game_players_contain(new.players, (select auth.uid()))
    )
  ) then
    raise exception 'game player authorization required';
  end if;

  if not app_private.check_rate_limit('game_update', 120, 60) then
    raise exception 'game update rate limit exceeded';
  end if;

  return new;
end;
$$;

drop trigger if exists game_sessions_guard_write on public.game_sessions;
create trigger game_sessions_guard_write
before insert or update on public.game_sessions
for each row execute function app_private.guard_game_session_write();

create or replace function app_private.guard_friendship_write()
returns trigger
language plpgsql
security definer
set search_path = public, app_private
as $$
begin
  if (select auth.uid()) is null then
    return new;
  end if;

  if not app_private.is_active_user() then
    raise exception 'active account required';
  end if;

  if tg_op = 'INSERT' then
    if new.requester_id <> (select auth.uid()) then
      raise exception 'friend request requester mismatch';
    end if;

    if new.requester_id = new.addressee_id then
      raise exception 'cannot friend yourself';
    end if;

    new.status := 'pending';

    if not app_private.check_rate_limit('friend_request', 30, 3600) then
      raise exception 'friend request rate limit exceeded';
    end if;

    return new;
  end if;

  if new.id is distinct from old.id
    or new.requester_id is distinct from old.requester_id
    or new.addressee_id is distinct from old.addressee_id
    or new.created_at is distinct from old.created_at then
    raise exception 'immutable friendship field update rejected';
  end if;

  if app_private.is_admin() then
    return new;
  end if;

  if old.status = 'pending'
    and new.status = 'accepted'
    and old.addressee_id = (select auth.uid()) then
    return new;
  end if;

  raise exception 'friendship update rejected';
end;
$$;

drop trigger if exists friendships_guard_write on public.friendships;
create trigger friendships_guard_write
before insert or update on public.friendships
for each row execute function app_private.guard_friendship_write();

create unique index if not exists friendships_canonical_pair_uidx
on public.friendships (
  (least(requester_id, addressee_id)),
  (greatest(requester_id, addressee_id))
);

create or replace function public.admin_list_profiles()
returns table (
  id uuid,
  email text,
  full_name text,
  handle text,
  avatar_url text,
  cover_url text,
  bio text,
  interests text[],
  level int,
  is_admin boolean,
  is_blocked boolean,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, app_private
as $$
begin
  if not app_private.is_admin() then
    raise exception 'admin access required';
  end if;

  return query
  select
    p.id,
    p.email,
    p.full_name,
    p.handle,
    p.avatar_url,
    p.cover_url,
    p.bio,
    p.interests,
    p.level,
    p.is_admin,
    p.is_blocked,
    p.created_at
  from public.profiles p
  order by p.created_at desc;
end;
$$;

create or replace function public.admin_set_user_blocked(target_user_id uuid, blocked boolean)
returns void
language plpgsql
volatile
security definer
set search_path = public, app_private
as $$
begin
  if not app_private.is_admin() then
    raise exception 'admin access required';
  end if;

  if target_user_id = (select auth.uid()) and blocked then
    raise exception 'admins cannot block themselves';
  end if;

  update public.profiles
  set is_blocked = blocked
  where id = target_user_id;
end;
$$;

revoke all on function public.admin_list_profiles() from public, anon;
revoke all on function public.admin_set_user_blocked(uuid, boolean) from public, anon;
grant execute on function public.admin_list_profiles() to authenticated;
grant execute on function public.admin_set_user_blocked(uuid, boolean) to authenticated;

revoke all on all tables in schema public from authenticated;

grant select (
  id,
  full_name,
  handle,
  avatar_url,
  cover_url,
  bio,
  interests,
  level,
  is_admin,
  created_at,
  updated_at
) on public.profiles to authenticated;
grant insert (
  id,
  email,
  full_name,
  handle,
  avatar_url,
  cover_url,
  bio,
  interests
) on public.profiles to authenticated;
grant update (
  full_name,
  handle,
  avatar_url,
  cover_url,
  bio,
  interests
) on public.profiles to authenticated;

grant select, insert, update on public.rooms to authenticated;
grant select, insert, update, delete on public.room_participants to authenticated;
grant select, insert on public.room_messages to authenticated;
grant select, insert, update on public.conversations to authenticated;
grant select, insert on public.conversation_members to authenticated;
grant select, insert on public.messages to authenticated;
grant select, insert, update, delete on public.room_meeting_notes to authenticated;
grant select, insert, update, delete on public.game_sessions to authenticated;
grant select, insert, update, delete on public.friendships to authenticated;

drop policy if exists "Profiles are visible to signed in users" on public.profiles;
drop policy if exists "Users can update their own profile" on public.profiles;
drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Active users can view safe profiles"
on public.profiles for select to authenticated
using (app_private.is_active_user());
create policy "Users can insert their own profile"
on public.profiles for insert to authenticated
with check (
  id = (select auth.uid())
  and (select auth.uid()) is not null
  and coalesce(((select auth.jwt())->>'is_anonymous')::boolean, false) = false
);
create policy "Users can update editable profile fields"
on public.profiles for update to authenticated
using (id = (select auth.uid()) and app_private.is_active_user())
with check (id = (select auth.uid()) and app_private.is_active_user());

drop policy if exists "Rooms are visible to signed in users" on public.rooms;
drop policy if exists "Users can create hosted rooms" on public.rooms;
drop policy if exists "Hosts and admins manage rooms" on public.rooms;
create policy "Active users view rooms"
on public.rooms for select to authenticated
using (app_private.is_active_user() or app_private.is_admin());
create policy "Active users create hosted rooms"
on public.rooms for insert to authenticated
with check (host_id = (select auth.uid()) and app_private.is_active_user());
create policy "Hosts and admins manage rooms"
on public.rooms for update to authenticated
using (
  (host_id = (select auth.uid()) and app_private.is_active_user())
  or app_private.is_admin()
)
with check (
  (host_id = (select auth.uid()) and app_private.is_active_user())
  or app_private.is_admin()
);

drop policy if exists "Participants are visible to signed in users" on public.room_participants;
drop policy if exists "Users join rooms as themselves" on public.room_participants;
drop policy if exists "Users, hosts, and admins update participants" on public.room_participants;
drop policy if exists "Users, hosts, and admins remove participants" on public.room_participants;
create policy "Active users view live room participants"
on public.room_participants for select to authenticated
using (app_private.is_active_user() or app_private.is_admin());
create policy "Active users join rooms as themselves"
on public.room_participants for insert to authenticated
with check (user_id = (select auth.uid()) and app_private.is_active_user());
create policy "Participants hosts and admins update room participants"
on public.room_participants for update to authenticated
using (
  (user_id = (select auth.uid()) and app_private.is_active_user())
  or app_private.is_room_host(room_id)
  or app_private.is_admin()
)
with check (
  (user_id = (select auth.uid()) and app_private.is_active_user())
  or app_private.is_room_host(room_id)
  or app_private.is_admin()
);
create policy "Participants hosts and admins remove room participants"
on public.room_participants for delete to authenticated
using (
  (user_id = (select auth.uid()) and app_private.is_active_user())
  or app_private.is_room_host(room_id)
  or app_private.is_admin()
);

drop policy if exists "Room messages are visible to signed in users" on public.room_messages;
drop policy if exists "Participants can send room messages" on public.room_messages;
create policy "Participants view room messages"
on public.room_messages for select to authenticated
using (
  app_private.is_active_user()
  and app_private.is_room_participant(room_id)
);
create policy "Participants send room messages"
on public.room_messages for insert to authenticated
with check (
  sender_id = (select auth.uid())
  and app_private.is_active_user()
  and app_private.is_room_participant(room_id)
);

drop policy if exists "Conversation visible to members" on public.conversations;
drop policy if exists "Conversation visible to members and creator" on public.conversations;
drop policy if exists "Users create conversations" on public.conversations;
drop policy if exists "Members update conversations" on public.conversations;
drop policy if exists "Members and creator update conversations" on public.conversations;
create policy "Conversation visible to members and creator"
on public.conversations for select to authenticated
using (
  app_private.is_active_user()
  and (created_by = (select auth.uid()) or app_private.is_conversation_member(id))
);
create policy "Active users create conversations"
on public.conversations for insert to authenticated
with check (created_by = (select auth.uid()) and app_private.is_active_user());
create policy "Members and creator update conversations"
on public.conversations for update to authenticated
using (
  app_private.is_active_user()
  and (created_by = (select auth.uid()) or app_private.is_conversation_member(id))
)
with check (
  app_private.is_active_user()
  and (created_by = (select auth.uid()) or app_private.is_conversation_member(id))
);

drop policy if exists "Members can view conversation members" on public.conversation_members;
drop policy if exists "Conversation creators add members" on public.conversation_members;
create policy "Members can view conversation members"
on public.conversation_members for select to authenticated
using (
  app_private.is_active_user()
  and (
    app_private.is_conversation_member(conversation_id)
    or exists (
      select 1
      from public.conversations
      where id = conversation_id
        and created_by = (select auth.uid())
    )
  )
);
create policy "Only conversation creators add members"
on public.conversation_members for insert to authenticated
with check (
  app_private.is_active_user()
  and exists (
    select 1
    from public.conversations
    where id = conversation_id
      and created_by = (select auth.uid())
  )
);

drop policy if exists "Messages visible to conversation members" on public.messages;
drop policy if exists "Members can send messages" on public.messages;
create policy "Messages visible to conversation members"
on public.messages for select to authenticated
using (
  app_private.is_active_user()
  and app_private.is_conversation_member(conversation_id)
);
create policy "Members can send messages"
on public.messages for insert to authenticated
with check (
  sender_id = (select auth.uid())
  and app_private.is_active_user()
  and app_private.is_conversation_member(conversation_id)
);

drop policy if exists "Participants view meeting notes" on public.room_meeting_notes;
drop policy if exists "Participants add meeting notes" on public.room_meeting_notes;
drop policy if exists "Authors hosts and admins update meeting notes" on public.room_meeting_notes;
drop policy if exists "Authors hosts and admins delete meeting notes" on public.room_meeting_notes;
create policy "Participants view meeting notes"
on public.room_meeting_notes for select to authenticated
using (
  app_private.is_active_user()
  and (app_private.is_room_participant(room_id) or app_private.is_admin())
);
create policy "Participants add meeting notes"
on public.room_meeting_notes for insert to authenticated
with check (
  author_id = (select auth.uid())
  and app_private.is_active_user()
  and app_private.is_room_participant(room_id)
);
create policy "Authors hosts and admins update meeting notes"
on public.room_meeting_notes for update to authenticated
using (
  (author_id = (select auth.uid()) and app_private.is_active_user())
  or app_private.is_room_host(room_id)
  or app_private.is_admin()
)
with check (
  (author_id = (select auth.uid()) and app_private.is_active_user())
  or app_private.is_room_host(room_id)
  or app_private.is_admin()
);
create policy "Authors hosts and admins delete meeting notes"
on public.room_meeting_notes for delete to authenticated
using (
  (author_id = (select auth.uid()) and app_private.is_active_user())
  or app_private.is_room_host(room_id)
  or app_private.is_admin()
);

drop policy if exists "Participants view game sessions" on public.game_sessions;
drop policy if exists "Participants create game sessions" on public.game_sessions;
drop policy if exists "Participants update game sessions" on public.game_sessions;
drop policy if exists "Hosts and admins delete game sessions" on public.game_sessions;
create policy "Participants view game sessions"
on public.game_sessions for select to authenticated
using (
  app_private.is_active_user()
  and (app_private.is_room_participant(room_id) or app_private.is_admin())
);
create policy "Participants create game sessions"
on public.game_sessions for insert to authenticated
with check (
  host_id = (select auth.uid())
  and app_private.is_active_user()
  and app_private.is_room_participant(room_id)
);
create policy "Game players update game sessions"
on public.game_sessions for update to authenticated
using (
  app_private.is_active_user()
  and (
    app_private.is_room_participant(room_id)
    or app_private.is_admin()
  )
)
with check (
  app_private.is_active_user()
  and (
    app_private.is_room_participant(room_id)
    or app_private.is_admin()
  )
);
create policy "Hosts and admins delete game sessions"
on public.game_sessions for delete to authenticated
using (
  app_private.is_admin()
  or app_private.is_room_host(room_id)
);

drop policy if exists "Friendships visible to users" on public.friendships;
drop policy if exists "Users request friendships" on public.friendships;
drop policy if exists "Friendship participants update" on public.friendships;
drop policy if exists "Friendship participants delete" on public.friendships;
create policy "Friendships visible to users"
on public.friendships for select to authenticated
using (
  app_private.is_active_user()
  and (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()))
);
create policy "Users request friendships"
on public.friendships for insert to authenticated
with check (
  app_private.is_active_user()
  and requester_id = (select auth.uid())
  and status = 'pending'
);
create policy "Friendship participants update"
on public.friendships for update to authenticated
using (
  app_private.is_active_user()
  and (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()))
)
with check (
  app_private.is_active_user()
  and (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()))
);
create policy "Friendship participants delete"
on public.friendships for delete to authenticated
using (
  app_private.is_active_user()
  and (requester_id = (select auth.uid()) or addressee_id = (select auth.uid()))
);

drop policy if exists "Authenticated users read profile media" on storage.objects;
drop policy if exists "Users upload own avatar files" on storage.objects;
drop policy if exists "Users update own avatar files" on storage.objects;
drop policy if exists "Users upload own cover files" on storage.objects;
drop policy if exists "Users update own cover files" on storage.objects;
create policy "Authenticated users read profile media"
on storage.objects for select to authenticated
using (bucket_id in ('avatars', 'covers') and app_private.is_active_user());
create policy "Users upload own avatar files"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatars'
  and app_private.is_active_user()
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
create policy "Users update own avatar files"
on storage.objects for update to authenticated
using (
  bucket_id = 'avatars'
  and app_private.is_active_user()
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'avatars'
  and app_private.is_active_user()
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
create policy "Users upload own cover files"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'covers'
  and app_private.is_active_user()
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
create policy "Users update own cover files"
on storage.objects for update to authenticated
using (
  bucket_id = 'covers'
  and app_private.is_active_user()
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'covers'
  and app_private.is_active_user()
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

alter table realtime.messages enable row level security;
drop policy if exists "Voice room participants receive realtime" on realtime.messages;
drop policy if exists "Voice room participants send realtime" on realtime.messages;
create policy "Voice room participants receive realtime"
on realtime.messages for select to authenticated
using (
  extension in ('broadcast', 'presence')
  and topic like 'voice-room-%'
  and app_private.is_active_user()
  and app_private.is_room_participant(app_private.voice_room_id_from_topic(topic))
);
create policy "Voice room participants send realtime"
on realtime.messages for insert to authenticated
with check (
  extension in ('broadcast', 'presence')
  and topic like 'voice-room-%'
  and app_private.is_active_user()
  and app_private.is_room_participant(app_private.voice_room_id_from_topic(topic))
);

alter table public.profiles replica identity default;
alter table public.rooms replica identity default;
alter table public.room_participants replica identity default;
alter table public.room_messages replica identity default;
alter table public.conversation_members replica identity default;
alter table public.messages replica identity default;
alter table public.room_meeting_notes replica identity default;
alter table public.game_sessions replica identity default;
alter table public.friendships replica identity default;
