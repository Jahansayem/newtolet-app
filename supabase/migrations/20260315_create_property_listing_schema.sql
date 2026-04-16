create extension if not exists pgcrypto with schema extensions;

create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text,
  property_type text,
  total_rooms integer,
  total_bathrooms integer,
  total_kitchen integer,
  balcony integer not null default 0,
  floor_level text,
  occupancy text,
  room_size_sqft integer,
  rent_amount_bdt integer,
  rent_period text not null default 'Monthly',
  state_district text,
  area text,
  sub_area text,
  contact_number text,
  short_description text,
  sector text,
  road text,
  house_plot text,
  lat double precision,
  lng double precision,
  available_from date,
  deadline date,
  status text not null default 'pending',
  views integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.property_images (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  image_url text not null,
  is_thumbnail boolean not null default false,
  display_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.property_amenities (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  amenity_type text not null,
  created_at timestamptz not null default timezone('utc', now()),
  constraint property_amenities_property_id_amenity_type_key unique (property_id, amenity_type)
);

create table if not exists public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, property_id)
);

create index if not exists idx_properties_status_created_at
  on public.properties (status, created_at);

create index if not exists idx_properties_area
  on public.properties (area);

create index if not exists idx_properties_state_district
  on public.properties (state_district);

create index if not exists idx_properties_rent_amount_bdt
  on public.properties (rent_amount_bdt);

create index if not exists idx_properties_user_id
  on public.properties (user_id);

create index if not exists idx_property_images_property_id
  on public.property_images (property_id, display_order);

create index if not exists idx_property_amenities_property_id
  on public.property_amenities (property_id);

create or replace function public.set_properties_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_properties_updated_at on public.properties;

create trigger set_properties_updated_at
before update on public.properties
for each row
execute function public.set_properties_updated_at();

create or replace function public.increment_property_views(p_id uuid)
returns void
language sql
security invoker
set search_path = public
as $$
  update public.properties
  set views = coalesce(views, 0) + 1
  where id = p_id;
$$;

alter table public.properties enable row level security;
alter table public.property_images enable row level security;
alter table public.property_amenities enable row level security;
alter table public.favorites enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'properties'
      and policyname = 'Approved properties are readable'
  ) then
    create policy "Approved properties are readable"
      on public.properties
      for select
      to anon, authenticated
      using (status = 'approved');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'properties'
      and policyname = 'Owners can read their properties'
  ) then
    create policy "Owners can read their properties"
      on public.properties
      for select
      to authenticated
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'properties'
      and policyname = 'Owners can insert properties'
  ) then
    create policy "Owners can insert properties"
      on public.properties
      for insert
      to authenticated
      with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'properties'
      and policyname = 'Owners can update properties'
  ) then
    create policy "Owners can update properties"
      on public.properties
      for update
      to authenticated
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'properties'
      and policyname = 'Owners can delete properties'
  ) then
    create policy "Owners can delete properties"
      on public.properties
      for delete
      to authenticated
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'property_images'
      and policyname = 'Property images are readable'
  ) then
    create policy "Property images are readable"
      on public.property_images
      for select
      to anon, authenticated
      using (
        exists (
          select 1
          from public.properties p
          where p.id = property_id
            and (p.status = 'approved' or p.user_id = auth.uid())
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'property_images'
      and policyname = 'Owners can insert property images'
  ) then
    create policy "Owners can insert property images"
      on public.property_images
      for insert
      to authenticated
      with check (
        exists (
          select 1
          from public.properties p
          where p.id = property_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'property_images'
      and policyname = 'Owners can delete property images'
  ) then
    create policy "Owners can delete property images"
      on public.property_images
      for delete
      to authenticated
      using (
        exists (
          select 1
          from public.properties p
          where p.id = property_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'property_amenities'
      and policyname = 'Property amenities are readable'
  ) then
    create policy "Property amenities are readable"
      on public.property_amenities
      for select
      to anon, authenticated
      using (
        exists (
          select 1
          from public.properties p
          where p.id = property_id
            and (p.status = 'approved' or p.user_id = auth.uid())
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'property_amenities'
      and policyname = 'Owners can insert property amenities'
  ) then
    create policy "Owners can insert property amenities"
      on public.property_amenities
      for insert
      to authenticated
      with check (
        exists (
          select 1
          from public.properties p
          where p.id = property_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'property_amenities'
      and policyname = 'Owners can delete property amenities'
  ) then
    create policy "Owners can delete property amenities"
      on public.property_amenities
      for delete
      to authenticated
      using (
        exists (
          select 1
          from public.properties p
          where p.id = property_id
            and p.user_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'favorites'
      and policyname = 'Users can read their favorites'
  ) then
    create policy "Users can read their favorites"
      on public.favorites
      for select
      to authenticated
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'favorites'
      and policyname = 'Users can insert their favorites'
  ) then
    create policy "Users can insert their favorites"
      on public.favorites
      for insert
      to authenticated
      with check (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'favorites'
      and policyname = 'Users can delete their favorites'
  ) then
    create policy "Users can delete their favorites"
      on public.favorites
      for delete
      to authenticated
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Public can read property images'
  ) then
    create policy "Public can read property images"
      on storage.objects
      for select
      to anon, authenticated
      using (bucket_id = 'property-images');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Authenticated users can upload property images'
  ) then
    create policy "Authenticated users can upload property images"
      on storage.objects
      for insert
      to authenticated
      with check (bucket_id = 'property-images');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Authenticated users can update property images'
  ) then
    create policy "Authenticated users can update property images"
      on storage.objects
      for update
      to authenticated
      using (bucket_id = 'property-images')
      with check (bucket_id = 'property-images');
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Authenticated users can delete property images'
  ) then
    create policy "Authenticated users can delete property images"
      on storage.objects
      for delete
      to authenticated
      using (bucket_id = 'property-images');
  end if;
end
$$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'property-images',
  'property-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
