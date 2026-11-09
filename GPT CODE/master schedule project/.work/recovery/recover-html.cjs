const fs=require('node:fs'),assert=require('node:assert/strict'),vm=require('node:vm');
const current=fs.readFileSync('Master_Schedule.html','utf8');
const candidatePath='backups/Master_Schedule_before_ExportReferenceFormat_1794199460452.html';
const candidate=fs.readFileSync(candidatePath,'utf8');
const dataPattern=/<script id="schedule-data" type="application\/json">([\s\S]*?)<\/script>/;
const previous=JSON.parse(current.match(dataPattern)[1]),data=JSON.parse(candidate.match(dataPattern)[1]);
assert.equal(previous.tasks.length,165);assert.equal(data.tasks.length,57);
const oldMrt=previous.groups.find(g=>g.id==='mrt-purple-line-std-dwg-c1');
const recoveredMrt=data.groups.find(g=>g.id===oldMrt.id);
// Preserve the only user-data difference in the current older file. All MRT
// child records and file selections are identical between the two sources.
recoveredMrt.name=oldMrt.name;if('barColor' in oldMrt)recoveredMrt.barColor=oldMrt.barColor;
assert.deepEqual(data.tasks.filter(t=>t.groupId===oldMrt.id),previous.tasks.filter(t=>t.groupId===oldMrt.id));
const template=JSON.parse(candidate.match(/const EXCEL_TEMPLATE=([^\n]*);\n/)[1]);
// Rebuild the embedded style asset from the reference's already-verified local
// format specification (README/AGENTS); no external workbook/drive is required.
const font=(name,size,bold,color)=>'<font>'+(bold?'<b/>':'')+'<sz val="'+size+'"/><color rgb="FF'+color+'"/><name val="'+name+'"/><family val="2"/><charset val="222"/></font>';
const fonts=[font('Tahoma',11,false,'000000'),font('CordiaUPC',36,true,'000000'),font('CordiaUPC',36,true,'FFC000'),font('CordiaUPC',28,true,'FFC000'),font('CordiaUPC',24,true,'FFC000'),font('Cordia New',20,true,'FFC000'),font('Cordia New',20,false,'FFC000'),font('Cordia New',24,true,'FFC000'),font('Cordia New',20,true,'FFC000')];
const colors=['262626','404040','3A3838','55452E','54353B','FFFFFF'];
const fills=['<fill><patternFill patternType="none"/></fill>','<fill><patternFill patternType="gray125"/></fill>',...colors.map(c=>'<fill><patternFill patternType="solid"><fgColor rgb="FF'+c+'"/><bgColor indexed="64"/></patternFill></fill>')];
const edge=(name,color,style='thin')=>'<'+name+' style="'+style+'"><color rgb="FF'+color+'"/></'+name+'>';
const border=(left='brown',top='brown',bottom='brown',right='brown')=>'<border>'+[['left',left],['right',right],['top',top],['bottom',bottom]].map(([k,v])=>v==='none'?'<'+k+'/>':edge(k,v==='blue'?'1F4E78':v==='black'?'000000':'833C0C',v==='blue'?'thick':v==='black'?'medium':'thin')).join('')+'<diagonal/></border>';
const borders=[border('none','none','none','none'),border(),border('black'),border('brown','blue','blue'),border('black','blue','blue'),border('none','none','blue','none'),border('brown','blue'),border('black','blue')];
const xfs=[],cache=new Map();function style(fontId,fillId,borderId=1,numFmtId=0,horizontal='left',vertical='bottom',wrap=false,rotation=0,indent=0){const xml='<xf numFmtId="'+numFmtId+'" fontId="'+fontId+'" fillId="'+fillId+'" borderId="'+borderId+'" xfId="0" applyFont="1" applyFill="1" applyBorder="1" applyNumberFormat="1" applyAlignment="1"><alignment horizontal="'+horizontal+'" vertical="'+vertical+'"'+(wrap?' wrapText="1"':'')+(rotation?' textRotation="'+rotation+'"':'')+(indent?' indent="'+indent+'"':'')+'/></xf>';if(cache.has(xml))return cache.get(xml);const index=xfs.push(xml)-1;cache.set(xml,index);return index}
style(0,0,0);
const styles={};styles.title=style(1,7,0,0,'left','center');styles.subtitle=style(2,2,5,0,'left','center');styles.month=style(8,7,0,0,'center');styles.report=style(3,2,5,164,'center','center');
styles.headerColumns=Array.from({length:18},(_,c)=>style(4,2,c===0?4:3,0,c===10?'left':'center','center',true,0,c===10?1:0));styles.header=styles.headerColumns[0];
styles.dayHeader=style(7,2,3,0,'left','top',true,90);styles.dayDate=style(8,2,5,166,'left','bottom',true,90);
styles.bodyColumns=[0,1,2].map(stripe=>Array.from({length:18},(_,c)=>{const fill=stripe===1?4:3,borderId=stripe===2?(c===0?7:6):c===0?2:1;return style(c===15||c===17&&stripe!==2?6:5,fill,borderId,[11,12,13].includes(c)?164:c===15?165:0,c===15?'right':[6,7,8,9,11,12,13].includes(c)?'center':'left',c===15||c===17?'center':'bottom',c===17)}));
for(const [stripe,suffix] of [[0,''],[1,'Even'],[2,'First']]){for(const [key,fill] of [['day',stripe===1?4:3],['saturday',5],['sunday',6]])styles[key+suffix]=style(stripe===2?5:6,fill,stripe===2?6:1,0,'left','center',true)}
Object.assign(styles,{text:styles.bodyColumns[0][0],section:styles.bodyColumns[2][4],date:styles.bodyColumns[0][11],number:styles.bodyColumns[0][8],integer:styles.bodyColumns[0][15],sectionDate:styles.bodyColumns[2][11],plan:styles.bodyColumns[2][17],actual:styles.bodyColumns[1][17]});
template.styles=styles;template.format={source:'Program & Actual Drawing Schedul By Tawan 09-11-26.xlsx',headerFill:'#262626',fontColor:'#FFC000',bodyFills:['#404040','#3A3838'],widths:[14.25,19.75,13.875,23.625,88.875,21.375,23.125,13.5,13.5,13.5,10.5,31.5,31,27.5,28.875,13,15,18],hiddenColumns:[2,3],rowHeights:{title:35.45,month:28.9,subtitle:82.15,header:63.6,first:31.5,body:30.75},zoom:55,dayWidth:9};
template.files['xl/styles.xml']='<?xml version="1.0" encoding="UTF-8" standalone="yes"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><numFmts count="3"><numFmt numFmtId="164" formatCode="dd/mm/yyyy"/><numFmt numFmtId="165" formatCode="#,##0"/><numFmt numFmtId="166" formatCode="dd/mmm"/></numFmts><fonts count="'+fonts.length+'">'+fonts.join('')+'</fonts><fills count="'+fills.length+'">'+fills.join('')+'</fills><borders count="'+borders.length+'">'+borders.join('')+'</borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="'+xfs.length+'">'+xfs.join('')+'</cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles><dxfs count="0"/></styleSheet>';
const feature=fs.readFileSync('.work/excel-export/export-feature.js','utf8');assert(feature.includes('columnStyles=s.bodyColumns'));
let recovered=candidate.replace(dataPattern,()=>'<script id="schedule-data" type="application/json">'+JSON.stringify(data).replace(/</g,'\\u003c')+'</script>');
recovered=recovered.replace(/const EXCEL_TEMPLATE=[^\n]*;\n[\s\S]*?(?=function snapshot\(\))/,'const EXCEL_TEMPLATE='+JSON.stringify(template).replace(/</g,'\\u003c')+';\n'+feature+'\n');
recovered=recovered.replace('ส่งออกไฟล์ .xlsx ตามหัวตารางตัวอย่าง พร้อม WBS','ส่งออกไฟล์ .xlsx พร้อมสี ฟอนต์ เส้นขอบ และรูปแบบตารางจาก Excel ต้นแบบ พร้อม WBS');
for(const script of recovered.matchAll(/<script([^>]*)>([\s\S]*?)<\/script>/g))if(!script[1].includes('application/json'))new vm.Script(script[2]);
assert.deepEqual(JSON.parse(recovered.match(dataPattern)[1]),data);
const auditDir=fs.readdirSync('backups').filter(n=>n.startsWith('recovery-audit-')).sort().at(-1);assert(auditDir);
fs.writeFileSync('backups/'+auditDir+'/recovered-data.json',JSON.stringify(data,null,2));fs.writeFileSync('backups/'+auditDir+'/Master_Schedule_recovered.html',recovered);
fs.writeFileSync('.work/excel-export/template.json',JSON.stringify(template));fs.writeFileSync('Master_Schedule.html',recovered);
console.log(JSON.stringify({result:'RESTORED',source:candidatePath,groups:data.groups.map(g=>g.name),tasks:data.tasks.length,workItems:data.tasks.filter(t=>t.nodeType==='task').length,fileCatalogs:data.tasks.filter(t=>t.fileCatalog).length,selectedFiles:data.tasks.flatMap(t=>t.fileCatalog?.files||[]).filter(f=>f.selected).length,preservedCurrentMrtName:oldMrt.name,auditDir:'backups/'+auditDir}));
