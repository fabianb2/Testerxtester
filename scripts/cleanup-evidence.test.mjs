import {test} from 'node:test';
import assert from 'node:assert/strict';
import {cleanup} from './cleanup-evidence.mjs';
const config={url:'https://example.supabase.co',key:'server-test-key'};
test('borra por Storage antes de actualizar referencias y reconcilia',async()=>{
 const calls=[];let candidates=0;
 const count=await cleanup({...config,request:async(url,options)=>{
  calls.push([url.pathname,options.method,JSON.parse(options.body)]);
  const data=url.pathname.endsWith('expired_evidence')?(candidates++===0?[{path:'app/user/capture.webp'}]:[]):null;
  return {ok:true,status:200,json:async()=>data};
 }});
 assert.equal(count,1);assert.equal(calls[1][0],'/storage/v1/object/test-evidence');assert.equal(calls[1][1],'DELETE');
 assert.deepEqual(calls[1][2],{prefixes:['app/user/capture.webp']});assert.equal(calls[2][0],'/rest/v1/rpc/mark_evidence_deleted');assert.equal(calls.at(-1)[0],'/rest/v1/rpc/reconcile_deleted_evidence');
});
test('no borra referencias si falla el almacenamiento',async()=>{
 const calls=[];
 await assert.rejects(cleanup({...config,request:async(url)=>{calls.push(url.pathname);return url.pathname.endsWith('expired_evidence')?{ok:true,status:200,json:async()=>[{path:'app/user/image.webp'}]}:{ok:false,status:500}}}));
 assert.equal(calls.length,2);assert.equal(calls.some(path=>path.endsWith('mark_evidence_deleted')),false);
});
test('sin credenciales no realiza peticiones',async()=>{
 await assert.rejects(cleanup({url:config.url,request:()=>{throw Error('No debe llamarse')}}),/Faltan/);
});
