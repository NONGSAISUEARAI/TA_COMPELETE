---
name: autocad-facade-outline
description: Maintain TA_FACADE_OUTLINE.lsp commands FO and FML, including overall outlines, length modes, CUSTOM nentsel picks, reusable attribute blocks, project documentation, and DWG checks with AutoCAD Core Console.
---

# ดูแลคำสั่ง FO / FML

ใช้กับโค้ด [TA_FACADE_OUTLINE.lsp](TA_FACADE_OUTLINE.lsp) ในโฟลเดอร์นี้ อ่าน [README.md](README.md) สำหรับวิธีใช้งานและค่า preset ก่อนแก้โค้ด ตรวจค่าจากไฟล์จริงทุกครั้ง เพราะผู้ใช้อาจปรับวัสดุ prefix ขนาดป้าย ตัวคั่น และ tolerance ระหว่างรอบงาน

เอกสารนี้อ้างอิงรุ่น 1.14 ให้ยึดไฟล์ LISP ปัจจุบันเมื่อค่า preset เปลี่ยน และใช้ README สำหรับตัวอย่างใช้งาน ไม่ตั้งค่าใน LISP กลับตามตัวอย่างเก่าโดยอัตโนมัติ

## แยกงานให้ตรงคำสั่ง

- อัปเดต 18 พฤศจิกายน 2026: FML OVERALL/MAX และ CUSTOM รองรับ LINE/ARC/CIRCLE/LWPOLYLINE เลือกผสมได้ LINE/ARC มีหนึ่งช่วงต่อวัตถุ ส่วน CIRCLE ใช้เส้นรอบวงเต็มหนึ่งป้าย ไม่แยกเป็นสองป้ายครึ่งวง ALL LONG/ALL SHORT ยังคงจำกัด Pline 4 มุม พฤติกรรมใหม่นี้แทนข้อจำกัด LWPOLYLINE-only เดิมของโหมดอัตโนมัติ

- `FO` / `FACADEOUTLINE`: เลือก Block, Pline และเส้นที่รองรับ สร้างขอบรวมกับ INFO ที่มี AREA/MAT/STATION/FLOOR คำสั่งนี้ยกเลิกการสร้าง LENGTH แล้ว
- `FML` / `FACADEMAXLENGTH`: ถามโหมดก่อน โหมดอัตโนมัติใช้ `ssget` เฉพาะ LWPOLYLINE มี OVERALL/ALL LONG/ALL SHORT/MAX ส่วน CUSTOM ใช้ `nentsel` จิ้ม LINE หรือช่วง LWPOLYLINE ทีละด้านจน nil/Esc รองรับ LINE ภายในบล็อกซ้อน
- เมื่อขอปรับเอกสาร ให้อธิบายพฤติกรรมที่พบในโค้ดโดยคง preset ที่ผู้ใช้ตั้งไว้

## พฤติกรรมที่ต้องรักษาเมื่อแก้งานเดิม

