const {createClient}=supabase;
const client=createClient(window.SUPABASE_URL,window.SUPABASE_PUBLISHABLE_KEY);
const $=id=>document.getElementById(id);
const state={orders:[],packages:[],settings:{}};

function esc(v){return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[m]));}
function showMsg(text,ok=false,target='dashMsg'){const e=$(target);if(e)e.innerHTML=`<div class="msg ${ok?'ok':'err'}">${esc(text)}</div>`;}
async function requireAdmin(user){
  const {data,error}=await client.from('profiles').select('role').eq('id',user.id).single();
  if(error||!data||data.role!=='admin'){
    await client.auth.signOut(); showMsg('এই account-এর Admin access নেই।','loginMsg'); return false;
  }
  $('who').textContent=user.email||user.id;$('loginCard').classList.add('hidden');$('dashboard').classList.remove('hidden');
  await loadAll(); return true;
}
async function loadAll(){await Promise.all([loadOrders(),loadPackages(),loadSettings()]);renderOverview();}
async function loadOrders(){
  let q=client.from('orders').select('*').order('created_at',{ascending:false}).limit(200);
  let {data,error}=await q;
  if(error){showMsg('Orders load হয়নি: '+error.message);return;}
  state.orders=data||[]; renderOrders();
}
async function loadPackages(){
  let {data,error}=await client.from('packages').select('*').order('sort_order',{ascending:true});
  if(error){showMsg('Packages load হয়নি: '+error.message);return;}
  state.packages=data||[]; renderPackages();
}
async function loadSettings(){
  let {data,error}=await client.from('site_settings').select('*').eq('id',1).maybeSingle();
  if(error){showMsg('Website settings load হয়নি: '+error.message);return;}
  state.settings=data||{}; fillSettings();
}
function renderOverview(){
  const count=s=>state.orders.filter(o=>o.status===s).length;
  $('sPending').textContent=count('pending');$('sProcessing').textContent=count('processing');$('sCompleted').textContent=count('completed');$('sCancelled').textContent=count('cancelled');
  $('recent').innerHTML=state.orders.slice(0,8).map(o=>`<div class="package"><b>${esc(o.order_code||o.id)}</b> — ${esc(o.customer_name||'')}</div>`).join('')||'<p class="muted">কোনো order নেই।</p>';
}
function renderOrders(){
  $('ordersBody').innerHTML=state.orders.map(o=>{
    const payment=o.transaction_id?`<b>TX:</b> ${esc(o.transaction_id)}`:'TX নেই';
    return `<tr>
      <td><b>${esc(o.order_code||String(o.id).slice(0,8))}</b><br><small>${esc(new Date(o.created_at).toLocaleString())}</small></td>
      <td>${esc(o.customer_name)}<br>${esc(o.customer_phone)}</td>
      <td><b>UID:</b> ${esc(o.uid)}<br><b>Code:</b> ${esc(o.game_code)}</td>
      <td>${payment}</td>
      <td><select data-status="${esc(o.id)}"><option value="pending" ${o.status==='pending'?'selected':''}>Pending</option><option value="processing" ${o.status==='processing'?'selected':''}>Processing</option><option value="completed" ${o.status==='completed'?'selected':''}>Completed</option><option value="cancelled" ${o.status==='cancelled'?'selected':''}>Cancelled</option></select></td>
      <td><button class="secondary" data-save-order="${esc(o.id)}">Save</button></td>
    </tr>`;
  }).join('')||'<tr><td colspan="6">কোনো order নেই।</td></tr>';
  document.querySelectorAll('[data-save-order]').forEach(b=>b.onclick=()=>updateOrder(b.dataset.saveOrder));
}
async function updateOrder(id){
  const sel=document.querySelector(`[data-status="${CSS.escape(id)}"]`);const status=sel.value;
  const {error}=await client.from('orders').update({status}).eq('id',id);
  if(error){showMsg('Order update হয়নি: '+error.message);return;}
  showMsg('Order status আপডেট হয়েছে।',true);await loadOrders();renderOverview();
}
function fillSettings(){
  const s=state.settings;
  ['site_name','owner_name','owner_role','payment_number','nagad_number','whatsapp_number','support_email','notice_text','hero_badge','hero_title','hero_text','about_title','about_text','seo_description'].forEach(k=>{if($(k))$(k).value=s[k]||'';});
}
async function saveSettings(){
  const payload={id:1};
  ['site_name','owner_name','owner_role','payment_number','nagad_number','whatsapp_number','support_email','notice_text','hero_badge','hero_title','hero_text','about_title','about_text','seo_description'].forEach(k=>payload[k]=$(k).value.trim());
  const {error}=await client.from('site_settings').upsert(payload,{onConflict:'id'});
  if(error){showMsg('Settings save হয়নি: '+error.message);return;}showMsg('Website settings সংরক্ষণ হয়েছে।',true);
}
function renderPackages(){
  $('packagesBox').innerHTML=state.packages.map((p,i)=>`<div class="package" data-p="${esc(p.id)}">
    <div class="grid2">
      <label>Name<input data-k="name" value="${esc(p.name??p.title??'')}"></label>
      <label>Diamonds<input data-k="diamonds" value="${esc(p.diamonds??'')}"></label>
      <label>Price<input data-k="price" value="${esc(p.price??'')}"></label>
      <label>Sort Order<input data-k="sort_order" type="number" value="${esc(p.sort_order??i)}"></label>
      <label>Active<select data-k="active"><option value="true" ${(p.active!==false)?'selected':''}>Yes</option><option value="false" ${p.active===false?'selected':''}>No</option></select></label>
    </div>
    <div class="package-actions"><button class="primary" data-save-package="${esc(p.id)}">💾 Save</button><button class="danger" data-delete-package="${esc(p.id)}">Delete</button></div>
  </div>`).join('')||'<p class="muted">কোনো package নেই।</p>';
  document.querySelectorAll('[data-save-package]').forEach(b=>b.onclick=()=>savePackage(b.dataset.savePackage));
  document.querySelectorAll('[data-delete-package]').forEach(b=>b.onclick=()=>deletePackage(b.dataset.deletePackage));
}
function packagePayload(box){
  const get=k=>box.querySelector(`[data-k="${k}"]`).value;
  return {name:get('name').trim(),title:get('name').trim(),diamonds:get('diamonds').trim(),price:get('price').trim(),sort_order:Number(get('sort_order')||0),active:get('active')==='true'};
}
async function savePackage(id){
  const box=document.querySelector(`[data-p="${CSS.escape(id)}"]`);const payload=packagePayload(box);
  let {error}=await client.from('packages').update(payload).eq('id',id);
  if(error){
    const fallback={title:payload.title,diamonds:payload.diamonds,price:payload.price,sort_order:payload.sort_order,active:payload.active};
    const r=await client.from('packages').update(fallback).eq('id',id);error=r.error;
  }
  if(error){showMsg('Package save হয়নি: '+error.message);return;}showMsg('Package আপডেট হয়েছে।',true);await loadPackages();
}
async function deletePackage(id){
  if(!confirm('এই package মুছে ফেলবেন?'))return;
  const {error}=await client.from('packages').delete().eq('id',id);
  if(error){showMsg('Delete হয়নি: '+error.message);return;}showMsg('Package মুছে ফেলা হয়েছে।',true);await loadPackages();
}
async function addPackage(){
  const base={title:'New Package',name:'New Package',diamonds:'0💎',price:'0 Tk',active:true,sort_order:state.packages.length+1};
  let {error}=await client.from('packages').insert(base);
  if(error){
    const r=await client.from('packages').insert({title:base.title,diamonds:base.diamonds,price:base.price,active:true,sort_order:base.sort_order});error=r.error;
  }
  if(error){showMsg('নতুন package যোগ হয়নি: '+error.message);return;}showMsg('নতুন package যোগ হয়েছে।',true);await loadPackages();
}
async function uploadPhoto(){
  const f=$('adminPhoto').files[0];if(!f){showMsg('আগে একটি ছবি নির্বাচন করুন।',false,'photoMsg');return;}
  const path='admin/admin.png';const {error}=await client.storage.from('admin-photos').upload(path,f,{upsert:true,contentType:f.type});
  if(error){showMsg('Photo upload হয়নি: '+error.message,false,'photoMsg');return;}
  const {data}=client.storage.from('admin-photos').getPublicUrl(path);
  const url=data.publicUrl+'?v='+Date.now();
  const r=await client.from('site_settings').upsert({id:1,admin_photo_url:url},{onConflict:'id'});
  if(r.error){showMsg('Photo uploaded, কিন্তু settings save হয়নি: '+r.error.message,false,'photoMsg');return;}
  showMsg('Admin photo সফলভাবে আপডেট হয়েছে।',true,'photoMsg');
}
async function changePassword(){
  const p=$('newPassword').value;if(p.length<8){showMsg('Password কমপক্ষে ৮ অক্ষরের দিন.');return;}
  const {error}=await client.auth.updateUser({password:p});if(error){showMsg(error.message);return;}
  $('newPassword').value='';showMsg('Password সফলভাবে পরিবর্তন হয়েছে।',true);
}

document.querySelectorAll('[data-tab]').forEach(b=>b.onclick=()=>{
  document.querySelectorAll('.tabs button').forEach(x=>x.classList.remove('active'));b.classList.add('active');
  document.querySelectorAll('[id^="tab-"]').forEach(x=>x.classList.add('hidden'));$('tab-'+b.dataset.tab).classList.remove('hidden');
});
$('login').onclick=async()=>{const email=$('email').value.trim(),password=$('password').value;const {data,error}=await client.auth.signInWithPassword({email,password});if(error){showMsg('Login failed: '+error.message,false,'loginMsg');return}await requireAdmin(data.user);};
$('logout').onclick=async()=>{await client.auth.signOut();location.reload();};
$('refresh').onclick=loadAll;$('saveSettings').onclick=saveSettings;$('addPackage').onclick=addPackage;$('uploadPhoto').onclick=uploadPhoto;$('changePassword').onclick=changePassword;
(async()=>{const {data:{session}}=await client.auth.getSession();if(session)await requireAdmin(session.user);})();