const fs=require('fs'),path=require('path'),assert=require('assert/strict'),{chromium}=require('playwright');
(async()=>{
 const file='Master_Schedule.html';let html=fs.readFileSync(file,'utf8');assert(!html.includes('id="editor-range-layout"'));
 const data=html.match(/<script id="schedule-data"[^>]*>([\s\S]*?)<\/script>/)[1];
 const browser=await chromium.launch({channel:'msedge',headless:true});
 try{
  const page=await browser.newPage();
  for(const id of ['task-dialog','group-dialog']){
   const pattern=new RegExp('<dialog id="'+id+'"[\\s\\S]*?</dialog>');const before=html.match(pattern)[0];
   const after=await page.evaluate(source=>{
    const doc=new DOMParser().parseFromString(source,'text/html'),dialog=doc.querySelector('dialog'),body=dialog.querySelector('.form-body'),nodes=[...body.children];
    const context=doc.createElement('div');context.className='editor-context';
    const sections=['ข้อมูลทั่วไป','วันที่และความก้าวหน้า','เอกสารและไฟล์อ้างอิง'].map((title,i)=>{const section=doc.createElement('section');section.className='edit-section'+(i===2?' edit-section-documents':'');const h=doc.createElement('h3');h.textContent=title;section.append(h);return section});
    const tail=[];
    for(const node of nodes){
     if(node.matches('.dialog-outline,.parent-field,.task-summary-note')||node.querySelector('#f-db-level,#f-group'))context.append(node);
     else if(node.matches('.error,.calendar-note')){node.classList.add('editor-form-note');tail.push(node)}
     else if(node.matches('.schedule-dates,.bar-color-editor')||node.querySelector('#f-progress,#f-category'))sections[1].append(node);
     else if(node.matches('.task-file-editor')||(node.matches('.drawing-fieldset')&&!node.matches('.drawing-core-fields')))sections[2].append(node);
     else sections[0].append(node);
    }
    body.replaceChildren(context,...sections,...tail);return dialog.outerHTML;
   },before);
   html=html.replace(pattern,()=>after);
  }
 }finally{await browser.close()}
 const controls='<div class="calendar-controls" role="group" aria-label="ช่วงวันที่บนปฏิทิน"><strong>ช่วงวันที่บนปฏิทิน</strong><label>ตั้งแต่วันที่<input id="calendar-from" type="date" aria-controls="schedule"></label><label>ถึงวันที่<input id="calendar-to" type="date" aria-controls="schedule"></label><button id="calendar-apply" type="button" class="primary">แสดงช่วงวันที่</button><button id="calendar-auto" type="button">ตามข้อมูลทั้งหมด</button><p id="calendar-range-note" class="calendar-range-note" role="status" aria-live="polite"></p></div>';
 assert(html.includes('<div class="reorder-hint"'));html=html.replace('<div class="reorder-hint"',controls+'<div class="reorder-hint"');
 const old='const weekday=new Date(min).getUTCDay(),start=min-((weekday+6)%7)*DAY,numberOfWeeks=Math.max(4,Math.ceil((max-start+DAY)/(7*DAY))),totalDays=numberOfWeeks*7,timelineWidth=totalDays*40;';assert(html.includes(old));
 html=html.replace(old,'const {start,numberOfWeeks,totalDays}=calendarWindow(min,max),timelineWidth=totalDays*40;refreshCalendarRange(min,max,start,totalDays);');
 const feature=fs.readFileSync('.work/calendar-range.js','utf8');
 const pos=html.lastIndexOf('render();saveStatus();');assert(pos>0);html=html.slice(0,pos)+feature+'\n'+html.slice(pos);
 html=html.replace('</head>','<style id="editor-range-layout">\n'+fs.readFileSync('.work/editor-range.css','utf8')+'\n</style>\n</head>');
 assert.equal(html.match(/<script id="schedule-data"[^>]*>([\s\S]*?)<\/script>/)[1],data);fs.writeFileSync(file,html);console.log('Updated editor columns and calendar range; schedule data unchanged.');
})().catch(e=>{console.error(e);process.exitCode=1});
