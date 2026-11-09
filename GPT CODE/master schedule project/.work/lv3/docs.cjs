const fs=require('node:fs'),crypto=require('node:crypto');
const h=fs.readFileSync('Master_Schedule.html','utf8'),d=JSON.parse(h.match(/<script id="schedule-data" type="application\/json">([\s\S]*?)<\/script>/)[1]),hash=crypto.createHash('sha256').update(h).digest('hex');
const project=d.groups.find(g=>g.id===d.primaryProjectId),lines=[project.pjCode+' / '+project.projectWorks];
for(const p of d.tasks.filter(t=>t.groupId===project.id&&!t.parentId)){lines.push('  '+p.product+' / '+p.drawingGroup);for(const t of d.tasks.filter(t=>t.parentId===p.id))lines.push('    '+t.name)}
fs.writeFileSync('README.md',`# Master Schedule — Rev03

ปรับวันที่ 9 พฤศจิกายน 2026 เป็นฐานข้อมูล 3 ระดับตามที่ผู้ใช้ยืนยัน ยกเลิกชั้น PP17–PP20 ในโครงการหลัก โดยไฟล์ใช้งานคือ Master_Schedule.html ไม่ต้องติดตั้งแพ็กเกจ

## ข้อมูลปัจจุบัน

- LV1: PJ + Project Works อยู่ในหมวดเดียวกัน
- LV2: Product + Group Drawing อยู่ในหัวข้อเดียวกัน
- LV3: Description แต่ละงานแสดง PLAN / ACTUAL คนละบรรทัด แยกวันเริ่ม–จบ
- 8 Product / 19 งานจริง / 38 แถวข้อมูล PLAN–ACTUAL เมื่อส่งออก
- ไม่สร้างวันที่ ผู้รับผิดชอบ หรือเปอร์เซ็นต์งานที่ยังไม่ทราบ ใช้ null หรือข้อความว่างตามชนิดข้อมูล

\
\
~~~text
${lines.join('\n')}
~~~

คงคำ MATTERIAL TAKEOFF และ MOCKUP (PP17) ตามรายการที่ผู้ใช้ส่ง คำ PP17 ในชื่องาน MOCKUP เป็นข้อความเดิม ไม่ใช่ระดับหัวข้อ

หมวดล่างสุด MRT PURPLE LINE STANDARD DRAWING C1 และหัวข้อ C02–C10 ยังคงเดิม รวม fileCatalog 6 โฟลเดอร์และไฟล์ที่เลือก 14 ไฟล์ ทั้ง HTML มี 2 หมวดหลัก / 36 แถวย่อย / 38 แถวรวมหมวดหลัก หมวดเอกสารเหล่านี้เป็น section ไม่ถูกนับเป็นงานหรือแถวฐานข้อมูลส่งออก

## เพิ่มและแก้ไข

เริ่มเป็น Viewer ปลดล็อก Editor ด้วย 123123 หมวดหลักใหม่กรอก PJ และ Project Works หัวข้อ LV2 กรอก Group Drawing และ Product งาน LV3 เลือก Product แล้วกรอก Description ข้อมูลโครงการและ Product ของงานรับจากหัวข้อแม่ แก้ชื่อ Product ครั้งเดียวแล้วข้อมูลในงานและไฟล์ส่งออกตามไปด้วย

โครงการฐานข้อมูลใช้ 3 ระดับ ไม่เพิ่มงานใต้ LV3 และไม่ย้ายโครงการ LV1 ไปซ้อนใต้หัวข้ออื่น หมวดเอกสารเก่ายังคงรูปแบบเดิม ย้ายลำดับด้วยคลิก WBS ต้นทาง/ปลายทางตามเดิม รักษา id ถาวรเมื่อแก้รายการ และคง id ของ C10 กับงานเดิมที่ตรงรายการใหม่

คง Dark Mode, SVG tree เส้น 1px, ยุบ–ขยาย, สี Gantt, PLAN/ACTUAL, วันทำงานจันทร์–เสาร์และการเว้นอาทิตย์ ปุ่ม Unhide 4 ช่องแสดง PJ/Project Works/Group Drawing/Product ซึ่งเริ่มซ่อน ป้ายจำนวนไฟล์อยู่ข้างชื่อหัวข้อฐานข้อมูล คลิกยุบ–ขยายชื่อไฟล์ที่เลือกได้

## ส่งออกและนำเข้า

Export Excel ส่งออกงานระดับสุดท้ายของโครงการฐานข้อมูลเท่านั้น แต่ละงานมี 2 แถว ข้อมูล PJ / Project Works / Group Drawing / Product / Description ครบทั้ง Plan และ Actual ไม่ใช้แถวหัวข้อหรือช่องว่างเพื่อสื่อความหมาย

| คอลัมน์ | ข้อมูล |
| --- | --- |
| A–E | PJ, Project Works, Group Drawing, Product, Description |
| F–P | ข้อมูลปัจจุบัน, Man, Unit, Quantity, Status, Action, Start, End, Approved, Remark, Duration ตามลำดับเดิม |
| Q | WBS สำหรับแสดงลำดับ |
| R | Plan / Actual |
| S | Node Type = Task |
| T | Task ID ถาวร |
| U | Project ID |
| V | Product ID |
| W เป็นต้นไป | ปฏิทินรายวันเมื่อเลือกส่งออกพร้อมปฏิทิน |

XLSX รักษาสีและรูปแบบต้นแบบ A:P พร้อมสูตรวันทำงานและ Gantt ที่ขยับตามวันที่ ซ่อน S:V ซึ่งเป็นรหัสอ้างอิง ห้ามแก้รหัสเหล่านี้เพื่อเปลี่ยนลำดับ ใช้ WBS ใน HTML จัดลำดับแทน

Import CSV อยู่ใน Editor รองรับ UTF-8 หัวตารางแถว 1 หรือ 4 ดาวน์โหลด CSV งานปัจจุบันไปกรอกใน Excel แล้วบันทึก CSV UTF-8 เพื่อนำกลับ ข้อมูลทั่วไปอ่านจากแถว Plan ส่วน Actual อ่านวันที่ L/M จับคู่งานจาก Task ID ก่อน จึงแก้ Description หรือย้ายลำดับได้ ถ้าไม่มี Task ID จะจับคู่ข้อมูล 5 ช่องที่ครบและไม่ซ้ำ

เพิ่มงานใหม่โดยเว้น Q และ T ในทั้งคู่ Plan/Actual หากเป็นโครงการหรือ Product ใหม่ให้เว้น U/V ด้วย ระบบสร้างหัวข้อที่ขาดจากข้อมูลครบ 5 ช่องโดยไม่คาดเดา ยังคงแสดงตัวอย่างก่อนยืนยัน เริ่มไม่ใช้ค่าว่างล้างข้อมูลเดิม การอัปเดตไม่เปลี่ยนสี ไฟล์แนบ ลำดับ หรือ % ของงานเดิม

VBA Export_MasterSchedule_CSV.bas อ่านชีต Programm Database หัวตารางแถว 4 โดยไม่บันทึก workbook ต้นฉบับ รองรับ A:E ที่กรอกครบเป็นฐานข้อมูล และเก็บ T:V จาก XLSX ของแอปไว้ โค้ดเดียวกันดาวน์โหลดจาก HTML ได้ ยังไม่ได้รัน macro รุ่นนี้ใน Excel จริง

ตัวอย่างจากข้อมูลจริงที่ยังไม่ระบุวัน อยู่ใน outputs/database/Master_Schedule_PJ25-031.csv และ .xlsx

## เปิดและบันทึก

- เปิด Master_Schedule.html ได้โดยตรง บันทึก HTML หรือดาวน์โหลดสำเนารวมโปรแกรมและข้อมูล
- Open_Master_Schedule.cmd เปิดตัวช่วยเฉพาะเครื่องสำหรับวาง path และเปิดเอกสาร Windows; ตัวช่วยไม่ได้ถูกเปิดระหว่างการแก้ครั้งนี้
- โหมด HTML ตรงใช้ตัวเลือกโฟลเดอร์สำรองตามข้อจำกัดเบราว์เซอร์
- หน้าเก่าที่เปิดค้างและมีข้อมูลเพิ่ม ต้องบันทึกแยกชื่อเพื่อผสาน ห้ามบันทึกหน้าเก่าทับ HTML ที่แก้โปรแกรมล่าสุด

## สำรองและการตรวจ

สำรองก่อนปรับโครงสร้าง: backups/Master_Schedule_before_LV3_database_1794215873731.html พร้อม README/AGENTS รุ่นก่อนหน้าใน backups ข้อมูลเดิม 57 แถวใช้เป็น fixture ทดสอบย้อนหลัง ไม่ใช่ข้อมูลปัจจุบัน ไม่อ่าน Z: และไม่กู้สำเนาเก่าทับอัตโนมัติ

- tests/DatabaseModel.test.cjs ผ่าน 58 ข้อ: โครงสร้าง 3 ระดับ, ข้อมูล 5 ช่อง, ไม่สมมติค่า, คง MRT/ไฟล์แนบ, ฟอร์มเพิ่ม/แก้ไข, ID/CSV roundtrip/เปลี่ยนชื่อ/ย้ายลำดับ/เพิ่มงาน, ตรวจข้อมูลผิด, PLAN/ACTUAL/วันอาทิตย์, Viewer, snapshot เปิดกลับ และ XLSX
- tests/CSVImport.test.cjs ผ่าน 65 ข้อ และ tests/Recovery.test.cjs ผ่าน โดยใช้ข้อมูลเก่าแบบ fixture กับโปรแกรมปัจจุบัน ไม่เขียนข้อมูลทดสอบทับ HTML จริง
- ตรวจ XLSX ด้วย ZIP/CRC/XML และ openpyxl แบบอ่านกลับ: 42 แถวรวม header / 38 phase rows / 50 คอลัมน์เมื่อรวม 28 วัน ข้อมูล 5 ช่องและ ID ครบทุกคู่ สี/ฟอนต์/ค่าว่าง/คอลัมน์ซ่อน/สูตรและ Gantt ผ่าน
- ตรวจจริงใน Microsoft Edge แบบ headless ผ่าน: แสดง 38 แถว, เพิ่ม LV2/LV3, ความจำเป็นของช่อง, วัน PLAN/ACTUAL แยกกัน, เปลี่ยน Product, เปิดกลับ และตำแหน่งป้ายไฟล์ข้างชื่อ ไม่มี JavaScript error ภาพอยู่ที่ outputs/database/Master_Schedule_Rev03.png
- ยังไม่ได้รัน VBA ใน Excel จริงหรือตรวจหน้าต่างเลือกไฟล์ Windows ในรอบนี้

SHA-256 ของ HTML รุ่นนี้: \`${hash}\`
`);
let a=fs.readFileSync('AGENTS.md','utf8'),start=a.indexOf('## โครงสร้างที่ผู้ใช้กำหนด'),end=a.indexOf('## กติกาที่ต้องรักษา');
a=a.slice(0,start)+`## โครงสร้างที่ผู้ใช้กำหนด

- ล่าสุด Rev03 วันที่ 9 พฤศจิกายน 2026: โครงการ PJ25-031 / MRT PURPLE LINE 4 STATION ใช้ databaseModel: "project-product-work-v1" และ state.primaryProjectId อ้างหมวดหลักนี้ ไม่มีชั้น PP17–PP20
- LV1 เก็บ pjCode/projectWorks ใน groups; LV2 เป็น section ใต้ group เก็บ product/drawingGroup; LV3 เป็น task ใต้ LV2 เก็บ Description ที่ name ใช้ drawingFieldsFor() รับข้อมูล 4 ช่องจากหัวข้อแม่เสมอ ไม่ทำสำเนาค่าซ้ำไว้ในลูกให้ล้าสมัย
- Product C02,C03,C04,C05,C06,C08,C09,C10 ตามลำดับ Group Drawing = กลุ่มงานฝ้า รายการครบตาม README และ HTML จริง รวม 8 Product / 19 งาน / 38 phase rows ส่งออก คงคำ MATTERIAL TAKEOFF และ MOCKUP (PP17) ตามผู้ใช้ ไม่สร้าง C07 หรือชั้น PP กลับเอง
- หมวดเอกสาร MRT PURPLE LINE STANDARD DRAWING C1 และ C02–C10 คงเดิม รวม fileCatalog 6 โฟลเดอร์/เลือก 14 ไฟล์ ทั้ง HTML 2 หมวดหลัก/36 แถวย่อย (38 แถวรวมหมวดหลัก) ไม่ส่งออก section เอกสารเป็นงานฐานข้อมูล
- id ของ C10 pp17-034 และงาน C10 เดิมที่ตรงรายการใหม่คงอยู่ แม้ชื่อ id มี pp17 ก็เป็นรหัสถาวร ไม่ใช้เป็นลำดับ ส่วนรายการใหม่มี id ใหม่
- โครงการฐานข้อมูลจำกัด 3 ระดับ ฟอร์มเพิ่ม LV1 กรอก PJ/Project Works, LV2 กรอก Group Drawing/Product, LV3 เลือก Product/กรอก Description ฟิลด์ที่สืบทอดอ่านอย่างเดียว ห้ามเพิ่มใต้ LV3 หรือซ้อน LV1 ใต้หัวข้ออื่น ไม่แปลงหมวดเอกสารเก่าเข้าโครงสร้างใหม่เงียบ ๆ ส่วนหมวด legacy ยังคงหลายระดับได้
- อ่านรายการล่าสุดจาก README.md และ HTML จริง ไม่สมมติวัน ผู้รับผิดชอบ % ปริมาณ หรือราคา ไม่อ่าน Z: ผู้ใช้ให้ใช้ไฟล์ในโฟลเดอร์นี้ สำเนาก่อนเปลี่ยนใน backups/Master_Schedule_before_LV3_database_1794215873731.html ไม่คืนข้อมูลเก่าอัตโนมัติ

`+a.slice(end);
a=a.replace('โปรแกรมปัจจุบันเป็น Rev02','โปรแกรมปัจจุบันเป็น Rev03');
a=a.replace('ส่วนไฟล์ที่เลือกใต้ชื่องานเยื้องไปทางขวาอีกหนึ่ง tree-step เท่ากับงานลูก โดยลูกศรสรุปไฟล์ใช้ระยะไอคอน/ข้อความเดียวกับหัวข้อย่อย','ส่วนป้ายไฟล์ของโครงการฐานข้อมูลวางข้างชื่อใน db-title-line เปิดรายการแล้วขึ้นบรรทัดเต็มได้ ส่วนหมวดเอกสารเก่ายังคงระยะเยื้องเดิม');
a=a.replace(/- Export Excel สร้าง[^\n]+/,'- Export Excel สร้าง .xlsx ออฟไลน์ด้วย EXCEL_TEMPLATE ที่ฝังใน HTML ในโหมดฐานข้อมูลส่งออกเฉพาะงาน LV3 ผ่าน excelExportRecords ส่วน scheduleTreeRecords ใช้แถวต้นไม้ครบสำหรับภายใน A:P คงตามต้นแบบ Q=WBS R=Plan/Actual S=Node Type T=Task ID U=Project ID V=Product ID ซ่อน S:V ปฏิทินเริ่ม W ทุกแถวกรอก 5 ช่องครบและ flat ไม่มี indent/outline สองแถวต่อ task id วันที่/Quantity เป็นตัวเลข null แยก 0 คง NETWORKDAYS.INTL/Conditional Formatting/เว้นอาทิตย์/สีรายงาน ไม่แก้ state/draft/Auto-save ใช้ Viewer ได้ โค้ดและ template ติด snapshot');
a=a.replace(/- เพิ่ม Import CSV UTF-8[^\n]+/,'- Import CSV UTF-8 รองรับฐานข้อมูลครบ A:E ทุกแถว Q=WBS (งานใหม่เว้นได้) R=Plan/Actual S=Task T=Task ID U=Project ID V=Product ID หัวตารางแถว1หรือ4 ใช้ Task ID จับคู่งานเดิมก่อน รองรับแก้ Description และย้าย WBS ถ้าไม่มี ID ใช้ข้อมูล5ช่องที่ไม่ซ้ำ ตรวจ PJ/Product/รหัสแม่และ Plan/Actual ให้ตรงกัน เพิ่มงานโดยเว้น Task ID และ WBS ถ้าเพิ่ม PJ/Product ใหม่ให้เว้นรหัสแม่ด้วย อัปเดตไม่พบ ID ห้ามสร้างแทนเงียบ ๆ โหมด update เพิ่มงานใหม่จากข้อมูลครบได้ โหมด append ปฏิเสธงานซ้ำ ทุกค่าใน preview ก่อนยืนยัน เก็บสี/ไฟล์/โน้ต/%/ลำดับ เริ่มไม่ล้างค่าว่าง วันอาทิตย์เลื่อนจันทร์ยกเว้น Approved ไม่คำนวณ progress จาก CSV โหมด legacy แยกไว้รองรับข้อมูลเก่าด้วย fixture');
a=a.replace('ตรวจหลักด้วย tests/CSVImport.test.cjs และ tests/Recovery.test.cjs','VBA ฐานข้อมูลกรอก A:E ครบจะไม่สร้างหัวข้อจาก indent เก็บ ID เดิมเมื่อมี ตรวจหลักด้วย tests/DatabaseModel.test.cjs (ข้อมูลปัจจุบัน) และ CSVImport/Recovery (fixture เดิม)');
fs.writeFileSync('AGENTS.md',a);console.log(JSON.stringify({hash,groups:d.groups.length,tasks:d.tasks.length}));
