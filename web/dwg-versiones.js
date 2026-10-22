/* PANORAMA LAB DWG Version Switch. Browser-only six-byte detection. Never transmits a drawing. */
(function(){
'use strict';
const known=Object.freeze({
AC1009:{label:'DWG R12',year:1992},
AC1012:{label:'DWG R13',year:1994},
AC1014:{label:'DWG R14',year:1997},
AC1015:{label:'DWG 2000',year:2000},
AC1018:{label:'DWG 2004',year:2004},
AC1021:{label:'DWG 2007',year:2007},
AC1024:{label:'DWG 2010',year:2010},
AC1027:{label:'DWG 2013',year:2013},
AC1032:{label:'DWG 2018–2027',year:2018}
});
const targetCodes=Object.freeze({
'R14':'AC1014','2000':'AC1015','2004':'AC1018',
'2007':'AC1021','2010':'AC1024','2013':'AC1027','2018':'AC1032'
});
const state={results:[]};
const pick=document.getElementById('dwg-input');
const zone=document.getElementById('drop-zone');
const list=document.getElementById('results');
const count=document.getElementById('files-count');
const clear=document.getElementById('clear-files');
const target=document.getElementById('target-version');
const notice=document.getElementById('compat-message');
const exportButton=document.getElementById('export-report');
if(!pick||!zone||!list||!count||!clear||!target||!notice||!exportButton)return;
function htmlNode(name,className,text){
 const el=document.createElement(name);
 if(className)el.className=className;
 if(text!==undefined)el.textContent=text;
 return el;
}
function displaySize(bytes){
 if(bytes<1024*1024)return (bytes/1024).toFixed(1)+' KB';
 return (bytes/1024/1024).toFixed(2)+' MB';
}
function compare(code,destination){
 const source=known[code],dest=known[targetCodes[destination]];
 if(!source||!dest)return {message:'No se puede determinar compatibilidad automaticamente.',tone:'caution'};
 if(source.year===dest.year)return {message:'Mismo formato DWG. No es necesario reconvertir por el año de AutoCAD.',tone:'good'};
 if(source.year<dest.year)return {message:'Actualizacion de formato: se puede guardar con una version moderna de AutoCAD, previa verificacion.',tone:'good'};
 return {message:'Guardado hacia una version anterior. Puede afectar objetos especializados, bloques dinamicos, XREF o datos no compatibles.',tone:'caution'};
}
function render(){
 count.textContent=state.results.length+' ARCHIVO'+(state.results.length===1?'':'S');
 clear.disabled=state.results.length===0;
 exportButton.disabled=state.results.length===0;
 list.replaceChildren();
 if(!state.results.length){
   list.append(htmlNode('div','empty-results','Los resultados apareceran aqui despues de elegir un DWG.'));
   notice.textContent='Selecciona archivos para analizar la conversion recomendada.';
   notice.className='compat-message';
   return;
 }
 const cases={same:0,up:0,down:0,unknown:0};
 state.results.forEach((item)=>{
   const row=htmlNode('div','result-item'+(item.error?' error':''));
   const left=htmlNode('div');
   left.append(htmlNode('div','result-file',item.name));
   const meta=item.error?item.error:(known[item.code].label+' · '+displaySize(item.bytes)+' · '+compare(item.code,target.value).message);
   left.append(htmlNode('div','result-desc',meta));
   row.append(left,htmlNode('div','result-code',item.error?'REVISAR':item.code));
   list.append(row);
   if(item.error){cases.unknown++;return;}
   const a=known[item.code].year,b=known[targetCodes[target.value]].year;
   if(a===b)cases.same++;else if(a>b)cases.down++;else cases.up++;
 });
 const notes=[];
 if(cases.same)notes.push(cases.same+' ya compatible(s), sin conversion necesaria');
 if(cases.up)notes.push(cases.up+' requieren actualizar formato');
 if(cases.down)notes.push(cases.down+' requieren guardado hacia atras y revision');
 if(cases.unknown)notes.push(cases.unknown+' no reconocidos');
 notice.textContent=notes.join(' · ')+'. Recuerda: identificar un formato no certifica integridad de entidades ni compatibilidad total.';
 notice.className='compat-message '+(cases.down||cases.unknown?'caution':'good');
}
async function analyze(files){
 const batch=Array.from(files||[]).slice(0,100);
 for(const file of batch){
   const item={name:file.name,bytes:file.size,code:null,error:null};
   if(!/\.dwg$/i.test(file.name)){item.error='Solo se admiten archivos .DWG';state.results.push(item);continue;}
   if(file.size<6){item.error='Archivo incompleto';state.results.push(item);continue;}
   try{
     const bytes=new Uint8Array(await file.slice(0,6).arrayBuffer());
     const code=String.fromCharCode(...bytes);
     if(!known[code])item.error='Cabecera no reconocida: '+code.replace(/[^\w]/g,'?')+'. Puede ser un archivo danado o un formato no soportado.';
     else item.code=code;
   }catch(e){item.error='No fue posible leer el archivo en este navegador.';}
   state.results.push(item);
 }
 pick.value='';
 render();
}
pick.addEventListener('change',()=>analyze(pick.files));
zone.addEventListener('click',()=>pick.click());
zone.addEventListener('keydown',event=>{
 if(event.key==='Enter'||event.key===' '){event.preventDefault();pick.click();}
});
['dragenter','dragover'].forEach(name=>zone.addEventListener(name,event=>{
 event.preventDefault();event.stopPropagation();zone.classList.add('dragover');
}));
['dragleave','drop'].forEach(name=>zone.addEventListener(name,event=>{
 event.preventDefault();event.stopPropagation();zone.classList.remove('dragover');
}));
zone.addEventListener('drop',event=>analyze(event.dataTransfer&&event.dataTransfer.files));
window.addEventListener('dragover',event=>event.preventDefault());
window.addEventListener('drop',event=>event.preventDefault());
clear.addEventListener('click',()=>{state.results=[];pick.value='';render();});
target.addEventListener('change',render);
exportButton.addEventListener('click',()=>{
 if(!state.results.length)return;
 const data={tool:'TraficLabPro DWG Version Switch',
  version:'1.0',generatedAt:new Date().toISOString(),
  destination:target.value,
  privacy:'Local browser header-only DWG analysis. Not a 1:1 geometry or object validation.',
  entries:state.results.map(item=>({
   name:item.name,sizeBytes:item.bytes,dwgHeader:item.code,
   format:item.code?known[item.code].label:null,
   compatibility:item.code?compare(item.code,target.value).message:null,
   error:item.error
  }))
 };
 const blob=new Blob([JSON.stringify(data,null,2)],{type:'application/json'});
 const url=URL.createObjectURL(blob);
 const a=document.createElement('a');
 a.href=url;a.download='DIAGNOSTICO-DWG-'+Date.now()+'.json';
 document.body.append(a);a.click();a.remove();
 setTimeout(()=>URL.revokeObjectURL(url),1000);
});
render();
})();
