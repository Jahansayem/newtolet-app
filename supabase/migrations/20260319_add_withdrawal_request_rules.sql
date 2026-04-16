create extension if not exists pgcrypto with schema extensions;

create table if not exists public.withdrawals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  requested_points integer not null default 0 check (requested_points >= 0),
  amount_usd numeric(12, 6) not null check (amount_usd > 0),
  amount_bdt numeric(12, 2) not null check (amount_bdt > 0),
  exchange_rate numeric(12, 4) not null check (exchange_rate > 0),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'paid', 'completed', 'rejected', 'failed', 'cancelled')),
  method text not null,
  account_number text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.withdrawals
  add column if not exists requested_points integer not null default 0;

alter table public.withdrawals
  add column if not exists account_number text;

alter table public.withdrawals
  add column if not exists updated_at timestamptz not null default timezone('utc', now());

update public.withdrawals
set requested_points = greatest(round(coalesce(amount_usd, 0)::numeric * 3500), 0)::integer
where coalesce(requested_points, 0) = 0
  and coalesce(amount_usd, 0) > 0;

update public.withdrawals
set account_number = coalesce(account_number, '')
where account_number is null;

create index if not exists idx_withdrawals_user_created_at
  on public.withdrawals (user_id, created_at desc);

create or replace function public.set_withdrawals_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_withdrawals_updated_at on public.withdrawals;

create trigger set_withdrawals_updated_at
before update on public.withdrawals
for each row
execute function public.set_withdrawals_updated_at();

alter table public.withdrawals enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'withdrawals'
      and policyname = 'Users can read their own withdrawals'
  ) then
    create policy "Users can read their own withdrawals"
      on public.withdrawals
      for select
      to authenticated
      using (user_id = auth.uid());
  end if;
end;
$$;

create or replace function public.request_withdrawal(
  p_requested_points integer,
  p_method text,
  p_account_number text
)
returns public.withdrawals
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_requested_points integer := coalesce(p_requested_points, 0);
  v_method text := lower(trim(coalesce(p_method, '')));
  v_account_number text := trim(coalesce(p_account_number, ''));
  v_now_dhaka timestamp without time zone := now() at time zone 'Asia/Dhaka';
  v_month_start_dhaka timestamp without time zone := date_trunc('month', v_now_dhaka);
  v_next_month_dhaka timestamp without time zone := v_month_start_dhaka + interval '1 month';
  v_balance_usd numeric(12, 6);
  v_reserved_usd numeric(12, 6);
  v_available_usd numeric(12, 6);
  v_amount_usd numeric(12, 6);
  v_amount_bdt numeric(12, 2);
  v_exchange_rate numeric(12, 4);
  v_withdrawal public.withdrawals%rowtype;
begin
  if v_user_id is null then
    raise exception 'User not authenticated';
  end if;

  if extract(day from v_now_dhaka) < 1 or extract(day from v_now_dhaka) > 5 then
    raise exception 'Withdrawals are available only from day 1 to 5 each month in Asia/Dhaka.';
  end if;

  if v_requested_points < 5000 then
    raise exception 'Minimum withdrawal is 5000 points.';
  end if;

  if v_method not in ('bkash', 'nagad') then
    raise exception 'Unsupported withdrawal method.';
  end if;

  if v_account_number = '' then
    raise exception 'Account number is required.';
  end if;

  if exists (
    select 1
    from public.withdrawals w
    where w.user_id = v_user_id
      and (w.created_at at time zone 'Asia/Dhaka') >= v_month_start_dhaka
      and (w.created_at at time zone 'Asia/Dhaka') < v_next_month_dhaka
  ) then
    raise exception 'A withdrawal request has already been submitted this month.';
  end if;

  select coalesce(balance_usd, 0)
  into v_balance_usd
  from public.users
  where id = v_user_id
  for update;

  if not found then
    raise exception 'User profile not found.';
  end if;

  select coalesce(sum(amount_usd), 0)
  into v_reserved_usd
  from public.withdrawals w
  where w.user_id = v_user_id
    and lower(coalesce(w.status, 'pending')) not in ('rejected', 'failed', 'cancelled');

  v_available_usd := greatest(v_balance_usd - v_reserved_usd, 0);
  v_amount_usd := round((v_requested_points::numeric / 3500.0), 6);

  if v_available_usd < v_amount_usd then
    raise exception 'Insufficient available balance for this withdrawal request.';
  end if;

  select usd_to_bdt
  into v_exchange_rate
  from public.exchange_rates
  order by effective_from desc
  limit 1;

  if v_exchange_rate is null or v_exchange_rate <= 0 then
    raise exception 'Exchange rate is not configured.';
  end if;

  v_amount_bdt := round(v_amount_usd * v_exchange_rate, 2);

  insert into public.withdrawals (
    user_id,
    requested_points,
    amount_usd,
    amount_bdt,
    exchange_rate,
    status,
    method,
    account_number,
    created_at,
    updated_at
  )
  values (
    v_user_id,
    v_requested_points,
    v_amount_usd,
    v_amount_bdt,
    v_exchange_rate,
    'pending',
    v_method,
    v_account_number,
    timezone('utc', now()),
    timezone('utc', now())
  )
  returning *
  into v_withdrawal;

  return v_withdrawal;
end;
$$;
