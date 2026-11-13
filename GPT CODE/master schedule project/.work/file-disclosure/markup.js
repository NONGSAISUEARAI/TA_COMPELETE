function taskFilesBadge(task){
 const catalog=task.fileCatalog,count=Array.isArray(catalog?.files)?Math.min(catalog.files.length,FILE_LIMIT):0,selected=selectedCatalogFiles(catalog),open=expandedFileLists.has(task.id),id=escapeHTML(task.id);
 return '<details class="task-files-disclosure" data-files-task="'+id+'" '+(open?'open':'')+'><summary id="file-toggle-'+id+'" aria-controls="file-body-'+id+'" aria-expanded="'+open+'" title="ยุบหรือขยายไฟล์ประกอบงาน '+escapeHTML(task.name)+'"><span class="file-disclosure-arrow" aria-hidden="true"></span><span class="file-disclosure-label">ไฟล์ที่เลือก '+selected.length.toLocaleString('th-TH')+' / '+count.toLocaleString('th-TH')+'</span></summary></details>';
}
function taskFilesBody(task){
 const selected=selectedCatalogFiles(task.fileCatalog),id=escapeHTML(task.id);
 return '<div class="task-files-body" id="file-body-'+id+'" data-files-body="'+id+'" role="region" aria-labelledby="file-toggle-'+id+'"'+(expandedFileLists.has(task.id)?'':' hidden')+'>'+(selected.length?'<ul class="task-file-preview">'+selected.slice(0,5).map(f=>'<li title="'+escapeHTML(f.path)+'">'+fileLinkMarkup(task.fileCatalog,f)+(fileParent(f.path)?'<small>'+escapeHTML(fileParent(f.path))+'</small>':'')+'</li>').join('')+'</ul>':'<p class="task-files-empty">ยังไม่มีไฟล์ที่เลือก</p>')+'<button type="button" class="task-selected-more" data-task-files="'+id+'" data-selected-only="'+(selected.length>5)+'">'+(selected.length>5?'ดูที่เลือกทั้งหมด ('+selected.length.toLocaleString('th-TH')+')':'ดูรายการไฟล์ทั้งหมด')+'</button></div>';
}
function syncTaskFilesDisclosure(details){
 const id=details.dataset.filesTask;if(!state.tasks.some(t=>t.id===id))return;
 if(details.open)expandedFileLists.add(id);else expandedFileLists.delete(id);
 const body=details.parentElement?.nextElementSibling;
 if(body?.dataset.filesBody===id)body.hidden=!details.open;
 details.querySelector('summary')?.setAttribute('aria-expanded',String(details.open));
}
