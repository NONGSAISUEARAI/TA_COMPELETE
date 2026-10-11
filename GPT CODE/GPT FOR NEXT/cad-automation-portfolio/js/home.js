"use strict";
// Homepage preview only. No CAD evaluation, analytics, external requests or downloads.
const copy = {
  th: {
    skip:"ข้ามไปเนื้อหา",navTools:"คลังคำสั่ง",navAbout:"เกี่ยวกับพอร์ต",tagline:"เปลี่ยนงานเขียนแบบที่ทำซ้ำ\nให้เป็นขั้นตอนที่ชัดเจนและตรวจสอบได้",
    intro:"พอร์ตเครื่องมือสำหรับ Block, Dynamic Block และงานจัดการข้อมูลในแบบ เริ่มจากปัญหาที่ต้องแก้ ไปจนถึงวิธีใช้และข้อจำกัดของแต่ละคำสั่ง",
    explore:"สำรวจคำสั่ง",featuredLink:"ดูผลงานที่กำลังคัดเลือก",heroNote:"TH / EN · แยกตามงานใช้งานจริง · ระบุสถานะการตรวจ",
    conceptStatus:"ถ่ายทอดค่า Length จากต้นแบบ",conceptButton:"ลองภาพแนวคิด",conceptDone:"ภาพแนวคิด: Length ของเป้าหมายตรงกับต้นแบบ",conceptReset:"คืนค่าภาพตัวอย่าง",
    conceptDisclaimer:"ภาพอธิบายแนวคิด ไม่ใช่ GIF หรือผลทดสอบจาก AutoCAD",workflow:"เส้นทางสำรวจ",step1:"01 เลือกหมวด",step2:"02 ดูคำสั่ง",step3:"03 วิธีใช้และสื่อสาธิต",
    toolsTitle:"เริ่มจากงานที่ต้องการทำ",toolsIntro:"แยกหมวดตามการใช้งาน\nไม่ต้องจำชื่อคำสั่งก่อนเริ่มค้นหา",categoryNote:"หมวดด้านบนเป็นโครงสร้างตัวอย่าง คลิกเพื่อกรองผลงานที่กำลังคัดเลือกด้านล่าง",
    featuredTitle:"เครื่องมือที่กำลังคัดเลือก",showAll:"แสดงทั้งหมด ↗",empty:"หมวดนี้ยังไม่มีผลงานในตัวอย่างหน้าแรก จะเพิ่มหลังคัดเลือกและตรวจคำสั่งแล้ว",
    reviewNote:"รายการนี้ผ่านการอ่าน source แต่ยังไม่ได้ทดสอบการทำงานใน CAD และยังไม่มีไฟล์ดาวน์โหลดหรือ GIF จริงในหน้าเว็บตัวอย่างนี้",
    aboutTitle:"ไม่ได้เล่าแค่คำสั่ง\nแต่เล่าวิธีแก้ปัญหา",profilePlaceholder:"ส่วนแนะนำผู้พัฒนา — รอเติมชื่อ ประวัติ และช่องทางติดต่อ",
    aboutLead:"พอร์ตนี้รวบรวม workflow อัตโนมัติสำหรับงานเขียนแบบ โดยแสดงว่าคำสั่งทำอะไร ใช้ข้อมูลใด และมีข้อจำกัดตรงไหน",
    principle1:"เริ่มจากปัญหา",principle1Body:"อธิบายงานที่ทำซ้ำและสิ่งที่เครื่องมือช่วยจัดการ",principle2:"แสดงหลักฐาน",principle2Body:"ใช้ source และสื่อสาธิตจริง ไม่อ้างผลลัพธ์ที่ยังไม่ทดสอบ",principle3:"บอกขอบเขต",principle3Body:"ระบุ compatibility, dependencies และเครดิตของ helpers",
    footerNote:"ตัวอย่างหน้าแรก · ยังไม่เผยแพร่ · TH / EN",backTop:"กลับด้านบน ↑",close:"ปิด ×",sourceState:"ตรวจ source แล้ว · รอทดสอบ CAD",openTool:"ดูภาพรวมคำสั่ง",limitations:"ข้อจำกัดที่พบจาก source",dialogNote:"หน้านี้เป็นตัวอย่างโครงสร้างพอร์ต ยังไม่มี GIF จริงหรือไฟล์ดาวน์โหลด และไม่ได้รันคำสั่ง CAD",commandLabel:"ชื่อคำสั่งจริง",filtered:"กำลังดูหมวด: ",allStatus:"ตัวอย่างผลงานเด่นจากการคัดเลือกเบื้องต้น",auditLink:"อ่านรายงานตรวจ source (Markdown)",categoriesLabel:"หมวดเครื่องมือ",dialogClose:"ปิดรายละเอียดคำสั่ง"
  },
  en: {
    skip:"Skip to content",navTools:"Tool library",navAbout:"About",tagline:"Turn repetitive drafting\ninto clear, verifiable workflows.",
    intro:"A portfolio of tools for blocks, dynamic blocks and drawing data. Explore the problem behind each workflow, how it works, and where its limits are.",
    explore:"Explore the tools",featuredLink:"View selected work",heroNote:"TH / EN · Organized by workflow · Review status included",
    conceptStatus:"Transfer Length from the reference",conceptButton:"Try the concept",conceptDone:"Concept: target lengths now match the reference",conceptReset:"Reset the concept",
    conceptDisclaimer:"Concept illustration, not an AutoCAD recording or test result",workflow:"EXPLORE THE LIBRARY",step1:"01 Choose a category",step2:"02 Explore a tool",step3:"03 Usage & demonstrations",
    toolsTitle:"Start with the task at hand.",toolsIntro:"Organized by practical use.\nNo command name needed to get started.",categoryNote:"These categories preview the site structure. Select one to filter the shortlisted tools below.",
    featuredTitle:"Selected tools. Under review.",showAll:"View all ↗",empty:"No tools are included in this category yet. Entries will be added after selection and source review.",
    reviewNote:"These tools have been reviewed in source only, not tested in CAD. This homepage preview has no real GIF recordings or downloadable Lisp files yet.",
    aboutTitle:"Not just commands.\nThe thinking behind them.",profilePlaceholder:"Developer introduction — name, background and contact details to be added.",
    aboutLead:"This portfolio documents drafting automation workflows: what a tool changes, what information it needs, and which limitations matter.",
    principle1:"Start with a problem",principle1Body:"Explain the repetitive task and what the tool helps manage.",principle2:"Show the evidence",principle2Body:"Use source and real demonstrations, not untested performance claims.",principle3:"Define the boundaries",principle3Body:"Document compatibility, dependencies and third-party helper credits.",
    footerNote:"Local homepage preview · Unpublished · TH / EN",backTop:"Back to top ↑",close:"Close ×",sourceState:"Source reviewed · CAD testing pending",openTool:"Explore the workflow",limitations:"Limitations found in source",dialogNote:"This is a portfolio structure preview. No real GIF, Lisp download or CAD execution is included.",commandLabel:"Actual command name",filtered:"Category: ",allStatus:"Featured candidates from the initial selection",auditLink:"Read the source review (Markdown)",categoriesLabel:"Tool categories",dialogClose:"Close tool overview"
  }
};
const categories = [
  {id:"block-dynamic",th:"Block และ Dynamic Block",en:"Block & Dynamic Block",sub:"Naming · Properties · Selection"},
  {id:"attributes-text",th:"Attribute ข้อความ และเลขลำดับ",en:"Attributes, Text & Numbering",sub:"Tags · Values · Annotations"},
  {id:"selection-inspection",th:"คัดเลือกและตรวจสอบวัตถุ",en:"Selection & Inspection",sub:"Filter · Inspect · Validate"},
  {id:"geometry-placement",th:"เรขาคณิตและการวางตำแหน่ง",en:"Geometry & Placement",sub:"Position · Align · Repeat"},
  {id:"drawing-standards",th:"มาตรฐานงานเขียนแบบ",en:"Drawing Standards",sub:"Layers · Colors · Units"},
  {id:"layout-documentation",th:"Layout และจัดทำแบบ",en:"Layout & Documentation",sub:"Layouts · Viewports · Sheets"},
  {id:"data-reporting",th:"ข้อมูลและรายงาน",en:"Data & Reporting",sub:"Counts · Summaries · Excel / CSV"}
];
const tools = [
  {id:"dynamic",title:"Match Dynamic Properties",th:"จับคู่คุณสมบัติ Dynamic Block",category:"block-dynamic",tags:["block-dynamic"],command:"matching_dynamic_properties_madynprop",
   description:{th:"ถ่ายทอดค่า parameter จาก block ต้นแบบไปยังเป้าหมายหลายชิ้น",en:"Transfer parameter values from a reference block to multiple targets."},
   detail:{th:"อ่านรายการ dynamic properties จากต้นแบบ แล้วเขียน property ชื่อเดียวกันลง block เป้าหมาย โดยข้ามชื่อ Origin ไม่ได้คัดลอก attributes, layer หรือ scale",en:"Reads dynamic properties from a reference and writes same-named properties to targets, skipping Origin. It does not copy attributes, layer or scale."},
   limits:{th:"ยังขาดการตรวจ Dynamic Block, ReadOnly, AllowedValues และการอ่านค่ากลับหลังเขียน การจับคู่ชื่อไม่ได้รับรองว่า property ของ block คนละชนิดมีความหมายตรงกัน",en:"Needs dynamic-block validation, ReadOnly and AllowedValues checks, and write readback. Matching names do not guarantee matching semantics across different block definitions."}},
  {id:"attributes",title:"Match Block Attributes",th:"ถ่ายทอดข้อมูล Attribute ตาม Tag",category:"attributes-text",tags:["attributes-text","block-dynamic"],command:"matching_attribute_properties_maatt",
   description:{th:"จับคู่ tag และถ่ายทอดข้อมูล พร้อมแนวทางข้ามค่าต้นแบบที่ว่าง",en:"Match attribute tags and transfer values, with a blank-source skip option."},
   detail:{th:"อ่าน tag/value จากต้นแบบแล้วเขียนลง attributes ของเป้าหมาย โหมด skip_blank_val_=0 เก็บค่าปลายทางเมื่อ source เป็นข้อความว่าง ไม่ได้เปลี่ยน attribute definitions หรือสั่ง ATTSYNC",en:"Reads source tag/value pairs and writes target attributes. With skip_blank_val_=0, blank source values retain the target value. It does not alter attribute definitions or run ATTSYNC."},
   limits:{th:"ต้องตรวจต้นแบบและ tag ที่มีจริงในเป้าหมาย พร้อมรายงานรายการที่ข้ามหรือล้มเหลว ยังไม่รับรอง constant หรือ multiline attributes ทุกกรณี",en:"Needs source validation, actual target-tag checks and skipped/failed write reporting. Full constant and multiline attribute support is not yet verified."}},
  {id:"rename",title:"Rename Block from Text",th:"เปลี่ยนชื่อ Block จากข้อความ",category:"block-dynamic",tags:["block-dynamic","drawing-standards"],command:"rename_block_RENBLKV2_RENB3x",
   description:{th:"ใช้ข้อความชื่อเดิมและชื่อใหม่เพื่อเปลี่ยนชื่อ block definition",en:"Use old-name and new-name text objects to rename a block definition."},
   detail:{th:"เลือก object ที่มี TextString สองตัว หา block definition ชื่อเดิม และเปลี่ยนชื่อ มีตัวแปรภายในและจับข้อผิดพลาดขณะ lookup/rename การเปลี่ยนชื่อมีผลกับ references ที่ใช้ definition ร่วมกัน",en:"Selects two TextString-bearing objects, looks up the old definition and renames it. Includes local variables and lookup/rename error handling. Renaming affects all references sharing that definition."},
   limits:{th:"ต้องป้องกัน object ที่ไม่มี TextString ตรวจชื่อว่าง ชื่อชนกัน formatting และ definitions ที่ไม่ควรเปลี่ยน ยังไม่ได้ทดสอบ runtime",en:"Needs TextString input validation, blank/collision/formatting checks and protected-definition handling. Runtime behavior has not been tested."}}
];
let language = "th";
let activeCategory = null;
let conceptMatched = false;
let activeTool = null;
const categoryGrid = document.getElementById("category-grid");
const toolGrid = document.getElementById("tool-grid");
const dialog = document.getElementById("tool-dialog");
const diagramArt = {
  dynamic:'<path d="M54 41H247V60H54Z M54 86H155V105H54Z"/><path d="M54 128H247" stroke-dasharray="4 4"/><path d="M272 45V100M263 91L272 100L281 91"/><path d="M54 45V130M247 45V130" stroke-dasharray="3 5"/>',
  attributes:'<rect x="52" y="31" width="98" height="88"/><rect x="187" y="31" width="98" height="88"/><path d="M52 57H150M52 81H150M187 57H285M187 81H285M160 75H177M171 69L177 75L171 81"/><g fill="#42786d" stroke="none" font-family="Consolas,monospace" font-size="10"><text x="64" y="49">CODE</text><text x="64" y="74">A-01</text><text x="64" y="99">FRAME</text><text x="199" y="49">CODE</text><text x="199" y="74">A-01</text><text x="199" y="99">FRAME</text></g>',
  rename:'<rect x="53" y="36" width="228" height="27"/><rect x="53" y="86" width="228" height="27"/><path d="M165 68V81M160 76L165 81L170 76"/><g fill="#42786d" stroke="none" font-family="Consolas,monospace" font-size="11"><text x="68" y="54">OLD_BLOCK_NAME</text><text x="68" y="104">NEW_BLOCK_NAME</text></g>'
};
function svgArt(id) {
  return `<svg viewBox="0 0 335 149" aria-hidden="true"><defs><pattern id="grid-${id}" width="18" height="18" patternUnits="userSpaceOnUse"><path d="M18 0H0V18" fill="none" stroke="#779b8f" stroke-opacity=".16"/></pattern></defs><rect width="335" height="149" fill="url(#grid-${id})"/><g fill="none" stroke="#4b8577" stroke-width="1.3">${diagramArt[id]}</g></svg>`;
}
function renderCategories() {
  categoryGrid.setAttribute("aria-label",copy[language].categoriesLabel);
  categoryGrid.innerHTML = categories.map((category,index) => `<button type="button" class="category" data-category="${category.id}" aria-pressed="${category.id===activeCategory}" aria-controls="tool-grid"><span class="category-top"><span>0${index+1}</span><span class="category-arrow" aria-hidden="true">↗</span></span><span class="category-title">${category[language]}</span><span class="category-sub">${language==="th"?category.en:category.sub}</span></button>`).join("");
}
function renderTools() {
  const visible = tools.filter(tool=>!activeCategory || tool.tags.includes(activeCategory));
  toolGrid.innerHTML = visible.map(tool=>`<article class="tool-card"><div class="tool-art"><span class="art-label">WORKFLOW / ${tool.id.toUpperCase()}</span>${svgArt(tool.id)}</div><div class="tool-body"><p class="tool-category">${categories.find(category=>category.id===tool.category).en.toUpperCase()}</p><h3>${tool.title}</h3>${language==="th"?`<p class="tool-thai">${tool.th}</p>`:""}<p class="tool-description">${tool.description[language]}</p><p class="tool-state">${copy[language].sourceState}</p><button class="tool-open" type="button" data-tool="${tool.id}" aria-haspopup="dialog" aria-label="${copy[language].openTool}: ${tool.title}"><span>${copy[language].openTool}</span><span aria-hidden="true">↗</span></button></div></article>`).join("");
  document.getElementById("empty-state").hidden = visible.length>0;
  const selected = categories.find(category=>category.id===activeCategory);
  document.getElementById("filter-status").textContent = selected?copy[language].filtered+selected[language]:copy[language].allStatus;
}
function renderConcept() {
  document.getElementById("drawing-card").classList.toggle("matched",conceptMatched);
  document.querySelectorAll(".target-value").forEach((node,index)=>node.textContent=`Length: ${conceptMatched?600:[300,420][index]}`);
  document.getElementById("concept-status").textContent = copy[language][conceptMatched?"conceptDone":"conceptStatus"];
  document.querySelector("#concept-toggle span:first-child").textContent = copy[language][conceptMatched?"conceptReset":"conceptButton"];
  document.getElementById("concept-toggle").setAttribute("aria-pressed",String(conceptMatched));
}
function renderDialog(tool) {
  document.getElementById("dialog-content").innerHTML = `<h2 class="dialog-title" id="dialog-title">${tool.title}</h2>${language==="th"?`<p class="dialog-subtitle">${tool.th}</p>`:""}<p class="dialog-command">${copy[language].commandLabel}<br><code>${tool.command}</code></p><p class="dialog-content-text">${tool.detail[language]}</p><div class="dialog-limits"><strong>${copy[language].limitations}</strong>${tool.limits[language]}</div><p class="dialog-note">${copy[language].dialogNote}</p><a class="dialog-action" href="docs/block-static-audit.md" target="_blank" rel="noopener">${copy[language].auditLink} ↗</a>`;
}
function setLanguage(next) {
  language = next;
  document.documentElement.lang = language;
  document.querySelectorAll("[data-i18n]").forEach(node=>{node.textContent=copy[language][node.dataset.i18n] || node.textContent;});
  const languageButton = document.getElementById("language-toggle");
  languageButton.innerHTML = `${language==="th"?"EN":"TH"} <span aria-hidden="true">↗</span>`;
  languageButton.setAttribute("aria-label",language==="th"?"Switch to English":"เปลี่ยนเป็นภาษาไทย");
  document.getElementById("dialog-close").setAttribute("aria-label",copy[language].dialogClose);
  renderCategories(); renderTools(); renderConcept();
  if(activeTool) renderDialog(activeTool);
}
document.getElementById("language-toggle").addEventListener("click",()=>setLanguage(language==="th"?"en":"th"));
document.getElementById("concept-toggle").addEventListener("click",()=>{conceptMatched=!conceptMatched;renderConcept();});
categoryGrid.addEventListener("click",event=>{
  const button=event.target.closest("[data-category]");
  if(!button) return;
  activeCategory=activeCategory===button.dataset.category?null:button.dataset.category;
  renderCategories();renderTools();
  categoryGrid.querySelector(`[data-category="${button.dataset.category}"]`).focus({preventScroll:true});
  document.getElementById("featured").scrollIntoView({behavior:window.matchMedia("(prefers-reduced-motion: reduce)").matches?"instant":"smooth"});
});
document.getElementById("reset-filter").addEventListener("click",()=>{activeCategory=null;renderCategories();renderTools();});
toolGrid.addEventListener("click",event=>{
  const button=event.target.closest("[data-tool]");
  if(!button) return;
  activeTool=tools.find(tool=>tool.id===button.dataset.tool);
  renderDialog(activeTool);dialog.showModal();
});
document.getElementById("dialog-close").addEventListener("click",()=>dialog.close());
dialog.addEventListener("close",()=>{activeTool=null;});
dialog.addEventListener("click",event=>{if(event.target===dialog){const rect=dialog.getBoundingClientRect();if(event.clientX<rect.left||event.clientX>rect.right||event.clientY<rect.top||event.clientY>rect.bottom)dialog.close();}});
setLanguage("th");