- เก็บ `;presetting c:FML` ไว้บนสุด และแยกส่วน FO ให้ผู้ใช้แก้ค่าเองได้ โหมดและวัสดุของ FML จำค่าที่ใช้สำเร็จล่าสุดใน session
- ชื่อบล็อกแต่ละประเภทมาจาก preset ของตัวเอง ใช้ Definition เดิมเมื่อมีอยู่ ไม่เติมชื่อ _2/_3 และไม่เปลี่ยนรูปแบบหรือค่า Reference เก่าโดยอัตโนมัติ
- INFO ต้องมี AREA/MAT/STATION/FLOOR; ป้าย FML ต้องมี NAME/LENGTH อย่างละหนึ่ง Tag ที่แก้ไขได้ ใช้ `TFO:CheckBlockTags` ตรวจและ `TFO:InsertAttributes` แทรก เพื่อคง Base Point, ATTDEF และ Attribute เพิ่มเติมของนิยามเดิม
- ATTDEF ที่คำสั่งสร้างใหม่ต้อง Lock Position และ `TFO:InsertAttributes` ล็อกทุก ATTRIB บน Reference ใหม่รวม Tag เพิ่มเติม โดยคงค่าแก้ไขได้ นิยามและ Reference ที่มีอยู่ก่อนใช้ต่อโดยไม่แก้ย้อนหลัง การล็อกใช้ `TFO:LockAttributeData` ระวัง DXF 280 ใน subclass เดียวกันมีทั้ง version ตัวแรกและ position lock ตัวที่สอง อย่าใช้ `assoc 280` แล้วแทนตัวแรก
- ระยะวางจุดแทรกต้องเป็นหน่วยแบบที่ไม่คูณสเกล: FO ใช้ `offset_info_`; FML ใช้ `offset_maxlength_` จากกึ่งกลางด้าน แล้วบวก `offset_xy_maxlength_` ตาม WCS หลังแปลง OCS ขนาด `height_maxlength_`/`height_info_` ใช้กับสเกลบล็อก/ข้อความเท่านั้น ไม่เพิ่มระยะตามความสูงอีก
- `NAME` ของ FML คือวัสดุ ส่วนข้อความ `LENGTH` ผ่าน `TFO:SideLengthText` ตัวคูณ/ทศนิยม/prefix ของ FML แยกจาก AREA และ `prefix_txt_` ของฟังก์ชัน LENGTH รุ่นเดิม อ่านตัวคั่นจากฟังก์ชันจริง ไม่สมมติว่าเป็น underscore เสมอ
- ตรวจ expression ของ prefix ด้วย: `"name_maxlength_"` เป็นข้อความ literal ส่วน `name_maxlength_` ที่ไม่มีคำพูดคือการคัดลอกค่าตัวแปรตอนโหลด ไม่ใช่การผูกค่าอัตโนมัติเมื่อผู้ใช้เปลี่ยน Material NAME ภายหลัง ในงานเอกสารให้อธิบายค่าจากไฟล์จริงและแยกตัวอย่างทางเลือกให้ชัด โดยไม่แก้ preset ตามการคาดเดา
- ความยาวดิบในผล `TFO:SideLengthBuild` ยังเป็นตัวเลข การเพิ่ม prefix เปลี่ยนเฉพาะข้อความ Attribute ของ Reference ใหม่
- OVERALL วัดทุกช่วงระหว่าง vertex และแยกป้ายแต่ละด้าน ไม่รวม perimeter เป็นค่าเดียว; Max เลือกหนึ่งช่วงที่ยาวที่สุดต่อชิ้น ส่วนโค้งใช้ระยะตามโค้งจริง Pline เปิดไม่มีด้านปิดท้าย และเมื่อยาวเท่ากัน Max เลือกด้านแรก
- แยก `outline_mode_` ของ FO จาก `mode_maxlength_` ของ FML แม้มีชื่อ OVERALL เหมือนกัน: FO สร้างขอบรวม/INFO ส่วน FML ใส่ป้ายแต่ละด้านของแต่ละชิ้น
- ALL LONG/ALL SHORT ใช้เฉพาะรูป 4 vertex (เปิด 3 ด้าน/ปิด 4 ด้าน) เปรียบเทียบผลรวมความยาวคู่ 0/2 กับ 1/3 ก่อนแปลงหน่วย/ปัดเศษ หากเท่ากัน ALL LONG เลือก 0/2 และ ALL SHORT เลือก 1/3 สำหรับรูปเปิด ใช้ด้านปิดสมมติแบบเส้นตรงเพื่อจำแนกคู่และทิศด้านนอก แต่ไม่สร้างเส้นหรือป้ายบนด้านนั้น ชุดเลือกไว้ล่วงหน้าที่มี vertex อื่นจะมีเฉพาะ Overall/Max/Custom และ default ที่ค้างเป็นโหมดคู่จะ fallback เป็น Max
- LONG 1/SHORT 1 ยกเลิก ใช้ CUSTOM แทน `TFO:FMLMode` รองรับชื่อ preset/API เดิม ALL/LONG/SHORT เป็น alias ของ OVERALL/ALL LONG/ALL SHORT
- CUSTOM ต้องแทรกหลังแต่ละ pick และวนต่อเมื่อเลือกชนิดที่ไม่รองรับ Enter/nil หรือ Esc จบลูปโดยคงป้ายที่ใส่สำเร็จไว้ เมื่อแทรกผิดพลาดล้างเฉพาะ pick นั้น ป้ายของ CUSTOM จัด UNDO ทีละ pick ส่วนโหมดอัตโนมัติจัดทั้งชุด
- CUSTOM ไม่จำกัดจำนวน vertex ของ LWPOLYLINE และอ่านเฉพาะช่วงที่ใกล้จุดจิ้มที่สุด ใช้ได้กับแถบหักมุมโดยไม่รวมความยาวทั้งแนว การจิ้มซ้ำสร้างป้ายซ้ำได้ตามพฤติกรรมปัจจุบัน
- `nentsel` คืน pick point ใน UCS และ matrix บล็อกแบบ row-vector 4×3 ต่างจาก helper 4×4 ในโค้ด ต้องแปลงทั้งจุดจิ้มและจุดนิยามให้ตรง WCS ก่อนเลือกช่วง/วัดความยาว ไม่แก้หรือ explode บล็อกต้นทาง
- AREA เป็นพื้นที่ขอบนอกหลังรวมช่องห่างใน OVERALL; `tolerance_fo_` เป็น epsilon ทางเรขาคณิต ไม่ใช่ระยะสำหรับแยกกลุ่ม และยังไม่มี group_tolerance_
- คงชิ้นงานต้นทาง วัตถุช่วยคำนวณต้องถูกเก็บกวาดเมื่อจบ/ผิดพลาด จัด UNDO ตามชุดหรือ pick และคืนค่าระบบ รวมถึง UCS ที่เปลี่ยนระหว่างแทรก

