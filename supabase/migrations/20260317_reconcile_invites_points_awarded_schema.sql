alter table if exists public.invites
  add column if not exists points_awarded_at timestamptz;

do $$
declare
  v_points_awarded_type text;
begin
  if to_regclass('public.invites') is null then
    raise exception 'public.invites table does not exist';
  end if;

  select data_type
  into v_points_awarded_type
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'invites'
    and column_name = 'points_awarded';

  if v_points_awarded_type is null then
    execute '
      alter table public.invites
      add column points_awarded integer not null default 0
    ';
  elsif v_points_awarded_type = 'boolean' then
    execute '
      alter table public.invites
      alter column points_awarded drop default
    ';
    execute '
      alter table public.invites
      alter column points_awarded type integer
      using (case when points_awarded then 150 else 0 end)
    ';
    execute '
      alter table public.invites
      alter column points_awarded set default 0
    ';
    execute '
      update public.invites
      set points_awarded = 0
      where points_awarded is null
    ';
    execute '
      alter table public.invites
      alter column points_awarded set not null
    ';
  elsif v_points_awarded_type in ('smallint', 'integer', 'bigint') then
    execute '
      alter table public.invites
      alter column points_awarded type integer
      using points_awarded::integer
    ';
    execute '
      update public.invites
      set points_awarded = 0
      where points_awarded is null
    ';
    execute '
      alter table public.invites
      alter column points_awarded set default 0
    ';
    execute '
      alter table public.invites
      alter column points_awarded set not null
    ';
  else
    raise exception 'Unsupported type for public.invites.points_awarded: %',
      v_points_awarded_type;
  end if;
end;
$$;

update public.invites
set points_awarded_at = coalesce(
  points_awarded_at,
  completed_at,
  registered_at,
  created_at,
  timezone('utc', now())
)
where points_awarded > 0
  and points_awarded_at is null;
