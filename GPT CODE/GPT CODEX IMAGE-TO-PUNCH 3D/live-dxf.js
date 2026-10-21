import {parseDxf} from './dxf.js';

export function setupLiveDxf(api){
 const section=document.createElement('details');section.id='live-dxf-section';section.open=true;
 section.innerHTML=`<summary>UPDATE FILE · LIVE DXF</summary><p id="live-dxf-name">ยังไม่ได้เลือกไฟล์ต้นทาง</p><button id="live-dxf-link" class="full">↻ Link source DXF</button><button id="live-dxf-manual" class="full">Update from file… (manual)</button><label>Drawing units<select id="live-dxf-units"><option value="auto">Read from DXF header</option><option value="1">Millimetres</option><option value="10">Centimetres</option><option value="1000">Metres</option><option value="25.4">Inches</option></select></label><div class="fields"><button id="live-dxf-update" disabled>Update now</button><button id="live-dxf-pause" disabled>Pause</button></div><button id="live-dxf-disconnect" class="full" disabled>Disconnect file</button><p id="live-dxf-status" role="status" aria-live="polite">เลือก DXF เพื่อเริ่มเชื่อมต่อ</p><p class="helper">เซฟ DXF จาก CAD → อัปเดตทุกประมาณ 2 วินาทีเมื่อหน้าเว็บทำงาน · รักษาค่า Curtain Wall และ Origin ในพิกัดโลก · Area ที่หายไปจะยังเก็บไว้ · เปิดหน้าใหม่ต้องเลือกไฟล์อีกครั้ง</p><input id="live-dxf-input" type="file" accept=".dxf" hidden>`;
 document.querySelector('.sidebar-bottom').before(section);
 const $=s=>section.querySelector(s),native=typeof window.showOpenFilePicker==='function';
 if(!native)$('#live-dxf-link').textContent='↻ Select DXF (manual)';
 let source=null,name='',timer=null,paused=true,busy=false,generation=0,lastStamp='',lastText=null,lastSuccess='';
 const status=text=>$('#live-dxf-status').textContent=text;
 function controls(){const linked=!!name;$('#live-dxf-link').disabled=busy;$('#live-dxf-manual').disabled=busy;$('#live-dxf-update').disabled=!linked||busy;$('#live-dxf-pause').disabled=!source;$('#live-dxf-pause').textContent=paused?'Resume':'Pause';$('#live-dxf-disconnect').disabled=!linked;$('#live-dxf-name').textContent=name||'ยังไม่ได้เลือกไฟล์ต้นทาง'}
 function stop(){clearTimeout(timer);timer=null;paused=true;controls()}
 function schedule(){clearTimeout(timer);if(source&&!paused)timer=setTimeout(()=>read(false),2000)}
 function disconnect(){generation++;stop();source=null;name='';lastStamp='';lastText=null;lastSuccess='';controls();status('ไม่ได้เชื่อมต่อไฟล์ · งานปัจจุบันยังอยู่')}
 async function read(force=false,file=null,token=generation){
  if(busy){schedule();return}
  if(!api.canUpdate()){status('รอให้จบคำสั่งหรือแก้ค่า แล้วจะตรวจไฟล์ต่อ');schedule();return}
  busy=true;controls();
  try{
   const fresh=file||await source.getFile();if(token!==generation)return;
   if(!/\.dxf$/i.test(fresh.name))throw Error('เลือกไฟล์ .dxf เท่านั้น');
   if(fresh.size>20e6)throw Error('DXF เกิน 20 MB');
   const stamp=fresh.lastModified+':'+fresh.size;
   if(!force&&stamp===lastStamp){status('Live · รอการเซฟจาก CAD'+(lastSuccess?' · ล่าสุด '+lastSuccess:''));return}
   const text=await fresh.text();if(token!==generation)return;
   if(source){const check=await source.getFile();if(token!==generation)return;if(check.lastModified!==fresh.lastModified||check.size!==fresh.size){status('CAD กำลังเขียนไฟล์ · รอตรวจรอบถัดไป');return}}
   if(text===lastText){lastStamp=stamp;status((paused?'Paused':'Live')+' · ไฟล์ยังไม่เปลี่ยน');return}
   if(!text.trimEnd().endsWith('EOF'))throw Error('DXF ยังเขียนไม่ครบ (ไม่พบ EOF)');
   const result=parseDxf(text,$('#live-dxf-units').value),problems=result.warnings.filter(w=>!w.endsWith(': ไม่ใช่ขอบเขตที่รองรับ'));
   if(problems.length)throw Error('ยังไม่อัปเดต: '+problems.slice(0,2).join(' · '));
   if(token!==generation)return;
   if(!api.canUpdate()){status('รอให้จบคำสั่งหรือแก้ค่า แล้วตรวจไฟล์อีกครั้ง');return}
   const report=api.apply(result.areas,fresh.name);if(report===false)throw Error('อัปเดตไม่สำเร็จ');
   name=fresh.name;lastText=text;lastStamp=stamp;lastSuccess=new Date().toLocaleTimeString('th-TH',{hour12:false});
   status(`${source&&!paused?'Live':'Manual'} · ${lastSuccess} · อัปเดต ${report.updated} / เพิ่ม ${report.added}${report.missing?' · ไม่พบ '+report.missing+' Area (เก็บเดิมไว้)':''}`);
  }catch(e){if(token===generation){if(e.name==='NotAllowedError'||e.name==='SecurityError'||e.name==='NotFoundError')stop();status('เก็บงานเดิมไว้ · '+e.message)}}
  finally{busy=false;controls();if(token===generation)schedule()}
 }
 $('#live-dxf-link').onclick=async()=>{
  if(busy)return;
  if(!native){$('#live-dxf-input').click();return}
  const token=++generation;stop();
  try{
   const [handle]=await window.showOpenFilePicker({multiple:false,types:[{description:'DXF drawing',accept:{'application/dxf':['.dxf']}}]});if(token!==generation)return;
   source=handle;name=handle.name;lastText=null;lastStamp='';paused=false;controls();await read(true,null,token);
  }catch(e){if(e.name!=='AbortError')status('เลือกไฟล์ไม่ได้ · '+e.message);else status('ยกเลิกเลือกไฟล์ · หยุดติดตามไว้ก่อน');controls()}
 };
 $('#live-dxf-input').onchange=e=>{const file=e.target.files[0];e.target.value='';if(!file||busy)return;generation++;stop();source=null;name=file.name;controls();read(true,file)};
 $('#live-dxf-manual').onclick=()=>$('#live-dxf-input').click();
 $('#live-dxf-update').onclick=()=>source?read(true):$('#live-dxf-input').click();
 $('#live-dxf-pause').onclick=()=>{if(!source)return;if(paused){paused=false;controls();read(true)}else{generation++;stop();status('Paused · กด Resume เพื่อติดตามต่อ')}};
 $('#live-dxf-disconnect').onclick=disconnect;
 $('#live-dxf-units').onchange=()=>{lastText=null;lastStamp='';if(source)read(true);else if(name)status('เปลี่ยนหน่วยแล้ว · กด Update now และเลือกไฟล์อีกครั้ง')};
 if(!native)status('เบราว์เซอร์นี้ใช้ Update now โดยเลือกไฟล์ซ้ำ · Auto update ใช้ Chrome / Edge');
 return {pause(){generation++;stop();lastText=null;lastStamp='';status(name?'Paused · งานเปลี่ยนแล้ว กด Resume เมื่อต้องการติดตามต่อ':'เลือก DXF เพื่อเริ่มเชื่อมต่อ')},disconnect};
}