ข้อกำหนดเหล่านี้อธิบายงานที่ตกลงไว้เดิม ปรับได้เมื่อผู้ใช้สั่งเปลี่ยนพฤติกรรมนั้นโดยตรง

## รับข้อความโดยคงค่าเดิม — แนวทางที่ตกลง ยังไม่ได้ติดตั้ง

- ใช้ subfunction กลางรับ prompt, ค่าเดิม และตัวเลือกว่าจะรับช่องว่างในชื่อหรือไม่ เก็บค่ารับเข้าเป็น local และคืนค่าผลลัพธ์แทนการแก้ตัวแปร preset ภายใน helper
- เมื่อได้ nil, `""` หรือข้อความที่มีแต่ช่องว่าง ให้คืนค่าเดิม; เมื่อไม่มีค่าเดิม ให้เริ่ม prompt ด้วยข้อความว่าง; Esc ให้ยกเลิกการรับค่า ส่วนข้อความใหม่ที่ใช้ได้ให้คืนแก่ผู้เรียก
- รวม if/cond ไว้ใน helper จุดเดียว ไม่ทำ setq ซ้อนหรือสร้างตัวแปร keep-value global ซ้ำกับค่าเดิม ต้องไม่เขียนทับค่าเดิมก่อนตรวจผลรับค่า ตัวแปรชื่อมีช่องว่างในตัวอย่างไม่ใช่ symbol เดียว และ setq ต้องครบคู่ตัวแปร/ค่า
- แยก `getstring` ที่จบด้วย Space/Enter จาก `getstring T` ที่รับช่องว่างและจบด้วย Enter ให้เป็นทางเลือก ไม่ตัดความสามารถรับวัสดุที่มีช่องว่างโดยพลการ การแสดง `<ค่าเดิม>` ใน prompt ไม่ควบคุมการเลือกข้อความสีน้ำเงินใน Dynamic Input
- รักษาค่าพรีเซ็ตและรูปแบบ LENGTH ที่ผู้ใช้บันทึกไว้ทุกครั้งที่แก้โค้ด เปลี่ยนเฉพาะส่วนที่ได้รับคำสั่ง แนวทางของผู้ใช้คือ prefix อ้างอิง NAME แต่ต้องแยกการคัดลอกค่าตอนโหลดกับการใช้ข้อความที่กรอกใหม่ ไม่อ้างว่า setq ผูกค่าแบบอัตโนมัติ
- ดูข้อวิเคราะห์ตัวอย่างและตารางกรณีรับค่าใน [README.md](README.md) หัวข้อ “วิเคราะห์ตัวอย่าง Get-string โดยคงค่าเดิม” บันทึกนี้เป็นแนวทางสำหรับการลงมือรอบถัดไป งานรอบนี้แก้เอกสารเท่านั้น ยังไม่เปลี่ยน FML หรือรันตัวอย่าง

