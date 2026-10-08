import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,readFileSync,rmSync,writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const script=fileURLToPath(new URL('../generate-env.mjs',import.meta.url));
for (const [name,file,processValue,expected] of [
 ['defaults without dotenv',null,null,'/api'],
 ['environment overrides dotenv','TRACKER_API_BASE_URL=/wrong','/custom','/custom'],
 ['quotes are safe','TRACKER_API_BASE_URL="/api"',null,'/api']
]) test(name,()=>{
 const cwd=mkdtempSync(join(tmpdir(),'tracker-env-'));
 try{
  if(file)writeFileSync(join(cwd,'.env'),file);
  const env={...process.env};delete env.TRACKER_API_BASE_URL;if(processValue)env.TRACKER_API_BASE_URL=processValue;
  const result=spawnSync(process.execPath,[script],{cwd,env,encoding:'utf8'});
  assert.equal(result.status,0,result.stderr);
  assert.ok(readFileSync(join(cwd,'src/environments/environment.generated.ts'),'utf8').includes(JSON.stringify(expected)));
 }finally{rmSync(cwd,{recursive:true,force:true});}
});
