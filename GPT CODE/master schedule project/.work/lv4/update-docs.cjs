const fs=require('fs'),crypto=require('crypto'),assert=require('assert/strict');
const html=fs.readFileSync('Master_Schedule.html','utf8'),pattern=/<script id="schedule-data" type="application\/json">([\s\S]*?)<\/script>/,data=JSON.parse(html.match(pattern)[1]),backup=fs.readFileSync('.work/lv4/baseline-path.txt','utf8');
assert.equal(html.match(pattern)[1],fs.readFileSync(backup+'/Master_Schedule.html','utf8').match(pattern)[1]);
const hash=crypto.createHash('sha256').update(html).digest('hex'),dbGroups=data.groups.filter(g=>g.databaseModel),products=data.tasks.filter(t=>dbGroups.some(g=>g.id===t.groupId)&&!t.parentId),descriptions=data.tasks.filter(t=>products.some(p=>p.id===t.parentId)),activities=data.tasks.filter(t=>descriptions.some(d=>d.id===t.parentId));
const lines=[];function tree(parent,prefix){for(const task of data.tasks.filter(t=>t.parentId===parent)){lines.push(prefix+task.name);tree(task.id,prefix+'  ')}}for(const group of data.groups){lines.push(group.pjCode?group.pjCode+' / '+group.projectWorks:group.name);for(const p of data.tasks.filter(t=>t.groupId===group.id&&!t.parentId)){lines.push('  '+p.name+(p.drawingGroup?' / '+p.drawingGroup:''));tree(p.id,'    ')}}
let r=fs.readFileSync('README.md','utf8');
r=r.replace('# Master Schedule — Rev03','# Master Schedule — Rev04').replace('ปรับวันที่ 9 พฤศจิกายน 2026 เป็นฐานข้อมูล 3 ระดับตามที่ผู้ใช้ยืนยัน ยกเลิกชั้น PP17–PP20 ในโครงการหลัก โดยไฟล์ใช้งานคือ Master_Schedule.html ไม่ต้องติดตั้งแพ็กเกจ','ปรับวันที่ 13 พฤศจิกายน 2026 รองรับ LV4 · Activity โดย LV3 ยังคงเป็น Description ส่วน Group Drawing + Product อยู่รวม LV2 ใช้ไฟล์หลัก Master_Schedule.html แบบไฟล์เดียว ไม่ต้องติดตั้งแพ็กเกจ ข้อมูลจริงล่าสุดอ่านจาก JSON ใน HTML');
const update=`## การเปลี่ยนแปลง Rev04 — 13 พฤศจิกายน 2026

- สำรองก่อนแก้: ${backup}/ มี HTML, JSON ข้อมูล, README, SKILL, AGENTS และชุดตรวจก่อนปรับ
- รองรับ LV1 โครงการ → LV2 Product/Group Drawing → LV3 Description → LV4 Activity โดยไม่เปลี่ยน id หรือลบข้อมูลเดิม
- กด “+ ย่อย” ที่ Description เพื่อเพิ่ม Activity กล่องแสดงต้นไม้ตำแหน่ง เลือก Description แม่แบบค้นหาได้ ชื่อช่องเปลี่ยนตามระดับ ข้อมูลโครงการ/Product/Description แม่อ่านอย่างเดียว ส่วนชื่อ Activity วันที่ ผู้รับผิดชอบ % สีและไฟล์แก้แยกได้
- Activity มี id และ PLAN/ACTUAL ของตัวเอง ไม่แสดงปุ่มเพิ่มต่อใต้ LV4 Description ที่มีลูกสรุป % ตามวันทำงานจากงานระดับสุดท้าย วันที่แม่กำหนดเองหรือกลับใช้วันลูกได้แยก Plan/Actual
- เมื่อเพิ่ม Activity แรก เก็บวันเดิมของ Description ไว้เป็นแผน/Actual ที่กำหนดเองหากมี ไม่สมมติวันที่หรือ % ให้ Activity ใหม่ และไม่เปลี่ยนวันที่ลูกเมื่อแก้วันแม่
- ส่งออกเฉพาะงานระดับสุดท้าย ป้องกันนับ Description ซ้ำกับ Activity เพิ่ม W=Activity และ X=Description ID ต่อท้าย A:V เดิม ปฏิทิน XLSX เริ่ม Y รับ CSV 22 คอลัมน์เดิมสำหรับงานที่ยังไม่มี Activity ได้
- ถอดปุ่มและคำแนะนำ VBA จากหน้า Import แล้ว ใช้ CSV UTF-8 ตามข้อตกลงเดิม ส่วนซอร์ส .bas และข้อความโค้ดเก่ายังอยู่เพื่อประวัติ ไม่ใช้กับ LV4
- ข้อมูลจริงยังไม่มี Activity ที่สร้างแทนผู้ใช้ จำนวนรายการและค่าที่บันทึกตรงกับสำเนาก่อนแก้ทุกค่า

`;
r=r.replace('## ข้อตกลงล่าสุด — 10 พฤศจิกายน 2026',update+'## ข้อตกลง Template — 10 พฤศจิกายน 2026 (ยังต้องพัฒนา)');
r=r.replace('สรุปการหารือเพิ่มเติมครั้งนี้เป็นภาษาไทย ปรับเฉพาะ README.md และ SKILL.md โปรแกรมและข้อมูลงานใน HTML ยังเป็น Rev03 เดิม','ส่วนนี้เป็นข้อกำหนดแม่แบบที่คุยไว้ก่อนหน้า ระบบโหลดแม่แบบจาก GitHub สูตร WBS และการล็อกแถวตามมาตรฐานรุ่นแม่แบบยังไม่ได้พัฒนา การรองรับ LV4 ใน Rev04 ไม่ใช่การทำข้อกำหนดแม่แบบทั้งหมดให้เสร็จ');
r=r.replace('| นำเข้า CSV UTF-8, ตรวจข้อมูลและแสดง preview | มีอยู่ใน Rev03 ตามขอบเขตชุดตรวจเดิม |','| นำเข้า CSV UTF-8, ตรวจข้อมูลและแสดง preview | มีใน Rev04 รองรับ Description/Activity และรหัสแม่แยกกัน |').replace('| ส่งออก XLSX พร้อมรูปแบบและ Gantt | มีอยู่ โดยใช้ EXCEL_TEMPLATE ที่ฝังใน HTML |','| ส่งออก XLSX พร้อมรูปแบบและ Gantt | มีใน Rev04 ใช้ EXCEL_TEMPLATE ที่ฝังใน HTML พร้อมคอลัมน์ Activity |').replace('| เลิกใช้ VBA ในขั้นตอนทำข้อมูล | ยืนยันเป็นข้อตกลงใหม่ แต่โค้ด/ปุ่มดาวน์โหลด VBA เก่ายังอยู่ ยังไม่ได้ถอดในครั้งนี้ |','| เลิกใช้ VBA ในขั้นตอนทำข้อมูล | ถอดปุ่มและคำแนะนำใน Rev04 แล้ว ส่วนซอร์สเก่ายังอยู่ ไม่ใช้กับกระบวนการใหม่ |');
r=r.replace('3. เพิ่มโครงการที่ LV1 → เพิ่ม Product ที่ LV2 → เพิ่ม Description ที่ LV3 แล้วกรอกวัน PLAN และ ACTUAL แยกกัน','3. เพิ่มโครงการ LV1 → Product/Group Drawing LV2 → Description LV3 หากต้องแยกขั้นตอน กด “+ ย่อย” ที่ Description เพื่อเพิ่ม Activity LV4 แล้วกรอก PLAN/ACTUAL แยกกัน');
const start=r.indexOf('## ข้อมูลปัจจุบัน'),end=r.indexOf('## เพิ่มและแก้ไข',start);
r=r.slice(0,start)+`## ข้อมูลปัจจุบัน

ข้อมูลบันทึกล่าสุดมี **${data.groups.length} หมวดหลัก / ${data.tasks.length} แถวย่อย / ${data.groups.length+data.tasks.length} แถวรวมหมวดหลัก** โครงการฐานข้อมูลมี ${products.length} Product, ${descriptions.length} Description และ ${activities.length} Activity ที่บันทึกจริง ขณะนี้งานระดับสุดท้าย ${descriptions.length} งาน ส่งออก ${descriptions.length*2} แถว PLAN/ACTUAL

LV1 = PJ + Project Works; LV2 = Group Drawing + Product; LV3 = Description; LV4 = Activity (เลือกแตกเพิ่มเมื่อต้องการ) หมวด MRT เอกสารเก่าคง C02–C10 และ fileCatalog 6 โฟลเดอร์/เลือก 14 ไฟล์ตามเดิม

~~~text
${lines.join('\n')}
~~~

ชื่อและลำดับข้างต้นมาจาก HTML จริง รวมรายการ MOCKUP, C09 PARTTERN SCREEN, C10 PATTERN SCREEN และ PJ26-008 ที่ผู้ใช้เพิ่มไว้ ไม่กู้รายชื่อ PP หรือชื่อเก่าทับข้อมูลล่าสุด ไม่สมมติวัน ผู้รับผิดชอบ % หรือ Activity ใหม่แทนผู้ใช้

`+r.slice(end);
r=r.replace('งาน LV3 เลือก Product แล้วกรอก Description','งาน LV3 เลือก Product แล้วกรอก Description ส่วน Activity LV4 เลือก Description แม่แล้วกรอกชื่อขั้นตอน');
r=r.replace('โครงการฐานข้อมูลใช้ 3 ระดับ ไม่เพิ่มงานใต้ LV3 และไม่ย้ายโครงการ LV1 ไปซ้อนใต้หัวข้ออื่น','โครงการฐานข้อมูลรองรับถึง 4 ระดับ เพิ่ม Activity ใต้ LV3 ได้ แต่ไม่เพิ่มต่อจาก LV4 และไม่ย้ายโครงการ LV1 ไปซ้อนใต้หัวข้ออื่น');
r=r.replace('Export Excel ส่งออกงานระดับสุดท้ายของโครงการฐานข้อมูลเท่านั้น แต่ละงานมี 2 แถว ข้อมูล PJ / Project Works / Group Drawing / Product / Description ครบทั้ง Plan และ Actual ไม่ใช้แถวหัวข้อหรือช่องว่างเพื่อสื่อความหมาย','Export Excel ส่งออกเฉพาะงานระดับสุดท้าย: Description ที่ไม่มี Activity หรือ Activity ใต้ Description แต่ละงานมี 2 แถว PJ / Project Works / Group Drawing / Product / Description ครบทั้ง Plan/Actual โดย E เป็นชื่อ Description เสมอ และ W เป็นชื่อ Activity เมื่อเป็น LV4 ไม่ส่งออกหัวข้อแม่ซ้ำกับลูก');
r=r.replace('| W เป็นต้นไป | ปฏิทินรายวันเมื่อเลือกส่งออกพร้อมปฏิทิน |','| W | Activity — ว่างเมื่อเป็น Description ที่ไม่มี Activity |\n| X | Description ID — รหัสหัวข้อแม่ของ Activity |\n| Y เป็นต้นไป | ปฏิทินรายวันเมื่อเลือกส่งออกพร้อมปฏิทิน |').replace('| S | Node Type = Task |','| S | Node Type = Task หรือ Activity |').replace('| T | Task ID ถาวร |','| T | Task ID ถาวรของ Description หรือ Activity ที่เป็นงานระดับสุดท้าย |');
r=r.replace('ซ่อน S:V ซึ่งเป็นรหัสอ้างอิง','ซ่อน S:V และ X ซึ่งเป็นรหัสอ้างอิง').replace('ถ้าไม่มี Task ID จะจับคู่ข้อมูล 5 ช่องที่ครบและไม่ซ้ำ','ถ้าไม่มี Task ID จะจับคู่ข้อมูล 5 ช่องหลัก + Activity ที่ครบและไม่ซ้ำ โดยตรวจ Product ID กับ Description ID แยกกัน');
r=r.replace('พฤติกรรม CSV ทั่วไปที่มีอยู่ใน Rev03:','พฤติกรรม CSV ทั่วไปใน Rev04:').replace('พฤติกรรมนี้ไม่ได้อนุญาตให้เพิ่มแถวใน Template แบบล็อกแถวที่ตกลงใหม่','Activity ใหม่กรอกชื่อใน W และ Description ID แม่ใน X (หรือปล่อย X ว่างเพื่อจับคู่ชื่อ Description ที่ไม่ซ้ำ) พฤติกรรมเพิ่มงานนี้ไม่ได้อนุญาตให้แทรกแถวใน Template แบบล็อกแถวที่ยังต้องพัฒนา');
r=r.replace(/ส่วนเก่าที่ยังอยู่: Export_MasterSchedule_CSV.bas[^\n]+/,'ส่วนเก่าที่ยังอยู่: Export_MasterSchedule_CSV.bas และค่าซอร์สฝัง CSV_VBA_TEXT เก็บไว้เพื่อประวัติ แต่ถอดปุ่มดาวน์โหลดและคำแนะนำ VBA จากหน้า Import แล้ว ใช้ Save As CSV UTF-8 จาก Excel โดยตรง ไม่นำ VBA รุ่นเก่ามาใช้กับ Activity');
r=r.replace('ตัวอย่างจากข้อมูลจริงที่ยังไม่ระบุวัน อยู่ใน outputs/database/Master_Schedule_PJ25-031.csv และ .xlsx','ไฟล์ใน outputs/database/ เป็นตัวอย่าง Rev03 เก่า ไม่ใช่ข้อมูลจริงล่าสุด ส่วน outputs/lv4-validation/ เป็นข้อมูลทดสอบจำลองและไฟล์ที่ดาวน์โหลดระหว่างตรวจ LV4 แยกจากไฟล์ใช้งานหลัก');
const oldTests=r.indexOf('- tests/DatabaseModel.test.cjs ผ่าน');const oldHash=r.indexOf('SHA-256 ของ HTML รุ่นนี้:',oldTests);
r=r.slice(0,oldTests)+`- tests/DatabaseModel.test.cjs เรียก Activity.test.cjs ผ่าน 61 ข้อ: ข้อมูลเดิม/ระดับ/Viewer, ฟอร์ม Activity และต้นไม้แม่, ป้องกัน LV5, วันเดิมหัวข้อแม่, summary ถ่วงน้ำหนัก, วันกำหนดเอง, inline edit, ย้าย Description พร้อมลูก, CSV ใหม่/22 คอลัมน์เก่า/รหัสแม่ผิด/ช่วงวันผิด, snapshot, XLSX และไม่เขียนทับข้อมูลจริง
- tests/CSVImport.test.cjs ผ่าน 65 ข้อ และ Recovery.test.cjs ผ่านกับ fixture เก่า ไม่ใช้จำนวนงานย้อนหลังมาแทนข้อมูลปัจจุบัน InlineEdit.test.cjs ผ่านกับข้อมูลล่าสุด
- ตรวจใน Microsoft Edge แบบ headless ผ่าน: ปลดล็อก/กดเพิ่มจากแถว/ค้นหา Description แม่/กรอกวันที่/%/ยกเลิก/แม่สรุป%/ป้องกันลบแม่/เลือกไฟล์ CSV และยืนยัน/ดาวน์โหลด XLSX จริง/snapshot เปิดกลับ คง fileCatalog และไม่พบ JavaScript error ตรวจภาพทั้งหน้าจอใหญ่และขนาดมือถือจำลองแล้ว (ยังไม่ได้ตรวจบน iPhone/iPad จริง)
- อ่านไฟล์ XLSX ทดสอบกลับด้วย ZIP/CRC/XML/openpyxl ผ่าน: ข้อมูล Activity/Description ID ครบคู่, ชนิดวัน/สูตร, สี/ฟอนต์เดิม, ซ่อน metadata, ปฏิทินเริ่ม Y และไฟล์ที่ดาวน์โหลดจากเบราว์เซอร์
- ตัวอย่างจำลองไม่ใส่กลับ HTML จริง ไม่ได้เปิด Local_File_Helper ไม่อ่าน Z: ไม่ทดสอบ VBA/แม่แบบ GitHub/สูตร WBS หรือ Excel 2016–2024 ครบทุกเวอร์ชันในรอบนี้

`+r.slice(oldHash);
r=r.replace(/SHA-256 ของ HTML รุ่นนี้: `[^`]+`/, 'SHA-256 ของ HTML รุ่นนี้: `'+hash+'`');
fs.writeFileSync('README.md',r);
let a=fs.readFileSync('AGENTS.md','utf8'),as=a.indexOf('## โครงสร้างที่ผู้ใช้กำหนด'),ae=a.indexOf('## กติกาที่ต้องรักษา',as);
a=a.slice(0,as)+`## โครงสร้างที่ผู้ใช้กำหนด

