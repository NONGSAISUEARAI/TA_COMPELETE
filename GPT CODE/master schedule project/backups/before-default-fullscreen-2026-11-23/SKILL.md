---
name: master-schedule-project
description: Maintain the local Master Schedule HTML application, its embedded project data, hierarchy rollups, ribbon tools, and Excel export. Use for changes in this project, including its legacy drawing groups.
metadata:
  updated: "2026-11-23"
  timezone: Asia/Bangkok
---

# Master Schedule Project

อัปเดตล่าสุด: **23 พฤศจิกายน 2569 (2026-11-23)** · เขตเวลา **Asia/Bangkok**

ใช้เอกสารนี้กับโปรเจกต์ `master schedule project` ตรวจโค้ดปัจจุบันก่อนแก้ เพราะผู้ใช้อาจบันทึกข้อมูลใหม่จากหน้าเว็บระหว่างงานได้ วันที่ด้านบนเป็นวันที่ตรวจและปรับเอกสาร ไม่ใช่วันรายงานของโครงการ

## ไฟล์และข้อมูลต้นทาง

- `Master_Schedule.html` คือแอปหลัก รวม HTML, CSS, JavaScript และข้อมูลจริงไว้ในไฟล์เดียว
- ข้อมูลอยู่ใน `<script id="schedule-data" type="application/json">` ประกอบด้วย `project`, `groups`, `tasks` และ metadata การบันทึก
- `Master_Schedule_iPad_Viewer.html` และไฟล์ชื่อมี revision/timestamp เป็นคนละสำเนา อย่าสันนิษฐานว่าแก้แอปหลักแล้วสำเนาอื่นเปลี่ยนตาม
- `Open_Master_Schedule.cmd` เปิด `Local_File_Helper.ps1` สำหรับใช้งานไฟล์อ้างอิงในเครื่อง ผ่าน `127.0.0.1:48731` ค่าเริ่มต้น; helper ไม่ใช่บริการ GitHub Pages
- `Export_MasterSchedule_CSV.bas` เป็นตัวช่วยส่ง CSV จาก Excel ต้องตรวจความเข้ากันได้เมื่อเปลี่ยน schema ส่งออก
- `backups/` เก็บสำเนาก่อนแก้, `tests/` เก็บ regression tests, `.work/` มีสคริปต์ทดลองและ browser QA; อย่าถือว่าไฟล์ใน `.work/` ทุกไฟล์ยังตรงกับรุ่นล่าสุด

เมื่อแก้โค้ด ให้เก็บ JSON ข้อมูลเดิมตรงตามต้นฉบับ เมื่อแก้ข้อมูล ให้เปลี่ยนเฉพาะรายการและช่องที่ผู้ใช้ระบุ สำรองไฟล์ก่อนเปลี่ยนข้อมูลจริง และตรวจ diff ทั้งส่วนโค้ดกับข้อมูล อย่าเขียนทับการบันทึกล่าสุดด้วยข้อมูลจาก backup หรือ fixture เก่า

## โครงสร้างงานสองรูปแบบ

| รูปแบบ | วิธีระบุ | ข้อควรระวัง |
| --- | --- | --- |
| ฐานข้อมูล LV1–LV4 | `databaseModel: 'project-product-work-v1'` ที่ group | LV1 โครงการ → LV2 Product / Group Drawing → LV3 Description → LV4 Activity |
| โครงสร้างเดิม | ไม่มี `databaseModel` ดังกล่าว | มี `groups`, งาน `nodeType: 'section'` และงานลูก; `databaseLevel()` อาจคืน 0 แม้แสดงอยู่ระดับที่ 2 ในตาราง |

**MRT PURPLE LINE STANDARD DRAWING C1** เป็นกลุ่มโครงสร้างเดิม: group ID `mrt-purple-line-std-dwg-c1` และมี C02–C10 ใต้กลุ่ม ห้ามทดสอบเฉพาะ LV2 แบบฐานข้อมูลแล้วสรุปว่ารองรับกลุ่มนี้ ใช้ `taskProgressModeSupported()`, `manualHeadingProgress()` และโครงสร้าง parent จริงประกอบการตรวจ

`id`, `groupId`, `parentId` เป็นตัวเชื่อมถาวร ส่วน WBS คำนวณจากตำแหน่งและเปลี่ยนเมื่อย้ายลำดับ อย่าใช้ชื่อหรือ WBS แทน ID ถาวร หลีกเลี่ยงแปลงโครงสร้างเดิมเป็นฐานข้อมูลโดยอัตโนมัติ

