alter table public.post_comments
add column if not exists parent_comment_id uuid;

alter table public.post_comments
drop constraint if exists post_comments_parent_comment_id_check;

alter table public.post_comments
add constraint post_comments_parent_comment_id_check
check (parent_comment_id is null or parent_comment_id <> id);

alter table public.post_comments
drop constraint if exists post_comments_id_post_id_key;

alter table public.post_comments
add constraint post_comments_id_post_id_key unique (id, post_id);

alter table public.post_comments
drop constraint if exists post_comments_parent_same_post_fkey;

alter table public.post_comments
add constraint post_comments_parent_same_post_fkey
foreign key (parent_comment_id, post_id)
references public.post_comments (id, post_id)
on delete cascade;

create index if not exists comments_parent_idx
on public.post_comments (post_id, parent_comment_id, created_at);
