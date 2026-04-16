alter table if exists public.properties
  add column if not exists is_rent_negotiable boolean not null default false;

do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'properties'
      and column_name = 'is_rent_negotiable'
  ) then
    update public.properties
    set is_rent_negotiable = false
    where is_rent_negotiable is null;
  end if;
end;
$$;