## จุดค้นโค้ด

- ขอบรวมและการตกหล่นของชิ้นงาน: `TFO:Read`, `TFO:GeometryLoops`, `TFO:OuterLoops`, `TFO:Overall`, `TFO:CheckCoverage`
- ความยาว/ตำแหน่งป้าย: `TFO:LengthSegments`, `TFO:FourCornerChoice`, `TFO:FourVertexSelectionP`, `TFO:SegmentLabelData`, `TFO:SideLengthText`
- ตรวจชื่อโหมดและ alias: `TFO:FMLMode`; แทรก NAME/LENGTH ร่วมกัน: `TFO:InsertLengthRecord`; แปลงหน่วย AREA: `TFO:Info`
- CUSTOM: `TFO:CustomPick`, `TFO:CustomLengthLoop`, `TFO:CustomLengthSegment`, `TFO:CustomLengthBuild`; ใช้ `TFO:LengthBuild` ร่วมกับโหมดอัตโนมัติสำหรับ cleanup/UNDO
- Block/Attribute: `TFO:CheckBlockTags`, `TFO:InsertAttributes`, `TFO:LockAttributeData`, `TFO:InfoBlock`, `TFO:MaxLengthBlock`
- เรียกคำนวณ FO: `TFO:CommandBuild`; FML ตามโหมด: `TFO:SideLengthBuild` ส่วน `TFO:MaxLengthBuild` เป็น wrapper แบบ Max เพื่อคง API เดิม

## ข้อผิดพลาดทางเรขาคณิตที่เคยพบ

รอยต่อที่เกือบทับกันเคยทำให้จุดแรกของวงขอบเข้าไปอยู่ฝั่งเพื่อนบ้านเล็กน้อย แล้วกรองแผงด้านซ้ายออกเหมือนเป็นช่องด้านใน การแก้ใน `TFO:OuterLoops` ตรวจว่าขอบทั้งวงอยู่ภายในจริงด้วย `TFO:EdgeCovered` ก่อนตัดวงนั้นออก

เมื่อพบ `Some selected edges lie outside the outline` ให้ตรวจวงที่ถูกกรองและรูปเชื่อมก่อน ไม่ใช้การเพิ่ม tolerance หรือข้าม coverage check เพื่อซ่อนชิ้นงานที่หาย ดูรูปทรง regression ที่ [near_coincident_panels.lsp](tests/fixtures/near_coincident_panels.lsp)

## ตรวจงานตามผลกระทบ

