-- Requiere 07-feedback-evidence.sql. No borra archivos al ejecutar esta consulta.
begin;
alter table public.feedback add column if not exists screenshot_deleted_at timestamptz;
create or replace function public.validate_feedback_evidence() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if tg_op='UPDATE' and auth.role()='service_role' and new.screenshot_path is null then return new; end if;
 if new.screenshot_path is null or new.screenshot_path not like new.app_id::text || '/' || new.user_id::text || '/%' then
   raise exception 'Adjunta una captura válida de la app instalada o en uso';
 end if;
 if not exists(select 1 from storage.objects where bucket_id='test-evidence' and name=new.screenshot_path) then
   raise exception 'La captura no se encuentra en el almacenamiento';
 end if;
 new.screenshot_deleted_at=null;
 return new;
end;
$$;
create or replace function public.feedback_timestamp() returns trigger language plpgsql set search_path='' as $$
begin
 if tg_op='UPDATE' and auth.role()='service_role' and new.screenshot_path is null then
   new.updated_at=old.updated_at;
 else new.updated_at=now(); end if;
 return new;
end;
$$;
create or replace function public.expired_evidence() returns table(path text)
language sql security definer set search_path='' as $$
 select name from storage.objects where bucket_id='test-evidence' and created_at<=now()-interval '48 hours'
 order by created_at limit 100;
$$;
create or replace function public.mark_evidence_deleted(deleted_paths text[]) returns void
language plpgsql security definer set search_path='' as $$
begin
 update public.feedback set screenshot_path=null,screenshot_deleted_at=now()
 where screenshot_path=any(deleted_paths)
 and not exists(select 1 from storage.objects where bucket_id='test-evidence' and name=screenshot_path);
end;
$$;
revoke all on function public.expired_evidence(),public.mark_evidence_deleted(text[]) from public,anon,authenticated;
grant execute on function public.expired_evidence(),public.mark_evidence_deleted(text[]) to service_role;
create or replace function public.reconcile_deleted_evidence() returns void
language plpgsql security definer set search_path='' as $$
begin
 update public.feedback set screenshot_path=null,screenshot_deleted_at=now()
 where screenshot_path is not null
 and not exists(select 1 from storage.objects where bucket_id='test-evidence' and name=screenshot_path);
end;
$$;
revoke all on function public.reconcile_deleted_evidence() from public,anon,authenticated;
grant execute on function public.reconcile_deleted_evidence() to service_role;
commit;