## ผลงานและวันที่ที่ต้องรักษา

### เปอร์เซ็นต์ผลงาน

- LV4 กรอกเปอร์เซ็นต์เอง 0–100 จำนวนเต็ม; ช่องว่างเก็บเป็น `null`
- LV3 มี LV4: `lv3ActivityProgress()` เฉลี่ยเปอร์เซ็นต์ของ LV4 ให้น้ำหนักเท่ากัน ช่องที่ยังไม่กรอกคิดเป็น 0 ไม่ขึ้นกับจำนวนวัน; ไม่มี LV4 ให้กรอกเอง
- LV2: `progressMode: 'auto' | 'manual'` ค่าเริ่มต้น auto โดย `lv2ChildProgress()` ใช้เปอร์เซ็นต์ที่สรุปแล้วของงานลูกโดยตรง ให้น้ำหนักเท่ากัน ไม่รอวันที่ครบ
- หัวข้อเดิมและ group รองรับโหมดใส่เองด้วย `manualHeadingProgress()`; group เดิมในโหมด auto สรุปจากหัวข้องานลูกโดยตรง
- ค่าเฉลี่ยครบ 100 ได้เมื่อทุกงานครบ 100 เท่านั้น; การปัดเศษค่าเฉลี่ยที่ยังไม่ครบถูกจำกัดสูงสุด 99; ไม่มีงานลูกในโหมด auto คืน `null`
- โหมด manual ต้องทำงานทั้งใน dialog และ inline cell พร้อมตรวจ 0–100, สถานะงาน, สีตัวอักษร, บันทึกและเปิด HTML กลับมา หัวข้อที่ไม่มีงานลูกแต่ใส่เองครบ 100 ต้องไม่แสดงป้าย “รอเพิ่มงานย่อย”
- `progressOf()` ยังใช้การถ่วงน้ำหนักตามวันในบางส่วน เช่นภาพรวมโครงการ อย่าเหมารวมว่าสรุปทุกระดับใช้สูตรเดียวกัน

### Plan และ Actual

- Plan ใช้ `dateMode`, `planStart`, `planEnd`; Actual ใช้ `actualDateMode`, `actualStart`, `actualEnd` แยกกัน
- LV3 auto ใช้วันที่ LV4 ที่มี: Start แรกสุดและ End หลังสุด ตรวจแต่ละขอบแยกกัน ไม่ต้องครบทุกงาน
- LV2 auto ใช้วันที่สรุปของ LV3 โดยตรง จึงรับวันที่จาก LV4 ผ่าน LV3 และเคารพวันที่ที่กำหนดเองของ LV3 ได้ ใช้กับหัวข้อเดิมที่รองรับด้วย
- `availableChildDates()`, `availablePlanChildDates()`, `actualDatesOf()`, `summarizeRecord()` และ `summarizeTask()` เป็นจุดตรวจหลัก
- วันที่ manual ของหัวข้อมีลำดับความสำคัญเหนือวันที่งานลูก ปุ่ม “ใช้วันที่จากงานย่อย” / “ใช้ Actual จากงานย่อย” คืนโหมด auto และต้องเก็บโหมดนี้หลังบันทึก
- ไม่ต้องรอวันที่ครบเพื่อแสดงวันที่ที่มีอยู่ แต่ต้องมีวันเริ่มและวันจบที่ถูกต้องจึงคำนวณระยะเวลาได้ ข้อความไม่มีวันที่ไม่ใช่สถานะกำลังประมวลผล
- เก็บวันที่ในข้อมูลเป็น ISO `YYYY-MM-DD`; ระยะเวลาทำงานนับจันทร์–เสาร์ ไม่รวมอาทิตย์ อย่าใช้ timezone ของเครื่องแทนวันรายงานหรือ Asia/Bangkok โดยไม่ตรวจ

## ตารางและ Ribbon

