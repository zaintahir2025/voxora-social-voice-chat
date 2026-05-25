create index if not exists room_messages_recent_brin_idx
on public.room_messages using brin (created_at);

create index if not exists messages_recent_brin_idx
on public.messages using brin (created_at);

create index if not exists room_participants_recent_seen_idx
on public.room_participants (last_seen_at desc, room_id);

create or replace view app_private.hot_room_message_pressure_5m as
select
  rm.room_id,
  count(*)::bigint as message_count,
  count(distinct rm.sender_id)::bigint as sender_count,
  max(rm.created_at) as last_message_at
from public.room_messages rm
where rm.created_at >= now() - interval '5 minutes'
group by rm.room_id
order by count(*) desc;

create or replace view app_private.direct_message_pressure_5m as
select
  m.conversation_id,
  count(*)::bigint as message_count,
  count(distinct m.sender_id)::bigint as sender_count,
  max(m.created_at) as last_message_at
from public.messages m
where m.created_at >= now() - interval '5 minutes'
group by m.conversation_id
order by count(*) desc;

create or replace view app_private.live_room_participant_pressure as
select
  r.id as room_id,
  r.title,
  r.capacity,
  count(rp.user_id)::bigint as participant_count,
  round((count(rp.user_id)::numeric / nullif(r.capacity, 0)) * 100, 2) as capacity_percent,
  max(rp.last_seen_at) as last_seen_at
from public.rooms r
left join public.room_participants rp on rp.room_id = r.id
where r.is_live = true
group by r.id, r.title, r.capacity
order by count(rp.user_id) desc;

create or replace view app_private.rate_limit_pressure_15m as
select
  action,
  count(distinct user_id)::bigint as limited_user_count,
  sum(request_count)::bigint as request_count,
  max(window_start) as latest_window_start
from app_private.rate_limits
where window_start >= now() - interval '15 minutes'
group by action
order by sum(request_count) desc;

create or replace function app_private.current_spike_snapshot()
returns table (
  metric text,
  value bigint
)
language sql
stable
set search_path = public, app_private
as $$
  select 'live_rooms', count(*)::bigint
  from public.rooms
  where is_live = true
  union all
  select 'active_room_participants_5m', count(*)::bigint
  from public.room_participants
  where last_seen_at >= now() - interval '5 minutes'
  union all
  select 'room_messages_5m', count(*)::bigint
  from public.room_messages
  where created_at >= now() - interval '5 minutes'
  union all
  select 'direct_messages_5m', count(*)::bigint
  from public.messages
  where created_at >= now() - interval '5 minutes'
  union all
  select 'rate_limited_actions_15m', coalesce(sum(request_count), 0)::bigint
  from app_private.rate_limits
  where window_start >= now() - interval '15 minutes';
$$;

revoke all on function app_private.current_spike_snapshot() from public, anon, authenticated;
