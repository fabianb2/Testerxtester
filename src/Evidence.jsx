import React,{useState} from 'react';
export default function Evidence({db,path}) {
 const [url,setUrl]=useState(''),[error,setError]=useState(''),[busy,setBusy]=useState(false);
 async function open(){setBusy(true);setError('');try{if(!db){setUrl(path);return}const {data,error}=await db.storage.from('test-evidence').createSignedUrl(path,300);if(error)throw error;setUrl(data.signedUrl)}catch{setError('No se pudo abrir la captura. Intenta nuevamente.')}finally{setBusy(false)}}
 return <div className="evidence"><button type="button" disabled={busy} onClick={open}>{busy?'Abriendo…':url?'Renovar acceso a captura':'Ver captura de prueba'}</button>{url&&<a href={url} target="_blank" rel="noopener noreferrer"><img src={url} alt="Captura aportada por el tester" loading="lazy" onError={()=>{setUrl('');setError('El acceso caducó o no se pudo cargar. Pulsa Ver captura nuevamente.')}}/></a>}{error&&<p role="status">{error}</p>}</div>;
}
