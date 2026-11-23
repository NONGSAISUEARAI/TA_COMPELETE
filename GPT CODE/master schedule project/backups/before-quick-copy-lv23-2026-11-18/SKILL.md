---
name: master-schedule-project
description: แก้ ตรวจ และเตรียมอัปโหลด Master Schedule Rev04 ในโปรเจกต์นี้ โดยรักษา JSON งานจริง โครงสร้าง LV1–LV4 การนำเข้า/ส่งออก และพฤติกรรม UI เดิม ใช้เมื่อทำงานกับ Master_Schedule.html หรือเตรียม code รอบเผยแพร่
---

# Master Schedule Rev04

ดูแลโปรเจกต์ HTML ไฟล์เดียวนี้โดยถือว่าข้อมูลใน `Master_Schedule.html` เป็นข้อมูลใช้งานจริง ห้ามให้การแก้โค้ดทำรายการงาน วันที่ ไฟล์แนบ หรือการเลือกไฟล์เปลี่ยนโดยไม่ตั้งใจ

## เริ่มงานทุกครั้ง

1. อ่าน `AGENTS.md` และ `README.md`
2. อ่าน JSON จาก `<script id="schedule-data" type="application/json">` ใน `Master_Schedule.html` จริง ห้ามยึดจำนวนจากเอกสาร fixture หรือ backup
3. เก็บหลักฐานก่อนแก้ของ JSON: SHA-256, จำนวน `groups`/`tasks`, ลำดับ `id`, ความสัมพันธ์ `groupId`/`parentId` และจำนวน fileCatalog/files/selected
4. ตรวจ working tree และแยกการเปลี่ยนแปลงเดิมของผู้ใช้ออกจากงานรอบนี้ ห้ามล้างไฟล์ที่ไม่เกี่ยวข้อง
5. ถ้าแก้โปรแกรมหรือข้อมูล ให้สำรองไฟล์หลักและเอกสารที่กำลังแก้ใน `backups/<เหตุผล>-<เวลา>/` ก่อนลงมือ ถ้าแก้เฉพาะเอกสารไม่ต้องสำรอง HTML

ห้ามอ่านไดรฟ์ Z: ห้ามนำ `backups/`, fixture, output เก่า หรือ `Master_Schedule_REV01.html` ทับไฟล์หลักอัตโนมัติ หากหน้าเก่าในเบราว์เซอร์มีข้อมูลเพิ่ม ให้ Export เป็นชื่อใหม่แล้ว Import/ผสานกับโค้ดล่าสุด ไม่เซฟหน้าเก่าทับไฟล์ที่เพิ่งแก้

## แหล่งความจริงและโครงสร้าง

- ไฟล์หลักคือ `Master_Schedule.html`; โปรแกรม หน้าตา template และข้อมูลอยู่ในไฟล์เดียว
- LV1 อยู่ใน `groups`: PJ + Project Works
- LV2 เป็น `tasks[]` ชนิด `section`: Product + Group Drawing
- LV3 เป็น `tasks[]` ชนิด `task`: Description
- LV4 เป็น `tasks[]` ชนิด `task` ใต้ Description: Activity และห้ามมีระดับถัดไป
- ใช้ `databaseLevel()` และ `parentId` คำนวณระดับ ไม่อนุมานจากชื่อหรือ id
- Description ที่ไม่มี Activity เป็นงานระดับสุดท้าย; เมื่อมี Activity จะเป็นหัวข้อสรุปโดยคง id และ `nodeType` เดิม
- WBS คำนวณจากลำดับ ไม่ใช่รหัสถาวร รักษา id เดิมเมื่อแก้ชื่อ ย้าย หรือบันทึก
- ค่าไม่ทราบใช้ `null` สำหรับวัน/ผลงาน/ปริมาณ และข้อความว่างสำหรับผู้รับผิดชอบ แยก `null` จาก 0 ที่ผู้ใช้ยืนยัน
- Plan ใช้ `start/end` และหัวข้อแม่ใช้ `dateMode/planStart/planEnd`; Actual ใช้ `actualStart/actualEnd/actualDateMode` แยกกัน ไม่อนุมาน Actual จาก progress
- หัวข้อแม่สรุป progress จากงานระดับสุดท้ายเท่านั้น ถ่วงน้ำหนักด้วยวันทำงาน และไม่บวกหัวข้อแม่ซ้ำ
- fileCatalog เก็บ metadata เท่านั้น `selected` เป็น boolean; ห้ามฝังเนื้อหาไฟล์ file handle หรือ session token

