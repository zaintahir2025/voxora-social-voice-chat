create or replace function app_private.touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop policy if exists "Admins manage gifts" on public.gifts;
drop policy if exists "Admins manage coin packages" on public.coin_packages;
