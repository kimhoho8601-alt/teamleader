create extension if not exists pgcrypto;

create table if not exists public.workshop_rooms (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[A-Z0-9]{5,8}$'),
  host_key text not null,
  title text not null default '팀장 인터뷰',
  active_question integer not null default 1 check (active_question between 1 and 3),
  is_open boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.workshop_responses (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.workshop_rooms(id) on delete cascade,
  participant_id text not null,
  nickname text,
  question_no integer not null check (question_no between 1 and 3),
  content text not null check (char_length(content) between 1 and 800),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(room_id, participant_id, question_no)
);

alter table public.workshop_rooms enable row level security;
alter table public.workshop_responses enable row level security;
revoke all on public.workshop_rooms from anon, authenticated;
revoke all on public.workshop_responses from anon, authenticated;

create or replace function public.create_workshop(p_code text, p_host_key text, p_title text default '팀장 인터뷰')
returns boolean language plpgsql security definer set search_path = public as $$
begin
  insert into public.workshop_rooms(code, host_key, title)
  values (upper(trim(p_code)), p_host_key, coalesce(nullif(trim(p_title), ''), '팀장 인터뷰'))
  on conflict (code) do nothing;
  return true;
end; $$;

create or replace function public.get_workshop_state(p_code text)
returns table(code text, title text, active_question integer, is_open boolean)
language sql security definer set search_path = public stable as $$
  select r.code, r.title, r.active_question, r.is_open
  from public.workshop_rooms r
  where r.code = upper(trim(p_code))
  limit 1;
$$;

create or replace function public.set_workshop_question(p_code text, p_host_key text, p_question integer)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if p_question not between 1 and 3 then return false; end if;
  update public.workshop_rooms set active_question = p_question
  where code = upper(trim(p_code)) and host_key = p_host_key;
  return found;
end; $$;

create or replace function public.set_workshop_open(p_code text, p_host_key text, p_is_open boolean)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  update public.workshop_rooms set is_open = p_is_open
  where code = upper(trim(p_code)) and host_key = p_host_key;
  return found;
end; $$;

create or replace function public.submit_workshop_response(
  p_code text,
  p_participant_id text,
  p_question integer,
  p_content text,
  p_nickname text default null
)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_room_id uuid; v_id uuid;
begin
  if p_question not between 1 and 3 or char_length(trim(p_content)) = 0 or char_length(trim(p_content)) > 800 then
    raise exception 'invalid response';
  end if;
  select id into v_room_id from public.workshop_rooms
  where code = upper(trim(p_code)) and is_open = true;
  if v_room_id is null then raise exception 'room not found or closed'; end if;
  insert into public.workshop_responses(room_id, participant_id, nickname, question_no, content)
  values (v_room_id, p_participant_id, nullif(trim(p_nickname), ''), p_question, trim(p_content))
  on conflict (room_id, participant_id, question_no)
  do update set nickname = excluded.nickname, content = excluded.content, updated_at = now()
  returning id into v_id;
  return v_id;
end; $$;

create or replace function public.get_workshop_responses(p_code text)
returns table(id uuid, participant_id text, question_no integer, content text, nickname text, created_at timestamptz, updated_at timestamptz)
language sql security definer set search_path = public stable as $$
  select wr.id, wr.participant_id, wr.question_no, wr.content, wr.nickname, wr.created_at, wr.updated_at
  from public.workshop_responses wr
  join public.workshop_rooms r on r.id = wr.room_id
  where r.code = upper(trim(p_code))
  order by wr.updated_at desc;
$$;

grant execute on function public.create_workshop(text, text, text) to anon, authenticated;
grant execute on function public.get_workshop_state(text) to anon, authenticated;
grant execute on function public.set_workshop_question(text, text, integer) to anon, authenticated;
grant execute on function public.set_workshop_open(text, text, boolean) to anon, authenticated;
grant execute on function public.submit_workshop_response(text, text, integer, text, text) to anon, authenticated;
grant execute on function public.get_workshop_responses(text) to anon, authenticated;