ข้อมูลจริงอาจเปลี่ยนหลังเปิดไฟล์หรือ Import จึงห้ามฝังจำนวน tasks/Product/Description/Activity แบบคงที่ในโค้ด หรือใช้ตัวเลขใน README ตัดสินว่าข้อมูลถูกต้อง

### Snapshot ที่ตรวจพบล่าสุด — 16 พฤศจิกายน 2026

ใช้ส่วนนี้เป็นข้อมูลอ้างอิงเพื่อตรวจจับความเปลี่ยนแปลง ไม่ใช่ค่าคงที่สำหรับเขียนทับ HTML:

- 3 groups / 70 tasks: LV2 section 19, LV3 Description 28, LV4 Activity 23
- `pj25-031` มี 46 tasks (LV2 9 / LV3 25 / LV4 12)
- `mrt-purple-line-std-dwg-c1` มี 9 tasks แบบ legacy/LV2 และยังไม่มีลูก
- `gmwegm0wejn4v3y` หรือ PJ26-008 มี 15 tasks (LV2 1 / LV3 3 / LV4 11)
- fileCatalog 6 ชุด / 104 files / selected 14 ยังคงเท่ากับข้อมูลก่อนหน้า
- เมื่อเทียบ baseline ต้นวันที่ 15 พฤศจิกายน tasks เพิ่มจาก 45 เป็น 70 รวม Activity ใหม่ 23 รายการและ Description ใหม่บางรายการ ห้ามย้อนจำนวนกลับเพื่อให้ตรง README เก่า
- รอบข้อมูลล่าสุดเติม `owner: "Tawan"` และ `action: "ดำเนินการ"` ให้หลายแถว; มี Action เฉพาะรายการ เช่น `ELEVATION PANEL KEY` เป็น `รอข้อมูล LOT 3 LOT 4 ,Varies` จึงห้าม normalize ทุกแถวด้วยค่าเดียว
- project เปิดกฎสีตัวอักษรงานเลยกำหนดโดยอ้างอิงวันนี้ และเปิดกฎสีงานครบ 100%; การแก้ UI ต้องรักษาค่า `overdueTextRule`/`completedTextRule`

ถ้าค่าปัจจุบันไม่ตรง snapshot นี้ ให้ถือ JSON ที่อ่านใหม่เป็นหลัก แล้วอัปเดตเอกสารเมื่อผู้ใช้ยืนยันข้อมูลรอบใหม่

## กติกา UI และโปรแกรมที่ต้องรักษา

อ่านรายละเอียดครบใน `AGENTS.md`; จุดเสี่ยงสูงคือ:

