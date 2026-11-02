
create or replace function public.academy_confirm_purchase(p_tutorial_id uuid,p_full_name text,p_contact text,p_amount numeric) returns table(purchase_id uuid,access_code text) language plpgsql security invoker set search_path='' as $$
declare v_customer uuid; v_purchase uuid;
begin
 if not public.is_academy_admin() then raise exception 'Administrator required' using errcode='42501'; end if;
 if length(trim(p_full_name))<2 or p_amount is null or p_amount<0 then raise exception 'Invalid purchase'; end if;
 perform 1 from public.academy_tutorials where id=p_tutorial_id and published and video_path is not null;
 if not found then raise exception 'Tutorial must be ready and published'; end if;
 insert into public.academy_customers(full_name,contact) values(trim(p_full_name),nullif(trim(p_contact),'')) returning id into v_customer;
 insert into public.academy_purchases(customer_id,tutorial_id,amount_ron,payment_status,confirmed_at) values(v_customer,p_tutorial_id,p_amount,'confirmed',now()) returning id into v_purchase;
 return query select v_purchase,public.academy_issue_access_code(v_purchase);
end; $$;
revoke all on function public.academy_confirm_purchase(uuid,text,text,numeric) from public,anon;
grant execute on function public.academy_confirm_purchase(uuid,text,text,numeric) to authenticated;
create or replace function public.academy_tutorial_guard() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 new.updated_at=now();
 if new.published and (new.video_path is null or not exists(select 1 from storage.objects where bucket_id='academy-videos' and name=new.video_path)) then raise exception 'Upload video before publishing'; end if;
 return new;
end; $$;
revoke all on function public.academy_tutorial_guard() from public,anon;
create trigger academy_tutorial_guard before insert or update on public.academy_tutorials for each row execute function public.academy_tutorial_guard();
-- Payment settings are configured privately in Supabase.