- แก้เอกสารหรือจัด preset โดยไม่เปลี่ยนพฤติกรรม: ตรวจลิงก์ ค่าในตัวอย่าง และ `node tests/check-syntax.mjs` ตามความเกี่ยวข้อง
- แก้โค้ด: ใช้ AutoCAD Core Console ที่ติดตั้งในเครื่องกับแบบว่างหรือสำเนา DWG และโปรไฟล์ทดสอบแยก ตัว `vl-load-com`/curve helpers ใช้ได้ในงานนี้ แต่อย่าสมมติว่า Core Console มี ActiveX Application object แบบ AutoCAD หน้าจอ
- ชุด [run.scr](tests/run.scr) ปัจจุบันรัน FO และบันทึก [results.txt](tests/results.txt) ตรวจ path ของ `tfot-root` และ template ให้ตรงเครื่องก่อนใช้ สคริปต์ปิด UNDO Auto เฉพาะแบบทดสอบเพื่อทดสอบกลุ่ม UNDO
- ชุด [run_fml.scr](tests/run_fml.scr) รันทั้ง FO และ [FML](tests/TA_FACADE_FML_tests.lsp) บันทึก [results_fml.txt](tests/results_fml.txt) เพิ่ม ตรวจโหมดอัตโนมัติและ alias เดิม, คู่ด้านของรูปเปิด/ปิด, ด้านที่ขาด, การแปลงหน่วยและ prefix, การใช้บล็อกเดิม, ตำแหน่งข้างด้าน, prompt และ UNDO ปรับค่าคาดหวังตามตัวคั่นที่อ่านจากโค้ดปัจจุบัน
- สคริปต์เดียวกันรัน [ชุดโหมดใหม่/CUSTOM](tests/TA_FACADE_FML_custom_tests.lsp) ด้วย ผล [results_fml_custom.txt](tests/results_fml_custom.txt) ตรวจ nentsel จริงผ่าน LINE/Pline/บล็อกซ้อนแล้ว Enter จบ การจบแบบ cancel ใช้ exception จำลอง แยกจากการกด Esc ผ่านหน้าจอจริง
- สคริปต์เดียวกันรัน [ตำแหน่ง/Lock Position](tests/TA_FACADE_PLACEMENT_tests.lsp) เพิ่ม ผล [results_placement.txt](tests/results_placement.txt) ตรวจพิกัดเมื่อสเกล 2 กับ 200, offset หลังแปลง OCS/สเกลบล็อกต้นทาง, ล็อก ATTDEF/ATTRIB ที่สร้างจริง และบล็อกเดิมที่มี Tag เพิ่มโดยคง layout/นิยาม/Reference เก่า
- แยกผลที่รันใหม่จากผลประวัติ รุ่น 1.14 ผ่าน FO 93, FML 31, CUSTOM 21 และตำแหน่ง/Lock Position 13 รวม 158 กรณีในวันที่ 10 พฤศจิกายน 2026 ส่วน FML 26 กรณีของรุ่น 1.10 เป็นหลักฐานเก่าและไฟล์ชุดเดิมไม่มีใน checkout ปัจจุบัน

## ตรวจไฟล์ DWG ที่ผู้ใช้ส่งมา

ทำงานในสำเนา ตรวจชนิดวัตถุ เลเยอร์ บล็อกข้อมูล และขอบเดิมก่อนเลือกกลุ่มทดลอง โหมด OVERALL ของ FO จะพยายามรวมทั้งชุดที่เลือก จึงต้องระบุว่าลองกับชุดใด แทนการเลือกทั้งแบบที่มีกริด/กรอบ/ข้อความปะปนโดยไม่ตรวจ

บล็อกข้อมูลอาจมี Pline ภายในแม้ TEXT/Attribute จะถูกละเว้นจากขอบแล้ว พิจารณารายการ `exception_blocks_` ตามวัตถุจริง การกรองนี้ใช้ชื่อ INSERT ตรงทั้งชื่อแบบไม่สนตัวพิมพ์เล็ก–ใหญ่ รวมบล็อกซ้อน และยังไม่ได้เพิ่ม EffectiveName resolver

บันทึกจำนวนวัตถุ/ผลลัพธ์ ค่า Attribute และการคงต้นฉบับ ถ้าต้องส่งผลให้ผู้ใช้ตรวจ ให้บันทึก DWG ผลใน workspace เป็นไฟล์ใหม่ สื่อสารว่าตรวจผ่าน Core Console หรือผ่านหน้าจอจริงตามที่ทำ และอัปเดต README เมื่อพฤติกรรมหรือ preset เปลี่ยน
