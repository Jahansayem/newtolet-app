create table if not exists public.referral_settings (
  id boolean primary key default true check (id),
  root_sponsor_user_id uuid not null references public.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_referral_settings_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_referral_settings_updated_at on public.referral_settings;

create trigger set_referral_settings_updated_at
before update on public.referral_settings
for each row
execute function public.set_referral_settings_updated_at();

insert into public.referral_settings (id, root_sponsor_user_id)
select true, u.id
from public.users u
where coalesce(u.is_admin, false) = true
order by u.created_at asc nulls last, u.id asc
limit 1
on conflict (id) do nothing;

alter table public.referral_settings enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'referral_settings'
      and policyname = 'Admins can read referral settings'
  ) then
    create policy "Admins can read referral settings"
      on public.referral_settings
      for select
      to authenticated
      using (
        exists (
          select 1
          from public.users u
          where u.id = auth.uid()
            and coalesce(u.is_admin, false) = true
        )
      );
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'referral_settings'
      and policyname = 'Admins can update referral settings'
  ) then
    create policy "Admins can update referral settings"
      on public.referral_settings
      for update
      to authenticated
      using (
        exists (
          select 1
          from public.users u
          where u.id = auth.uid()
            and coalesce(u.is_admin, false) = true
        )
      )
      with check (
        exists (
          select 1
          from public.users u
          where u.id = auth.uid()
            and coalesce(u.is_admin, false) = true
        )
      );
  end if;
end;
$$;

create or replace function public.generate_unique_referral_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
begin
  loop
    v_code := 'NT' || upper(substr(md5(clock_timestamp()::text || random()::text), 1, 6));
    exit when not exists (
      select 1
      from public.users
      where referral_code = v_code
    );
  end loop;

  return v_code;
end;
$$;

create or replace function public.get_root_sponsor_user_id()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_root uuid;
begin
  select rs.root_sponsor_user_id
  into v_root
  from public.referral_settings rs
  where rs.id = true;

  if v_root is null then
    raise exception 'Root sponsor is not configured';
  end if;

  if not exists (
    select 1
    from public.users u
    where u.id = v_root
      and coalesce(u.is_admin, false) = true
  ) then
    raise exception 'Root sponsor must reference an admin user';
  end if;

  return v_root;
end;
$$;

