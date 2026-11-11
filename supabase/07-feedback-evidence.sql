-- Requiere 06-feedback.sql. Conserva los feedback existentes.
begin;
alter table public.feedback add column if not exists screenshot_path text;
grant update(screenshot_path) on public.feedback to authenticated;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('test-evidence','test-evidence',false,409600,array['image/webp'])
on conflict(id) do update set public=false,file_size_limit=409600,allowed_mime_types=array['image/webp'];
drop policy if exists evidence_upload on storage.objects;
create policy evidence_upload on storage.objects for insert to authenticated with check (
 bucket_id='test-evidence' and public.is_member()
 and (storage.foldername(name))[2]=auth.uid()::text
 and exists(select 1 from public.participants p where p.app_id::text=(storage.foldername(name))[1] and p.user_id=auth.uid())
);
drop policy if exists evidence_read on storage.objects;
create policy evidence_read on storage.objects for select to authenticated using (
 bucket_id='test-evidence' and public.is_member() and (
 (storage.foldername(name))[2]=auth.uid()::text or public.is_admin()
 or exists(select 1 from public.apps a where a.id::text=(storage.foldername(name))[1] and a.owner_id=auth.uid())
 ));
drop policy if exists evidence_cleanup on storage.objects;
create policy evidence_cleanup on storage.objects for delete to authenticated using (
 bucket_id='test-evidence' and public.is_member() and (storage.foldername(name))[2]=auth.uid()::text
 and not exists(select 1 from public.feedback f where f.screenshot_path=name)
);
create or replace function public.validate_feedback_evidence() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if new.screenshot_path is null or new.screenshot_path not like new.app_id::text || '/' || new.user_id::text || '/%' then
   raise exception 'Adjunta una captura válida de la app instalada o en uso';
 end if;
 if not exists(select 1 from storage.objects where bucket_id='test-evidence' and name=new.screenshot_path) then
   raise exception 'La captura no se encuentra en el almacenamiento';
 end if;
 return new;
end;
$$;
revoke all on function public.validate_feedback_evidence() from public,anon,authenticated;
drop trigger if exists validate_feedback_evidence on public.feedback;
create trigger validate_feedback_evidence before insert or update on public.feedback
 for each row execute function public.validate_feedback_evidence();
commit;
