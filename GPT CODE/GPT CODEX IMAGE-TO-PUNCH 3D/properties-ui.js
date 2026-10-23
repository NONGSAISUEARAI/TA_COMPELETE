export function setupPropertiesPanel(){
  const panel=document.querySelector('.right-panel'),layout=document.querySelector('.layout'),key='facade-studio-properties-ui-v1';
  let saved={};try{const parsed=JSON.parse(localStorage.getItem(key)||'{}');if(parsed&&typeof parsed==='object'&&!Array.isArray(parsed))saved=parsed}catch{}
  const collapsed=Array.isArray(saved.collapsed)?saved.collapsed:[];
  let width=Number.isFinite(saved.width)?saved.width:288,previousWidth=288;
  const store=()=>{try{localStorage.setItem(key,JSON.stringify({hidden:panel.hidden,width,scrollTop:panel.scrollTop,leftScroll:document.querySelector('.left-panel').scrollTop,tableScroll:document.querySelector('.panel-bend-table-wrap')?.scrollLeft||0,collapsed:[...panel.querySelectorAll('.property-section-toggle')].map((button,i)=>button.getAttribute('aria-expanded')==='false'?i:null).filter(i=>i!==null)}))}catch{}};
  panel.id='properties-panel';
  const toggle=document.createElement('button');toggle.id='toggle-properties';toggle.type='button';toggle.setAttribute('aria-controls',panel.id);document.querySelector('.toolbar-end').append(toggle);
  const setVisible=visible=>{panel.hidden=!visible;layout.classList.toggle('properties-hidden',!visible);toggle.classList.toggle('active',visible);toggle.setAttribute('aria-expanded',String(visible));toggle.textContent=visible?'Properties ▸':'Properties ◂';toggle.title=visible?'Hide Properties panel':'Show Properties panel';store()};
  toggle.onclick=()=>setVisible(panel.hidden);
  const close=document.createElement('button');close.type='button';close.className='close-properties';close.textContent='×';close.title='Hide Properties panel';close.setAttribute('aria-label','Hide Properties panel');close.onclick=()=>setVisible(false);panel.querySelector('.panel-heading').append(close);
  panel.querySelectorAll('#inspector > section').forEach((section,i)=>{
    const title=section.querySelector('.section-title');if(!title)return;
    const button=document.createElement('button');button.type='button';button.className='section-title property-section-toggle';
    const number=document.createElement('span');number.textContent=title.querySelector('span')?.textContent||'';
    const label=document.createElement('span');label.className='property-section-name';label.textContent=title.querySelector('h2')?.textContent||'';
    const caret=document.createElement('span');caret.className='property-caret';caret.textContent='⌄';caret.setAttribute('aria-hidden','true');button.append(number,label,caret);
    const body=document.createElement('div');body.className='property-section-body';body.id='property-section-'+i;button.setAttribute('aria-controls',body.id);
    title.replaceWith(button);for(const child of [...section.childNodes])if(child!==button)body.append(child);section.append(body);
    function expand(value){body.hidden=!value;button.setAttribute('aria-expanded',String(value));section.classList.toggle('property-collapsed',!value)}
    expand(!collapsed.includes(i));button.onclick=()=>{expand(body.hidden);store()};
  });
  const grip=document.createElement('div');grip.id='properties-resize-handle';grip.tabIndex=0;grip.setAttribute('role','separator');grip.setAttribute('aria-orientation','vertical');grip.setAttribute('aria-label','Resize Properties width');grip.title='ลากเพื่อขยาย Properties · ลูกศรซ้าย/ขวา · ดับเบิลคลิกคืนขนาด';layout.append(grip);
  const maxWidth=()=>Math.max(240,Math.min(1000,layout.clientWidth-document.querySelector('.left-panel').getBoundingClientRect().width-360));
  const resize=(next,persist=true)=>{width=Math.round(Math.max(240,Math.min(maxWidth(),next)));layout.style.setProperty('--properties-width',width+'px');grip.setAttribute('aria-valuemin','240');grip.setAttribute('aria-valuemax',String(maxWidth()));grip.setAttribute('aria-valuenow',String(width));if(persist)store()};
  const expand=document.createElement('button');expand.id='expand-properties-width';expand.type='button';expand.textContent='↔';expand.title='ขยาย / คืนความกว้าง Properties';expand.setAttribute('aria-label','Expand Properties width');panel.querySelector('.panel-heading').insertBefore(expand,close);
  expand.onclick=()=>{const target=Math.min(700,maxWidth());if(Math.abs(width-target)<2)resize(previousWidth);else{previousWidth=width;resize(target)}};
  let drag=null;grip.addEventListener('pointerdown',e=>{if(e.button!==0||matchMedia('(max-width:850px)').matches)return;drag={x:e.clientX,width,id:e.pointerId};grip.setPointerCapture(e.pointerId);layout.classList.add('properties-resizing');e.preventDefault()});
  grip.addEventListener('pointermove',e=>{if(drag)resize(drag.width+drag.x-e.clientX,false)});
  const finish=cancel=>{if(!drag)return;const original=drag.width;drag=null;layout.classList.remove('properties-resizing');if(cancel)resize(original);else store()};
  grip.addEventListener('pointerup',()=>finish(false));grip.addEventListener('pointercancel',()=>finish(true));grip.addEventListener('lostpointercapture',()=>finish(false));
  grip.addEventListener('dblclick',()=>resize(288));grip.addEventListener('keydown',e=>{if(e.key==='ArrowLeft'||e.key==='ArrowRight'){e.preventDefault();resize(width+(e.key==='ArrowLeft'?20:-20))}else if(e.key==='Home'){e.preventDefault();resize(240)}else if(e.key==='End'){e.preventDefault();resize(maxWidth())}else if(e.key==='Escape')finish(true)});
  window.addEventListener('keydown',e=>{if(e.key==='Escape'&&drag)finish(true)});window.addEventListener('blur',()=>finish(true));window.addEventListener('resize',()=>resize(width));resize(width,false);
  let scrollTimer,restoringScroll=true;
  const saveScroll=()=>{if(restoringScroll)return;clearTimeout(scrollTimer);scrollTimer=setTimeout(store,100)};
  panel.addEventListener('scroll',saveScroll,true);document.querySelector('.left-panel').addEventListener('scroll',saveScroll,{passive:true});window.addEventListener('pagehide',store);
  requestAnimationFrame(()=>requestAnimationFrame(()=>{if(Number.isFinite(saved.scrollTop))panel.scrollTop=Math.max(0,saved.scrollTop);if(Number.isFinite(saved.leftScroll))document.querySelector('.left-panel').scrollTop=Math.max(0,saved.leftScroll);const table=document.querySelector('.panel-bend-table-wrap');if(table&&Number.isFinite(saved.tableScroll))table.scrollLeft=Math.max(0,saved.tableScroll);restoringScroll=false;store()}));
  setVisible(saved.hidden!==true);
}
