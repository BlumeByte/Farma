create table public.field_officers (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 100),
  district text not null check (char_length(btrim(district)) between 1 and 100)
);

create table public.cloud_observations (
  owner_id uuid not null references auth.users(id) on delete cascade,
  observed_at timestamptz not null,
  title text not null check (char_length(btrim(title)) between 1 and 100),
  category text not null check (char_length(category) between 1 and 80),
  notes text not null default '' check (char_length(notes) <= 1000),
  photo_base64 text check (
    char_length(photo_base64) between 16 and 1398104
    and char_length(photo_base64) % 4 = 0
    and photo_base64 ~ '^[A-Za-z0-9+/]+={0,2}$'
  ),
  photo_description text check (char_length(photo_description) <= 300),
  primary key (owner_id, observed_at)
);

create table public.observation_reviews (
  id uuid primary key default gen_random_uuid(),
  farmer_id uuid not null default auth.uid(),
  observation_date timestamptz not null,
  officer_id uuid not null references public.field_officers(id) on delete cascade,
  requested_at timestamptz not null default now(),
  follow_up text check (char_length(btrim(follow_up)) between 1 and 1000),
  check (officer_id <> farmer_id),
  unique (farmer_id, observation_date, officer_id),
  foreign key (farmer_id, observation_date)
    references public.cloud_observations (owner_id, observed_at) on delete cascade
);

alter table public.field_officers enable row level security;
alter table public.cloud_observations enable row level security;
alter table public.observation_reviews enable row level security;
revoke all on public.field_officers, public.cloud_observations, public.observation_reviews
  from anon, authenticated;
grant select on public.field_officers to authenticated;
grant select, insert, update on public.cloud_observations to authenticated;
grant select, delete on public.observation_reviews to authenticated;
grant insert (observation_date, officer_id) on public.observation_reviews to authenticated;
grant update (follow_up) on public.observation_reviews to authenticated;

create policy "Read approved officers" on public.field_officers
  for select to authenticated using (true);
create policy "Read your observation or assigned record" on public.cloud_observations
  for select to authenticated using (
    owner_id = (select auth.uid()) or exists (
      select 1 from public.observation_reviews as review
      where review.farmer_id = cloud_observations.owner_id
        and review.observation_date = cloud_observations.observed_at
        and review.officer_id = (select auth.uid())
    )
  );
create policy "Create your cloud observation" on public.cloud_observations
  for insert to authenticated with check (owner_id = (select auth.uid()));
create policy "Update your cloud observation" on public.cloud_observations
  for update to authenticated using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
create policy "Read your reviews" on public.observation_reviews
  for select to authenticated using ((select auth.uid()) in (farmer_id, officer_id));
create policy "Request review for your record" on public.observation_reviews
  for insert to authenticated with check (farmer_id = (select auth.uid()));
create policy "Withdraw your review request" on public.observation_reviews
  for delete to authenticated using (farmer_id = (select auth.uid()));
create policy "Respond as assigned officer" on public.observation_reviews
  for update to authenticated
  using (officer_id = (select auth.uid()) and follow_up is null)
  with check (officer_id = (select auth.uid()) and follow_up is not null);

create index observation_reviews_officer_requested_idx
  on public.observation_reviews (officer_id, requested_at desc);
