# TA_SHOW_HIDDEN — บันทึกส่งต่องาน v2.1

- วันที่จัดทำ: 2026-11-03, Asia/Bangkok
- เครื่องที่สร้างเอกสาร: `DESKTOP-VNKD8FJ` ตรวจด้วย `[Environment]::MachineName`
- Prefix เอกสาร: `DESKTOP-VNKD8FJ_`
- Workspace: `C:\Users\tawan.t\Documents\GitHub\TA_COMPELETE`
- โฟลเดอร์งาน: `GPT CODE/TA_SHOW_HIDDEN`
- แหล่งข้อมูล: โค้ด คู่มือ ผลทดสอบที่เก็บไว้ และการตรวจสอบในบทสนทนานี้
- เอกสารนี้เป็นบันทึกพัฒนาต่อ ไม่ใช่ Codex skill ที่ติดตั้งแล้ว

## ความต้องการที่ยืนยันกับผู้ใช้

แสดงส่วนของวัตถุทั้งหมดที่อยู่ใต้ WIPEOUT เป็นเส้น Hidden ไม่จำกัดเฉพาะชิ้นพับแนวตั้งหรือชิ้นแนวนอน รองรับทั้งวัตถุอิสระและ Block เมื่อทำกับ Block ต้องสร้างวัตถุผลลัพธ์ออกมาด้านนอก Block และเก็บต้นฉบับไว้ รองรับ HATCH ด้วยคำสั่งแยกเพื่อให้เลือกใช้โดยตั้งใจ

ภาพแรกอธิบายเส้นรูปตัว L ที่ซ่อนอยู่ใต้พื้นที่บัง ภาพถัดมาพบว่าขึ้นเพียงเส้นแดงสั้นบางส่วน ส่วนภาพล่าสุดแสดงเส้นแดงเริ่มก่อนถึงขอบ WIPEOUT เอียงและเลยพื้นที่จริง จึงต้องตรวจพิกัดของขอบตัวบัง ไม่ใช่แก้เฉพาะสเกลเส้นประ

## ไฟล์หลักและคำสั่ง

| ไฟล์ / คำสั่ง | หน้าที่ |
| --- | --- |
| `TA_SHOW_HIDDEN.lsp` | โค้ด standalone รุ่น 2.1 โหลดด้วย APPLOAD |
| `SHW`, `SHOWHIDDEN` | สร้าง Hidden ด้วย WIPEOUT |
| `SHWHATCH` | สร้าง Hidden ด้วย HATCH |
| `README.md` | คู่มือ Markdown เดิม |
| `DESKTOP-VNKD8FJ_README.txt` | คู่มือภาษาไทยพร้อมสถานะทดสอบและ Prefix |
| `tests/TA_SHOW_HIDDEN_tests.lsp` | ชุด integration เดิม 32 ข้อ |
| `tests/TA_SHOW_HIDDEN_v2_tests.lsp` | ชุดเพิ่ม v2 จำนวน 14 ข้อ |
| `tests/TA_SHOW_HIDDEN_v21_tests.lsp` | ชุดพิกัด WIPEOUT จำนวน 13 ข้อ |
| `tests/check-syntax.mjs` | ตรวจวงเล็บและสตริงของ Lisp ไม่ใช่ตัวรัน AutoLISP |
| `tests/prepare-core-tests.mjs` | ดึงฟังก์ชันจริงจากโค้ดหลักเพื่อทดสอบใน Core Console |
| `tests/run.scr` | รันชุดทดสอบใน AutoCAD ตัวเต็มบนแบบทดสอบแยก |
| `tests/run-core.scr` | รันเฉพาะชุดพิกัด WIPEOUT ใน Core Console |

## สถาปัตยกรรมที่ต้องรักษา

