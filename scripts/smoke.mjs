// Creates two test users in the selected deployment; see README before running.
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
import {execFileSync} from 'node:child_process';
const require=createRequire(new URL('../app/package.json',import.meta.url));
const {chromium}=require('playwright');
const base=(process.env.TRACKER_URL || 'http://localhost:8080').replace(/\/$/,'');
const suffix=Date.now().toString(36);
const first=`smoke-a-${suffix}`,second=`smoke-b-${suffix}`,password='Smoke-pass-1234!';
const browser=await chromium.launch({headless:true});
try {
 const a=await browser.newContext({baseURL:base,extraHTTPHeaders:{Origin:new URL(base).origin}});
 const b=await browser.newContext({baseURL:base,extraHTTPHeaders:{Origin:new URL(base).origin}});
 const page=await a.newPage();await page.goto('/');await page.waitForLoadState('networkidle');assert.match(await page.title(),/tracker/i);
 async function api(ctx,method,path,data) {
  const r=await ctx.request.fetch(`/api${path}`,{method,data});assert.ok(r.ok(),`${method} ${path}: ${r.status()} ${await r.text()}`);return (await r.json()).data;
 }
 const ua=await api(a,'POST','/user/register',{username:first,password});
 const ub=await api(b,'POST','/user/register',{username:second,password});
 await api(a,'POST','/auth/login',{username:first,password});await api(b,'POST','/auth/login',{username:second,password});
 const cookies=await a.cookies();assert.ok(cookies.find(c=>c.name==='token'&&c.httpOnly));
 const record=await api(a,'POST','/user/record',{title:'makan siang di warteg',description:'smoke test',amount:1000,date:new Date().toISOString().slice(0,10)});
 assert.equal(record.isCommitted,false);assert.ok(record.categories.some(c=>c.type==='primary'));
 await api(a,'PUT','/user/record/commit',{recordId:record.id,category:'makanan',secondaryCategory:'jajanan'});
 assert.equal((await api(a,'GET','/user/records')).cash,-1000);
 const repeated=await a.request.put('/api/user/record/commit',{data:{recordId:record.id}});assert.equal(repeated.status(),409);
 await api(a,'POST','/user/friend/add',{friendId:ub.id});const requests=await api(b,'GET','/user/friend/request');
 await api(b,'PUT','/user/friend/request/response',{friendRequestId:requests.find(r=>r.sender.id===ua.id).id,action:'accept'});
 assert.ok((await api(a,'GET','/user/friend')).some(f=>f.id===ub.id));
 const debt=await api(a,'POST','/debt/create',{amount:2000,description:'smoke loan',debtorId:ub.id});await api(b,'PUT','/debt/finish',{debtId:debt.id});
 const overview=await api(a,'GET','/user/records');assert.equal(overview.cash,-1000);assert.equal(overview.receivable,0);
 const debtor=await api(b,'GET','/user/records');assert.equal(debtor.cash,-2000);assert.equal(debtor.debt,0);
 await api(a,'PUT','/user/profile',{username:`${first}-renamed`});await api(a,'GET','/auth/validate-session');
 await page.goto('/dashboard');await page.waitForLoadState('networkidle');assert.ok(!page.url().endsWith('/login'));
 if(process.env.TRACKER_CHECK_RESTART==='1') {
  execFileSync('docker',['compose','up','-d','--no-deps','--force-recreate','--wait','backend'],{stdio:'inherit'});
  let recovered=false;
  for(let i=0;i<30;i++) {
   const r=await a.request.get('/api/user/profile');
   if(r.ok()) {assert.equal((await r.json()).data.username,`${first}-renamed`);recovered=true;break;}
   await new Promise(resolve=>setTimeout(resolve,1000));
  }
  assert.ok(recovered,'Frontend proxy must recover after backend replacement');
  assert.equal((await api(a,'GET','/user/records')).cash,-1000);
 }
 await api(a,'POST','/auth/logout');assert.equal((await a.request.get('/api/auth/validate-session')).status(),401);
 console.log(`Smoke passed. Test users: ${first}-renamed and ${second}.`);
} finally {await browser.close();}
