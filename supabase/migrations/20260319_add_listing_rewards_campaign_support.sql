create or replace function public.get_approved_listing_daily_counts(
  p_user_id uuid,
  p_days integer default 30
)
returns table (
  activity_date date,
  listing_count integer
)
language sql
stable
security definer
set search_path = public
as $$
  with bounds as (
    select
      greatest(coalesce(p_days, 30), 1) as days_requested,
      timezone('Asia/Dhaka', now())::date as today_dhaka
  ),
  day_series as (
    select generate_series(
      (select today_dhaka - (days_requested - 1) from bounds),
      (select today_dhaka from bounds),
      interval '1 day'
    )::date as activity_date
  ),
  listing_totals as (
    select
      (coalesce(p.listing_points_awarded_at, p.created_at) at time zone 'Asia/Dhaka')::date as activity_date,
      count(*)::integer as listing_count
    from public.properties p
    cross join bounds b
    where p.user_id = p_user_id
      and p.status = 'approved'
      and (coalesce(p.listing_points_awarded_at, p.created_at) at time zone 'Asia/Dhaka')::date >=
        (b.today_dhaka - (b.days_requested - 1))
      and (coalesce(p.listing_points_awarded_at, p.created_at) at time zone 'Asia/Dhaka')::date <=
        b.today_dhaka
    group by 1
  )
  select
    ds.activity_date,
    coalesce(lt.listing_count, 0)::integer as listing_count
  from day_series ds
  left join listing_totals lt using (activity_date)
  order by ds.activity_date asc;
$$;
