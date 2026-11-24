create schema if not exists farma_private;
revoke all on schema farma_private from public, anon, authenticated;

create table farma_private.signup_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique check (username ~ '^[a-z0-9_]{3,24}$'),
  full_name text not null check (char_length(full_name) between 1 and 120),
  country_code text not null check (country_code ~ '^[A-Z]{2}$'),
  phone_e164 text not null check (phone_e164 ~ '^\+[1-9][0-9]{6,14}$')
);

alter table farma_private.signup_profiles enable row level security;
revoke all on farma_private.signup_profiles from public, anon, authenticated;

-- Only Farma registrations use this metadata contract. Existing accounts and
-- invitations from other Auth flows may sign in without a profile.
create function farma_private.record_signup_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.raw_user_meta_data->>'farma_registration' = '1' then
    insert into farma_private.signup_profiles
      (user_id, username, full_name, country_code, phone_e164)
    values
      (new.id,
       lower(btrim(new.raw_user_meta_data->>'username')),
       btrim(new.raw_user_meta_data->>'full_name'),
       upper(btrim(new.raw_user_meta_data->>'country_code')),
       btrim(new.raw_user_meta_data->>'phone_e164'));
  end if;
  return new;
end;
$$;

revoke all on function farma_private.record_signup_profile() from public, anon, authenticated;
create trigger farma_record_signup_profile
after insert on auth.users
for each row execute function farma_private.record_signup_profile();
