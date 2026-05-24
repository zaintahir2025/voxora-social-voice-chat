do $$
begin
  if exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'coin_purchases'
  ) then
    alter publication supabase_realtime drop table public.coin_purchases;
  end if;

  if exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'gift_transactions'
  ) then
    alter publication supabase_realtime drop table public.gift_transactions;
  end if;
end;
$$;

drop trigger if exists coin_purchase_prepare on public.coin_purchases;
drop trigger if exists coin_purchase_complete on public.coin_purchases;
drop trigger if exists gift_transaction_prepare on public.gift_transactions;

drop function if exists app_private.prepare_coin_purchase();
drop function if exists app_private.complete_coin_purchase();
drop function if exists app_private.prepare_gift_transaction();

drop table if exists public.gift_transactions cascade;
drop table if exists public.gifts cascade;
drop table if exists public.coin_purchases cascade;
drop table if exists public.coin_packages cascade;

alter table public.room_messages
  drop constraint if exists room_messages_kind_check,
  add constraint room_messages_kind_check check (kind in ('chat', 'system'));

alter table public.profiles
  drop column if exists vip_tier,
  drop column if exists coins,
  drop column if exists earnings;