- ล่าสุด Rev04 วันที่ 13 พฤศจิกายน 2026 รองรับ LV4 · Activity: LV1 PJ + Project Works / LV2 Product + Group Drawing / LV3 Description / LV4 Activity ไม่แยก Group Drawing กับ Product เป็นคนละระดับ ใช้ databaseModel เดิม project-product-work-v1; databaseLevel() คำนวณระดับจาก parentId
- ข้อมูลใช้งานจริงตอนแก้มี ${data.groups.length} หมวดหลัก/${data.tasks.length} แถวย่อย รวม ${data.groups.length+data.tasks.length} แถว: PJ25-031 / MRT PURPLE LINE 4 STATION, MRT PURPLE LINE STANDARD DRAWING C1 และ PJ26-008 / MRT PURPLE LINE (ABOVE GROUND) มี ${products.length} Product/${descriptions.length} Description/${activities.length} Activity ที่บันทึกจริง รวม MOCKUP/แบบขอตัวอย่าง/PATTERN SCREEN ที่ผู้ใช้เพิ่ม อ่าน HTML จริงก่อนแก้ทุกครั้ง ไม่ใช้จำนวนคงที่ทับข้อมูลใหม่
- LV1 อยู่ใน groups; LV2 เป็น task nodeType section ใต้ group; LV3 และ LV4 เป็น nodeType task แยกระดับด้วย parentId ทั้ง Description/Activity ใช้ name เก็บชื่อ เมื่อ Description มีลูกจะเป็นหัวข้อสรุปโดยไม่เปลี่ยน id ไม่ต้องเปลี่ยน nodeType เป็น section จึงยังกลับเป็นงานได้เมื่อไม่มี Activity
- Activity มี id, สี, fileCatalog และ Plan/Actual ของตัวเอง ห้ามเพิ่มต่อจาก LV4 เลือกแม่ได้เฉพาะ Description ระดับ3และป้องกันวงจร/ข้ามหมวด legacy; ชื่อ Activity แยกจากฟิลด์ Action เดิม เมื่อย้าย Description หรือ Product ให้พาลูกไปด้วยและปรับพื้นที่ที่สืบทอดตาม Product
- เพิ่ม Activity แรกต้องเก็บวันเดิมของ Description เป็นวันกำหนดเองถ้ามี ไม่คัดลอกวัน/owner/% ให้ลูกใหม่ หัวข้อแม่สรุป%จากงานระดับสุดท้าย ไม่บวกซ้ำ วันที่แม่แก้ manual หรือกลับใช้วันลูกได้แยก Plan/Actual และไม่เปลี่ยนวันลูก
- กล่องเพิ่ม/แก้ไขใช้ระดับ product/work/activity เปลี่ยน label Description/Activity ตามระดับ แสดง Description แม่อ่านอย่างเดียวสำหรับ LV4 ใช้ต้นไม้ค้นหาและ SVG เดิม + ย่อย บน LV3 เปิด Activity; LV4 ไม่มีปุ่มเพิ่มต่อ
- เก็บ JSON ใน schedule-data ตรงกับก่อนแก้ทุกค่า ไม่มี Activity ตัวอย่างในข้อมูลจริง สำเนาก่อนแก้รวมชุดตรวจ: ${backup}/ ไม่อ่าน Z: หรือคืน backup เก่าอัตโนมัติ
- หมวด MRT เอกสารเก่า C02–C10, fileCatalog 6 โฟลเดอร์และไฟล์เลือก 14 ไฟล์คงเดิม รักษาชื่อ/สะกด/id ที่บันทึกล่าสุด ไม่กู้ชั้น PP17–PP20 หรือชื่อ MOCKUP เดิมทับผู้ใช้

