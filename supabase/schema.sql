begin;
create table public.members (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null check (length(trim(display_name)) between 1 and 100),
 role text not null default 'member' check(role in ('admin','member'))
);
create function public.is_member() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.members where id=auth.uid());
$$;
create function public.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.members where id=auth.uid() and role='admin');
$$;
revoke all on function public.is_member(), public.is_admin() from public, anon;
grant execute on function public.is_member(), public.is_admin() to authenticated;
create table public.apps (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references public.members(id) on delete cascade,
 developer text not null check(length(trim(developer)) between 1 and 100),
 name text not null check(length(trim(name)) between 1 and 100),
 group_url text not null check(length(group_url)<=2048 and group_url ~ '^https?://[^[:space:]]+$'),
 accept_url text not null check(length(accept_url)<=2048 and accept_url ~ '^https?://[^[:space:]]+$'),
 app_url text not null check(length(app_url)<=2048 and app_url ~ '^https?://[^[:space:]]+$'),
 created_at timestamptz not null default now()
);
create table public.participants (
 app_id uuid not null references public.apps(id) on delete cascade,
 user_id uuid not null references public.members(id) on delete cascade,
 display_name text not null,
 created_at timestamptz not null default now(),
 primary key(app_id,user_id)
);
create index apps_owner_idx on public.apps(owner_id);
create index participants_user_idx on public.participants(user_id);
alter table public.members enable row level security;
alter table public.apps enable row level security;
alter table public.participants enable row level security;
revoke all on public.members,public.apps,public.participants from anon,authenticated;
grant select on public.members to authenticated;
grant select,insert,delete on public.apps to authenticated;
grant update(developer,name,group_url,accept_url,app_url) on public.apps to authenticated;
grant select,insert,delete on public.participants to authenticated;
create policy members_read on public.members for select to authenticated using(public.is_member());
create policy apps_read on public.apps for select to authenticated using(public.is_member());
create policy apps_insert on public.apps for insert to authenticated with check(public.is_member() and owner_id=auth.uid());
create policy apps_update on public.apps for update to authenticated using(public.is_member() and (owner_id=auth.uid() or public.is_admin())) with check(public.is_member() and (owner_id=auth.uid() or public.is_admin()));
create policy apps_delete on public.apps for delete to authenticated using(public.is_member() and (owner_id=auth.uid() or public.is_admin()));
create policy participants_read on public.participants for select to authenticated using(public.is_member());
create policy participants_insert on public.participants for insert to authenticated with check(
 public.is_member() and user_id=auth.uid() and display_name=(select display_name from public.members where id=auth.uid())
);
create policy participants_delete on public.participants for delete to authenticated using(public.is_member() and (user_id=auth.uid() or public.is_admin()));
commit;
