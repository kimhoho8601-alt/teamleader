-- Run once in the teamleader project's SQL Editor after restoring the project.
-- This invalidates every previously published host key. It does not delete workshop data.
begin;
alter table public.workshop_rooms enable row level security;
revoke all on public.workshop_rooms from anon, authenticated;
create or replace function public.authenticate_workshop_host(p_code text, p_host_key text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.workshop_rooms r
    where r.code = upper(trim(p_code))
      and p_host_key is not null
      and length(p_host_key) >= 32
      and r.host_key = p_host_key
  );
$$;
revoke all on function public.authenticate_workshop_host(text,text) from public;
grant execute on function public.authenticate_workshop_host(text,text) to anon, authenticated;
-- UUID v4 supplies a new high-entropy, server-held shared credential.
update public.workshop_rooms set host_key = gen_random_uuid()::text;
commit;
-- Keep the following output private. Never paste the result into GitHub or a URL.
select code, host_key as new_private_host_code from public.workshop_rooms order by code;
