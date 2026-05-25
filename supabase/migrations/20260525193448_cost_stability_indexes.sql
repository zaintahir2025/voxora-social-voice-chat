create index if not exists profiles_created_at_desc_idx
on public.profiles (created_at desc, id desc);

create index if not exists profiles_lower_handle_idx
on public.profiles (lower(handle));

create index if not exists profiles_lower_full_name_idx
on public.profiles (lower(full_name));

create index if not exists rooms_live_recent_partial_idx
on public.rooms (created_at desc, id desc)
where is_live = true;

create index if not exists room_participants_joined_recent_idx
on public.room_participants (room_id, joined_at desc, user_id);

create index if not exists room_participants_user_recent_idx
on public.room_participants (user_id, last_seen_at desc, room_id);

create index if not exists room_messages_room_created_desc_idx
on public.room_messages (room_id, created_at desc, id desc);

create index if not exists room_messages_created_desc_idx
on public.room_messages (created_at desc, id desc);

create index if not exists room_meeting_notes_room_created_desc_idx
on public.room_meeting_notes (room_id, created_at desc, id desc);

create index if not exists game_sessions_active_recent_idx
on public.game_sessions (created_at desc, id desc)
where is_active = true;

create index if not exists game_sessions_room_active_recent_idx
on public.game_sessions (room_id, is_active, created_at desc, id desc);

create index if not exists friendships_requester_recent_idx
on public.friendships (requester_id, created_at desc, id desc);

create index if not exists friendships_addressee_recent_idx
on public.friendships (addressee_id, created_at desc, id desc);

create index if not exists conversation_members_user_recent_idx
on public.conversation_members (user_id, joined_at desc, conversation_id);

create index if not exists messages_conversation_created_desc_idx
on public.messages (conversation_id, created_at desc, id desc);

drop function if exists public.admin_list_profiles();

create function public.admin_list_profiles(
  result_limit int default 500,
  search_term text default null
)
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
declare
  safe_limit int := least(greatest(coalesce(result_limit, 500), 1), 1000);
  q text := nullif(lower(trim(search_term)), '');
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
  where q is null
     or lower(p.handle) like q || '%'
     or lower(p.full_name) like q || '%'
     or lower(coalesce(p.email, '')) like q || '%'
  order by p.created_at desc
  limit safe_limit;
end;
$$;

revoke all on function public.admin_list_profiles(int, text) from public, anon;
grant execute on function public.admin_list_profiles(int, text) to authenticated;
