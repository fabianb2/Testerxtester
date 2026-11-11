begin;
create table if not exists public.feedback (
 app_id uuid not null references public.apps(id) on delete cascade,
 user_id uuid not null references public.members(id) on delete cascade,
 display_name text not null,
 body text not null check(length(trim(body)) between 10 and 2000),
 updated_at timestamptz not null default now(),
 primary key(app_id,user_id)
);
alter table public.feedback enable row level security;
revoke all on public.feedback from public,anon,authenticated;
grant select,insert on public.feedback to authenticated;
grant update(body,display_name) on public.feedback to authenticated;
-- Upsert también escribe las claves, sin poder cambiar de autor gracias a RLS.
grant update(app_id,user_id) on public.feedback to authenticated;
create or replace function public.feedback_timestamp() returns trigger language plpgsql set search_path='' as $$
begin new.updated_at=now(); return new; end;
$$;
revoke all on function public.feedback_timestamp() from public,anon,authenticated;
drop trigger if exists feedback_timestamp on public.feedback;
create trigger feedback_timestamp before insert or update on public.feedback for each row execute function public.feedback_timestamp();
drop policy if exists feedback_read on public.feedback;
create policy feedback_read on public.feedback for select to authenticated using(public.is_member());
drop policy if exists feedback_insert on public.feedback;
create policy feedback_insert on public.feedback for insert to authenticated with check (
 public.is_member() and user_id=auth.uid()
 and display_name=(select display_name from public.members where id=auth.uid())
 and exists(select 1 from public.participants where app_id=feedback.app_id and user_id=auth.uid())
);
drop policy if exists feedback_update on public.feedback;
create policy feedback_update on public.feedback for update to authenticated
 using(public.is_member() and user_id=auth.uid())
 with check(public.is_member() and user_id=auth.uid()
 and display_name=(select display_name from public.members where id=auth.uid())
 and exists(select 1 from public.participants where app_id=feedback.app_id and user_id=auth.uid()));
commit;
