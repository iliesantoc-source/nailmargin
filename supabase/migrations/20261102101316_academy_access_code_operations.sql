
create function public.academy_issue_access_code(p_purchase_id uuid) returns text language plpgsql security invoker set search_path='' as $$
declare v_code text;
begin
 if not public.is_academy_admin() then raise exception 'Administrator required' using errcode='42501'; end if;
 perform 1 from public.academy_purchases where id=p_purchase_id and payment_status='confirmed' for update;
 if not found then raise exception 'Confirmed purchase required'; end if;
 v_code := replace(gen_random_uuid()::text,'-','') || replace(gen_random_uuid()::text,'-','');
 insert into public.academy_access_codes(purchase_id,code_hash) values(p_purchase_id,encode(sha256(convert_to(v_code,'UTF8')),'hex'));
 return v_code;
end; $$;
revoke all on function public.academy_issue_access_code(uuid) from public,anon;
grant execute on function public.academy_issue_access_code(uuid) to authenticated;
create function public.academy_redeem_access_code(p_code_hash text,p_device_hash text,p_tutorial_id uuid) returns text language plpgsql security invoker set search_path='' as $$
declare v_record record; v_video text;
begin
 if p_code_hash !~ '^[a-f0-9]{64}$' or p_device_hash !~ '^[a-f0-9]{64}$' or p_device_hash is null then return null; end if;
 select c.id,c.device_hash into v_record from public.academy_access_codes c join public.academy_purchases p on p.id=c.purchase_id
 where c.code_hash=p_code_hash and c.revoked_at is null and p.payment_status='confirmed' and p.tutorial_id=p_tutorial_id for update of c,p;
 if not found then return null; end if;
 if v_record.device_hash is not null and v_record.device_hash<>p_device_hash then return null; end if;
 select video_path into v_video from public.academy_tutorials where id=p_tutorial_id and published and video_path is not null;
 if v_video is null then return null; end if;
 update public.academy_access_codes set device_hash=p_device_hash,redeemed_at=coalesce(redeemed_at,now()) where id=v_record.id;
 return v_video;
end; $$;
revoke all on function public.academy_redeem_access_code(text,text,uuid) from public,anon,authenticated;
grant execute on function public.academy_redeem_access_code(text,text,uuid) to service_role;

