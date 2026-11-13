// View preference only. Resizing never changes schedule data, drafts or revisions.
const descriptionWidthKey='master-schedule-description-width:'+state.projectId;
const DESCRIPTION_WIDTH_MIN=280,DESCRIPTION_WIDTH_MAX=1200;
function storedDescriptionWidth(){try{const value=localStorage.getItem(descriptionWidthKey),n=Number(value);return value!==null&&value!==''&&Number.isFinite(n)&&n>=DESCRIPTION_WIDTH_MIN&&n<=DESCRIPTION_WIDTH_MAX?Math.round(n):null}catch{return null}}
let descriptionColumnWidth=storedDescriptionWidth(),descriptionResize=null;
function defaultDescriptionWidth(){const maxDepth=Math.max(0,...[...taskPaths().values()].map(code=>code.split('.').length-1));return Math.max(360,240+(maxDepth+1)*22)}
function currentDescriptionWidth(){return descriptionColumnWidth??defaultDescriptionWidth()}
function syncDescriptionResizeHandle(){const handle=$('description-resize');handle.setAttribute('aria-valuenow',String(currentDescriptionWidth()));handle.setAttribute('aria-valuetext',currentDescriptionWidth()+' พิกเซล')}
function rememberDescriptionWidth(){try{if(descriptionColumnWidth===null)localStorage.removeItem(descriptionWidthKey);else localStorage.setItem(descriptionWidthKey,String(descriptionColumnWidth))}catch{}}
function setDescriptionWidth(value,remember=false){
 const width=value===null?null:Math.max(DESCRIPTION_WIDTH_MIN,Math.min(DESCRIPTION_WIDTH_MAX,Math.round(value)));
 if(width!==null&&!Number.isFinite(width))return;
 const column=document.querySelector('#cols .col-name'),previous=column?parseFloat(column.style.width):currentDescriptionWidth();descriptionColumnWidth=width;const next=currentDescriptionWidth();
 if(column){column.style.width=next+'px';const table=$('schedule'),total=parseFloat(table.style.width);if(Number.isFinite(total)&&Number.isFinite(previous))table.style.width=total+next-previous+'px'}
 syncDescriptionResizeHandle();if(remember)rememberDescriptionWidth();
}
function endDescriptionResize(cancel=false){
 const drag=descriptionResize;if(!drag)return;descriptionResize=null;document.body.classList.remove('resizing-description');
 if(cancel)setDescriptionWidth(drag.previous);else rememberDescriptionWidth();
 const handle=$('description-resize');if(handle.hasPointerCapture?.(drag.pointerId))handle.releasePointerCapture(drag.pointerId);
}
$('description-resize').addEventListener('pointerdown',event=>{
 if(event.button!==0)return;event.preventDefault();const handle=$('description-resize');handle.focus({preventScroll:true});descriptionResize={pointerId:event.pointerId,x:event.clientX,width:currentDescriptionWidth(),previous:descriptionColumnWidth};handle.setPointerCapture(event.pointerId);document.body.classList.add('resizing-description');
});
$('description-resize').addEventListener('pointermove',event=>{const drag=descriptionResize;if(!drag||event.pointerId!==drag.pointerId)return;event.preventDefault();setDescriptionWidth(drag.width+event.clientX-drag.x)});
$('description-resize').addEventListener('pointerup',event=>{if(event.pointerId===descriptionResize?.pointerId)endDescriptionResize()});
$('description-resize').addEventListener('pointercancel',()=>endDescriptionResize(true));
$('description-resize').addEventListener('lostpointercapture',()=>{if(descriptionResize)endDescriptionResize(true)});
$('description-resize').addEventListener('dblclick',event=>{event.preventDefault();endDescriptionResize(true);setDescriptionWidth(null,true)});
$('description-resize').addEventListener('keydown',event=>{
 if(event.key==='Escape'&&descriptionResize){event.preventDefault();event.stopPropagation();endDescriptionResize(true);return}
 const step=event.shiftKey?50:20;let width;
 if(event.key==='ArrowLeft')width=currentDescriptionWidth()-step;else if(event.key==='ArrowRight')width=currentDescriptionWidth()+step;else if(event.key==='Home')width=DESCRIPTION_WIDTH_MIN;else if(event.key==='End')width=DESCRIPTION_WIDTH_MAX;else return;
 event.preventDefault();event.stopPropagation();setDescriptionWidth(width,true);
});