create or replace function public.resolve_signup_sponsor_id(
  p_referral_code text,
  p_legacy_sponsor_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text := upper(trim(coalesce(p_referral_code, '')));
  v_sponsor_id uuid;
begin
  if v_code <> '' then
    select u.id
    into v_sponsor_id
    from public.users u
    where upper(coalesce(u.referral_code, '')) = v_code
      and coalesce(u.is_active, true) = true
    limit 1;

    if v_sponsor_id is null then
      raise exception 'Invalid referral code';
    end if;

    return v_sponsor_id;
  end if;

  if p_legacy_sponsor_id is not null
     and exists (
       select 1
       from public.users u
       where u.id = p_legacy_sponsor_id
         and coalesce(u.is_active, true) = true
     ) then
    return p_legacy_sponsor_id;
  end if;

  return public.get_root_sponsor_user_id();
end;
$$;

create or replace function public.upsert_team_tree_entry(
  p_user_id uuid,
  p_sponsor_id uuid,
  p_placement_parent_id uuid,
  p_joined_at timestamptz default now()
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_label text := replace(p_user_id::text, '-', '_');
  v_sponsor_path ltree;
  v_placement_path ltree;
begin
  if p_sponsor_id is null then
    v_sponsor_path := v_user_label::ltree;
  else
    select tt.sponsor_path
    into v_sponsor_path
    from public.team_tree tt
    where tt.user_id = p_sponsor_id;

    if v_sponsor_path is null then
      raise exception 'Sponsor tree entry missing for %', p_sponsor_id;
    end if;

    v_sponsor_path := v_sponsor_path || v_user_label::ltree;
  end if;

  if p_placement_parent_id is null then
    v_placement_path := v_sponsor_path;
  else
    select tt.placement_path
    into v_placement_path
    from public.team_tree tt
    where tt.user_id = p_placement_parent_id;

    if v_placement_path is null then
      raise exception 'Placement parent tree entry missing for %', p_placement_parent_id;
    end if;

    v_placement_path := v_placement_path || v_user_label::ltree;
  end if;

  insert into public.team_tree (
    user_id,
    sponsor_id,
    placement_parent_id,
    sponsor_path,
    placement_path,
    sponsor_depth,
    placement_depth,
    joined_at,
    updated_at
  )
  values (
    p_user_id,
    p_sponsor_id,
    p_placement_parent_id,
    v_sponsor_path,
    v_placement_path,
    greatest(nlevel(v_sponsor_path) - 1, 0),
    greatest(nlevel(v_placement_path) - 1, 0),
    coalesce(p_joined_at, now()),
    now()
  )
  on conflict (user_id) do update
  set
    sponsor_id = excluded.sponsor_id,
    placement_parent_id = excluded.placement_parent_id,
    sponsor_path = excluded.sponsor_path,
    placement_path = excluded.placement_path,
    sponsor_depth = excluded.sponsor_depth,
    placement_depth = excluded.placement_depth,
    joined_at = coalesce(public.team_tree.joined_at, excluded.joined_at),
    updated_at = now();
end;
$$;

create or replace function public.rebuild_team_tree_metrics()
returns void
language sql
security definer
set search_path = public
as $$
  update public.team_tree tt
  set
    direct_referral_count = coalesce((
      select count(*)
      from public.team_tree child
      where child.sponsor_id = tt.user_id
    ), 0),
    total_team_size = coalesce((
      select count(*)
      from public.team_tree child
      where child.sponsor_path <@ tt.sponsor_path
        and child.user_id <> tt.user_id
    ), 0),
    sponsor_depth = greatest(nlevel(tt.sponsor_path) - 1, 0),
    placement_depth = greatest(nlevel(tt.placement_path) - 1, 0),
    updated_at = now();
$$;

create or replace function public.backfill_referral_tree()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_root uuid;
  r record;
begin
  v_root := public.get_root_sponsor_user_id();

  update public.users
  set
    sponsor_id = null,
    placement_parent_id = null,
    referral_code = coalesce(referral_code, public.generate_unique_referral_code()),
    updated_at = now()
  where id = v_root;

  perform public.upsert_team_tree_entry(
    v_root,
    null,
    null,
    (
      select coalesce(u.created_at at time zone 'utc', now())
      from public.users u
      where u.id = v_root
    )
  );

  delete from public.team_tree
  where user_id <> v_root;

  for r in
    select
      u.id,
      coalesce(u.sponsor_id, v_root) as sponsor_id,
      coalesce(u.placement_parent_id, u.sponsor_id, v_root) as placement_parent_id,
      u.created_at
    from public.users u
    where u.id <> v_root
    order by u.created_at asc nulls last, u.id asc
  loop
    if not exists (
      select 1
      from public.team_tree tt
      where tt.user_id = r.sponsor_id
    ) then
      r.sponsor_id := v_root;
    end if;

    if not exists (
      select 1
      from public.team_tree tt
      where tt.user_id = r.placement_parent_id
    ) then
      r.placement_parent_id := r.sponsor_id;
    end if;

    update public.users
    set
      sponsor_id = r.sponsor_id,
      placement_parent_id = r.placement_parent_id,
      role = case
        when coalesce(role, 'tenant') = 'tenant' then 'agent'
        else role
      end,
      referral_code = coalesce(referral_code, public.generate_unique_referral_code()),
      updated_at = now()
    where id = r.id;

    perform public.upsert_team_tree_entry(
      r.id,
      r.sponsor_id,
      r.placement_parent_id,
      coalesce(r.created_at at time zone 'utc', now())
    );
  end loop;

  delete from public.team_tree tt
  where not exists (
    select 1
    from public.users u
    where u.id = tt.user_id
  );

  perform public.rebuild_team_tree_metrics();
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_referral_code text := upper(trim(coalesce(NEW.raw_user_meta_data->>'referral_code', '')));
  v_legacy_sponsor_id uuid;
  v_sponsor_id uuid;
  v_referral_code_value text;
begin
  begin
    v_legacy_sponsor_id := (NEW.raw_user_meta_data->>'sponsor_id')::uuid;
  exception when others then
    v_legacy_sponsor_id := null;
  end;

  v_sponsor_id := public.resolve_signup_sponsor_id(
    v_referral_code,
    v_legacy_sponsor_id
  );

  v_referral_code_value := public.generate_unique_referral_code();

  insert into public.users (
    id,
    email,
    phone,
    name,
    credits,
    verified,
    is_admin,
    is_active,
    role,
    referral_code,
    sponsor_id,
    placement_parent_id,
    created_at,
    updated_at
  )
  values (
    NEW.id,
    NEW.email,
    coalesce(NEW.phone, NEW.raw_user_meta_data->>'phone'),
    coalesce(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    0,
    false,
    false,
    true,
    'agent',
    v_referral_code_value,
    v_sponsor_id,
    v_sponsor_id,
    now(),
    now()
  )
  on conflict (id) do update
  set
    phone = coalesce(excluded.phone, public.users.phone),
    name = coalesce(excluded.name, public.users.name),
    sponsor_id = coalesce(public.users.sponsor_id, excluded.sponsor_id),
    placement_parent_id = coalesce(public.users.placement_parent_id, excluded.placement_parent_id),
    referral_code = coalesce(public.users.referral_code, excluded.referral_code),
    role = case
      when coalesce(public.users.role, 'tenant') = 'tenant' then 'agent'
      else public.users.role
    end,
    updated_at = now();

  perform public.upsert_team_tree_entry(
    NEW.id,
    v_sponsor_id,
    v_sponsor_id,
    coalesce(NEW.created_at, now())
  );

  perform public.rebuild_team_tree_metrics();

  return NEW;
end;
$$;

select public.backfill_referral_tree();
