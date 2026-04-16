create extension if not exists pgcrypto with schema extensions;

create table if not exists public.credit_topups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  provider text not null default 'uddoktapay',
  status text not null default 'created'
    check (status in ('created', 'pending', 'paid', 'failed', 'cancelled', 'refunded')),
  amount_bdt integer not null check (amount_bdt > 0),
  credits_to_add integer not null check (credits_to_add > 0),
  invoice_id text unique,
  transaction_id text,
  payment_method text,
  checkout_url text,
  redirect_url text,
  cancel_url text,
  webhook_url text,
  provider_payload jsonb not null default '{}'::jsonb,
  verified_payload jsonb not null default '{}'::jsonb,
  credited_at timestamptz,
  refunded_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_credit_topups_user_created_at
  on public.credit_topups (user_id, created_at desc);

create index if not exists idx_credit_topups_status
  on public.credit_topups (status);

alter table public.credit_transactions
  add column if not exists credits_amount integer;

alter table public.credit_transactions
  add column if not exists balance_after integer;

alter table public.credit_transactions
  add column if not exists reference_type text;

alter table public.credit_transactions
  add column if not exists reference_id uuid;

alter table public.credit_transactions
  add column if not exists provider text;

alter table public.credit_transactions
  add column if not exists metadata jsonb not null default '{}'::jsonb;

create unique index if not exists idx_credit_transactions_reference_unique
  on public.credit_transactions (reference_type, reference_id, transaction_type)
  where reference_type is not null
    and reference_id is not null;

create or replace function public.set_credit_topups_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_credit_topups_updated_at on public.credit_topups;

create trigger set_credit_topups_updated_at
before update on public.credit_topups
for each row
execute function public.set_credit_topups_updated_at();

alter table public.credit_topups enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'credit_topups'
      and policyname = 'Users can read their own credit topups'
  ) then
    create policy "Users can read their own credit topups"
      on public.credit_topups
      for select
      to authenticated
      using (user_id = auth.uid());
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'credit_topups'
      and policyname = 'Users can insert their own credit topups'
  ) then
    create policy "Users can insert their own credit topups"
      on public.credit_topups
      for insert
      to authenticated
      with check (user_id = auth.uid());
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'credit_topups'
      and policyname = 'Users can update their own pending credit topups'
  ) then
    create policy "Users can update their own pending credit topups"
      on public.credit_topups
      for update
      to authenticated
      using (user_id = auth.uid() and status in ('created', 'pending'))
      with check (user_id = auth.uid());
  end if;
end;
$$;

create or replace function public.increment_user_credits(
  p_user_id uuid,
  p_amount integer
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new_balance integer;
begin
  update public.users
  set credits = coalesce(credits, 0) + p_amount
  where id = p_user_id
  returning credits into v_new_balance;

  return coalesce(v_new_balance, 0);
end;
$$;