- Viewer ดู/ค้นหา/กรอง/ส่งออกได้; Editor จึงแก้ข้อมูลได้ รหัสปลดล็อกหกตัวเป็นเพียง UI guard ของแอป ไม่ใช่ระบบสิทธิ์บนเซิร์ฟเวอร์
- Ribbon ปัจจุบัน: ภาพรวม, แผนงาน, ค้นหา/กรอง, มุมมอง, ปฏิทิน, สรุปสถานการณ์, รูปแบบ, นำเข้า–ส่งออก ดู `RIBBON_TABS` เป็นหลัก
- แท็บเครื่องมือใช้ความสูงคงที่ตามขนาดหน้าจอ เพื่อไม่ให้ตารางขยับเมื่อสลับแท็บ คลิกแท็บที่เปิดซ้ำเพื่อย่อ และคลิกอีกครั้งเพื่อเปิด
- “สรุปสถานการณ์” เป็นหน้าแยก ไม่ใช่แผงเครื่องมือความสูงคงที่ของ Ribbon; มีการติดตาม `followMode: 'self' | 'subtree'` และสรุปรายสัปดาห์อ้างอิงวันรายงาน
- ปุ่มดาวด่วนอยู่หลังชื่อ LV2/LV3/LV4: ไม่มีวงกลม เส้นขอบ หรือพื้นหลัง แต่คงพื้นที่กดโปร่งใส 24×24; รายการที่ยังไม่ติดตามแสดง `☆` จางเมื่อ hover/focus ส่วนที่ติดตามแสดง `★` เหลืองตลอด ในโหมดตารางเต็มจอต้องยกเว้น `dialog` จาก `inert` เพื่อให้หน้าต่างเลือกขอบเขตของ LV2/LV3 กดได้
- `followMode: 'self' | 'subtree' | 'exclude'`: `subtree` ของ LV2/LV3 ต้องแสดงดาวบนลูกทุกระดับและล้าง `exclude` เก่าของลูกเมื่อผู้ใช้เลือก “งานย่อยทั้งหมด” ใหม่; LV4 ที่รับดาวสืบทอดกดดาวเพื่อตั้ง `exclude` เฉพาะตัวเองได้โดยไม่กระทบแม่หรือพี่น้อง กดอีกครั้งเพื่อล้างข้อยกเว้นและกลับมารับดาวสืบทอด ห้ามคัดลอกสถานะดาวไปกับสำเนาแผนงาน
- Ctrl+คลิก Start/End เพื่อเลือกแก้วันที่หลายรายการ; Ctrl+C / Ctrl+V รองรับวันที่และตาราง Start/End จาก Excel อย่ากลับไปใช้ Shift+คลิก
- คลิกแถบ Plan/Actual เลือกสีแยกกันได้ และ Ctrl+คลิกเลือกหลายแถบ; `planBarColor`, `actualBarColor`, `barColor` มีหน้าที่ต่างกัน
- คลิกแถวเลือกสีพื้นหลังและใช้แถบรูปแบบด้านบน ไม่เพิ่มปุ่มสีรายแถว; สีพื้นหลังเก็บใน `rowColor`
- กฎสีตัวอักษรงานเลยกำหนด (`project.overdueTextRule`) กับงานครบ 100% (`project.completedTextRule`) เปิด–ปิดและกำหนดสีแยกกัน รักษาค่าที่ผู้ใช้บันทึกไว้
- แถบ Plan/Actual ต่อเนื่องข้ามอาทิตย์ แม้ระยะเวลางานยังไม่นับอาทิตย์; Actual แสดงความคืบหน้าและป้ายเปอร์เซ็นต์ ตารางปฏิทินรุ่นนี้ซ่อนเส้นแนวตั้ง แต่ยังมีแถบสีวันหยุด
- ตัวกรองรองรับคำค้น/WBS/รายละเอียด, โครงการ, หมวดงาน, ผู้รับผิดชอบหลายคน, ผลงาน, กำหนดเวลา, ช่วง Plan ทับซ้อน, ระดับงาน, พื้นที่และสถานะ แสดงแถวแม่ประกอบ และแยกจำนวนรายการที่ตรงจริงกับจำนวนแถวที่แสดง
- “ใกล้ครบกำหนด” ใช้ภายใน 7 วันจากวันรายงาน; filter เป็น view state ไม่ควรแก้ task data หรือทำให้ไฟล์ dirty

## บันทึก นำเข้า และ Excel

