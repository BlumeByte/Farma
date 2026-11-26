create table public.district_managers (
  account_id uuid primary key references auth.users(id) on delete cascade,
  district text not null check (
    char_length(btrim(district)) between 1 and 100 and district = btrim(district)
  )
);

alter table public.district_managers enable row level security;
revoke all on public.district_managers from anon, authenticated;
grant select on public.district_managers to authenticated;
create policy "Read your district assignment" on public.district_managers
  for select to authenticated using (account_id = (select auth.uid()));

alter table public.field_officers add column active boolean not null default true;
create index field_officers_district_idx on public.field_officers (district);

alter policy "Read approved officers" on public.field_officers
  using (active or id = (select auth.uid()));

alter policy "Read your reviews" on public.observation_reviews
  using (
    farmer_id = (select auth.uid())
    or (officer_id = (select auth.uid()) and exists (
      select 1 from public.field_officers
      where id = (select auth.uid()) and active
    ))
  );

alter policy "Request review for your record" on public.observation_reviews
  with check (
    farmer_id = (select auth.uid()) and exists (
      select 1 from public.field_officers
      where id = officer_id and active
    )
  );

alter policy "Respond as assigned officer" on public.observation_reviews
  using (
    officer_id = (select auth.uid()) and follow_up is null and exists (
      select 1 from public.field_officers
      where id = (select auth.uid()) and active
    )
  )
  with check (
    officer_id = (select auth.uid()) and follow_up is not null and exists (
      select 1 from public.field_officers
      where id = (select auth.uid()) and active
    )
  );

create function public.district_review_summary()
returns table (
  officer_id uuid, display_name text, active boolean, awaiting bigint, completed bigint
)
language sql
stable
security definer
set search_path = ''
as $$
  select officer.id, officer.display_name, officer.active,
    count(review.id) filter (where review.follow_up is null),
    count(review.id) filter (where review.follow_up is not null)
  from public.district_managers as manager
  join public.field_officers as officer on officer.district = manager.district
  left join public.observation_reviews as review on review.officer_id = officer.id
  where manager.account_id = (select auth.uid())
  group by officer.id, officer.display_name, officer.active
  order by officer.active desc, officer.display_name, officer.id;
$$;

create function public.set_district_officer(
  target_account uuid, target_name text, target_active boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  managed_district text;
begin
  select district into managed_district
  from public.district_managers where account_id = auth.uid()
  for share;

  if managed_district is null then
    raise insufficient_privilege using message = 'A district assignment is required';
  end if;

  if target_active is null then
    raise invalid_parameter_value using message = 'Officer access state is required';
  end if;

  if target_name is null then
    update public.field_officers set active = target_active
    where id = target_account and district = managed_district;
  else
    insert into public.field_officers as officer (id, display_name, district, active)
    values (target_account, btrim(target_name), managed_district, target_active)
    on conflict (id) do update set display_name = excluded.display_name, active = excluded.active
    where officer.district = managed_district;
  end if;

  if not found then
    raise insufficient_privilege using message = 'Officer is outside your district or unavailable';
  end if;
end;
$$;

revoke all on function public.district_review_summary() from public, anon, authenticated;
revoke all on function public.set_district_officer(uuid, text, boolean) from public, anon, authenticated;
grant execute on function public.district_review_summary() to authenticated;
grant execute on function public.set_district_officer(uuid, text, boolean) to authenticated;
