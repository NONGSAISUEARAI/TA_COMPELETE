const fs=require('fs'),assert=require('assert/strict');
const file='Master_Schedule.html';let html=fs.readFileSync(file,'utf8');
const data=html.match(/<script id="schedule-data"[^>]*>([\s\S]*?)<\/script>/)[1];
const start=html.indexOf('function taskRow('),end=html.indexOf('\nfunction render()',start);let row=html.slice(start,end);
assert(row.includes("return '<tr class="));row=row.replace("return '<tr class=","return inlineRowMarkup('<tr class=");assert(row.includes("</td></tr>'}"));row=row.replace("</td></tr>'}","</td></tr>',t,main)}");html=html.slice(0,start)+row+html.slice(end);
html=html.replace('function render(){','function render(){\n cancelInlineEdit(false);');
html=html.replace('refreshOrderUI()}','refreshOrderUI();refreshInlineRole();if(!isEditor)cancelInlineEdit()}');
const feature=fs.readFileSync('.work/inline-edit.js','utf8');html=html.replace('render();saveStatus();\n</script>',feature+'\nrender();saveStatus();\n</script>');assert(html.includes('function inlineUpdate('));
html=html.replace('</head>',`<style>
body[data-role="editor"] .inline-cell{cursor:text;outline-offset:-2px}body[data-role="editor"] .inline-cell:hover{box-shadow:inset 0 0 0 1px #79cbb6;background-color:#24433e!important}.inline-cell:focus-visible{outline:2px solid #9cddc9}.inline-editing{position:relative!important;overflow:visible!important;z-index:5}.inline-editor{display:flex;flex-wrap:wrap;gap:4px;min-width:0;width:100%;padding:3px}.inline-editor input{font:inherit;font-size:12px;min-width:0;width:100%;padding:7px 4px;border:1px solid #91d7bf;border-radius:4px;background:#102630;color:#e1f4ed;color-scheme:dark}.inline-editor-actions{display:flex;gap:4px}.inline-editor button{padding:3px 10px;min-height:28px;border-color:#70aa9d;background:#24483e;color:#def9eb}.inline-error{display:block;flex-basis:100%;white-space:normal;color:#ffb7ad;font-size:10px;line-height:1.5}.date-line.inline-editing{height:auto;min-height:36px;white-space:normal}.inline-cell.inline-editing .inline-editor{flex:1}.inline-cell.inline-editing .inline-editor input{font-size:11px}@media print{.inline-editor{display:none!important}}
</style></head>`);
assert.equal(html.match(/<script id="schedule-data"[^>]*>([\s\S]*?)<\/script>/)[1],data);fs.writeFileSync(file,html);console.log('Installed inline editing; embedded data unchanged.');