- การแก้ในหน้าจอกับ draft ในเบราว์เซอร์ยังไม่เท่ากับบันทึกลง HTML ใช้ `changed()`, `snapshot()`, การบันทึกไฟล์ และ import validation ตามหน้าที่เดิม
- รักษา field เพิ่มเติมใน `project` เช่นกฎสี เมื่อบันทึก dialog อย่าสร้าง object ทับจน metadata หาย
- Export Excel มี `level: 'leaf' | '3' | '4'`: แบบเดิม, LV3 เท่านั้น, LV4 เท่านั้น ผ่าน `excelExportRecords(groupId, level)` และ `buildExcelWorkbook()`
- LV3 export ต้องรวม Description ที่มี LV4 และใช้ค่าที่สรุปแล้ว; LV4 export เก็บ Description แม่และ Activity แยกคอลัมน์ พร้อม ID ถาวรและ Plan/Actual สองแถวต่อรายการ
- ตรวจ layout ปัจจุบันก่อนแก้: Description อยู่ E, Activity ถัดไป F, Start/End M/N, ผลงาน R เฉพาะแถว Actual, ปฏิทินเริ่ม Z ไม่ใช่ Y หลังเพิ่มคอลัมน์ผลงานแล้ว
- เปลี่ยนคอลัมน์ Excel ต้องตรวจสูตร, references, conditional formatting, autoFilter, freeze panes, metadata และ CSV import/export ร่วมกัน อย่าถือว่า Excel กับ CSV ใช้ลำดับคอลัมน์เดียวกัน
- ระดับที่ไม่มีข้อมูลต้องแจ้งและปิดการดาวน์โหลด; ตรวจไฟล์ XLSX ที่ได้จริง ไม่ใช่เพียงชื่อหรือข้อความ preview
- เคยเติม owner ว่างเป็น `Tawan` และ action ว่างเป็น `ดำเนินการ` ตามคำสั่งผู้ใช้เฉพาะครั้ง ไม่ใช่ข้อกำหนดให้เติมทุกครั้งหรือเขียนทับค่าที่มีอยู่
- แจ้งให้ชัดว่าแก้ไฟล์ local หรือเผยแพร่แล้วจริง การแก้ HTML ในเครื่องไม่เปลี่ยน GitHub Pages อัตโนมัติ

## วิธีตรวจงาน

`tests/helpers/schedule-harness.cjs` ส่งออก `boot(html)` และ `dataPattern` สำหรับรัน app logic ใน VM/fake DOM ไม่ใช่ browser จริง ใช้ fixture ในหน่วยความจำและเทียบข้อมูลก่อน–หลัง อย่าแก้ JSON จริงเพื่อให้ test ผ่าน

เลือกทดสอบตามส่วนที่แก้ เช่น:

```powershell
node --test tests/LV2AutoProgress.test.cjs tests/LV2ProgressMode.test.cjs tests/LegacyProgressMode.test.cjs
node --test tests/LV2PlanDates.test.cjs tests/LV2ActualDates.test.cjs tests/LV3PartialDates.test.cjs tests/LV3Progress.test.cjs
node --test tests/ExcelLevels.test.cjs tests/ExcelProgressColumn.test.cjs tests/ExcelGanttReferenceStyle.test.cjs
node --test tests/SearchFilter.test.cjs tests/SummaryTracking.test.cjs tests/ContinuousBarsProgress.test.cjs tests/HTMLTimelineGrid.test.cjs
```

สำหรับ save/import ให้เพิ่ม `tests/HTMLImport.test.cjs`; สำหรับสีเลือก `RowColor`, `TimelineColor`, `OverdueText`, `CompletedText`; สำหรับวันหลายรายการเลือก `BatchDates`, `DateClipboard` ตามงาน

จำนวนงานและข้อมูลจริงเปลี่ยนได้ บาง test รุ่นเก่าเทียบกับ backup หรือ fixture เก่า จึงต้องแยก stale expectation ออกจาก regression ของโค้ด ห้ามอ้างว่าชุดทดสอบทั้งหมดผ่านถ้ายังไม่ได้รัน

เมื่อแก้ UI หรือมีผู้ใช้แจ้งว่าทำไม่ได้ ให้ลองผ่าน browser กับแถว/กลุ่มที่แจ้งจริง รวมการกดบันทึกและเปิด HTML กลับมา ก่อนสรุปผล ตรวจทั้งโครงสร้างฐานข้อมูลและโครงสร้างเดิมตามขอบเขตงาน ใช้ข้อมูลจำลองใน browser โดยไม่บันทึกทับข้อมูลจริง

เมื่อแก้เอกสารนี้ครั้งต่อไป ให้ตรวจฟังก์ชันและ tests ปัจจุบันอีกครั้ง และปรับวันที่อัปเดตด้านบนตามวันที่ทำงานจริง
