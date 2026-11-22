const fileNameInput=document.getElementById('file-name');
const fileMaterialInput=document.getElementById('file-material');
const fileSaveStatus=document.getElementById('file-save-status');
model.fileNaming=model.fileNaming||{materialName:'ถาดไฟ VA และ SOLID',baseName:'',manual:false};
function safeFileBase(value){
  return String(value||'').replace(/[<>:"/\\|?*\u0000-\u001f]/g,'-').replace(/\.(?:html?|pdf)$/i,'').replace(/\s+/g,' ').replace(/[. ]+$/g,'').trim();
}
function automaticFileBase(){
  const documentNo=String(model.headers.documentNo||'BU2-DE-26xxx').trim();
  const project=String(model.headers.project||'').replace(/^\s*โครงการ\s*/,'').trim();
  return safeFileBase(`${documentNo}_โครงการ ${project} ${model.fileNaming.materialName||''}`);
}
function syncFileName(forceAutomatic=false){
  if(forceAutomatic)model.fileNaming.manual=false;
  if(!model.fileNaming.manual||!model.fileNaming.baseName)model.fileNaming.baseName=automaticFileBase();
  fileNameInput.value=model.fileNaming.baseName;
  if(fileMaterialInput.value!==(model.fileNaming.materialName||''))fileMaterialInput.value=model.fileNaming.materialName||'';
  document.title=safeFileBase(model.fileNaming.baseName)||automaticFileBase();
  model.downloadFilename=document.title+'.html';
}
function exportFileBase(){
  const name=safeFileBase(fileNameInput.value)||automaticFileBase();
  fileNameInput.value=name;model.fileNaming.baseName=name;document.title=name;
  model.downloadFilename=name+'.html';return name;
}
fileMaterialInput.addEventListener('input',()=>{
  model.fileNaming.materialName=fileMaterialInput.value;
  if(!model.fileNaming.manual)syncFileName();
  fileSaveStatus.textContent='';
});
fileNameInput.addEventListener('input',()=>{
  model.fileNaming.manual=true;model.fileNaming.baseName=fileNameInput.value;
  document.title=safeFileBase(fileNameInput.value)||automaticFileBase();fileSaveStatus.textContent='';
});
fileNameInput.addEventListener('blur',()=>{exportFileBase();});
document.getElementById('auto-file-name').addEventListener('click',()=>{syncFileName(true);fileSaveStatus.textContent='ตั้งชื่อไฟล์ตามเลขที่ใบขอ โครงการ และชื่อวัสดุแล้ว';});
window.addEventListener('beforeprint',()=>{exportFileBase();calibrate();});
document.getElementById('save-pdf').addEventListener('click',async()=>{
  const name=exportFileBase();
  if(document.fonts)await document.fonts.ready;
  calibrate();
  fileSaveStatus.textContent=`เลือก “บันทึกเป็น PDF / Save as PDF” แล้วใช้ชื่อ ${name}.pdf`;
  // The browser owns the final PDF destination and confirmation dialog.
  // The document title supplies the suggested PDF filename.
  window.print();
});
syncFileName();
