create table public.produce_listings (
  owner_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  draft_created_at timestamptz not null,
  title text not null check (char_length(btrim(title)) between 1 and 100),
  category text not null check (category in ('Fruit', 'Vegetables', 'Grains', 'Other')),
  description text not null default '' check (char_length(description) <= 1000),
  published boolean not null default true,
  published_at timestamptz not null default now(),
  primary key (owner_id, draft_created_at)
);

alter table public.produce_listings enable row level security;
grant select, insert, update on public.produce_listings to authenticated;
revoke all on public.produce_listings from anon;

create policy "Read published or own listings"
  on public.produce_listings for select to authenticated
  using (published or owner_id = (select auth.uid()));
create policy "Create own listings"
  on public.produce_listings for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy "Update own listings"
  on public.produce_listings for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create index produce_listings_published_at_idx
  on public.produce_listings (published_at desc) where published;
