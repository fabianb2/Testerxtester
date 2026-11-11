import {pathToFileURL} from 'node:url';
// Ejecutar solo en servidor: nunca importar esta credencial en React/Vite.
export async function cleanup({url,key,request=fetch}) {
 if(!url||!key) throw Error('Faltan SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY.');
 const base=new URL(url);if(base.protocol!=='https:')throw Error('Se requiere HTTPS.');
 async function call(path,body,method='POST'){
  const response=await request(new URL(path,base),{method,headers:{apikey:key,Authorization:`Bearer ${key}`,'Content-Type':'application/json'},body:JSON.stringify(body)});
  if(!response.ok)throw Error(`Falló la limpieza (${response.status}). No se marcaron archivos como eliminados.`);
  return response.status===204?null:response.json();
 }
 let count=0;
 // Límite por ejecución para no bloquear el trabajo si hay muchas capturas.
 for(let batch=0;batch<20;batch++){
  const rows=await call('/rest/v1/rpc/expired_evidence',{});
  if(!Array.isArray(rows))throw Error('Respuesta de candidatos inválida.');
  const paths=rows.map(row=>row.path);
  if(!paths.length)break;
  if(paths.some(path=>typeof path!=='string'||path.split('/').length!==3))throw Error('Ruta de evidencia inválida.');
  // Storage API elimina el archivo físico. SQL por sí solo no libera espacio.
  await call('/storage/v1/object/test-evidence',{prefixes:paths},'DELETE');
  await call('/rest/v1/rpc/mark_evidence_deleted',{deleted_paths:paths});
  count+=paths.length;
 }
 // Recupera enlaces pendientes si una ejecución anterior falló después del borrado físico.
 await call('/rest/v1/rpc/reconcile_deleted_evidence',{});
 return count;
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){
 cleanup({url:process.env.SUPABASE_URL,key:process.env.SUPABASE_SERVICE_ROLE_KEY}).then(count=>console.log(`Capturas procesadas: ${count}`)).catch(()=>{console.error('Falló la limpieza de capturas. Revisa la configuración y la migración 08.');process.exitCode=1});
}