1. รับต้นทางและตัวบังจาก active model/paper space เดียวกัน กด Enter ในการเลือกตัวบังเพื่อใช้ตัวบังภายใน Block ต้นทางที่เลือกแล้วได้
2. ทำสำเนาชั่วคราวด้วย `Copies` / `Leaves` แล้วอ่าน Block ซ้อน ไม่แก้หรือ Explode ต้นฉบับ
3. Block ที่ Explode สำเนาได้ใช้วิธีนั้น กรณีสเกลไม่เท่ากันใช้ `AffineLeaves` อ่าน definition และประกอบ insert matrices รวม origin, rotation, normal และ scale
4. `AffineLeaf` แปลงชิ้นส่วนสู่ active space เส้นตรงแปลงปลายเส้น ส่วนโค้ง/วงกลมมี `AffineEllipse` สำหรับการแปลงเป็นวงรี ส่วนที่ต้องประมาณรูปใช้ `AffinePolyline`
5. `Sources` แยก Polyline เป็นชิ้นส่วน เก็บระดับ Z แล้วทำงานเรขาคณิตใน WCS XY
6. `WipeVertices` แปลง DXF WIPEOUT เป็นจุด WCS; `WipeLoop` สร้างวงปิดชั่วคราว ส่วน `HatchLoops` ใช้ `HATCHGENERATEBOUNDARY` ผ่าน `command-s`
7. `Intersections` ใช้ IntersectWith หาแนวตัด `Intervals` แบ่งช่วงตามระยะบนเส้น และใช้จุดกึ่งกลางกับ `InsideLoop` / `InsideMask` ตรวจพื้นที่รวมของตัวบัง
8. `Emit` สร้างเฉพาะช่วงที่อยู่ในพื้นที่บังคืนระดับ Z เดิม วงรีและ Spline ใช้ Polyline ประมาณรูป
9. `Style` ตั้งเลเยอร์ `TA-HIDDEN-OVERLAY` สีแดง HIDDEN; Auto ใช้ความยาวจริงกับ pattern และ LTSCALE เพื่อให้เห็นเส้นประช่วงสั้น
10. `Front` ใช้ SortentsTable ย้ายผลลัพธ์ขึ้นหน้า มี Undo mark, catch/cleanup สำเนา และคืนสถานะ Lock ของเลเยอร์กับ CMDECHO/OSMODE

อย่าเปลี่ยนกลับไปสั่ง DRAWORDER แบบ command โดยไม่ตรวจ command state เพราะเคยมีปัญหาจากลำดับคำสั่งและ selection ค้าง การสร้างขอบ Hatch มีการล้าง pickfirst ก่อนสั่งงาน

### API และค่าตั้งต้น

- `TA:SHW:BuildMode(sources, blockers, scale, shw-mask-kind)` เรียก Build โดยกำหนดโหมด `"Wipeout"` หรือ `"Hatch"`
- `sources` / `blockers` เป็นรายการ entity names ใน active space; `scale` เป็น symbol `'Auto` หรือค่าบวก
- ผลคืนเป็นรายการ VLA objects ใหม่ หรือ nil; nil อาจหมายถึงไม่ตัดพื้นที่บังหรือเกิดข้อผิดพลาด ให้ตรวจ `TA:SHW-LastError` แยกกรณี
- `*TA:SHW-Chord* = 0.05` หน่วยแบบ สำหรับการประมาณเส้นโค้ง; ขอบ Hatch ที่แปลง affine ใช้ 0.001
- tolerance หลัก `shw-eps = 1e-7`; จำกัด Block ซ้อนลึก 32 ระดับ
- `*TA:SHW-Scale*` เริ่ม 1.0 และบันทึกค่าที่ป้อน แต่ prompt ปัจจุบันเลือก Auto เมื่อกด Enter

## สาเหตุที่พิสูจน์แล้วและการแก้ v2.1

พิกัด clip ของ WIPEOUT ใช้แกน Y ของภาพซึ่งสวนทางกับเวกเตอร์ V ใน WCS สูตรเดิมกลับทิศ Y ผิด และไม่ได้อ้างอิงความสูงภาพจริง

```text
สูตรเดิม:
P = origin + U * (clipX + 0.5) + V * (clipY + 0.5)

สูตรแก้:
P = origin + U * (clipX + 0.5) + V * (imageHeight - 0.5 - clipY)

origin = DXF group 10
U      = DXF group 11
V      = DXF group 12
imageHeight = Y ของ DXF group 13
clipX, clipY = จุด DXF group 14
```

ห้ามใช้ค่าสูงสุด Y ของ polygon แทน imageHeight การทดสอบเฉพาะหน้ากากสี่เหลี่ยมจัตุรัสเต็มภาพอาจไม่พบข้อผิดพลาด เพราะรูปทรงสมมาตรภายใต้การกลับด้าน

ตัวอย่างยืนยันด้วย WIPEOUT ที่ AutoCAD สร้างจริงจาก polygon:

```text
จุดต้นฉบับ: (2,0), (20,0), (20,10), (6,10)
origin: (2,0,0)
U: (18,0,0), V: (0,18,0), image size: (1,1,0)
clip: (-0.5,0.5), (0.5,0.5), (0.5,-0.0555556), (-0.277778,-0.0555556)
สูตรเดิมย้าย y=0 ไป y=18 และ y=10 ไป y=8
สูตรใหม่คืนจุดตรงกับรูปทรงที่วาด
ที่ y=2 ขอบซ้ายต้องตัด x=2.8; ที่ y=8 ต้องตัด x=5.2
ที่ y=14 ต้องไม่มีช่วง Hidden
```

