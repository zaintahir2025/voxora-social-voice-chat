create table if not exists public.stories (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  caption text not null default '' check (char_length(caption) <= 280),
  image_url text not null,
  storage_path text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  check (expires_at > created_at),
  check (expires_at <= created_at + interval '24 hours')
);

create index if not exists stories_author_active_idx
on public.stories (author_id, expires_at desc, created_at desc);

create index if not exists stories_active_idx
on public.stories (expires_at desc, created_at desc);

alter table public.stories enable row level security;

grant select on public.stories to anon;
grant select, insert, delete on public.stories to authenticated;

drop policy if exists "Active stories are visible" on public.stories;
create policy "Active stories are visible"
on public.stories for select
using (expires_at > now() or author_id = (select auth.uid()));

drop policy if exists "Users create own stories" on public.stories;
create policy "Users create own stories"
on public.stories for insert to authenticated
with check (
  author_id = (select auth.uid())
  and storage_path like (select auth.uid())::text || '/%'
  and expires_at > now()
  and expires_at <= now() + interval '24 hours'
);

drop policy if exists "Users delete own stories" on public.stories;
create policy "Users delete own stories"
on public.stories for delete to authenticated
using (author_id = (select auth.uid()));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('stories', 'stories', true, 15728640, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Public story media is readable" on storage.objects;
create policy "Public story media is readable"
on storage.objects for select to anon, authenticated
using (bucket_id = 'stories');

drop policy if exists "Users upload own story files" on storage.objects;
create policy "Users upload own story files"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'stories'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

drop policy if exists "Users delete own story files" on storage.objects;
create policy "Users delete own story files"
on storage.objects for delete to authenticated
using (
  bucket_id = 'stories'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

alter table public.stories replica identity full;

do $$
begin
  alter publication supabase_realtime add table public.stories;
exception when duplicate_object or undefined_object then null;
end $$;
