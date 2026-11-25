create table public.farm_assistant_quota (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_start timestamptz not null,
  requests integer not null
);

alter table public.farm_assistant_quota enable row level security;
revoke all on public.farm_assistant_quota from anon, authenticated;
grant select, insert, update on public.farm_assistant_quota to service_role;

create function public.consume_farm_assistant_quota(request_user uuid)
returns boolean
language sql
set search_path = ''
as $$
  with usage as (
    insert into public.farm_assistant_quota as quota
      (user_id, window_start, requests)
    values (request_user, now(), 1)
    on conflict (user_id) do update set
      requests = case when quota.window_start <= now() - interval '1 hour'
        then 1 else quota.requests + 1 end,
      window_start = case when quota.window_start <= now() - interval '1 hour'
        then now() else quota.window_start end
    where quota.requests < 20
      or quota.window_start <= now() - interval '1 hour'
    returning 1
  )
  select exists (select 1 from usage);
$$;

revoke all on function public.consume_farm_assistant_quota(uuid) from public, anon, authenticated;
grant execute on function public.consume_farm_assistant_quota(uuid) to service_role;