`+a.slice(ae);
a=a.replace('โปรแกรมปัจจุบันเป็น Rev03','โปรแกรมปัจจุบันเป็น Rev04');
a=a.replace('- หัวข้อหลักแก้ช่อง “อยู่ใต้หัวข้อ”','- สำหรับหมวด legacy หัวข้อหลักแก้ช่อง “อยู่ใต้หัวข้อ”').replace('- งานย่อยแตกต่อได้หลายระดับ','- สำหรับหมวด legacy งานย่อยแตกต่อได้หลายระดับ');
a=a.replace(/- Export Excel สร้าง[^\n]+/,'- Export Excel สร้าง .xlsx ออฟไลน์ด้วย EXCEL_TEMPLATE ผ่าน excelExportRecords เฉพาะงานระดับสุดท้าย (Description ไม่มี Activity หรือ Activity ใต้ Description) ส่วน scheduleTreeRecords ใช้ต้นไม้ภายในครบ A:P ตามต้นแบบ E เป็น Description เสมอ Q=WBS R=Plan/Actual S=Task/Activity T=Task ID U=Project ID V=Product ID W=Activity X=Description ID ซ่อน S:V และ X ปฏิทินเริ่ม Y ทุกคู่เติมข้อมูล5ช่องครบ ไม่ส่งออกหัวข้อแม่ซ้ำ คงชนิดวัน/Quantity/null/0 สูตรและ Conditional Formatting/เว้นอาทิตย์/สีรายงาน ไม่แก้ state/draft/Auto-save ใช้ Viewer ได้ โค้ด/template ติด snapshot');
a=a.replace(/- Import CSV UTF-8[^\n]+/,'- Import CSV UTF-8: รับ 24 คอลัมน์ A:X ใหม่และ 22 คอลัมน์ A:V เดิมสำหรับ Description ไม่มี Activity ใช้ E ชื่อ Description และ W ชื่อ Activity/X รหัส Description แม่ จับคู่ Task ID ก่อน ถ้าไม่มีใช้5ช่อง+Activityที่ไม่ซ้ำ ตรวจ Product ID/Description ID/คู่ Plan–Actual และระดับให้ตรง แก้ชื่อ Activity ไม่ย้ายแม่โดยเงียบ ๆ ข้อมูลทั่วไปอ่าน Plan และ Actual อ่าน L/M, preview ก่อนยืนยัน, ไม่ล้างค่าว่างโดยปริยาย, ไม่แก้สี/ไฟล์/%/ลำดับ โครงการ/Product/Description ที่ยังขาดสร้างจากข้อมูลครบด้วย id ใหม่ แต่อัปเดต Task ID ที่ไม่พบต้องปฏิเสธ');
a=a.replace(/VBA อยู่ที่ Export_MasterSchedule_CSV.bas[^\n]+/,'VBA เป็นซอร์สเก่าไม่ใช้ใน workflow ใหม่ ถอดปุ่มดาวน์โหลด/คำแนะนำแล้ว ซอร์ส .bas/CSV_VBA_TEXT ยังอยู่เพื่อประวัติ ชุดตรวจ Activity ผ่าน DatabaseModel เป็นหลัก, CSVImport/Recovery ใช้ fixture เก่า และ InlineEdit ใช้ข้อมูลล่าสุด');
fs.writeFileSync('AGENTS.md',a);console.log(JSON.stringify({revision:'Rev04',groups:data.groups.length,tasks:data.tasks.length,products:products.length,descriptions:descriptions.length,activities:activities.length,sha256:hash}));
