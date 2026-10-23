# Layer / viewport settings CSV transfer

สำหรับ AutoCAD 2025 บน Windows (.NET 8) — สองคำสั่ง `MAVPEXPORT` และ `MAVPIMPORT`

## โหลดและเริ่มใช้

1. ใช้ `APPLOAD` โหลด `C:/TA/TA_COMPELETE/GPT CODE/TA_LAYER_TRANSFER/Maviewport.lsp`
2. หรือใช้ `NETLOAD` เลือก `bin/TA_LAYER_TRANSFER_v4.dll` โดยตรง (รุ่นล่าสุด)
3. หาก AutoCAD ถามเรื่องไฟล์ที่เชื่อถือได้ ให้ตรวจชื่อและตำแหน่ง DLL แล้วโหลดตามขั้นตอนปกติของ AutoCAD
4. ถ้าอัปเดต DLL หลังจากโหลดแล้ว ต้องเปิด AutoCAD ใหม่ก่อนโหลดรุ่นใหม่

LISP เป็นตัวโหลด ส่วนงานอ่าน/เขียน VP Overrides และ Filter Tree ใช้ .NET API ของ AutoCAD โดยตรง ไม่แก้ internal dictionaries ด้วย `entmod` และไม่เปลี่ยน `SECURELOAD` หรือ `TRUSTEDPATHS`

ตัวโหลดหา DLL ใน `bin/TA_LAYER_TRANSFER_v4.dll` ก่อน และรองรับ DLL ที่วางข้าง LISP ด้วย เก็บตำแหน่งจริงไว้ใน `*MAVP-ROOT*` และ `*MAVP-DLL*` สำหรับตรวจสอบ ค้นจาก root ที่ระบุไว้ก่อน ตามด้วย AutoCAD search paths และพาธติดตั้งปัจจุบันข้างต้น จึงใช้ APPLOAD ได้แม้ยังไม่ได้เพิ่มโฟลเดอร์ใน Support File Search Path ไฟล์ `C:/TA/TA_COMPELETE/Maviewport.lsp` เดิมเป็นตัวส่งต่อมายังโฟลเดอร์ใหม่

หากย้ายทั้งโฟลเดอร์อีกครั้ง ให้ระบุ root ก่อนโหลด เช่น `(setq *MAVP-ROOT* "D:/CAD/TA_LAYER_TRANSFER")` แล้วโหลด LISP จากพาธนั้น หรือเลือก DLL เมื่อโปรแกรมถาม ไม่ได้อนุมานตำแหน่ง LISP ที่กำลังทำงานจาก `findfile` โดยไม่มีเงื่อนไข

## MAVPEXPORT

เก็บเลเยอร์ **ทุกตัวในไฟล์** และ Layer Filters ทุกครั้ง พร้อมเลือก VP ที่จะเก็บ:

- `Current`: เก็บ VP ที่กำลังทำงานอยู่ ต้องอยู่ภายใน VP บน Layout
- `Select`: เลือกกรอบ VP ได้หลายอันจาก Paper Space ของ Layout ปัจจุบัน
- `All`: เก็บ VP ในทุก Layout ของไฟล์
- `None`: เก็บเฉพาะเลเยอร์และ Filters

หน้าต่าง Save ตั้งโฟลเดอร์เริ่มต้นเป็นโฟลเดอร์เดียวกับ DWG และตั้งชื่อเป็น `<ชื่อ DWG>_<ชื่อ layout>_exlay_yyyyMMdd_HHmmss.csv` เช่น `Floor Plan_Layout1_exlay_20261022_143025.csv` ใช้ชื่อ Layout ที่เปิดอยู่ขณะ Export (ถ้าอยู่ Model จะเป็น `Model`) และแทนอักขระที่ Windows ไม่อนุญาตในชื่อไฟล์ด้วย `_` ใช้ปี ค.ศ. และเวลาเครื่องแบบ 24 ชั่วโมง โดยยังแก้ชื่อหรือเปลี่ยนโฟลเดอร์ได้ หาก DWG ยังไม่เคยบันทึก จะให้บันทึก DWG ก่อน

