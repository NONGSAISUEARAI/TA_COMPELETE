// Export the current RFQ data into the user's original XLSX package.
// Native controls, styles, validation, drawings and printer setup are retained.
const rfqXlsxNS={sheet:'http://schemas.openxmlformats.org/spreadsheetml/2006/main',rel:'http://schemas.openxmlformats.org/package/2006/relationships',officeRel:'http://schemas.openxmlformats.org/officeDocument/2006/relationships',types:'http://schemas.openxmlformats.org/package/2006/content-types',excel:'urn:schemas-microsoft-com:office:excel',vml:'urn:schemas-microsoft-com:vml'};
function rfqXlsxParse(text){
  const doc=new DOMParser().parseFromString(text,'application/xml');
  if(doc.getElementsByTagName('parsererror').length)throw new Error('อ่านโครงสร้าง Excel ไม่สำเร็จ');
  return doc;
}
function rfqXlsxXml(doc){return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'+new XMLSerializer().serializeToString(doc.documentElement);}
function rfqXlsxNodes(doc,name,ns='*'){return [...doc.getElementsByTagNameNS(ns,name)];}
function rfqXlsxResolve(owner,target){
  const stack=target.startsWith('/')?[]:owner.split('/').slice(0,-1);
  for(const part of target.split('/'))if(part==='..')stack.pop();else if(part&&part!=='.')stack.push(part);
  return stack.join('/');
}
function rfqXlsxRelative(owner,target){
  const from=owner.split('/').slice(0,-1),to=target.split('/');
  while(from.length&&to.length&&from[0]===to[0]){from.shift();to.shift();}
  return '../'.repeat(from.length)+to.join('/');
}
function rfqXlsxRels(part){const p=part.split('/');return [...p.slice(0,-1),'_rels',p.at(-1)+'.rels'].join('/');}
function rfqXlsxNumber(value){
  if(value===null||value===undefined||String(value).trim()==='')return '';
  const str=String(value).trim();
  return /^[-+]?\d[\d,]*(?:\.\d+)?$/.test(str)&&Number.isFinite(Number(str.replaceAll(',','')))?Number(str.replaceAll(',','')):str;
}
function rfqXlsxCellWriter(sheet){
  const cells=new Map(rfqXlsxNodes(sheet,'c',rfqXlsxNS.sheet).map(c=>[c.getAttribute('r'),c]));
  const rows=new Map(rfqXlsxNodes(sheet,'row',rfqXlsxNS.sheet).map(r=>[Number(r.getAttribute('r')),r]));
  return (address,value,formula=null)=>{
    let cell=cells.get(address);
    if(!cell){
      const rowNumber=Number(address.match(/\d+/)[0]),row=rows.get(rowNumber);
      if(!row)throw new Error('ไม่พบแถว Excel '+rowNumber);
      cell=sheet.createElementNS(rfqXlsxNS.sheet,'c');cell.setAttribute('r',address);
      const col=address.replace(/\d+/g,'');
      const neighbor=cells.get(col+(rowNumber-1));if(neighbor?.hasAttribute('s'))cell.setAttribute('s',neighbor.getAttribute('s'));
      const colIndex=a=>a.replace(/\d+/g,'').split('').reduce((n,c)=>n*26+c.charCodeAt(0)-64,0);
      const after=[...row.children].find(c=>colIndex(c.getAttribute('r'))>colIndex(address));
      row.insertBefore(cell,after||null);cells.set(address,cell);
    }
    cell.replaceChildren();cell.removeAttribute('t');
    if(formula!==null){
      const f=sheet.createElementNS(rfqXlsxNS.sheet,'f');f.textContent=formula;cell.append(f);
      if(typeof value==='string')cell.setAttribute('t','str');
      const v=sheet.createElementNS(rfqXlsxNS.sheet,'v');v.textContent=String(value??'');cell.append(v);
    }else if(value!==null&&value!==undefined&&String(value)!==''){
      if(typeof value==='number'){
        if(!Number.isFinite(value))throw new Error('ตัวเลขใน Excel ไม่ถูกต้อง: '+address);
        const v=sheet.createElementNS(rfqXlsxNS.sheet,'v');v.textContent=String(value);cell.append(v);
      }else{
        cell.setAttribute('t','inlineStr');
        const is=sheet.createElementNS(rfqXlsxNS.sheet,'is'),t=sheet.createElementNS(rfqXlsxNS.sheet,'t');
        t.setAttributeNS('http://www.w3.org/XML/1998/namespace','xml:space','preserve');t.textContent=String(value);is.append(t);cell.append(is);
      }
    }
  };
}
function rfqXlsxRequestDate(value,documentNo){
  const match=String(value||'').trim().match(/^(\d{1,2})\/(\d{1,2})\/(\d{2}|\d{4})$/);
  if(!match)return value||'';
  const day=Number(match[1]),month=Number(match[2]);let year=Number(match[3]);
  if(match[3].length===2){
    // Resolve a short Gregorian year only when it agrees with the RFQ year.
    const docYear=String(documentNo).match(/^BU2-DE-(\d{2})/i)?.[1];
    if(docYear!==match[3])return value;year=2000+year;
  }else if(year>2400){return value;}
  const date=new Date(Date.UTC(year,month-1,day));
  if(date.getUTCFullYear()!==year||date.getUTCMonth()!==month-1||date.getUTCDate()!==day)return value;
  return (date.getTime()-Date.UTC(1899,11,30))/86400000;
}
async function rfqCreateXlsx(snapshot){
  const payload=document.getElementById('excel-template-data');
  if(!payload?.textContent.trim())throw new Error('ไม่พบไฟล์ Excel ต้นแบบ');
  const original=await JSZip.loadAsync(payload.textContent.trim(),{base64:true});
  // Inflate together, avoiding a separate background-browser task per cell part.
  const files=new Map(await Promise.all(Object.entries(original.files).filter(([,f])=>!f.dir).map(async([path,file])=>[path,await file.async('uint8array')])));
  const decoder=new TextDecoder('utf-8');
  const output=new JSZip(),read=async path=>{
    const file=files.get(path);if(!file)throw new Error('Excel ต้นแบบไม่มี '+path);return decoder.decode(file);
  };
  const removed=path=>/^xl\/(?:worksheets|drawings|ctrlProps|printerSettings)\//.test(path)||path==='xl/calcChain.xml';
  for(const [path,bytes] of files)if(!removed(path))output.file(path,bytes);
  const workbook=rfqXlsxParse(await read('xl/workbook.xml'));
  const rels=rfqXlsxParse(await read('xl/_rels/workbook.xml.rels'));
  const contentTypes=rfqXlsxParse(await read('[Content_Types].xml'));
  const overrides=new Map(rfqXlsxNodes(contentTypes,'Override').map(n=>[n.getAttribute('PartName').replace(/^\//,''),n.getAttribute('ContentType')]));
  for(const node of rfqXlsxNodes(contentTypes,'Override'))if(removed(node.getAttribute('PartName').replace(/^\//,'')))node.remove();
  const addType=(path,source)=>{
    if(!overrides.has(source))return;
    const e=contentTypes.createElementNS(rfqXlsxNS.types,'Override');e.setAttribute('PartName','/'+path);e.setAttribute('ContentType',overrides.get(source));contentTypes.documentElement.append(e);
  };
  const firstSheet=rfqXlsxNodes(workbook,'sheet',rfqXlsxNS.sheet)[0];
  const firstRid=firstSheet.getAttributeNS(rfqXlsxNS.officeRel,'id');
  const firstRel=rfqXlsxNodes(rels,'Relationship').find(r=>r.getAttribute('Id')===firstRid);
  const sourceSheet=rfqXlsxResolve('xl/workbook.xml',firstRel.getAttribute('Target'));
  const sourceSheetText=await read(sourceSheet),sourceRelsText=await read(rfqXlsxRels(sourceSheet));
  const sourceRels=rfqXlsxParse(sourceRelsText);
  const oldSheets=rfqXlsxNodes(workbook,'sheets',rfqXlsxNS.sheet)[0];oldSheets.replaceChildren();
  for(const r of rfqXlsxNodes(rels,'Relationship'))if(/\/(worksheet|calcChain)$/.test(r.getAttribute('Type')))r.remove();
  const defined=rfqXlsxNodes(workbook,'definedNames',rfqXlsxNS.sheet)[0];
  const localNames=defined?[...defined.children].filter(n=>n.getAttribute('localSheetId')==='0'&&n.getAttribute('name')!=='_xlnm.Print_Area').map(n=>n.cloneNode(true)):[];
  if(defined)for(const n of [...defined.children])if(n.hasAttribute('localSheetId')||n.getAttribute('name')==='_xlnm.Print_Area')n.remove();
  const pageCount=Math.max(1,snapshot.pageCount||1,Math.ceil(snapshot.current.length/20),(snapshot.secondary||[]).length);
  const sharedStrings=rfqXlsxParse(await read('xl/sharedStrings.xml'));
  const strings=rfqXlsxNodes(sharedStrings,'si',rfqXlsxNS.sheet).map(si=>rfqXlsxNodes(si,'t',rfqXlsxNS.sheet).map(t=>t.textContent).join(''));
  const sourceDoc=rfqXlsxParse(sourceSheetText);
  const sourceCells=new Map(rfqXlsxNodes(sourceDoc,'c',rfqXlsxNS.sheet).map(c=>[c.getAttribute('r'),c]));
  const sourceValue=address=>{
    const c=sourceCells.get(address),value=c?rfqXlsxNodes(c,'v',rfqXlsxNS.sheet)[0]?.textContent||'':'';
    return c?.getAttribute('t')==='s'?strings[Number(value)]||'':value;
  };
  const materials=new Map();
  for(let row=51;row<=86;row++)materials.set(sourceValue('AE'+row),{name:sourceValue('AF'+row),density:Number(sourceValue('AG'+row))});
  const columns={no:'A',description:'B',materialCode:'E',thickness:'I',special:'J',width:'K',height:'L',length:'M',cc:'N',sp:'O',pc:'P',acp:'Q',otherCoat:'R',specialColor:'S',paintType:'T',brand:'U',sides:'V',qty:'W',unit:'X',cost:'Y',remark:'Z'};
  const numeric=new Set(['no','materialCode','thickness','width','height','length','qty','cost']);
  for(let pageIndex=0;pageIndex<pageCount;pageIndex++){
    const copied=new Map(),prefix='rfq'+(pageIndex+1)+'-';
    const clonePart=async source=>{
      if(copied.has(source))return copied.get(source);
      const slash=source.lastIndexOf('/'),path=source.slice(0,slash+1)+prefix+source.slice(slash+1);copied.set(source,path);
      output.file(path,files.get(source));addType(path,source);
      const sourceRelPath=rfqXlsxRels(source);
      if(original.file(sourceRelPath)){
        const partRels=rfqXlsxParse(await read(sourceRelPath));
        for(const r of rfqXlsxNodes(partRels,'Relationship')){
          if(r.getAttribute('TargetMode')==='External')continue;
          const dependency=rfqXlsxResolve(source,r.getAttribute('Target'));
          if(removed(dependency))r.setAttribute('Target',rfqXlsxRelative(path,await clonePart(dependency)));
        }
        output.file(rfqXlsxRels(path),rfqXlsxXml(partRels));
      }
      return path;
    };
    const path=await clonePart(sourceSheet);
    const sheet=rfqXlsxParse(sourceSheetText),write=rfqXlsxCellWriter(sheet),headers=snapshot.headers;
    // Legacy Excel control IDs are workbook-wide. Allocate another ID block
    // for each page; reusing them makes Excel discard later-page controls.
    const controlIds=new Map(rfqXlsxNodes(sheet,'control',rfqXlsxNS.sheet).map(c=>[c.getAttribute('shapeId'),String(Number(c.getAttribute('shapeId'))+pageIndex*1024)]));
    const titleFields={Z1:headers.documentNo,Z2:headers.job,C2:headers.project,C3:headers.customer,V3:headers.dueDay,W3:headers.dueMonth,X3:headers.dueYear,C43:headers.requester,C44:rfqXlsxRequestDate(headers.requestDate,headers.documentNo),Z45:`${pageIndex+1}/${pageCount}`};
    for(const [cell,value] of Object.entries(titleFields))write(cell,['V3','W3','X3'].includes(cell)?rfqXlsxNumber(value):value??'');
    for(const cell of ['H43','H44','S43','S44','V43','V44','Z43','Z44'])write(cell,'');
    // Twenty HTML rows map to Excel rows 7:26. Row 27 stays a blank spacer.
    for(const [start,count,rows,firstNo] of [[7,21,snapshot.current.slice(pageIndex*20,pageIndex*20+20),pageIndex*20+1],[31,11,snapshot.secondary?.[pageIndex]||[],1]]){
      for(let index=0;index<count;index++){
        const row=rows[index]||{},excelRow=start+index,exists=['description','materialCode','qty'].some(k=>String(row[k]??'').trim());
        for(const [key,col] of Object.entries(columns)){
          let value=row[key]??'';
          if(key==='no')value=exists?(row.no||String(firstNo+index)):'';
          write(col+excelRow,numeric.has(key)?rfqXlsxNumber(value):value);
        }
        if(exists){
          const description=rfqXlsxNodes(sheet,'c',rfqXlsxNS.sheet).find(c=>c.getAttribute('r')==='B'+excelRow);
          description.setAttribute('s',sourceCells.get('B7').getAttribute('s'));
        }
        const code=String(row.materialCode??'').trim(),material=materials.get(code);
        if(code&&(!material||material.name!==(snapshot.materials[code]||'')))throw new Error('รหัสวัสดุ '+code+' ไม่ตรงกับ Excel ต้นแบบ');
        const lookup=`VLOOKUP($E$${excelRow},$AE$50:$A`;
        write('F'+excelRow,code?material.density:'',`IF($E$${excelRow}="","",${lookup}G$86,3,FALSE))`);
        write('G'+excelRow,code?material.name:'',`IF($E$${excelRow}="","",${lookup}F$86,2,FALSE))`);
      }
    }
    const checks=snapshot.pageChecks?.[pageIndex]||snapshot.defaultChecks||{};
    const labelToKey={'เพื่อเสนอราคา':'quote','เพื่อผลิต':'production','ฝ้าเพดาน':'ceiling','แผงบังแดด':'sunshade','ผนังหุ้มอาคาร':'wall','อื่นๆ':'other','ภายในอาคาร':'inside','ภายนอกอาคาร':'outside'};
    const shapeChecks=new Map();
    for(const rel of rfqXlsxNodes(sourceRels,'Relationship')){
      if(!rel.getAttribute('Type').endsWith('/vmlDrawing'))continue;
      const sourceVml=rfqXlsxResolve(sourceSheet,rel.getAttribute('Target')),vml=rfqXlsxParse(await read(sourceVml));
      for(const shape of rfqXlsxNodes(vml,'shape',rfqXlsxNS.vml)){
        const client=rfqXlsxNodes(shape,'ClientData',rfqXlsxNS.excel)[0];
        if(client?.getAttribute('ObjectType')!=='Checkbox')continue;
        const label=rfqXlsxNodes(shape,'textbox',rfqXlsxNS.vml)[0]?.textContent.replace(/\s+/g,'').trim();
        const key=labelToKey[label];if(!key)throw new Error('ไม่รู้จักช่องติ๊ก Excel: '+label);
        const selected=Boolean(checks[key]);shapeChecks.set(shape.getAttribute('id').replace('_x0000_s',''),selected);
        for(const old of rfqXlsxNodes(client,'Checked',rfqXlsxNS.excel))old.remove();
        if(selected){const checked=vml.createElementNS(rfqXlsxNS.excel,'x:Checked');checked.textContent='1';client.append(checked);}
      }
      for(const shape of rfqXlsxNodes(vml,'shape',rfqXlsxNS.vml)){
        const old=shape.getAttribute('id').replace('_x0000_s','');
        if(controlIds.has(old))shape.setAttribute('id','_x0000_s'+controlIds.get(old));
      }
      for(const idmap of rfqXlsxNodes(vml,'idmap'))idmap.setAttribute('data',String(Number(idmap.getAttribute('data'))+pageIndex));
      output.file(copied.get(sourceVml),rfqXlsxXml(vml));
    }
    for(const control of rfqXlsxNodes(sheet,'control',rfqXlsxNS.sheet)){
      const shape=control.getAttribute('shapeId');if(!shapeChecks.has(shape))continue;
      const rid=control.getAttributeNS(rfqXlsxNS.officeRel,'id'),rel=rfqXlsxNodes(sourceRels,'Relationship').find(r=>r.getAttribute('Id')===rid);
      const originalProp=rfqXlsxResolve(sourceSheet,rel.getAttribute('Target')),prop=rfqXlsxParse(await read(originalProp));
      if(shapeChecks.get(shape))prop.documentElement.setAttribute('checked','Checked');
      else prop.documentElement.removeAttribute('checked');
      output.file(copied.get(originalProp),rfqXlsxXml(prop));
    }
    for(const control of rfqXlsxNodes(sheet,'control',rfqXlsxNS.sheet))control.setAttribute('shapeId',controlIds.get(control.getAttribute('shapeId')));
    for(const rel of rfqXlsxNodes(sourceRels,'Relationship')){
      if(!rel.getAttribute('Type').endsWith('/drawing'))continue;
      const sourceDrawing=rfqXlsxResolve(sourceSheet,rel.getAttribute('Target'));
      let drawing=await read(sourceDrawing);
      for(const [old,next] of controlIds)if(old!==next){
        drawing=drawing.replaceAll(`id="${old}"`,`id="${next}"`).replaceAll(`_x0000_s${old}`,`_x0000_s${next}`);
      }
      output.file(copied.get(sourceDrawing),drawing);
    }
    sheet.documentElement.setAttributeNS('http://schemas.microsoft.com/office/spreadsheetml/2014/revision','xr:uid',`{00000000-0001-0000-0000-${String(pageIndex+1).padStart(12,'0')}}`);
    const sheetPr=rfqXlsxNodes(sheet,'sheetPr',rfqXlsxNS.sheet)[0];if(sheetPr)sheetPr.setAttribute('codeName','RFQPage'+(pageIndex+1));
    for(const view of rfqXlsxNodes(sheet,'sheetView',rfqXlsxNS.sheet)){view.setAttribute('tabSelected',pageIndex===0?'1':'0');view.setAttribute('topLeftCell','A1');}
    for(const selection of rfqXlsxNodes(sheet,'selection',rfqXlsxNS.sheet)){selection.setAttribute('activeCell','A1');selection.setAttribute('sqref','A1');}
    output.file(path,rfqXlsxXml(sheet));
    const sheetNode=workbook.createElementNS(rfqXlsxNS.sheet,'sheet'),rid='rIdRFQ'+(pageIndex+1),name=String(pageIndex+1);
    sheetNode.setAttribute('name',name);sheetNode.setAttribute('sheetId',String(pageIndex+1));sheetNode.setAttributeNS(rfqXlsxNS.officeRel,'r:id',rid);oldSheets.append(sheetNode);
    const rel=rels.createElementNS(rfqXlsxNS.rel,'Relationship');rel.setAttribute('Id',rid);rel.setAttribute('Type',rfqXlsxNS.officeRel+'/worksheet');rel.setAttribute('Target',rfqXlsxRelative('xl/workbook.xml',path));rels.documentElement.append(rel);
    if(defined){
      for(const originalName of localNames){const clone=originalName.cloneNode(true);clone.setAttribute('localSheetId',String(pageIndex));defined.append(clone);}
      const area=workbook.createElementNS(rfqXlsxNS.sheet,'definedName');area.setAttribute('name','_xlnm.Print_Area');area.setAttribute('localSheetId',String(pageIndex));area.textContent=`'${name}'!$A$1:$Z$45`;defined.append(area);
    }
    await new Promise(resolve=>setTimeout(resolve,0));
  }
  for(const view of rfqXlsxNodes(workbook,'workbookView',rfqXlsxNS.sheet)){view.setAttribute('activeTab','0');view.setAttribute('firstSheet','0');}
  let calc=rfqXlsxNodes(workbook,'calcPr',rfqXlsxNS.sheet)[0];
  if(!calc){calc=workbook.createElementNS(rfqXlsxNS.sheet,'calcPr');workbook.documentElement.append(calc);}
  calc.setAttribute('fullCalcOnLoad','1');calc.setAttribute('forceFullCalc','1');calc.setAttribute('calcMode','auto');
  output.file('xl/workbook.xml',rfqXlsxXml(workbook));output.file('xl/_rels/workbook.xml.rels',rfqXlsxXml(rels));output.file('[Content_Types].xml',rfqXlsxXml(contentTypes));
  // Keep document properties consistent with the actual generated pages.
  if(original.file('docProps/app.xml')){
    const app=rfqXlsxParse(await read('docProps/app.xml'));
    const titles=rfqXlsxNodes(app,'TitlesOfParts')[0]?.firstElementChild;
    if(titles){
      titles.replaceChildren();titles.setAttribute('size',String(pageCount*2));
      for(const label of [...Array.from({length:pageCount},(_,i)=>String(i+1)),...Array.from({length:pageCount},(_,i)=>`'${i+1}'!Print_Area`)]){
        const e=app.createElementNS(titles.namespaceURI,'vt:lpstr');e.textContent=label;titles.append(e);
      }
    }
    const heading=rfqXlsxNodes(app,'HeadingPairs')[0];if(heading)for(const count of rfqXlsxNodes(heading,'i4'))count.textContent=String(pageCount);
    output.file('docProps/app.xml',rfqXlsxXml(app));
  }
  return output.generateAsync({type:'blob',mimeType:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',compression:'DEFLATE',compressionOptions:{level:6}});
}
document.getElementById('save-excel').addEventListener('click',async event=>{
  const button=event.currentTarget;if(button.disabled)return;
  const name=exportFileBase(),snapshot=structuredClone(model);button.disabled=true;button.setAttribute('aria-busy','true');fileSaveStatus.textContent='กำลังสร้าง Excel…';
  try{
    const blob=await rfqCreateXlsx(snapshot),url=URL.createObjectURL(blob),link=document.createElement('a');
    link.href=url;link.download=name+'.xlsx';document.body.append(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),60000);
    const bytes=new Uint8Array(await blob.arrayBuffer());let binary='';
    for(let i=0;i<bytes.length;i+=32768)binary+=String.fromCharCode(...bytes.subarray(i,i+32768));
    const again=document.createElement('a');again.id='excel-download-again';again.download=name+'.xlsx';
    again.href='data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,'+btoa(binary);
    again.textContent='ดาวน์โหลดอีกครั้ง';
    fileSaveStatus.replaceChildren(document.createTextNode(`ดาวน์โหลดแล้ว: ${name}.xlsx `),again);
  }catch(error){console.error('RFQ Excel export:',error);fileSaveStatus.textContent='สร้าง Excel ไม่สำเร็จ: '+error.message;}
  finally{button.disabled=false;button.removeAttribute('aria-busy');}
});