- เริ่มหน้าเป็น Viewer; Editor ใช้รหัส `123123` เพื่อกันการแก้ผ่าน UI ไม่ใช่ระบบเข้ารหัส
- Dark Mode ใช้บนหน้าจอ ส่วนงานพิมพ์พื้นสว่าง
- ตารางใช้เต็มความกว้างบน screen; ไม่คืน `max-width: 1680px`
- Tree ทั้งตารางและตัวเลือกแม่ใช้ SVG `treeGuides` เส้น 1px พร้อม `non-scaling-stroke` และ `crispEdges`
- ปุ่ม LV1–LV4 ควบคุม `activeTreeLevel`/`collapsedGroups` โดยไม่เปลี่ยน state, dirty, draft, Auto-save หรือขอบเขต export
- Ctrl +/− เป็น browser zoom; ไม่เพิ่ม CSS zoom
- Description resize เป็น view preference ใน localStorage ใช้ได้ Viewer/Editor และไม่ทำข้อมูล dirty
- ป้ายไฟล์อยู่ขวาของ `db-title-line`; `taskFilesBody()` เป็น region เต็มแถวถัดไป และ `syncTaskFilesDisclosure()` ดูแล hidden/aria-expanded/expandedFileLists ห้ามนำกฎ `details[open]` ที่กินเต็ม grid กลับมา
- ย้ายลำดับด้วย WBS ต้นทาง/ปลายทาง พาหัวข้อพร้อมลูก และไม่เปลี่ยน id/parentId/groupId โดยพลการ
- หมวด legacy อาจลึกหลายระดับและมีกฎแปลง group เป็น section; ห้ามใช้กฎฐานข้อมูล LV1–LV4 ทำลาย legacy
- Local File Helper ต้องอยู่เฉพาะ `127.0.0.1:48731` รักษาการตรวจ token/origin/Host/root/traversal/reparse point และห้ามเปิดสู่ LAN

### เครื่องมือตารางที่เพิ่มในรุ่นปัจจุบัน

- Ribbon มีแท็บ ภาพรวม, แผนงาน, ค้นหา/กรอง, มุมมอง, ปฏิทิน, สรุปปัจจุบัน, รูปแบบ และนำเข้า–ส่งออก; กดแท็บเดิมซ้ำเพื่อย่อได้ยกเว้นสรุปปัจจุบันซึ่งเป็นหน้าแยก รองรับลูกศร/Home/End และต้องรักษาความสูงคงที่ตาม breakpoint
- สรุปปัจจุบันต้องเป็นหน้าแยกจากตารางงานภายใน HTML เดียวกัน: เมื่อเลือกแท็บให้ซ่อน caption/filter/table/footer/help ของตารางและแสดงหน้าสรุปเต็มพื้นที่ เมื่อเลือกแท็บอื่นให้คืนตารางและ state/filter/collapse เดิมโดยไม่แก้ข้อมูลหรือ Auto-save
- หน้าสรุปเริ่มจากแยกตามโครงการ มีภาพรวมสถานการณ์จาก LV2, tree รายละเอียดเริ่ม LV3 และแสดง LV4 และแถบ “x เรื่องต้องติดตามอาทิตย์นี้” ตามวันรายงาน
- ฟอร์ม LV2–LV4 ใช้ปุ่มดาวที่เห็นชัด ไม่ใช้ select “ไม่ติดตาม” เป็นตัวควบคุมหลัก; LV2/LV3 เลือก scope เฉพาะตัวหรือ subtree ได้ ส่วน LV4 เลือกได้เฉพาะตัวเอง เก็บค่า `followMode` เป็น `null`, `self` หรือ `subtree` และแสดงดาวเหลืองหลังชื่อของรายการที่ติดตามโดยตรงหรือสืบทอดจากแม่
- ใน Editor ตารางหลักมีปุ่มดาวแบบด่วนท้ายข้อความ LV ของทุก database task: LV2/LV3 เปิดตัวเลือก `self` หรือ `subtree`, LV4 สลับ `self` โดยตรง, การยกเลิกดาวของรายการที่กำหนดเองทำได้จากปุ่มเดิม; Viewer ซ่อนปุ่มนี้แต่ยังแสดงดาวสถานะหลังชื่อ และปุ่มต้องไม่เพิ่มความสูงแถว
- รองรับ inline edit ในตาราง โดยใช้ state/draft/summary/save pipeline เดียวกับฟอร์ม ต้องตรวจสิทธิ์ Editor และไม่ให้การคลิกแถวเปิดฟอร์มโดยไม่ตั้งใจ
- การคลิกแถวเลือกไว้สำหรับสีพื้นหลังได้ แต่ต้องคง Ribbon tab ปัจจุบัน ไม่เด้งไปแท็บ “รูปแบบ” อัตโนมัติ; ผู้ใช้เปิดแท็บรูปแบบเอง และ Ctrl+คลิกยังเลือกหลายแถวได้
- เลือกหลายแถวเพื่อแก้วันที่แบบ batch และวางวันที่จาก clipboard ได้ทั้ง Plan/Actual; ต้องคงการตรวจ Start/End, partial dates, งานลูก และการยกเลิก
- ฟอร์มงานมี copy/paste แผนงานทั้งชุดในระดับเดียวกัน รวมลูก Actual progress และ fileCatalog แต่คงโครงการ/Product/ตำแหน่งปลายทาง และเปลี่ยนจริงเมื่อกดบันทึก
- ปรับสีแถวและสี timeline จาก Ribbon ได้; สีข้อความงานเลยกำหนดกับงานครบ 100% เป็น project settings แยกกัน ใช้ได้ทั้งหน้าจอและพิมพ์
- กฎ overdue เลือกอ้างอิงวันรายงานหรือวันนี้ในเขตเวลา Asia/Bangkok; งานที่ `progress !== 100` และ End ก่อนวันอ้างอิงจึงถือว่าเลยกำหนด ส่วน completed ใช้ `progress === 100`
- Search/filter รุ่นใหม่ต้องทำงานร่วมกับ tree collapse, ribbon context และ full-screen โดยไม่แก้ข้อมูลหรือ Auto-save
- Gantt ฝั่ง HTML ต้องไม่มีเส้นแนวตั้งทั้งหัววัน แถวงาน เส้นแบ่งสัปดาห์ และเส้นวันรายงาน; คงพื้นสีเสาร์–อาทิตย์ เส้นแนวนอนของแถว และให้แถบ Plan/Actual ต่อเนื่องผ่านวันอาทิตย์ โดยวันทำงาน/Duration ยังเว้นวันอาทิตย์
- HTML Actual ที่มีวันเริ่ม–จบครบและมี progress ต้องมีชั้นสีอ่อนวิ่งทับตามเปอร์เซ็นต์พร้อมตัวเลข `%`; partial Actual ห้ามสร้างอีกข้างหรือแสดง progress span ที่ชวนให้เข้าใจว่ามีช่วงวันครบ
- LV2/LV3 ที่เป็นหัวข้อรองรับ progress mode และการ roll up Plan/Actual แยกชุด; partial Actual ต้องไม่สร้างวันที่อีกข้าง และ legacy ใช้กฎ summary ที่สอดคล้องโดยไม่ถูกบังคับเป็น database node