ข้อมูลเขียนเป็น UTF-8 BOM ใช้ comma และ quoting ตาม RFC 4180 รองรับชื่อไทย เครื่องหมาย comma, quote และหลายบรรทัดใน Description มีไฟล์ `.export.log` แจ้งรายการที่ข้าม

VP1, VP2 ฯลฯ เป็นรหัส snapshot ภายใน CSV ไม่ใช่หมายเลข VP ของ AutoCAD จึงเลือกจับคู่กับ VP ในไฟล์อื่นได้ ค่า Layout และ Handle ช่วยบอกว่า snapshot มาจาก VP ใด ไม่ใช้ Handle เพื่อค้นหา VP ปลายทาง

## MAVPIMPORT

หน้าต่างเลือก CSV เริ่มที่โฟลเดอร์เดียวกับ DWG ปัจจุบัน โดย v4 ใช้ native OpenFileDialog พร้อม DefaultIsFolder และ ForceDefaultFolder เพื่อบังคับโฟลเดอร์เริ่มต้นทุกครั้ง แม้ AutoCAD จะเคยจำ Documents หรือโฟลเดอร์อื่นไว้ สามารถเลือกไฟล์จากโฟลเดอร์อื่นได้ หาก FILEDIA=0 หรือกำลังรัน script จะใช้ command-line prompt ตามเดิม หากรับพาธแบบ relative จะอ้างจากโฟลเดอร์ DWG และรองรับ full path ที่ครอบด้วย double quotes จากนั้นตอบตัวเลือก:

| ตัวเลือก | ความหมาย |
|---|---|
| `Viewport` | ใช้ VP Freeze และ VP Overrides เฉพาะ VP ปลายทาง ไม่เปลี่ยนค่าระดับไฟล์ของเลเยอร์ที่มีอยู่ และไม่เปลี่ยน Filters |
| `Drawing` | ใช้ค่าหลักของเลเยอร์และเลือกนำเข้า Filters โดยไม่แก้ VP Overrides |
| `Both` | ใช้ทั้งค่าหลักและค่าเฉพาะ VP |
| Missing `Create` / `Skip` | สร้างเลเยอร์ที่ยังไม่มี หรือข้ามพร้อมบันทึกใน log |
| Existing `Overwrite` / `Keep` | เขียนทับหรือข้ามเลเยอร์ชื่อซ้ำ **ภายในขอบเขตที่เลือก**; ในโหมด Viewport การเลือก Keep จะข้ามค่า VP ของเลเยอร์ชื่อซ้ำนั้นด้วย |
| Filters `Merge` | นำเข้าตามชื่อและ parent; แทนสมาชิก/เงื่อนไขของ filter ชื่อซ้ำ เก็บ filter อื่นไว้ และเรียง imported siblings ตาม Order |
| Filters `Replace` | แทนที่ต้นไม้ custom filters เดิมด้วยต้นไม้จาก CSV; system filters คงอยู่ |
| Filters `Skip` | ไม่แก้ Filters |

เมื่อ CSV มีหลาย VP โปรแกรมแสดงแต่ละ snapshot ให้เลือก `Apply` หรือ `Skip` แล้วเลือก VP ปลายทางด้วย `Current` หรือ `Select` หนึ่ง snapshot ใช้กับหลาย VP ได้ และห้ามนำหลาย snapshot ไปทับ VP ปลายทางเดียวกันในการ Import ครั้งเดียว

หากเลือก `Select` ให้อยู่ Paper Space ก่อนเริ่ม Import ถ้าต้องการใช้คนละ Layout ให้รันคำสั่งซ้ำใน Layout นั้น หรือเข้า VP แล้วเลือก `Current`

ในโหมด Viewport ถ้าเลือก Create เลเยอร์ใหม่จะได้รับค่าหลักจากแถว LAYER ด้วย เพราะเลเยอร์ใหม่เป็นทรัพยากรระดับไฟล์ ส่วนเลเยอร์ที่มีอยู่แล้วไม่เปลี่ยนค่าหลัก ค่า Freeze/Off ระดับไฟล์มีผลต่อทุก VP แม้แถว VPFreeze จะเป็น 0 โปรแกรมแจ้งกรณีนี้ใน log

