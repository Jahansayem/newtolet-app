insert into public.listing_roles (
  role_key,
  display_name,
  points_per_listing,
  is_active
)
values
  ('field_officer', 'Field Officer', 500, true),
  ('remote_officer', 'Remote Officer', 100, true)
on conflict (role_key) do update
set
  display_name = excluded.display_name,
  points_per_listing = excluded.points_per_listing,
  is_active = excluded.is_active;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'listing_roles'
      and policyname = 'Authenticated users can read active listing roles'
  ) then
    create policy "Authenticated users can read active listing roles"
      on public.listing_roles
      for select
      to authenticated
      using (is_active = true);
  end if;
end;
$$;

alter table if exists public.invites
  add column if not exists points_awarded integer not null default 0;

alter table if exists public.invites
  add column if not exists points_awarded_at timestamptz;

create or replace function public.get_approved_listing_count(p_user_id uuid)
returns integer
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::integer
  from public.properties
  where user_id = p_user_id
    and status = 'approved';
$$;

create or replace function public.is_referral_bonus_eligible(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.get_approved_listing_count(p_user_id) >= 5;
$$;

create or replace function public.process_referral_bonus_for_invite(
  p_invite_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inviter_id uuid;
  v_points_awarded integer;
  v_points integer := 150;
  v_usd numeric(12, 6) := round((150::numeric / 3500.0), 6);
begin
  select inviter_id,
         coalesce(points_awarded, 0)
  into v_inviter_id,
       v_points_awarded
  from public.invites
  where id = p_invite_id
    and status = 'completed'
  limit 1;

  if v_inviter_id is null or v_points_awarded > 0 then
    return 0;
  end if;

  if not public.is_referral_bonus_eligible(v_inviter_id) then
    return 0;
  end if;

  insert into public.points_ledger (
    user_id,
    action,
    points,
    usd_value,
    created_at
  )
  values (
    v_inviter_id,
    'referral',
    v_points,
    v_usd,
    timezone('utc', now())
  );

  update public.users
  set
    ppv = coalesce(ppv, 0) + v_points,
    balance_usd = coalesce(balance_usd, 0) + v_usd
  where id = v_inviter_id;

  update public.invites
  set
    points_awarded = v_points,
    points_awarded_at = timezone('utc', now())
  where id = p_invite_id
    and coalesce(points_awarded, 0) = 0;

  return v_points;
end;
$$;

create or replace function public.award_completed_referral_points_for_user(
  p_inviter_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite_id uuid;
  v_awarded integer := 0;
begin
  if not public.is_referral_bonus_eligible(p_inviter_id) then
    return 0;
  end if;

  for v_invite_id in
    select id
    from public.invites
    where inviter_id = p_inviter_id
      and status = 'completed'
      and coalesce(points_awarded, 0) = 0
    order by created_at asc
  loop
    v_awarded := v_awarded + public.process_referral_bonus_for_invite(v_invite_id);
  end loop;

  return v_awarded;
end;
$$;

create or replace function public.award_referral_points_on_invite_completion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'completed'
     and coalesce(old.status, '') <> 'completed' then
    perform public.process_referral_bonus_for_invite(new.id);
  end if;

  return new;
end;
$$;

do $$
begin
  if to_regclass('public.invites') is not null then
    drop trigger if exists award_referral_points_on_invite_completion on public.invites;

    create trigger award_referral_points_on_invite_completion
    after update of status on public.invites
    for each row
    execute function public.award_referral_points_on_invite_completion();
  end if;
end;
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

      perform public.award_completed_referral_points_for_user(new.user_id);
    end if;

    new.listing_points_awarded = v_points;
    new.listing_points_awarded_at = timezone('utc', now());
  end if;

  return new;
end;
$$;
