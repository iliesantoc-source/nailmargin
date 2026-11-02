import { createClient } from "npm:@supabase/supabase-js@2.57.4";
const client=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,{auth:{persistSession:false,autoRefreshToken:false}});
const hash=async(s:string)=>Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256",new TextEncoder().encode(s)))).map(b=>b.toString(16).padStart(2,"0")).join("");
Deno.serve(async(req:Request)=>{
 const origin=req.headers.get("origin"); const allowed=["https://nailmargin.ro","https://www.nailmargin.ro"];
 const headers:Record<string,string>={"Content-Type":"application/json","Cache-Control":"no-store","Vary":"Origin","Access-Control-Allow-Headers":"authorization, apikey, content-type, x-client-info","Access-Control-Allow-Methods":"GET, POST, OPTIONS"};
 if(origin&&allowed.includes(origin))headers["Access-Control-Allow-Origin"]=origin;
 const reply=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers});
 if(origin&&!allowed.includes(origin))return reply({error:"Origin not allowed"},403);
 if(req.method==="OPTIONS")return new Response(null,{status:204,headers});
 try{
 if(req.method==="GET"){
 const [{data,error},{data:payment,error:paymentError}]=await Promise.all([
 client.from("academy_tutorials").select("id,title,description,price_ron,cover_path").eq("published",true).eq("is_test",false).order("created_at"),
 client.from("academy_settings").select("beneficiary,bank_iban,revolut_tag,whatsapp_number").eq("id",true).single()
 ]);
 if(error||paymentError)return reply({error:"Catalog unavailable"},503);
 // The owner explicitly approved public API disclosure for client payments.
 return reply({tutorials:data,payment});
 }
 if(req.method!=="POST")return reply({error:"Method not allowed"},405);
 if(Number(req.headers.get("content-length")||0)>2048)return reply({error:"Request too large"},413);
 const raw=await req.text();if(raw.length>2048)return reply({error:"Request too large"},413);
 const {code,deviceToken,tutorialId}=JSON.parse(raw);
 if(typeof code!=="string"||!/^[a-f0-9]{64}$/i.test(code)||typeof deviceToken!=="string"||!/^[a-f0-9]{64}$/i.test(deviceToken)||typeof tutorialId!=="string"||!/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(tutorialId))return reply({error:"Invalid access credentials"},400);
 // Purchase code is a high-entropy bearer credential; the browser token binds first use.
 const {data:path,error}=await client.rpc("academy_redeem_access_code",{p_code_hash:await hash(code.toLowerCase()),p_device_hash:await hash(deviceToken.toLowerCase()),p_tutorial_id:tutorialId});
 if(error||!path)return reply({error:"Access denied"},403);
 const {data,error:signError}=await client.storage.from("academy-videos").createSignedUrl(path,300);
 if(signError||!data)return reply({error:"Video unavailable"},503);
 return reply({url:data.signedUrl,expiresIn:300});
 }catch{return reply({error:"Invalid request"},400);}
});