การ Import เป็นหนึ่งคำสั่งและใช้ transaction; ข้อมูลผิดทำให้ยกเลิกและย้อนคืนการเปลี่ยนแปลง ต้องเปิด UNDO recording ก่อนใช้ ถ้า CSV ต้อง Freeze เลเยอร์ปัจจุบันให้เปลี่ยน current layer แล้ว Import ใหม่ โปรแกรมไม่เปลี่ยน current layer ให้อัตโนมัติ

## รูปแบบ CSV สำหรับแก้ใน Excel

ใช้ Data > From Text/CSV และเลือก UTF-8 ตั้งคอลัมน์ชื่อ/รหัสเป็น Text โดยเฉพาะชื่อเลเยอร์ที่เป็นตัวเลข เก็บ header เดิมและบันทึกเป็น **CSV UTF-8** รองรับ semicolon CSV ที่ Excel บาง locale ใช้ด้วย

CSV เป็นตารางเดียว มีคอลัมน์ `Record` แยกชนิดข้อมูล:

| Record | คอลัมน์หลัก |
|---|---|
| META | Version=1, SourceDwg, PlotStyleMode=CTB/STB |
| LAYER | Layer และค่าหลักทุกคอลัมน์ |
| VIEWPORT | Viewport, Layout, Handle |
| VPLAYER | Viewport, Layer, VPFreeze และ VP overrides |
| FILTER | FilterId, ParentId, Order, FilterName, FilterType, Expression |
| MEMBER | FilterId, Layer — หนึ่งแถวต่อสมาชิก Group Filter |

ค่าระดับไฟล์: Color, Linetype, Lineweight, Transparency, On, Frozen, Locked, Plot, NewVPFreeze, Description, Material, PlotStyle และ Hidden

ค่า VP: VPFreeze, VPColor, VPLinetype, VPLineweight, VPTransparency, VPPlotStyle

- Boolean: `1` = ใช่, `0` = ไม่ใช่ เช่น On=1 แสดง, Frozen=1 Freeze, VPFreeze=1 Freeze ใน VP นี้
- สี: `ACI:1` หรือ `RGB:255:128:0`; กรอกเลข ACI 1–255 เดี่ยว ๆ ได้; Color Book เก็บเป็น `BOOK:` ตามด้วย dictionary key
- Lineweight: หน่วย mm เช่น `0.18`, `0.35`, `0.70` หรือ `DEFAULT`
- Transparency: 0–100 เปอร์เซ็นต์ เก็บทศนิยมเพื่อคืนค่า alpha เดิมได้พอดี หรือ `BYLAYER` / `BYBLOCK`
- `INHERIT` ในคอลัมน์ VP Override = ล้าง Override ของคุณสมบัตินั้นและกลับไปใช้ค่าหลัก แม้ค่าที่ Override เคยเท่าค่าหลักก็ยังแยกแยะได้
- ช่องค่าที่ว่าง = คงค่าปลายทางไว้ ยกเว้น Description ว่าง = ล้างคำอธิบาย
- `VPFreeze` ใช้ 0/1 เท่านั้น; ไม่ใช้ INHERIT
- FilterType: `GROUP` หรือ `PROPERTY`; ParentId ว่างหมายถึงใต้ root; Order เป็นจำนวนเต็มตั้งแต่ 0 เรียงระหว่าง siblings
- Expression ใช้ syntax ของ AutoCAD Property Filter เช่น `NAME=="A-*"`
- เพิ่มเลเยอร์: เพิ่มแถว LAYER; หากต้องการค่าของ VP ด้วย ให้เพิ่มแถว VPLAYER ที่อ้าง Layer ชื่อเดียวกันและ Viewport ที่มีอยู่
- เพิ่ม Group Filter: เพิ่มแถว FILTER และแถว MEMBER ของสมาชิก; FilterId ต้องไม่ซ้ำ และ ParentId ต้องอ้าง FilterId ที่มีจริง
- การลบแถว LAYER/VPLAYER จาก CSV หมายถึงไม่ดำเนินการกับรายการนั้น ไม่ได้ลบเลเยอร์ใน DWG

## การย้ายไปไฟล์อื่นและข้อจำกัด