## Import/Export HTML และการบันทึก

- Import HTML รับเฉพาะ JSON ใน `schedule-data` ไม่รันหรือรับ script/style/markup จากต้นทาง
- merge จับคู่ด้วย id คงรายการ/ลำดับเดิมและฟิลด์ที่ต้นทางไม่มี แต่ค่าว่างที่ระบุต้องทับค่าเดิม
- replace ใช้ชุด/ลำดับต้นทาง พร้อม preview การลบและ checkbox ยืนยัน
- ตรวจ schema, ชนิดค่า, วันที่, id ซ้ำ, แม่หาย, วงจร, ข้าม group, ระดับฐานข้อมูล และ file metadata ก่อนยืนยัน
- ใช้ revision/generation guard; ยกเลิก กลับ Viewer หรือผลอ่านล่าช้าต้องไม่เปลี่ยนข้อมูล
- ยืนยัน Import แล้วหยุด Auto-save และปลด fileHandle; staging ห้ามติด snapshot
- Export HTML ใช้ได้ Viewer/Editor และต้องคงโค้ดปัจจุบันพร้อม JSON ที่ยืนยันแล้ว
- ก่อน `createWritable` ตรวจ signature ของ script/style และข้อมูลปลายทาง หากต่างให้หยุดและแนะนำ Export แยกชื่อแล้ว Import ในรุ่นล่าสุด
- อัปเดต `htmlSaveExpectedData` หลังปิด stream สำเร็จเท่านั้น

