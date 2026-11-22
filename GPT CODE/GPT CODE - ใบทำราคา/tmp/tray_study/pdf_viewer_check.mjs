
const assets=JSON.parse(document.getElementById('pdf-assets').textContent);
const papers=[...document.querySelectorAll('.paper')];
const zoom=document.getElementById('zoom');
const bytes=value=>Uint8Array.from(atob(value),char=>char.charCodeAt(0));
let pdf=null,revision=0,timer=null;
const jobs=new Map();
function sizing(){
  for(const paper of papers){paper.style.width=zoom.value==='fit'?'100%':`${1056*Number(zoom.value)}px`;}
}
async function renderPages(){
  if(!pdf)return;
  const current=++revision;
  for(let index=0;index<papers.length;index++){
    if(current!==revision)return;
    const paper=papers[index],canvas=paper.querySelector('canvas'),image=paper.querySelector('img');
    const old=jobs.get(canvas);if(old){old.cancel();try{await old.promise}catch{}}
    if(current!==revision)return;
    const page=await pdf.getPage(index+1);
    const viewport=page.getViewport({scale:paper.clientWidth/792*Math.min(devicePixelRatio||1,3)});
    canvas.width=Math.ceil(viewport.width);canvas.height=Math.ceil(viewport.height);
    const task=page.render({canvasContext:canvas.getContext('2d'),viewport});jobs.set(canvas,task);
    try{await task.promise;if(current===revision){canvas.hidden=false;image.classList.add('rendered');}}
    catch(error){if(error.name!=='RenderingCancelledException')console.error(error)}
    finally{if(jobs.get(canvas)===task)jobs.delete(canvas);}
  }
}
zoom.addEventListener('change',()=>{sizing();renderPages();});
window.addEventListener('resize',()=>{clearTimeout(timer);timer=setTimeout(()=>{if(zoom.value==='fit')renderPages();},180);});
sizing();
try{
  const moduleUrl=URL.createObjectURL(new Blob([bytes(assets.module)],{type:'text/javascript'}));
  const workerUrl=URL.createObjectURL(new Blob([bytes(assets.worker)],{type:'text/javascript'}));
  const pdfjs=await import(moduleUrl);pdfjs.GlobalWorkerOptions.workerSrc=workerUrl;
  pdf=await pdfjs.getDocument({data:bytes(assets.pdf),isEvalSupported:false,useWorkerFetch:false}).promise;
  await renderPages();
}catch(error){console.error('PDF rendering unavailable; showing embedded page images.',error);}