การแก้ production รอบ v2.1 จำกัดอยู่ที่แยก `WipeVertices` ออกจาก `WipeLoop`, แก้สูตร Y, เพิ่มคำอธิบายและเลขรุ่น ไม่ได้เพิ่มการวิเคราะห์ Draw Order เดิม

## หลักฐานและขอบเขตการทดสอบ

| ชุด | ผลที่บันทึก | ขอบเขต |
| --- | --- | --- |
| `results.txt` | 32 ผ่าน / 0 ไม่ผ่าน | integration ของรุ่น 2.0 |
| `results-v2.txt` | 14 ผ่าน / 0 ไม่ผ่าน | integration เพิ่มของรุ่น 2.0 |
| `results-v21-before.txt` | 3 ผ่าน / 10 ไม่ผ่าน | สูตร WIPEOUT เดิม |
| `results-v21.txt` | 13 ผ่าน / 0 ไม่ผ่าน | สูตร WIPEOUT แก้แล้ว |

ชุด v2.1 สร้าง WIPEOUT จริงด้วยคำสั่ง AutoCAD แล้วเทียบจุดที่ฟังก์ชัน production อ่านกลับกับ polygon ตั้งต้น ไม่ใช่ทดสอบสูตรด้วยข้อมูลจำลองเพียงอย่างเดียว ครอบคลุม square, wide/tall rectangle, sloped trapezoid, จุดตัดแนวนอนสองระดับ, จุดนอกขอบ, clockwise, concave, native ROTATE 37 องศา, native MIRROR, native MOVE ไปพิกัดใหญ่ และ rectangular clip ที่มี imageHeight เท่ากับ 2

ชุดเต็ม 32+14 ข้อยังไม่ได้รันซ้ำสำเร็จหลังแก้ v2.1 เนื่องจาก AutoCAD ตัวเต็มที่เปิดเพื่อทดสอบค้างตอนเริ่ม การทดสอบพิกัด 13 ข้อใน Core Console สำเร็จแทน จึงห้ามกล่าวว่า v2.1 ผ่าน full integration 59 ข้อ หรือยืนยันผลครบกระบวนการบน DWG ล่าสุดแล้ว เอกสารวันที่ 2026-11-03 อ้างอิงผลเดิม ไม่ใช่ผลทดสอบ AutoCAD รอบใหม่

### วิธีตรวจและรันซ้ำ

จากโฟลเดอร์ TA_SHOW_HIDDEN:

```powershell
node tests/check-syntax.mjs
node tests/prepare-core-tests.mjs
& 'C:\Program Files\Autodesk\AutoCAD 2026\accoreconsole.exe' /s "$PWD\tests\run-core.scr" /l en-US
```

ก่อนรัน ให้ตรวจ `sht-root` ใน script ให้ตรงที่อยู่จริง และใช้แบบทดสอบแยก สคริปต์จบด้วย QUIT จึงไม่ควรรันในแบบงานผู้ใช้ที่กำลังแก้ไข `run.scr` ใช้ AutoCAD ตัวเต็มและโหลดทั้งสามชุด ส่วน `run-core.scr` โหลดเฉพาะฟังก์ชัน pure ที่เตรียมจาก production กับชุด v2.1

Core Console ในสภาพแวดล้อมที่ทดสอบรองรับ native Lisp, entget, entmakex และ command-s แต่ไม่มี ActiveX document API ที่ SHW ใช้ ห้ามนำผลเฉพาะ Core Console ไปอ้างว่าคำสั่ง SHW ทั้งชุดทำงานได้ใน Core Console

สคริปต์ทดสอบเดิมเปลี่ยน SECURELOAD ชั่วคราว; ชุดเต็มเปลี่ยน TRUSTEDPATHS และ logging ด้วย และคืนค่าตอนจบตามปกติ หากรันสะดุดให้ตรวจว่าคืนค่าแล้ว อย่าคัดลอกการตั้งค่าทดสอบนี้ไปเป็นข้อกำหนดติดตั้งของผู้ใช้

## สิ่งที่ตรวจจากแบบงานในรอบก่อน

เคยอ่าน block แผงเจาะรูจากแบบผู้ใช้ และส่งออกสำเนาตัวอย่างเข้า `tests/private/` เพื่อวิเคราะห์ โครงสร้างที่พบมี 4,190 objects: CIRCLE 4,150, LWPOLYLINE 1, TEXT 26 และ ATTDEF 13 ไม่มี WIPEOUT ภายใน Block ตัวอย่าง จึงไม่ควรสรุปว่าปัญหาภาพล่าสุดเกิดจาก WIPEOUT ภายในต้นทางโดยไม่มีหลักฐาน

