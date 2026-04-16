create extension if not exists pgcrypto with schema extensions;

create table if not exists public.listing_roles (
  id uuid primary key default gen_random_uuid(),
  role_key text not null unique,
  display_name text not null,
  points_per_listing integer not null check (points_per_listing >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint listing_roles_role_key_format
    check (role_key ~ '^[a-z0-9_]+$')
);

create index if not exists idx_listing_roles_active
  on public.listing_roles (is_active);

insert into public.listing_roles (
  role_key,
  display_name,
  points_per_listing,
  is_active
)
values
  ('agent', 'Agent', 100, true)
on conflict (role_key) do nothing;

create or replace function public.set_listing_roles_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_listing_roles_updated_at on public.listing_roles;

create trigger set_listing_roles_updated_at
before update on public.listing_roles
for each row
execute function public.set_listing_roles_updated_at();

create or replace function public.is_current_user_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users
    where id = (select auth.uid())
      and coalesce(is_admin, false) = true
  );
$$;

alter table public.listing_roles enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'listing_roles'
      and policyname = 'Admins can read listing roles'
  ) then
    create policy "Admins can read listing roles"
      on public.listing_roles
      for select
      to authenticated
      using ((select public.is_current_user_admin()));
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'listing_roles'
      and policyname = 'Admins can insert listing roles'
  ) then
    create policy "Admins can insert listing roles"
      on public.listing_roles
      for insert
      to authenticated
      with check ((select public.is_current_user_admin()));
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'listing_roles'
      and policyname = 'Admins can update listing roles'
  ) then
    create policy "Admins can update listing roles"
      on public.listing_roles
      for update
      to authenticated
      using ((select public.is_current_user_admin()))
      with check ((select public.is_current_user_admin()));
  end if;
end;
$$;

alter table public.properties
  add column if not exists listing_points_awarded integer not null default 0;

alter table public.properties
  add column if not exists listing_points_awarded_at timestamptz;

create or replace function public.resolve_listing_points_for_role(p_role text)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (
      select lr.points_per_listing
      from public.listing_roles lr
      where lr.role_key = lower(coalesce(p_role, ''))
        and lr.is_active = true
      limit 1
    ),
    (
      select lr.points_per_listing
      from public.listing_roles lr
      where lr.role_key = 'agent'
        and lr.is_active = true
      limit 1
    ),
    100
  );
$$;

create or replace function public.award_listing_points_on_approval()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role text;
  v_points integer;
  v_usd numeric(12, 6);
begin
  if new.status = 'approved'
     and coalesce(old.status, '') <> 'approved'
     and new.listing_points_awarded_at is null then
    select role
    into v_role
    from public.users
    where id = new.user_id;

    v_points := public.resolve_listing_points_for_role(v_role);
    v_usd := round((v_points::numeric / 3500.0), 6);

    if v_points > 0 then
      insert into public.points_ledger (
        user_id,
        action,
        points,
        usd_value,
        created_at
      )
      values (
        new.user_id,
        'listing',
        v_points,
        v_usd,
        timezone('utc', now())
      );

      update public.users
      set
        ppv = coalesce(ppv, 0) + v_points,
        balance_usd = coalesce(balance_usd, 0) + v_usd
      where id = new.user_id;
    end if;

    new.listing_points_awarded = v_points;
    new.listing_points_awarded_at = timezone('utc', now());
  end if;

  return new;
end;
$$;

drop trigger if exists award_listing_points_on_approval on public.properties;

create trigger award_listing_points_on_approval
before update of status on public.properties
for each row
execute function public.award_listing_points_on_approval();
