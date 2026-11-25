create table public.seller_profiles (
  owner_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  display_name text not null check (char_length(btrim(display_name)) between 1 and 80),
  area text not null check (char_length(btrim(area)) between 1 and 80)
);

alter table public.seller_profiles enable row level security;
revoke all on public.seller_profiles from anon, authenticated;
grant select, insert, update on public.seller_profiles to authenticated;
create policy "Signed-in users can read seller profiles"
  on public.seller_profiles for select to authenticated using (true);
create policy "Create your seller profile"
  on public.seller_profiles for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy "Edit your seller profile"
  on public.seller_profiles for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create table public.produce_enquiries (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  seller_id uuid not null,
  listing_date timestamptz not null,
  topic text not null check (topic in ('Availability', 'Quantity', 'Pickup')),
  question text not null check (char_length(btrim(question)) between 1 and 500),
  created_at timestamptz not null default now(),
  reply text check (char_length(btrim(reply)) between 1 and 500),
  unique (buyer_id, seller_id, listing_date, topic),
  check (buyer_id <> seller_id),
  foreign key (seller_id, listing_date)
    references public.produce_listings (owner_id, draft_created_at) on delete cascade
);

alter table public.produce_enquiries enable row level security;
revoke all on public.produce_enquiries from anon, authenticated;
grant select on public.produce_enquiries to authenticated;
grant insert (seller_id, listing_date, topic, question) on public.produce_enquiries to authenticated;
grant update (reply) on public.produce_enquiries to authenticated;

create policy "Read your produce enquiries"
  on public.produce_enquiries for select to authenticated
  using ((select auth.uid()) in (buyer_id, seller_id));
create policy "Enquire about published produce"
  on public.produce_enquiries for insert to authenticated
  with check (
    buyer_id = (select auth.uid()) and exists (
      select 1 from public.produce_listings as listing
      where listing.owner_id = seller_id
        and listing.draft_created_at = listing_date
        and listing.published
    )
  );
create policy "Reply once as the seller"
  on public.produce_enquiries for update to authenticated
  using (seller_id = (select auth.uid()) and reply is null)
  with check (seller_id = (select auth.uid()) and reply is not null);

create index produce_enquiries_seller_created_idx
  on public.produce_enquiries (seller_id, created_at desc);
create index produce_enquiries_buyer_created_idx
  on public.produce_enquiries (buyer_id, created_at desc);