ตัวอย่างนี้ไม่ได้รวมตัวบังจริงภายนอกตามภาพล่าสุดครบถ้วน ข้อมูลว่า AutoCAD เปิดแบบใดอยู่หรือ process ID ใดเป็นของผู้ใช้เป็นข้อมูลเก่า ต้องตรวจใหม่ทุกครั้ง ห้ามใช้ ID เก่าปิด process

ไฟล์ DWG ตัวอย่างและ snapshot ก่อนแก้ใน `tests/private/` เป็นข้อมูลวิเคราะห์เฉพาะเครื่อง ถูก ignore ไว้ ห้ามนำไปเผยแพร่หรือเพิ่มใน Git โดยอัตโนมัติ เอกสารนี้ไม่ต้องพึ่งไฟล์ส่วนตัวเหล่านั้นเพื่ออธิบายสูตรแก้

ข้อสังเกตสำหรับเครื่องมือเดิม: Windows PowerShell 5 ที่ใช้ตรวจ COM เคยไม่รู้จัก alias `[short[]]` ให้ใช้ `[Int16[]]` สำหรับ selection filter; การ AddItems ด้วย object array เคยล้มเหลวจาก SAFEARRAY จึงใช้ SelectionSet.Select กับ filter แทน

## ข้อจำกัดที่ยังคงอยู่

- ไม่วิเคราะห์ Draw Order เดิมระหว่างต้นทางกับตัวบัง ใช้รายการตัวบังที่ผู้ใช้เลือกเป็นความตั้งใจ
- HATCH ไม่ตรวจสีหรือความโปร่งใสเพื่ออนุมานว่าควรบังหรือไม่
- เป็นผลลัพธ์ snapshot เมื่อย้ายต้นทางหรือตัวบังต้องสร้างใหม่
- รองรับวัตถุ 2D ขนาน WCS XY; ไม่รองรับ Xref, XCLIP, MINSERT และ 3D Surface/Solid
- ไม่คิดความกว้าง Polyline, Thickness หรือ Lineweight เป็นพื้นที่
- วงรีและ Spline เป็น Polyline ประมาณรูป; อย่าอ้างว่าทุกชนิดสร้างเป็นเส้นโค้ง native
- แบบที่มีวัตถุย่อยหลายพันชิ้นอาจต้องใช้เวลา ยังไม่มี benchmark ประสิทธิภาพที่บันทึกไว้

## แนวทางพัฒนาต่อ

รักษาข้อกำหนดผลลัพธ์นอก Block และต้นฉบับไม่เปลี่ยนเป็นหลัก ถ้าพบภาพผิดอีก ให้ตรวจเลขรุ่นที่โหลด ผลลัพธ์เก่าซ้อน ตัวบังที่เลือก พิกัด DXF และรูปทรงที่คาดหวังก่อนแก้ หากเกี่ยวกับ Draw Order ให้เก็บกรณีทดสอบที่พิสูจน์ความต้องการก่อนเพิ่มพฤติกรรมใหม่

งานตรวจที่ยังมีประโยชน์คือรัน full integration ของ v2.1 ใน AutoCAD ตัวเต็มเมื่อเริ่มโปรแกรมทดสอบได้ และยืนยันบนสำเนากรณีจริงที่รวมทั้งต้นทางกับตัวบัง จากนั้นบันทึกผลแยกตามรุ่นและวันที่ ห้ามแทนผลเก่าด้วยคำว่า “ผ่าน” โดยไม่ได้รันจริง

อย่าแก้ไฟล์อื่นใน repository ที่ไม่เกี่ยวข้องกับ TA_SHOW_HIDDEN และอย่าเปลี่ยนชื่อ entry point LSP หรือ command เพื่อทำ Prefix เอกสาร เพราะ test scripts และคู่มือเดิมอ้างอิงชื่อเหล่านี้อยู่

## กติกาชื่อไฟล์ที่ผู้ใช้ขอในรอบนี้

เอกสารใหม่ใช้ `<ชื่อเครื่องขณะสร้าง>_upskill.md` และ `<ชื่อเครื่องขณะสร้าง>_README.txt` โดยอ่านชื่อเครื่องจริง ณ เวลาสร้างด้วย `[Environment]::MachineName` ไม่ hardcode ชื่อเครื่องนี้เป็นค่าใช้กับทุกเครื่องในอนาคต และไม่เปลี่ยน Prefix เอกสารเดิมเพียงเพราะเปิดบนเครื่องอื่น

รอบนี้สร้าง `DESKTOP-VNKD8FJ_upskill.md` กับ `DESKTOP-VNKD8FJ_README.txt` เท่านั้น การใช้ Prefix นี้เป็นการตั้งชื่อเอกสาร ไม่ใช่การแก้ namespace `TA:SHW`, ชื่อเลเยอร์ หรือบังคับสร้าง Prefix ให้ผลลัพธ์ CAD อัตโนมัติ
