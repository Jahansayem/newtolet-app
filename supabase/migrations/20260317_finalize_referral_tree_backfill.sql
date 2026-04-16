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

select public.backfill_referral_tree();