## CSV และ Excel

- ส่งออกเฉพาะงานระดับสุดท้าย: Description ที่ไม่มี Activity หรือ Activity ใต้ Description เป็นคู่ Plan/Actual
- A:P ตามต้นแบบ, Q=Duration, R=ผลงาน, S=WBS, T=Plan/Actual, U=Task/Activity, V=Task ID, W=Project ID, X=Product ID, Y=Description ID; ปฏิทินเริ่ม Z
- E เป็น Description เสมอ; F เป็น Activity; Y เป็น id ของ Description แม่ ซ่อน U:Y ตาม metadata เดิม ส่วน R แสดง progress แบบเปอร์เซ็นต์เฉพาะแถว Actual และแถว Plan ว่าง
- คอลัมน์ R ต้องมองเห็นได้ ไม่ใช่ helper ที่ซ่อน เก็บค่าเป็นตัวเลขทศนิยม `progress/100` พร้อม number format `0%`; ค่า `null` ต้องเป็นเซลล์ว่าง และห้ามเขียน progress ลงแถว Plan
- รักษา EXCEL_TEMPLATE, DisplayFormat, custom table style, font, สี, border, ขนาดแถว/คอลัมน์, สูตร และ conditional formatting; สูตรวันทำงานยังเว้นอาทิตย์ แต่สีแถบ Gantt ต้องต่อเนื่องผ่านอาทิตย์
- ปฏิทิน Excel ไม่มีเส้นขอบแนวตั้งทั้งหัวและแถวข้อมูล คงเฉพาะเส้นแนวนอน สีเสาร์–อาทิตย์ และแถบ Gantt; ใช้ `TODAY()` เน้นเฉพาะหัววันที่ปัจจุบันสีแดง ไม่ลากเส้นวันนี้ผ่านตาราง คง Plan สีอ่อนและ Actual สีเต็มแยกแถว และใช้ progress ระบายชั้นสีอ่อนทับ Actual โดยไม่อนุมานวันที่ Actual
- Excel Export ต้องไม่มีเส้นขอบแนวตั้งทุกคอลัมน์ รวม A:Y หัวตาราง และปฏิทิน Z เป็นต้นไป; เก็บเส้นแนวนอน สีพื้น ฟอนต์ และ Conditional Formatting ไว้
- Excel Gantt ใช้ range-based Conditional Formatting 3 rules สำหรับทั้งช่วงปฏิทิน: Plan `#C7E2DD`, Actual `#73B7A9` และ Progress `#B9DBD4` โดยอ้าง `$T5`, `$M5`, `$N5`, progress `$R5` และ `Z$3` แบบ relative; Progress ต้องมี priority เหนือ Actual เพื่อให้สีวิ่งทับ ห้ามตัดวันอาทิตย์ออกจากสี และไม่สร้าง rule แยกทุกแถว
- เมื่อแก้ Excel Export ให้รัน `tests/ExcelProgressColumn.test.cjs`, `tests/ExcelGanttReferenceStyle.test.cjs` และ `tests/Recovery.test.cjs`; ตรวจว่า R ของ Plan ว่าง, R ของ Actual ตรงกับข้อมูล, ปฏิทินเริ่ม Z และ JSON ใน HTML ไม่เปลี่ยน
- Import CSV รองรับ UTF-8 แบบ A:X และ A:V เดิม จับคู่ Task ID ก่อน; หากไม่มีจึงใช้ 5 ช่อง + Activity ที่ครบและไม่ซ้ำ
- ตรวจ Product ID/Description ID และคู่ Plan/Actual; ไม่ย้ายแม่ ไม่ล้างค่าว่าง ไม่แก้สี/ไฟล์/%/ลำดับโดยปริยาย
- VBA เก่าเป็นประวัติ ไม่ใช้เป็นกระบวนการหลัก

## วิธีแก้อย่างปลอดภัย

