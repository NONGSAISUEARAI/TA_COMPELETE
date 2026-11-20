import fs from 'node:fs/promises';
import path from 'node:path';
import {createRequire} from 'node:module';
import {pathToFileURL} from 'node:url';
const req=createRequire('C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1119-907-0_26.1119.907.0_x64__3k8sg7r9htsxt/dependencies/node/node_modules/package.json');
const {FileBlob,SpreadsheetFile}=await import(pathToFileURL(req.resolve('@oai/artifact-tool')).href);
const root=path.resolve(import.meta.dirname,'..');
const old=path.join(root,'outputs/rfq_26106_rev01');
const source=(await fs.readdir(old)).find(n=>n.endsWith('.xlsm')&&!n.includes('REV'));
const data=JSON.parse(await fs.readFile(path.join(old,'source_table.json'),'utf8'));
const dir=path.join(root,'outputs/rfq_26106_corrected');await fs.mkdir(dir,{recursive:true});
const sorted=data.map((x,i)=>({kind:x[0],w1:x[1],w2:x[2],finish:x[3],qty:x[4],original:i+1})).sort((a,b)=>a.finish.localeCompare(b.finish,'en')||(a.w1+a.w2)-(b.w1+b.w2)||a.w1-b.w1||a.w2-b.w2||a.original-b.original);
const wb=await SpreadsheetFile.importXlsx(await FileBlob.load(path.join(old,source)));
const edits={};
for(let page=1;page<=2;page++){
 const sh=wb.worksheets.getItem(String(page)); const e={Z1:'BU2-DE-26106',Z2:'PJ25-031',Z45:`${page}/2`};
 for(let r=7;r<=26;r++)for(const c of 'ABEIJKLMNPQRSTUVWXZ')e[c+r]=null;
 sorted.slice((page-1)*20,page*20).forEach((x,j)=>{
  const r=7+j;const no=(page-1)*20+j+1;
  const part=`AL.1.2mm.thk.TRAY-LT 249x(${x.w1}+${x.w2})mm. L=${x.w1+x.w2}mm.`;
  const code=`PJ25-031AL-TRAY-LT-VA-${String(no).padStart(2,'0')}`;
  Object.assign(e,{['A'+r]:no,['B'+r]:`${part}\n(${code})`,['E'+r]:1,['I'+r]:1.2,['J'+r]:'1100 H14',['K'+r]:249,['M'+r]:x.w1+x.w2,['V'+r]:'1 ด้าน',['W'+r]:x.qty.reduce((a,b)=>a+b,0),['X'+r]:'ชิ้น'});
  const station=['PP17','PP18','PP19','PP20'].filter((s,i)=>[x.qty[0]+x.qty[1]+x.qty[2],x.qty[3],x.qty[4]+x.qty[5],x.qty[6]][i]>0).join(' / ');
  if(x.finish==='SD-9211'){e['P'+r]=x.finish;e['Z'+r]=station;}
  else{
   const db={'NS-1S-E0114':['PE or PC','CORNEL','PC21010087'],'S2214V':['PE or PC','AKZO NOBEL','PC21010085'],'SA-09101':['WET-P or SP','THAI PAINT','PC21010083']}[x.finish];
   e['S'+r]=x.finish;e['T'+r]=db[0];e['U'+r]=db[1];e['Z'+r]=db[2]+'\n'+station;
  }
 });
 for(let r=7;r<=26;r++){if(e['V'+r]!==null)e['V'+r]='1 \u0e14\u0e49\u0e32\u0e19';if(e['X'+r]!==null)e['X'+r]='\u0e0a\u0e34\u0e49\u0e19';}
 for(const [a,v] of Object.entries(e))sh.getRange(a).values=[[v]];
 sh.getRange('B7:D26').format.wrapText=true;
 edits[String(page)]=e;
}
wb.recalculate();
await fs.writeFile(path.join(dir,'edits.json'),JSON.stringify(edits));
await fs.writeFile(path.join(dir,'sorted_source.json'),JSON.stringify(sorted,null,2));
await (await SpreadsheetFile.exportXlsx(wb)).save(path.join(dir,'verification.xlsx'));
console.log(JSON.stringify({items:sorted.length,total:sorted.reduce((a,x)=>a+x.qty.reduce((s,n)=>s+n,0),0),output:dir}));
