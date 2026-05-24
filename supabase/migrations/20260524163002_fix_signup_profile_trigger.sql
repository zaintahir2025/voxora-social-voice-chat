create or replace function app_private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  base_handle text;
  final_handle text;
  suffix int := 0;
begin
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

  final_handle := base_handle;
  while exists (select 1 from public.profiles where handle = final_handle) loop
    suffix := suffix + 1;
    final_handle := base_handle || '-' || substring(new.id::text from 1 for 6);
    if suffix > 1 then
      final_handle := final_handle || '-' || suffix::text;
    end if;
  end loop;

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
    coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'), ''), 'Voxora Member'),
    final_handle,
    coalesce(new.raw_user_meta_data->>'bio', ''),
    coalesce(
      array_remove(string_to_array(new.raw_user_meta_data->>'interests', ','), ''),
      '{}'
    ),
    not exists (select 1 from public.profiles)
  );

  return new;
end;
$$;
