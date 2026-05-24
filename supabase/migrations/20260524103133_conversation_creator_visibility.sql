drop policy if exists "Conversation visible to members" on public.conversations;
create policy "Conversation visible to members and creator"
on public.conversations for select to authenticated
using (created_by = (select auth.uid()) or app_private.is_conversation_member(id));

drop policy if exists "Members update conversations" on public.conversations;
create policy "Members and creator update conversations"
on public.conversations for update to authenticated
using (created_by = (select auth.uid()) or app_private.is_conversation_member(id))
with check (created_by = (select auth.uid()) or app_private.is_conversation_member(id));
