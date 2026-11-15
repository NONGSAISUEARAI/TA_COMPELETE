const fs=require('fs'),assert=require('assert/strict'),{chromium}=require('playwright');
(async()=>{
 const file='Master_Schedule.html';let html=fs.readFileSync(file,'utf8');assert(!html.includes('id="schedule-ribbon"'));
 const data=html.match(/<script id="schedule-data"[^>]*>([\s\S]*?)<\/script>/)[1],beforeIds=[...html.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1]);
 const start=html.indexOf('<body'),end=html.indexOf('\n<dialog',start);assert(end>start);const body=html.slice(start,end),browser=await chromium.launch({channel:'msedge',headless:true});let changed;
 try{
  const page=await browser.newPage();changed=await page.evaluate(source=>{
   const doc=new DOMParser().parseFromString(source,'text/html'),table=doc.getElementById('table-section'),toolbar=table.querySelector('.toolbar'),filters=toolbar.querySelector('.filters'),actions=doc.querySelector('.hero .actions');
   const ribbon=doc.createElement('section');ribbon.id='schedule-ribbon';ribbon.className='schedule-ribbon';ribbon.setAttribute('aria-label','เครื่องมือ Master Schedule');
   ribbon.innerHTML='<div class="ribbon-header"><div class="ribbon-tabs" role="tablist" aria-label="หมวดเครื่องมือ"></div><div class="ribbon-header-tools"></div></div><div id="ribbon-panels" class="ribbon-panels"></div>';
   const tabs=[['overview','ภาพรวม'],['schedule','แผนงาน'],['view','มุมมอง'],['calendar','ปฏิทิน'],['files','นำเข้า–ส่งออก']];
   for(const [key,label]of tabs){const button=doc.createElement('button');button.type='button';button.id='ribbon-tab-'+key;button.setAttribute('role','tab');button.setAttribute('aria-controls','ribbon-panel-'+key);button.setAttribute('aria-selected',String(key==='schedule'));button.tabIndex=key==='schedule'?0:-1;button.textContent=label;ribbon.querySelector('.ribbon-tabs').append(button);const panel=doc.createElement('div');panel.id='ribbon-panel-'+key;panel.className='ribbon-panel';panel.setAttribute('role','tabpanel');panel.setAttribute('aria-labelledby',button.id);panel.hidden=key!=='schedule';ribbon.querySelector('#ribbon-panels').append(panel)}
   const panel=key=>ribbon.querySelector('#ribbon-panel-'+key);
   const group=(key,label)=>{const g=doc.createElement('div');g.className='ribbon-group';const tools=doc.createElement('div');tools.className='ribbon-tools';const caption=doc.createElement('div');caption.className='ribbon-group-title';caption.textContent=label;g.append(tools,caption);panel(key).append(g);return tools};
   const move=(target,ids)=>ids.forEach(id=>{const node=doc.getElementById(id);if(!node)throw Error('Missing '+id);target.append(node)});
   panel('overview').append(doc.querySelector('.metrics'));move(group('overview','ข้อมูลโครงการ'),['project-edit']);
   const add=group('schedule','เพิ่มรายการ');add.parentElement.setAttribute('data-editor-only','');move(add,['add-group','add']);
   const guide=group('schedule','การใช้งาน');guide.innerHTML='<p class="ribbon-note">ปลดล็อก Editor เพื่อเพิ่มและแก้ไขงาน · แตะช่องข้อมูลเพื่อแก้ในตาราง<br>คลิกเลข WBS ต้นทางและปลายทางเพื่อย้ายลำดับ · กดลูกศรข้างชื่อเพื่อยุบ–ขยาย</p>';
   const quick=group('schedule','พื้นที่ทำงาน');move(quick,['table-fullsize']);
   move(group('view','ค้นหาและกรองข้อมูล'),['search','area-filter','status-filter']);
   const columns=group('view','คอลัมน์ที่แสดง');move(columns,['toggle-drawing-core']);columns.append(doc.getElementById('show-drawing-details').closest('label'));
   const levels=group('view','ระดับโครงสร้าง');levels.append(filters.querySelector('.tree-level-controls'));move(levels,['expand-groups','collapse-groups']);
   panel('calendar').append(table.querySelector('.calendar-controls'),table.querySelector('.legend'));
   move(group('files','นำเข้าข้อมูล'),['import-html','import-csv']);move(group('files','ส่งออกและพิมพ์'),['download','export-excel','print']);panel('files').append(doc.querySelector('.save-panel'));
   const header=ribbon.querySelector('.ribbon-header-tools');header.append(doc.querySelector('.access-panel'));move(header,['save']);const collapse=doc.createElement('button');collapse.id='ribbon-collapse';collapse.type='button';collapse.className='ribbon-collapse';collapse.textContent='⌃';collapse.setAttribute('aria-label','ย่อแถบเครื่องมือ');collapse.setAttribute('aria-expanded','true');collapse.setAttribute('aria-controls','ribbon-panels');header.append(collapse);
   const caption=doc.createElement('div');caption.className='schedule-caption';caption.append(doc.getElementById('schedule-title'));const summary=doc.createElement('span');summary.id='ribbon-context';summary.className='ribbon-context';summary.setAttribute('role','status');caption.append(summary);
   table.prepend(ribbon,caption);toolbar.remove();actions.remove();return doc.body.outerHTML.replace(/<\/body>$/,'');
  },body);
 }finally{await browser.close()}
 html=html.slice(0,start)+changed+html.slice(end);
 html=html.replace('</head>','<style id="schedule-ribbon-style">\n'+fs.readFileSync('.work/schedule-ribbon.css','utf8')+'\n</style>\n</head>');
 const marker=html.lastIndexOf('render();saveStatus();');assert(marker>0);html=html.slice(0,marker)+fs.readFileSync('.work/schedule-ribbon.js','utf8')+'\n'+html.slice(marker);
 const renderMarker="$('row-count').textContent=";assert(html.includes(renderMarker));html=html.replace(renderMarker,'refreshRibbonContext();\n '+renderMarker);
 assert.equal(html.match(/<script id="schedule-data"[^>]*>([\s\S]*?)<\/script>/)[1],data);
 for(const id of beforeIds)assert(html.includes('id="'+id+'"'),'Lost ID '+id);
 const ids=[...html.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1]);assert.equal(new Set(ids).size,ids.length,'Duplicate IDs');
 fs.writeFileSync(file,html);console.log('Installed five ribbon tabs. Original IDs and schedule data preserved.');
})().catch(e=>{console.error(e);process.exitCode=1});
