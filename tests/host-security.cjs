const fs=require('node:fs');
const vm=require('node:vm');
const assert=require('node:assert/strict');
const html=fs.readFileSync(__dirname+'/../host.html','utf8');
const script=html.match(/<script>\s*([\s\S]*?)<\/script>/)[1];
new vm.Script(script);
function setup(answer){
  const elements=new Map();
  function el(selector){if(!elements.has(selector))elements.set(selector,{value:'',textContent:'',innerHTML:'',disabled:false,dataset:{},classList:{values:new Set(selector==='#lobby'?['hidden']:[]),add(v){this.values.add(v)},remove(v){this.values.delete(v)},toggle(){}}});return elements.get(selector)}
  const calls=[];
  const ctx={document:{querySelector:el,querySelectorAll:()=>[]},location:{origin:'https://test.invalid',pathname:'/host.html'},supabase:{createClient:()=>({rpc:async(name,args)=>{calls.push({name,args});return name==='authenticate_workshop_host'?answer:{data:[],error:null}}})},QRCode:Object.assign(function(){},{CorrectLevel:{M:1}}),setTimeout:()=>1,clearTimeout(){},setInterval(){},console,Date,Intl};
  ctx.window=ctx;vm.createContext(ctx);vm.runInContext(script,ctx);
  return {ctx,el,calls};
}
(async()=>{
  for(const answer of [{data:false,error:null},{data:null,error:{message:'offline'}}]){
    const t=setup(answer);assert.equal(t.calls.length,0,'no polling before authentication');
    t.el('#hostCodeInput').value='invalid-input';await t.el('#hostAuthForm').onsubmit({preventDefault(){}});
    assert.deepEqual(t.calls.map(c=>c.name),['authenticate_workshop_host']);
    assert(t.el('#lobby').classList.values.has('hidden'),'invalid/error auth must keep lobby locked');
    await t.el('#enterConsole').onclick();assert.equal(t.calls.length,1,'invalid auth cannot mutate room');
  }
  const t=setup({data:true,error:null});t.el('#hostCodeInput').value='test-only-private-host-code';
  await t.el('#hostAuthForm').onsubmit({preventDefault(){}});
  assert(!t.el('#lobby').classList.values.has('hidden'),'server-approved host can enter lobby');
  assert.equal(t.el('#hostCodeInput').value,'','credential cleared from input');
  assert(t.calls.some(c=>c.name==='get_workshop_participants'&&c.args.p_host_key==='test-only-private-host-code'));
  await t.el('#enterConsole').onclick();assert(t.el('#console').classList.values.has('hidden')===false);
  // A failed mutation returns [] here and must not mark the host as entered.
  assert.equal(vm.runInContext('entered',t.ctx),false,'false/non-boolean RPC result cannot open console');
  assert(!/HOST_KEY\s*=\s*['"][^'"]+['"]/.test(script),'no embedded host credential');
  console.log('PASS: locked startup, invalid/server-error denial, approved authentication, credential clearing, failed mutation denial, no embedded credential');
})().catch(e=>{console.error(e);process.exit(1)});
