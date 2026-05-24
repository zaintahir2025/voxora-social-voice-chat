alter table public.rooms
  drop constraint if exists rooms_capacity_check,
  add constraint rooms_capacity_check check (capacity between 2 and 500);

create table public.room_meeting_notes (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  note_type text not null check (note_type in ('agenda', 'decision', 'action')),
  body text not null check (char_length(trim(body)) between 1 and 1200),
  is_done boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.game_sessions (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  host_id uuid not null references public.profiles(id) on delete cascade,
  game_type text not null check (game_type in ('chess', 'ludo', 'cards')),
  title text not null,
  players jsonb not null default '{}'::jsonb,
  state jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
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
  check (requester_id <> addressee_id),
  unique (requester_id, addressee_id)
);

create index room_meeting_notes_room_idx on public.room_meeting_notes (room_id, created_at);
create index game_sessions_room_idx on public.game_sessions (room_id, is_active, created_at desc);
create index friendships_user_idx on public.friendships (requester_id, addressee_id, status);

create trigger game_sessions_touch_updated_at
before update on public.game_sessions
for each row execute function app_private.touch_updated_at();

create trigger friendships_touch_updated_at
before update on public.friendships
for each row execute function app_private.touch_updated_at();

alter table public.room_meeting_notes enable row level security;
alter table public.game_sessions enable row level security;
alter table public.friendships enable row level security;

grant select, insert, update, delete on public.room_meeting_notes to authenticated;
grant select, insert, update, delete on public.game_sessions to authenticated;
grant select, insert, update, delete on public.friendships to authenticated;

create policy "Participants view meeting notes"
on public.room_meeting_notes for select to authenticated
using (app_private.is_room_participant(room_id) or app_private.is_admin());

create policy "Participants add meeting notes"
on public.room_meeting_notes for insert to authenticated
with check (author_id = auth.uid() and app_private.is_room_participant(room_id));

create policy "Authors hosts and admins update meeting notes"
on public.room_meeting_notes for update to authenticated
using (
  author_id = auth.uid()
  or app_private.is_admin()
  or exists (select 1 from public.rooms where id = room_id and host_id = auth.uid())
)
with check (
  author_id = auth.uid()
  or app_private.is_admin()
  or exists (select 1 from public.rooms where id = room_id and host_id = auth.uid())
);

create policy "Authors hosts and admins delete meeting notes"
on public.room_meeting_notes for delete to authenticated
using (
  author_id = auth.uid()
  or app_private.is_admin()
  or exists (select 1 from public.rooms where id = room_id and host_id = auth.uid())
);

create policy "Participants view game sessions"
on public.game_sessions for select to authenticated
using (app_private.is_room_participant(room_id) or app_private.is_admin());

create policy "Participants create game sessions"
on public.game_sessions for insert to authenticated
with check (host_id = auth.uid() and app_private.is_room_participant(room_id));

create policy "Participants update game sessions"
on public.game_sessions for update to authenticated
using (app_private.is_room_participant(room_id) or app_private.is_admin())
with check (app_private.is_room_participant(room_id) or app_private.is_admin());

create policy "Hosts and admins delete game sessions"
on public.game_sessions for delete to authenticated
using (
  host_id = auth.uid()
  or app_private.is_admin()
  or exists (select 1 from public.rooms where id = room_id and host_id = auth.uid())
);

create policy "Friendships visible to users"
on public.friendships for select to authenticated
using (requester_id = auth.uid() or addressee_id = auth.uid());

create policy "Users request friendships"
on public.friendships for insert to authenticated
with check (requester_id = auth.uid() and status = 'pending');

create policy "Friendship participants update"
on public.friendships for update to authenticated
using (requester_id = auth.uid() or addressee_id = auth.uid())
with check (requester_id = auth.uid() or addressee_id = auth.uid());

create policy "Friendship participants delete"
on public.friendships for delete to authenticated
using (requester_id = auth.uid() or addressee_id = auth.uid());

alter table public.room_meeting_notes replica identity full;
alter table public.game_sessions replica identity full;
alter table public.friendships replica identity full;
alter publication supabase_realtime add table public.room_meeting_notes;
alter publication supabase_realtime add table public.game_sessions;
alter publication supabase_realtime add table public.friendships;
