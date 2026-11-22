# Block / Dynamic Block — วิเคราะห์ source เพื่อคัดผลงาน

ตรวจวันที่ 11 ตุลาคม 2026 — Static source review only

ต้นฉบับ: [z00x_TA_standard_sun_func_and_MAIN.lsp](C:/TA/TA_COMPELETE/z00x_TA_standard_sun_func_and_MAIN.lsp)

## ข้อสรุปสำหรับการเลือก

**ตัวหลักที่น่าพัฒนาเป็นผลงาน:** Match Dynamic Properties, Match Attributes และ Rename Block from Text ส่วน Select Dynamic / Non-Dynamic Blocks เหมาะเป็นเครื่องมือเสริมสั้น ๆ และ Set Block Units เหมาะเป็นงานจัดมาตรฐานแบบ

**ตัวหลักที่ยังไม่ควรนำไปแจกหรือทำ demo บนงานจริง:** Replacement ทั้งสามรุ่น, redynamicblock และ save_dynamic_scale_scdyn_ มีข้อจำกัดหรือทางเดินที่เสี่ยงต่อข้อมูลเดิม ต้องแก้ในสำเนาและทดสอบก่อน

นี่เป็นข้อเสนอ ไม่ใช่มติเลือก/ตัดคำสั่งแทนผู้ใช้ และไม่ใช่การรับรองว่าใช้งานได้จริงครบทุกกรณี

## ขอบเขตและความเชื่อมั่น

- อ่านไฟล์ปัจจุบันโดยไม่โหลดเข้า AutoCAD ไม่ประเมินผล AutoLISP และไม่แก้ต้นฉบับ
- ตรวจโครงสร้าง 45 คำสั่งในหมวด Block เดิม และเพิ่ม 15 คำสั่งที่เกี่ยวกับ attribute, placement และ counting จากหมวดอื่น รวม **60 ชื่อคำสั่ง / 61 definitions** เพราะ `counting_blklist_` ประกาศสองครั้ง
- ตรวจทางเดินหลักและ helpers ของตัวที่จัดอันดับและตัวเสี่ยงโดยตรง; รายการเฉพาะทางที่เหลือเป็นการคัดกรองจากโครงสร้าง/ข้อความ/คำสั่ง CAD ไม่ใช่การทดสอบทุก branch
- ขอบเขตนี้ไม่ใช่คำยืนยันว่าค้นพบทุกคำสั่งที่แตะ Block ในไฟล์ทั้งหมด
- ไฟล์ที่ตรวจมี 66,104 บรรทัด และ 1,004 `defun` definitions รวม helpers และ nested definitions
- SHA-256: `b6d5966a5d70f9e0335c62f90b57b12c3b5a92bc19c480fdc73c511595ec811f`
- ตัวเลขความซับซ้อนด้านล่างเป็นการประเมิน workflow/dependencies/ความเสี่ยง ไม่ใช่คะแนน benchmark หรือ cyclomatic complexity
- ชื่อย่อ เช่น `madynprop`, `maatt`, `RENB3x` ใช้เป็นป้ายอ่านง่ายในรายงานเท่านั้น ชื่อที่ประกาศจริงคือชื่อเต็มหลัง `c:`; ยังไม่รับรองว่า alias เหล่านี้เรียกได้

## แยกหมวดก่อนทำหน้ารวมคำสั่ง

| หมวดไทย / English | ตัวอย่าง | ลักษณะผลกระทบ |
|---|---|---|
| เลือกและตรวจ Block / Selection & Inspection | seldyn, select_not_dynamic, qblk | คัดชุดเลือกหรือเก็บชื่อ ไม่จำเป็นต้องเปลี่ยน geometry |
| จัดการชื่อและมาตรฐาน / Naming & Standards | RENB3x, TA_SET_ALL_BLOCK_UNITS_MM, ALEX, unisc_ | แก้ definition/metadata ซึ่งมีผลกับ references ที่ใช้ร่วมกัน |
| ถ่ายทอดข้อมูล / Property & Attribute Matching | madynprop, maatt, madeepatt | เขียนค่าลง BlockReference/AttributeReference เป้าหมาย |
| สร้าง แทนที่ และสร้างซ้ำ / Creation & Replacement | MKblk, Reblock, redynamicblock | สร้างหรือลบวัตถุ มีความเสี่ยงต่อข้อมูลและ identity เดิม |
| วางตำแหน่ง ทำซ้ำ และสรุป / Placement, Arrays & Reporting | B2B, ofblk, insarray, blk2ct, counting_blklist_ | ย้าย/ทำสำเนา references หรือสร้างข้อความสรุป |
| เครื่องมือ Dynamic เฉพาะแบบ / Schema-specific Dynamic Tools | ADVSM, rew1/rew2, UCupdate, dynjoint | ต้องมี parameter/action/block library ตามที่โค้ดกำหนด |