- แก้เฉพาะส่วนที่เกี่ยวข้องและรักษา JSON byte-for-byte เมื่อคำขอเป็น code/UI-only
- หากต้องเปลี่ยนข้อมูล ให้เปรียบเทียบ field-level diff และรายงานรายการที่เปลี่ยน ห้ามสร้างวัน owner progress สี หรือ Activity ตัวอย่างใส่ข้อมูลจริง
- อย่า serialize DOM/JSON ทั้งไฟล์ถ้าไม่จำเป็น เพราะทำ diff กว้างและเสี่ยงเปลี่ยนข้อมูล ใช้ patch แคบและตรวจ script syntax หลังแก้
- ปรับ `README.md` เมื่อพฤติกรรม วิธีใช้ จำนวนข้อมูลที่รายงาน หรือสถานะงานเปลี่ยน ปรับ `AGENTS.md` เฉพาะเมื่อกติกาของผู้ใช้เปลี่ยน
- อย่า commit, push, upload, สร้าง release หรือเขียนทับ remote จนกว่าผู้ใช้จะสั่งโดยตรง

## การตรวจ

การเปลี่ยนแกนหลักหรือก่อนอัปโหลดให้รัน full suite:

```powershell
node --test tests/*.test.cjs
```

ถ้า shell ไม่ขยาย wildcard ให้รันไฟล์ทดสอบทีละไฟล์ หรือใช้คำสั่งเทียบเท่าโดยไม่แก้ข้อมูลจริง

- UI: Viewer/Editor, Dark Mode, desktop/mobile, tree SVG, collapse/filter, file disclosure, resize และ keyboard
- วันที่/progress: Plan/Actual แยกชุด, partial dates, Sunday shift, working days, summary ระดับสุดท้าย และ overdue
- Import/save: merge/replace/preview/cancel/revision/generation/save-target guard และ snapshot เปิดกลับ
- CSV/XLSX: คู่ Plan/Actual, Activity/Description IDs, null/0, สูตร, style, hidden columns และ Gantt

ชุด VM/fake DOM ไม่ใช่หลักฐานตำแหน่งจริงในเบราว์เซอร์ ให้แยกรายงาน unit/VM, browser และ Excel จริงออกจากกัน

## Pre-upload gate

ก่อนบอกว่าพร้อมอัปโหลด ต้องผ่านทุกข้อ:

1. อ่าน JSON จาก HTML หลังแก้และตรวจ parse สำเร็จ
2. ถ้าเป็น code-only: SHA-256 ของข้อความ JSON, จำนวน/ลำดับ id, parent graph และ file selections ต้องตรงกับก่อนแก้ทุกค่า
3. ถ้าเป็น data change: diff ต้องมีเฉพาะค่าที่ผู้ใช้สั่ง และไม่มี id ซ้ำ แม่หาย วงจร หรือ Activity เกิน LV4
4. JavaScript ใน HTML parse/compile ได้ และไม่มี conflict marker หรือ placeholder ที่เพิ่งสร้างค้างอยู่
5. ชุดทดสอบที่เกี่ยวข้องผ่าน; ก่อนอัปโหลดรัน full suite และระบุจำนวนผ่าน/ล้มเหลว
6. ตรวจ `git diff --check`, `git status --short` และ review diff ทุกไฟล์ ระวัง backup/output/tmp/ไฟล์ข้อมูลส่วนตัวติด staging
7. ตรวจ README/AGENTS/SKILL ให้ตรงกับพฤติกรรมจริง และไม่อ้างผล browser/Excel ที่ยังไม่ได้ทดสอบ
8. รายงานไฟล์ที่เปลี่ยน ผลตรวจ ข้อจำกัด และยืนยันว่าไม่ได้ commit/push/upload หากผู้ใช้ยังไม่ได้สั่ง

เมื่อผู้ใช้สั่งอัปโหลด ให้ตรวจ remote, branch, รายการไฟล์ และสถานะล่าสุดก่อนทำ mutation ภายนอก หาก JSON หรือ working tree เปลี่ยนจากตอนตรวจ ให้ทำ pre-upload gate ใหม่