- CSV เก็บ **ชื่อ** Linetype, Material และ Plot Style; ถ้าปลายทางไม่มี โปรแกรมอ่านนิยามจากไฟล์ DWG ใน META.SourceDwg แล้ว clone ไปยังปลายทาง
- บันทึก DWG ต้นทางก่อน Export หากมีนิยามใหม่ที่ยังไม่เคยบันทึก เมื่อนำ CSV ไปเครื่องอื่น ให้ส่ง DWG ต้นทางไปด้วยและแก้ SourceDwg หรือโหลดนิยามที่ขาดในปลายทางก่อน
- ถ้าใช้ชื่อ Linetype/Material ที่มีอยู่แล้ว จะใช้นิยามในปลายทาง การเขียนทับชื่อเลเยอร์ไม่ได้เขียนทับนิยามทรัพยากรเหล่านี้
- ถ้าหานิยามที่ต้องใช้ไม่ได้ จะยกเลิก Import พร้อมระบุแถว ไม่มีการแทนด้วย Continuous อย่างเงียบ ๆ
- Named Plot Style จาก STB ใช้กับ CTB ไม่ได้ โปรแกรมข้ามค่านั้นและแจ้งใน log โดยไม่เปลี่ยนโหมด CTB/STB ของไฟล์
- ส่งออกเลเยอร์ Xref ได้ แต่สร้างชื่อแบบ `xref|layer` เองไม่ได้ ต้องมี Xref นั้นในปลายทางก่อน; ข้ามค่าหลักของเลเยอร์ Xref แต่ใช้ VP Overrides ได้เมื่อชื่อมีอยู่
- ส่งออก custom Group/Property Filters และลำดับใน filter collection; system/dynamic/proxy filters ที่ AutoCAD สร้างเองข้ามพร้อม log ลำดับที่ UI แสดงอาจขึ้นกับการเรียงของ AutoCAD
- ไม่เก็บตำแหน่ง/ขนาด/สเกล/มุมมองของกรอบ VP และไม่สร้าง VP ใหม่
- รุ่นนี้ compile อ้างอิง AutoCAD 2025 และทดสอบใน AutoCAD 2025 Core Console; ยังไม่ได้ทดสอบ AutoCAD รุ่นอื่นหรือ LT

## Build และทดสอบ

ใช้ PowerShell 7 และ .NET 8 runtime พร้อม AutoCAD 2025 ที่ติดตั้งในเครื่อง:

```powershell
./build.ps1
./build.ps1 -Tests
```

Build ใช้ Roslyn ที่มาพร้อม PowerShell ไม่ต้องติดตั้ง SDK หรือ restore NuGet

โหลด `tests/bin/TA_LAYER_TRANSFER.dll` ใน Core Console แล้วรัน `MAVPTEST` ผลอยู่ใน `tests/results.txt` และ CSV ตัวอย่างอยู่ใน `tests/sample.csv` ทดสอบบนฐานข้อมูล DWG ที่สร้างขึ้นใหม่ ไม่ใช้ DWG งานจริงของผู้ใช้

ทดสอบ round trip CSV/Unicode, VP ที่ค่าต่างกัน, explicit/INHERIT overrides, create/skip/keep, global/VP isolation, filter hierarchy/order/membership, resource cloning, invalid CSV และ transaction rollback

ผลตรวจวันที่ 22 ตุลาคม 2026: integration checks ผ่าน 35 ข้อใน AutoCAD 2025 Core Console และตรวจการโหลดผ่าน Maviewport.lsp / เรียก MAVPEXPORT / MAVPIMPORT จาก command line บน DWG จำลองสำเร็จ ยังไม่ได้ทดสอบกับ DWG งานจริงของผู้ใช้

API อ้างอิง:

- [LayerViewportProperties](https://help.autodesk.com/cloudhelp/2026/ENU/OARX-ManagedRefGuide/files/OARX-ManagedRefGuide-Autodesk_AutoCAD_DatabaseServices_LayerViewportProperties.html)
- [Viewport methods](https://help.autodesk.com/cloudhelp/2026/ENU/OARX-ManagedRefGuide/files/OARX-ManagedRefGuide-__MEMBERTYPE_Methods_Autodesk_AutoCAD_DatabaseServices_Viewport.html)
- [LayerManager](https://help.autodesk.com/cloudhelp/2019/ENU/OARX-ManagedRefGuide/files/OREFNET-Autodesk_AutoCAD_LayerManager.html)