คำสั่ง PPLINE ที่ผู้ใช้ปัดตกยังไม่กลับเข้าสู่ shortlist; ไม่ตัดคำสั่งเกี่ยวกับ polyline อื่น ๆ โดยอัตโนมัติเพียงเพราะเกี่ยวกับ geometry ชนิดเดียวกัน

## ตัวที่ควรคัด — แยกคุณค่าพอร์ตจากความพร้อม

| ชื่อจริงหลัง `c:` / บรรทัด | ชื่อผลงานไทย / English | คุณค่าพอร์ต | ความซับซ้อน | ความพร้อมจาก source |
|---|---|---|---|---|
| `matching_dynamic_properties_madynprop` / 18348 | จับคู่คุณสมบัติ Dynamic Block / Match Dynamic Block Properties | สูง: เห็นการถ่ายทอด parameter ไปหลายชิ้นชัด | กลาง–สูง | ต้องเสริมการตรวจ property และตรวจผลก่อน demo |
| `matching_attribute_properties_maatt` / 18456 | ถ่ายทอดข้อมูล Attribute / Match Block Attributes | สูง: ปัญหางานเขียนแบบทั่วไป ไม่ผูกชื่อ block ตายตัว | กลาง | ต้องเสริม source/target validation และ cleanup |
| `rename_block_RENBLKV2_RENB3x` / 11419 | เปลี่ยนชื่อ Block จากข้อความ / Rename Block from Text | กลาง–สูง: workflow ชัดและอธิบายง่าย | ต่ำ–กลาง | โครงสร้างใกล้พร้อมกว่าตัวหลักอื่น แต่ยังต้องตรวจ object/name และทดสอบ |
| `select_dynamic_block_seldyn` / 51869 + `select_not_dynamic_block_` / 51915 | คัดเลือกชนิด Block / Select Blocks by Dynamic Status | กลาง: demo สั้นและใช้ได้กว้าง | ต่ำ | ต้องรองรับ selection=nil และผลลัพธ์ว่าง |
| `TA_SET_ALL_BLOCK_UNITS_MM` / 65145 | ตั้งหน่วยแทรก Block เป็นมิลลิเมตร / Normalize Block Insertion Units | กลาง: แสดงการจัดมาตรฐาน batch | ต่ำ–กลาง | มี local variables/skip/catch/count แต่ต้องเพิ่ม preview และ Undo/cleanup |
| `allow_explode_block_ALEX` / 4363 | อนุญาตให้ Explode Block / Enable Block Exploding | ต่ำ–กลาง: เหมาะเป็น utility เสริม | ต่ำ | helper ไม่ใช้ argument และ selection ยังไม่ป้องกัน |

ลำดับ **เตรียมให้พร้อม** ที่เสนอ: RENB3x → คู่คัดเลือก Block → Match Attributes → Match Dynamic Properties → Units ส่วนลำดับ **โชว์บนหน้าเว็บเมื่อผ่านทดสอบแล้ว** ให้ Match Dynamic Properties และ Match Attributes อยู่ด้านบนได้

### 1. Match Dynamic Properties — น่าสนใจที่สุด แต่ไม่ใช่ copy ทุกอย่าง

อ่าน `LM:getdynprops` ของต้นแบบ แล้วไล่เขียน property ชื่อเดียวกันในเป้าหมายผ่าน `LM:setdynpropvalue` ข้ามชื่อ `Origin` ที่ 18431–18434 ไม่ได้เปลี่ยน block definition หรือคัดลอก attributes/layer/scale

จุดเด่นคือ workflow เลือกต้นแบบครั้งเดียวและเลือกเป้าหมายหลายชุด มี `_StartUndo`/`_EndUndo` และ progress display

ข้อจำกัดที่ตรวจพบ:

- เงื่อนไข effective name เท่ากันถูก comment ที่ 18430 จึงอนุญาตข้าม block schema โดยไม่ตรวจความหมายของ property ให้ตรงกัน
- ไม่พบ guard `IsDynamicBlock` สำหรับต้นแบบและเป้าหมายในตัวคำสั่ง; filter `INSERT` อย่างเดียวไม่รับรองว่าเป็น dynamic block
- setter ที่ 158–171 ทำ variant coercion แต่ไม่มี ReadOnly/AllowedValues/readback; คำสั่งไม่ได้ตรวจว่าค่าปลายทางเปลี่ยนจริง
- Autodesk ระบุว่า dynamic property อาจปฏิเสธค่าที่อยู่นอก allowed values/range โดยไม่แจ้ง error ดังนั้นการไม่มี exception หรือ setter คืนค่าที่ป้อน **ไม่เพียงพอที่จะนับเป็น success** ([Value Property](https://help.autodesk.com/cloudhelp/2015/PLK/AutoCAD-ActiveX/files/GUID-2FFB80CC-12DB-4B31-BDD0-18A565B15A02.htm))
- ควรตรวจ [ReadOnly](https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-ActiveX-Reference/files/GUID-F907311B-2BFC-4498-BD1D-560D537F7FE8.htm), ชนิดค่า และข้อจำกัดก่อนเขียน แล้วอ่านกลับ; allowed-value list อย่างเดียวไม่ครอบคลุม min/max ([AllowedValues](https://help.autodesk.com/cloudhelp/2016/PTB/AutoCAD-ActiveX/files/GUID-EB41B402-5E46-4D9B-9853-AF172AEF1A65.htm))
- target selection ถูก catch แต่การเขียน property ไม่ได้ catch ราย property; failure ระหว่างงานอาจทำให้ไม่ถึง `_EndUndo`/กลับหน้าจอ และเกิด partial update

ขอบเขต demo รุ่นแรกที่เสนอ: dynamic blocks จาก definition เดียวกัน ตรวจ property ที่แก้ได้ก่อน และรายงาน Applied / Skipped / Failed จริง ไม่ใช้คำอธิบายว่า “รองรับ Dynamic Block ทุกประเภท”

### 2. Match Attributes — ควรเพิ่มเข้าตัวหลักของพอร์ต

อ่าน tag/value จากต้นแบบ และเขียนตาม tag ลงเป้าหมายที่ 18549–18562 มีโหมด `skip_blank_val_=0` ที่เก็บค่าปลายทางเมื่อ source เป็นข้อความว่าง ไม่ได้เปลี่ยน attribute definitions หรือสั่ง ATTSYNC

ข้อควรปรับ:

- ตรวจต้นแบบมี editable attributes และกรณีไม่ได้เลือกต้นแบบก่อนถามเป้าหมาย
- `member` ที่ 18545 เทียบ tag กับรายการ tag ของ **ต้นแบบเอง** ไม่ใช่ยืนยันว่าเป้าหมายมี tag นั้น; setter อาจไม่พบ tag แล้วคืน nil โดยไม่มีรายงาน
- effective-name check ถูก comment ที่ 18544; การจับคู่ข้ามชนิด block ควรเป็นตัวเลือกที่ผู้ใช้เข้าใจ ไม่ใช่สัญญาว่า schema ตรงกันเสมอ
- รายงาน tag ที่ไม่มีในเป้าหมาย / blank ที่ข้าม / การเขียนที่ล้มเหลว และทดสอบ constant/multiline attributes ก่อนกล่าวอ้างรองรับ
- local variables, error cleanup และ Undo ต้องครอบคลุมทั้งคำสั่ง

GIF ที่เหมาะ: ต้นแบบมี CODE, DESCRIPTION และช่องว่าง → เป้าหมายหลายชิ้น → แสดงค่าที่ถูกถ่ายทอดและค่าที่ไม่ถูกล้าง เห็นประโยชน์โดยไม่ต้องใช้ library เฉพาะงาน

### 3. Rename from Text — จุดเริ่มต้นที่เหมาะสำหรับแยกเป็นไฟล์เดี่ยว

RENB3x มี 9 local variables, เรียก `vl-load-com`, ตรวจว่า entsel สองครั้งคืนค่า และ catch ตอนหา definition กับเปลี่ยนชื่อ (11443–11484) ดีกว่า RENB3 รุ่นสั้นที่เรียก `rename` ตรง ๆ

แต่ `TextString` ที่ 11435–11436 อ่านก่อน catch ถ้าเลือกเส้นหรือ object ที่ไม่รองรับจะ error; nil check ไม่ครอบคลุม Escape ทั้งหมด ควรตรวจชนิด object/property, ชื่อว่าง/ชื่อซ้ำ/ชื่อไม่ถูกต้อง, MText formatting และ definition ที่ไม่ควรเปลี่ยน เช่น Xref/anonymous/layout

ชื่อใหม่มีผลกับ block definition และ references ที่ใช้ definition นั้นร่วมกัน ไม่ใช่ rename reference ชิ้นเดียว

พบ helper `TA:renameblock_` ที่ 11056–11143 ซึ่งมี local variables ตรวจ string/blank/name collision และ catch อยู่แล้ว แต่ **RENB3x ปัจจุบันยังไม่ได้เรียก helper นี้** นี่คือฐานที่ควรพิจารณา reuse ในสำเนาเมื่อได้รับคำสั่งให้แก้ ไม่ใช่ dependency ที่ต้องขนไปโดยอัตโนมัติ

### 4. Selection / Units / Enable Exploding — utility เสริม

- คู่ selection ใช้ `IsDynamicBlock` และ `pselect` ไม่มี helper ภายในที่เรียกโดยตรง แต่เรียก `sslength` โดยไม่มี guard selection=nil ก่อน loop จึงต้องทดสอบ Enter/Escape/ไม่พบผลลัพธ์
- Units ตั้ง `INSUNITS=4` และ `Units=4` ของ definitions ที่ไม่ใช่ Layout/Xref และมี writable Units มีผลนับ success/skip แต่ยังไม่แยก unsupported ออกจาก failure ในข้อความสรุป ไม่ได้ scale geometry เก่า คำอธิบาย “แปลงทุกอย่างเป็น mm” ใน comment กว้างกว่าพฤติกรรมจริง
- ALEX เปลี่ยน `Explodable` ของ definition ไม่ได้ explode object; helper `TA:set-block-explodable` ที่ 4339–4362 รับ `allow-exploding` แต่เขียน true เสมอ และ lookup definition ก่อนตรวจ nil ขาด input validation
- `expl-p` ที่ 25301 เปลี่ยน Explodable หลาย definitions; ไม่ควรใช้แทน ALEX ใน demo เพราะขอบเขตผลกระทบกว้างกว่า
- `unisc_` ที่ 27315 ตั้ง BlockScaling ของ definition ผ่าน helper ไม่ใช่การทำให้ scale XYZ ของ references เดิมเท่ากัน ส่วน `resc` ที่ 29004 คูณเฉพาะ XScaleFactor ไม่ใช่ uniform scaling

## จุดที่ต้องพักก่อน — หลักฐานความเสี่ยงต่อข้อมูล

### Reblock / reblock2 / reblock3 ไม่ใช่รุ่นที่แทนกันได้

| รุ่น | สิ่งที่ทำจริง | ปัญหาสำคัญ |
|---|---|---|
| `Replace_block_object_Reblock` / 5221 | กรอง effective name ของของเดิม แทรกชื่อใหม่ ณ insertion point/rotation เดิมแล้วลบของเดิม | scale=1; ไม่ถ่ายทอด attributes/dynamic values/layer/XYZ scale; ช่วงท้ายปรับ rotation ทุกตัวเป็นค่าที่เลือกใหม่; คืน OSMODE เป็น 1279 ไม่ใช่ค่าเดิม |
| `replace_block_object_reblock2` / 5324 | เปลี่ยน INSERTs ที่เลือกโดยไม่กรอง effective name เดิมแบบรุ่นแรก แล้วลบชุดเดิม | **ลบชุดเดิมนอกเงื่อนไข target selection สำเร็จ**; scale=1 และข้อมูลอื่นไม่ได้ถ่ายทอด |
| `replace_block_object_reblock3` / 5426 | แทรกใหม่และถ่ายเฉพาะ `distance1` | ขั้นลบชุดเดิมถูก comment ที่ 5501–5509 จึงเกิดของเก่า+ของใหม่ ไม่ใช่ replacement สมบูรณ์; ไม่ตรวจ schema/property ที่ขาด |

กรณีเสี่ยงที่ยืนยันจาก control flow ของ reblock2:

1. เลือกชุด block เดิมได้สำเร็จ
2. ยกเลิก target selection หรือเลือก object ที่อ่าน effective name ไม่ได้: error ถูกจับที่ 5353–5364
3. replacement loop ข้ามเพราะ ERR_ เป็น error ที่ 5368–5371
4. ยังไปเรียก `TA:ss-erase` ที่ **5393** โดยไม่มี guard ERR_ และ helper ที่ 2198–2208 ใช้ `vla-delete` ทีละตัว

นี่เป็นผลจากการอ่าน source ไม่ใช่การทดลองลบแบบจริง Catch ไม่ใช่ rollback และ Undo mark ก็ไม่ใช่การย้อนกลับอัตโนมัติ

ก่อนพัฒนา Replacement ควรกำหนด contract ชัดเจนว่าจะเก็บ insertion point, normal, rotation, XYZ scale/mirror, layer/appearance, editable attributes และ dynamic values อะไรบ้าง; validation และการสร้างใหม่ต้องสำเร็จ/ตรวจผลก่อนลบตัวเดิม พร้อมรองรับ partial failure อย่างปลอดภัย การสร้างใหม่ยังเปลี่ยน handle/object identity จึงต้องระบุข้อจำกัดด้านข้อมูลอ้างอิงหรือ metadata อื่นด้วย

### redynamicblock — สร้างใหม่ ไม่ใช่ refresh ที่รักษาข้อมูลครบ

ที่ 7055–7126: เก็บ effective name/insertion point/rotation/dynamic properties → insert definition เดิมใหม่ scale=1 → เขียน properties → ลบ reference เดิมที่ 7122 ไม่พบการถ่าย attribute values, layer และ scale/mirror เดิม

ไม่ควรโฆษณาว่า reset/repair dynamic block โดยข้อมูลครบ การใช้ `entlast` หลัง insert และไม่มี readback/catch ของแต่ละ write เพิ่มความเสี่ยง; helper UI ถูกเปิดแบบ text โดยไม่เห็นการคืนในตัวคำสั่ง

### save_dynamic_scale_scdyn_ — Flip ถูก toggle ใน loop

ที่ 11039 เรียก `LM:toggleflipstate` **ทุก iteration ของรายการ property** แล้วค่อย restore property ตัวนั้นที่ 11045 ไม่ใช่การเก็บ flip แล้วคืนครั้งเดียว helper 218–230 เลือก property แรกที่ AllowedValues เท่ากับ `(0 1)` จึงไม่ควรถือว่าจับ flip ที่ตั้งใจเสมอไป

สถานะท้ายอาจขึ้นกับลำดับ properties/จำนวนรอบ/ตำแหน่ง flip ในรายการ ไม่รับรองว่าจะคง flip เดิม ส่วนคำสั่ง scale ที่ 11016–11023 อยู่นอก dynamic check ถ้าเลือก static block จะยัง rescale และอาจใช้ property list global ที่ค้างจากการเรียกก่อนหน้า

### madeepatt — reference error ไม่หยุดการเขียน

ที่ 18582–18592 จับ error ตอนอ่านต้นแบบเป็น Er-msg_ แต่ไม่มีการตรวจ Er-msg_ ก่อนเข้า target loop; บรรทัด 18607 ยังเขียนจาก `deepatt_obj_atttxt_` ซึ่งไม่ได้เป็น local หากอ่านต้นแบบครั้งใหม่ล้มเหลวและตัวแปรนี้มีข้อความจากครั้งก่อน อาจเขียนข้อความเก่าไปยัง target ได้ ต้องพักก่อนจน source validation/locals/exit path ถูกแก้

### MKblk / MKTblk / MKBREAL — การสร้างผูกกับผลลบ definition

MKblk ตั้งชื่อจาก DWG + suffix, MKBREAL ใช้ TextString จาก object และทั้งกลุ่มมี lookup/delete definition ผ่าน global `doc` ก่อน `_block` และ insert

ตัวอย่าง MKblk ที่ 6258–6267: เงื่อนไขเข้าสร้างใหม่ทดสอบข้อความของ **ผลการลบ** ด้วย wildcard `*error*,*IAcadBlock*` ไม่ใช่สถานะ transaction ที่ชัดเจน กรณีลบ definition ที่ลบได้สำเร็จและคืน nil จะไม่เข้า branch `_block` ต่อ จึงมีทางเดินลบ definition แต่ไม่สร้างใหม่ อย่าตีความการ catch ว่าอนุญาตให้ overwrite ได้อย่างปลอดภัย ([Autodesk Delete Method: ไม่มี return value](https://help.autodesk.com/cloudhelp/2020/ENU/AutoCAD-ActiveX-Reference/files/GUID-167FBA5F-C3F3-4195-A170-02E5E46EC797.htm))

ต้องแยก New / Exists / In-use / Delete failed / Redefine เป็น branch ที่ชัดเจน ไม่ตรวจ string ของ error/object และไม่ใช้ doc ที่อาจไม่มีค่าหรืออ้าง document อื่น

### Counting — มีสอง definitions และไม่ใช่ generic block counter

`c:counting_blklist_` ประกาศที่ 21737 และ 21898; เมื่อประเมิน definitions ทั้งสองตามลำดับ ตัวหลังแทนตัวแรก แต่ยังไม่ได้ยืนยันว่าการโหลดไฟล์ทั้งก้อนจะสำเร็จถึงบรรทัดนั้น

รุ่นหลังนับเฉพาะ dynamic blocks แยก effective name แล้วกลุ่มตาม `Distance1` ที่ปัดด้วย LM:round (21985–21993) สร้าง MText ผ่าน TA:List_to_mtext_ ไม่ใช่ AutoCAD Table/CSV/BOM ครบระบบ หาก block ไม่มี Distance1 จะเสี่ยงส่ง nil เข้า round ต้องกำหนด schema/fallback; complexity สูงขึ้นจากการกรองซ้ำและนับรายการซ้ำใน loop

## Dependencies ที่ต้องแยกให้ถูก

| งาน | helpers ที่อ่าน/อ้างจาก source | ประเด็นตอนแยกเป็นไฟล์เดี่ยว |
|---|---|---|
| Match Dynamic | LM:effectivename (37), LM:getdynprops (177), LM:setdynpropvalue (158), _StartUndo (15523), _EndUndo (15532), TA:interface_text_ (20110), TA:textscr_process_V2 (2673) | validation/readback, document binding, cancel cleanup; UI/progress เป็นส่วนแยกได้ |
| Match Attributes | LM:vl-getattributevalues (111), LM:vl-getattributevalue (81), LM:vl-setattributevalue (96), tag/value helpers (116/121), LM:effectivename + Undo/UI/progress | ทดสอบ editable/constant/multiline; ไม่ขน helper ที่ไม่ใช้เพียงเพราะอยู่ข้างกัน |
| Replacement | TA:vla-insertblock (4314), TA:EF_Filter_ss_set_ (1257; รุ่นแรก), TA:ss-erase (2198; รุ่น2), LM helpers, deg-to-rad/rad-to-deg | helper ไม่ได้รักษาคุณสมบัติเดิมโดยอัตโนมัติ และไม่มี transaction safety |
| Rename RENB3x | ไม่มี internal helper call ที่ต้องตามไป | TA:renameblock_ เป็นตัวเลือก reuse ไม่ใช่ dependency ปัจจุบัน |
| Selection / Units | ไม่มี internal helper call ที่ต้องตามไป | ยังพึ่ง AutoCAD selection/ActiveX และสภาพ document ไม่ใช่ pure standalone Lisp |
| Counting | LM:effectivename, LM:getdynpropvalue, LM:round, TA:Count_item_in_list_, TA:EF_Filter_ss_set_, TA:List_to_mtext_, TA:assembly_coordinate_coner | ตรวจ duplicate definitions, Distance1 schema และ text layout/UCS |

TA:vla-insertblock ใช้ CVPORT เลือก ModelSpace/PaperSpace และตั้ง `acadApp`, `doc`, `ms`, `block` เป็น globals ไม่ใช่ locals อีกทั้งรับ scale ตัวเดียวแล้วใช้ทั้ง XYZ ควรจับ object ที่ helper คืนมาแทน `entlast` เพื่อผูกผลลัพธ์กับการสร้างครั้งนั้น; InsertBlock คืน BlockReference และรับจุดแบบ WCS ตาม [Autodesk InsertBlock](https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-LT-ActiveX-Reference/files/GUID-17F86FDD-B7FC-4F43-9F16-B4958F73A66D.htm)

_StartUndo/_EndUndo มี fallback หา ActiveDocument ถ้ารับ doc=nil ดังนั้น **doc ไม่ได้ set ใน command ไม่ได้แปลว่าเสียเสมอไป** แต่ global doc ที่เก่าหรืออ้าง document อื่นยังต้องจัดการ และ helper นี้ไม่ได้ rollback การเปลี่ยนแปลงเมื่อเกิด error

ใน 60 ชื่อที่สำรวจ มี 58 ชื่อไม่ประกาศ local variables ใน command definitions; ข้อที่สำคัญกว่าตัวเลขคือชื่อ global ร่วม เช่น ERR_, ss_pre_filter_set_xx_ และ REF_get_att_list_ สามารถมีค่าค้างข้ามคำสั่ง/helpers การแยกไฟล์ต้องจัดการ scope ไม่ใช่ตัดช่วงข้อความอย่างเดียว

รายการ internal calls แบบอ่านเชิงโครงสร้างอยู่ใน [block-command-inventory.json](../data/block-command-inventory.json) รวมตำแหน่ง helpers โดยเป็น direct call-head candidates ไม่ใช่ complete runtime dependency graph; quoted/indirect calls และ CAD command strings ยังต้องตรวจด้วยมือ

## เฉพาะทาง / ยังไม่ควรใช้เป็น utility ทั่วไป

| ชุด / บรรทัดเริ่ม | สิ่งที่พบ | คำแนะนำ |
|---|---|---|
| ADVSM / 4382 | visibility presets screw/U-profile/bolt/cutting plan; copy อ่าน `view`; สั่ง Block Editor | ใช้เป็น case study การสร้าง library หลังยืนยัน schema/environment ไม่ใช่ generic visibility editor |
| REAR, rew1, rew2, ARsaveas, arsins / 4608–4896 | ชื่อ parameter `array_width`, action `ARRAY_MAIN` และการ bsaveas | รวมเป็น workflow เดียวแทน 5 การ์ดซ้ำ ต้องมีตัวอย่าง dynamic definition |
| UCupdate / 6910 | `total_u-profile_depth`, `u-profile_width_set`, `Position1 Y` และ resetblock | เก็บใน case study เฉพาะชิ้นส่วน |
| mktbolt / 5759 | library `000 - PROTOTYPE-DYNAMIC_THREAD_BOLT` และค่าขนาด thread | ต้องมี library ที่มีสิทธิ์เผยแพร่ |
| MKP2, MKPC06 / 6339, 6445 | naming/text/part schema; MKPC06 ผูก panel/NAME_PANEL | ไม่จัดเป็น generic Make Block |
| rename_block_bycase, get_block_bycase, insert_block_list_ / 6798, 6822, 6883 | wildcard/naming เช่น C10_PANEL และ ASPG-COMBINE ตายตัว; get_block_bycase มีการ rename จริง | ชื่อต้องสื่อว่าเปลี่ยนข้อมูล ไม่ใช่แค่ get/inspect |
| RENB2, RENBLK / 11370, 11492 | ใช้ BOX_EF_NAME_REV02 และ attributes เฉพาะ; RENBLK มี rename หลัง branch alert | พัก variant เหล่านี้และพัฒนา RENB3x เป็นรุ่นทั่วไป |
| b2text, EF2text / 11285, 11326 | เขียน tag `name1`/`nameblk` ลง bubble/BOX block ชื่อตายตัว | เป็น label synchronization เฉพาะ library ไม่ใช่ Block→Text conversion ทั่วไป |
| DP1, STAHP, tempPG, temp_T7 / 33032, 59933, 60100, 65091 | parameter/library เฉพาะ เช่น Harray_width/AHP_length/FRAME_HEIGHT/anonymous name | เก็บในหมวดเฉพาะงาน ไม่ใช้ temp เป็นชื่อผลงาน |
| dynjoint / 59760 | คำนวณแนวขอบ offset 12.5, เส้นยาว 50000 และ distance1/distance2 | มีแนวคิด parametric joint ที่น่าสนใจ แต่ต้องตรวจขนาน/inters=nil, mirrored/non-unit scale และ schema |
| special_explode_sexx / 62703 | explode/delete แล้วเลือกทั้ง bounding window; กรอง AHP_06_FRAMING; อ่าน/เขียน distance1 | เสี่ยงเลือกวัตถุอื่นที่ซ้อนในพื้นที่ และไม่กรองชนิดก่อน effective name; พักก่อน ไม่ใช่ generic explode utility |
| REC-TO-BLK / 65013 | LWPOLYLINE สี3 → block C10_PANEL_GREEN_PLATE ที่ระบุ | อย่าโฆษณาว่าแปลง rectangle ใด ๆ เป็น block |
| pt2blk / 59602, ccc1_ / 25518 | ชื่อ AS-BUILT_POINT / end-cap เฉพาะ | ต้องมี DWG/library และคำอธิบายขอบเขต |
| Assembly_blcok_ / 33156 | มีแค่ selection ไม่มีขั้น assembly ต่อ | เป็น stub ไม่ควรจัดเป็นผลงานสำเร็จ |

## Placement ที่น่าศึกษาต่อ แต่ยังไม่คัดเป็นตัวหลัก

- **B2B (5011):** vla-move จาก insertion point ของแต่ละ reference ไปจุดเดียว/จุดของต้นแบบ ทุกตัวจึงไปจุดเดียวกัน ไม่ใช่การย้ายทั้งชุดโดยรักษาระยะห่าง และไม่ใช่การเปลี่ยน base point ของ block definition; คืน OSMODE=1215 ตายตัว
- **ofblk (19069):** ทำ vla-copy แล้วใช้ helper วาง offset ตาม rotation/axis; selection อาศัย implied pickset โดยไม่ตรวจ nil ไม่ใช่ geometric OFFSET ของเส้นขอบ block
- **insarray (21442):** copy/move ทีละตัวตาม angle/spacing ด้วย Enter ไม่ใช่ associative ARRAY; ใช้ `entlast` แทน return object และจุดจาก UCS ถูกส่งให้ vla-move จึงต้องทดสอบ UCS/WCS อย่างจริงจัง
- **blk2pline / blk2in_ (20287–20642):** placement paths มีการเปลี่ยน InsertionPoint ของ references เดิม อย่าถือว่าชื่อ insert หมายถึงสร้าง reference ใหม่เสมอ; ต้องตรวจ geometry/rotation/count mismatch เป็นรายรุ่น
- **blk2ct (20643):** ย้าย block เดิมไป centroid ผ่าน LM:PolyCentroid ต้องตรวจ polyline type/closed shape/UCS
- **blk2cen (20662):** ใช้กลางกรอบสี่เหลี่ยมจากสองจุดที่ผู้ใช้เลือก ไม่ใช่ area centroid; เขียน `distance1` และสะกด `distnace2` ที่ 20688 ต้องยืนยันชื่อ schema จริงก่อนถือว่าเป็น typo ที่แก้ได้
- **prefix-subfix_all-block_ (62831):** suffix `_SUB` ตายตัว เปลี่ยนชื่อทั้งหมด ไม่มี preview/collision policy; ควรพัฒนา UI/scope ก่อนทำ generic batch rename
- **qblk (20214):** เก็บ effective name ใน global เพื่อใช้ workflow ถัดไป ไม่ได้ insert block ใน command นี้

## แผนทดสอบที่ต้องทำก่อนอ้างว่า Ready

นี่คือ test plan ยังไม่ได้รัน ให้ใช้ DWG สำเนาที่ไม่มีข้อมูลลับและ block ที่มีสิทธิ์ใช้

| ชุด | กรณีขั้นต่ำ | เกณฑ์ผ่าน |
|---|---|---|
| ทุกคำสั่ง | Enter/Escape ทุก prompt, object ผิดชนิด, layer locked, ทำซ้ำหลังยกเลิก, เปิดคนละ document | ไม่ใช้ค่าค้าง ไม่แก้ข้อมูลเมื่อ validation ล้มเหลว จบคำสั่งสะอาด และคืน system variables/Undo state |
| Match Dynamic | static source/target, definition เดียว/ต่างกัน, missing/read-only property, ค่า list/range ไม่ผ่าน, visibility/flip | readback ตรงเมื่อ success; skip/fail มีเหตุผล ไม่รายงานสำเร็จเพราะไม่มี error อย่างเดียว |
| Match Attributes | target ไม่มี tag, source blank, constant/multiline, tag case, target มีข้อมูลเดิม | blank policy ตรงที่เลือก; ไม่ล้าง tag อื่น; จำนวน applied/skipped/failed ตรวจสอบได้ |
| Rename | ชื่อว่าง/ซ้ำ/เดิม=ใหม่/ไม่มีชื่อเดิม, Text/MText/Attribute/เส้น, Xref/anonymous, text formatting | เปลี่ยน definition ที่ตั้งใจเท่านั้น; failure อธิบายได้ ไม่มี rename จากค่าค้าง |
| Selection | ไม่มี selection, ทั้ง static, ทั้ง dynamic, mixed, xref/MINSERT | ผลเลือกตรงขอบเขตที่ระบุ ไม่ error เมื่อไม่มีผล |
| Units | mm/meters/unitless, Xref/layout/unsupported, มี refs อยู่แล้ว | metadata เปลี่ยนถูก scope; geometry/ขนาด references เดิมไม่เปลี่ยน และไม่อ้างว่า scale conversion |
| Replacement/Rebuild | cancel target, insertion/write failure, scale XYZ ต่างกัน/negative, attrs, dynamic values, rotation ต่างกัน, UCS, Model/PaperSpace | ห้ามลบเดิมเมื่อใหม่ไม่สำเร็จ; ค่าที่สัญญาว่ารักษาต้องเท่าเดิม; Undo/partial failure กู้คืนได้ |
| Counting | static/dynamic ผสม, ไม่มี Distance1, ความยาวใกล้กันที่ถูกปัด, definitions ซ้ำ | ผลรวมตรวจนับได้จริง; ระบุ rounding/schema และ active implementation |

สำหรับพอร์ต ให้มี GIF ก่อน–หลังและตารางขอบเขต/ข้อจำกัดที่ผ่านการทดสอบแล้ว ไม่สร้างตัวเลข “ลดเวลา X%” โดยไม่มีการวัด

## รูปแบบการเล่าในพอร์ตสองภาษา

เลือก 3 หน้าตัวหลัก: **Match Dynamic Block Properties**, **Match Block Attributes**, **Rename Block from Text** และรวมคู่ selection เป็นหน้า utility เดียว; Units เป็นหน้าเสริม ไม่จำเป็นต้องใช้ทุก variant ที่มีใน source

แต่ละหน้า: ปัญหาที่แก้ / Problem → ชื่อคำสั่งจริง / Command → GIF → วิธีใช้ / Usage → Supported Inputs → Limitations → Tested AutoCAD Version → Dependencies & Credits → Download เฉพาะไฟล์ที่มีสิทธิ์เผยแพร่

source ระบุ Lee Mac ใน helpers เช่น dynamic property functions ที่ 139–230 และ namespace LM: จึงต้องแยกเครดิต helper ที่นำมาใช้จาก workflow/ส่วนที่ผู้ใช้พัฒนาเอง ตรวจสิทธิ์/เงื่อนไขของ code และ DWG ก่อนแจกไฟล์ ไม่ใช่เปลี่ยนชื่อ namespace แล้วถือว่าเป็นผลงานที่เขียนทั้งหมดเอง

ยังไม่ได้สร้างเว็บไซต์ แยก AutoLISP เป็นไฟล์แจก แก้ defect หรือจัดทำ GIF ในรอบนี้
