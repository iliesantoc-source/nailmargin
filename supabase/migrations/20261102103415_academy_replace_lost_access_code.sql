
create function public.academy_replace_access_code(p_code_id uuid) returns text language plpgsql security invoker set search_path='' as $$
declare v_code text;
begin
 if not public.is_academy_admin() then raise exception 'Administrator required' using errcode='42501';end if;
 perform 1 from public.academy_access_codes c join public.academy_purchases p on p.id=c.purchase_id where c.id=p_code_id and p.payment_status='confirmed' for update of c,p;
 if not found then raise exception 'Confirmed purchase required';end if;
 v_code:=replace(gen_random_uuid()::text,'-','')||replace(gen_random_uuid()::text,'-','');
 update public.academy_access_codes set code_hash=encode(sha256(convert_to(v_code,'UTF8')),'hex'),device_hash=null,redeemed_at=null,revoked_at=null where id=p_code_id;
 return v_code;
end;$$;
revoke all on function public.academy_replace_access_code(uuid) from public,anon;
grant execute on function public.academy_replace_access_code(uuid) to authenticated;

