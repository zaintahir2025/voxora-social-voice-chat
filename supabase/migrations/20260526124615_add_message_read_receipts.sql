create table if not exists public.message_reads (
  message_id uuid not null references public.messages(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (message_id, user_id)
);

create index if not exists message_reads_user_idx
on public.message_reads (user_id, read_at desc);

alter table public.message_reads enable row level security;

grant select, insert, update, delete on public.message_reads to authenticated;

drop policy if exists "Conversation members view message reads" on public.message_reads;
create policy "Conversation members view message reads"
on public.message_reads for select to authenticated
using (
  exists (
    select 1
    from public.messages
    where messages.id = message_reads.message_id
      and app_private.is_conversation_member(messages.conversation_id)
  )
);

drop policy if exists "Users mark own message reads" on public.message_reads;
create policy "Users mark own message reads"
on public.message_reads for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1
    from public.messages
    where messages.id = message_reads.message_id
      and app_private.is_conversation_member(messages.conversation_id)
  )
);

drop policy if exists "Users update own message reads" on public.message_reads;
create policy "Users update own message reads"
on public.message_reads for update to authenticated
using (user_id = (select auth.uid()))
with check (
  user_id = (select auth.uid())
  and exists (
    select 1
    from public.messages
    where messages.id = message_reads.message_id
      and app_private.is_conversation_member(messages.conversation_id)
  )
);

alter table public.message_reads replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.message_reads;
exception when duplicate_object or undefined_object then null;
end $$;
