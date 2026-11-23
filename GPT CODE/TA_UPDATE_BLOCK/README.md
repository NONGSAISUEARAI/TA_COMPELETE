# TA UPDATE BLOCK — LISP v1.3

เลือก Block ต้นแบบจาก **DWG ที่เปิดอยู่** แล้วนำ definition ไป redefine Block ชื่อเดียวกันใน DWG ปลายทางหลายไฟล์ ไฟล์ปัจจุบันเป็นต้นทาง ไม่ถูกบันทึกแก้ไขโดยโปรแกรม

ผู้ใช้เรียกผ่าน AutoLISP ส่วน C# ทำงานกับฐานข้อมูล DWG ปลายทางโดยไม่เปิดหน้าต่างไฟล์เหล่านั้น

คู่มือฉบับเต็ม: [TA_UPDATE_BLOCK.qmd](TA_UPDATE_BLOCK.qmd) — การใช้งาน, API, การ build, การทดสอบ และข้อจำกัด

## เริ่มใช้งาน

สภาพแวดล้อมที่ build และทดสอบแล้ว: **AutoCAD 2026 บน Windows x64 / .NET 8** ยังไม่ได้ยืนยันกับ AutoCAD รุ่นอื่น, AutoCAD LT หรือ macOS

1. เก็บ `TA_UPDATE_BLOCK.lsp` และ DLL ตามโครงสร้างด้านล่าง
2. เปิด DWG ต้นทางที่เคยบันทึกชื่อไฟล์แล้ว และ Save การแก้ไข Block ให้เรียบร้อย
3. ใช้ `APPLOAD` โหลด `TA_UPDATE_BLOCK.lsp` ต้องเห็นข้อความ `TA_UPDATE_BLOCK v1.3 loaded`
4. พิมพ์ `TAUB` หรือ `TAUPDATEBLOCK` — LISP จะตรวจและ `NETLOAD` DLL ให้อัตโนมัติ
5. คลิก Block ต้นแบบในไฟล์ปัจจุบัน
6. เลือก `Folder` หรือ `Files` เพื่อกำหนด **ปลายทาง**
7. เลือกสร้าง Backup (`Yes` เป็นค่าเริ่มต้น) โปรแกรมจะอัปเดตและบันทึก DWG ปลายทางอัตโนมัติ

```text
TA_UPDATE_BLOCK/
  TA_UPDATE_BLOCK.lsp
  bin/Release/net8.0-windows/TA_UPDATE_BLOCK.dll
```

วาง DLL ข้าง LISP ได้เช่นกัน หากย้ายโฟลเดอร์ติดตั้งและไม่ได้เพิ่มโฟลเดอร์ LISP ใน Support Path ให้กำหนดตำแหน่งก่อนเรียกคำสั่ง:

```lisp
(setq *TAUB:install-dir* "D:/MyTools/TA_UPDATE_BLOCK")
```

ตัว loader มี fallback เป็นตำแหน่งโปรเจกต์เดิมบนเครื่องผู้พัฒนา ไม่ควรพึ่ง fallback นี้เมื่อนำไปใช้เครื่องอื่น หาก AutoCAD บล็อกการโหลด ให้เพิ่มเฉพาะโฟลเดอร์ LISP และโฟลเดอร์ DLL ที่ใช้ใน `TRUSTEDPATHS` ผ่าน Options โปรแกรมไม่เปลี่ยน `SECURELOAD` หรือ `TRUSTEDPATHS` ให้เอง

## คำสั่งและการเลือกปลายทาง

| คำสั่ง / ตัวเลือก | การทำงาน |
| --- | --- |
| `TAUB` / `TAUPDATEBLOCK` | คำสั่งหลัก ทั้งสองชื่อทำงานเหมือนกัน |
| `TAUBFOLDER` | ทดสอบหน้าต่างเลือกโฟลเดอร์อย่างเดียว ไม่อัปเดต DWG และไม่จำเป็นต้องเรียกก่อน `TAUB` |
| `Folder` | หน้าต่างแบบ File Explorer ใช้ช่อง Address วาง path ได้ ใช้ DWG ในโฟลเดอร์นั้น ไม่รวมโฟลเดอร์ย่อย |
| `Files` | เลือก DWG ทีละไฟล์ กด Cancel เมื่อเลือกครบ รายการที่เลือกไว้ยังถูกนำไปประมวลผล |

ตัวอย่าง: เปิด `MASTER.dwg` → เลือก Block `DOOR_01` → เลือก `A.dwg` และ `B.dwg` → redefine Block ชื่อ `DOOR_01` ในสองไฟล์นั้น หากไม่มีชื่อนี้ในปลายทาง โปรแกรมจะเพิ่ม definition แต่ไม่วาง Block reference ใหม่ให้

## สิ่งที่เปลี่ยนในปลายทาง

- Block reference เดิมใช้ definition ที่อัปเดตตามชื่อ Block ที่เลือก
- Attribute ที่ Tag ตรงกันเก็บค่า TextString เดิม แต่ปรับตาม definition ใหม่ เพิ่ม Tag ใหม่ด้วยค่า default และลบ Tag ที่ไม่มีในต้นแบบแล้ว
- เมื่อเปิด Backup จะสร้างไฟล์ เช่น `A.TAUB_20261106_103000.bak` ก่อนพยายามแก้ DWG กู้คืนได้โดยคัดลอก Backup แล้วเปลี่ยนนามสกุลสำเนาเป็น `.dwg`
- ปลายทางที่เปิดอยู่ใน AutoCAD session เดียวกัน, ไฟล์ที่เป็นต้นทางเอง หรือไฟล์ที่ทำงานไม่สำเร็จ จะแสดง `FAIL` แล้วทำไฟล์ถัดไป

```text
TA UPDATE BLOCK: 2 succeeded, 1 failed.
OK   D:\CAD\A.dwg
OK   D:\CAD\B.dwg
FAIL D:\CAD\C.dwg : target drawing is open; close it first
```

ไฟล์ที่ขึ้น `OK` ถูกบันทึกแล้ว การทำงานไม่ได้ rollback ทั้งชุด หากบางไฟล์ล้มเหลว ไฟล์ที่สำเร็จก่อนหน้ายังคงถูกอัปเดต

## เรียกจาก LISP อื่น

```lisp
(TAUB:Run
  "D:/CAD/MASTER.dwg"
  "MY_BLOCK"
  '("D:/CAD/A.dwg" "D:/CAD/B.dwg")
  T)
;; ผลสำเร็จตัวอย่าง: (2 0 "OK ...\nOK ...")
```

ส่ง full path, ชื่อ definition ต้นทาง, list ของ full path ปลายทาง และ `T`/`nil` เพื่อเปิด/ปิด Backup ตามลำดับ ผลลัพธ์เป็น `(success-count failure-count report)` หรือ `nil` หาก loader/การเรียก DLL ล้มเหลว

## ปัญหาที่พบบ่อย

| อาการ | วิธีตรวจและแก้ |
| --- | --- |
| `no function definition: TAUB-PICK-FOLDER` | APPLOAD LISP v1.3 แล้วเรียก `TAUB` ให้โหลด DLL หาก DLL รุ่นเก่าค้างใน session ให้บันทึกงานและเปิด AutoCAD ใหม่ |
| `No target drawings selected.` ทั้งที่เลือกโฟลเดอร์แล้ว | อาจเป็น LISP รุ่นก่อน v1.3 ที่ไม่แปลง path แบบ list จาก .NET ให้ APPLOAD v1.3 ใหม่ ใช้ DLL Explorer เดิมได้ |
| `No DWG files found in this folder...` | ตรวจว่ามี `.dwg` อยู่ในโฟลเดอร์ที่เลือกจริง โปรแกรมไม่ค้นหาในโฟลเดอร์ย่อย |
| `Folder selection cancelled.` | ยกเลิก dialog จึงไม่เริ่มอัปเดต |
| `TA_UPDATE_BLOCK.dll was not found...` | ตรวจตำแหน่ง DLL และ `*TAUB:install-dir*` |
| `target drawing is open; close it first` | บันทึกและปิดไฟล์ปลายทางก่อนเรียกใหม่ |

หากเปลี่ยนเฉพาะ LISP v1.2 → v1.3 ให้ APPLOAD ใหม่ได้ทันที แต่หากเปลี่ยน DLL ที่โหลดอยู่แล้ว ต้องเปิด AutoCAD ใหม่ก่อนโหลด DLL รุ่นใหม่

## Build และทดสอบ

รันจากโฟลเดอร์นี้ด้วย PowerShell 7 ที่มี Roslyn (`Microsoft.CodeAnalysis*.dll`) และมี .NET 8 runtime / Windows Desktop runtime ตามที่ `build.ps1` ใช้:

```powershell
& .\build.ps1
& .\build.ps1 -Tests
```

หรือใช้ .NET 8 SDK:

```powershell
dotnet build .\TA_UPDATE_BLOCK.csproj -c Release
```

ผล build ปกติอยู่ที่ `bin/Release/net8.0-windows/TA_UPDATE_BLOCK.dll` ส่วน `-Tests` สร้าง `tests/bin/TA_UPDATE_BLOCK_TESTS.dll` แยกต่างหาก ไม่ใช้ DLL ทดสอบกับงานจริง

เคยทดสอบผ่าน AutoCAD Core Console ด้วย DWG จำลองแล้ว: รับ path แบบ list จาก C# กลับ LISP, Cancel แบบ `(nil)`, ค้นหา DWG, redefine geometry จริง, ตำแหน่ง insertion เดิม, ค่า Attribute เดิม/Tag ใหม่/Tag ที่ลบ, Backup และ hash ของไฟล์ต้นทาง รวมถึงการเรียกผ่าน `TAUB:Run`

สคริปต์และคำสั่งรันทดสอบอยู่ใน [คู่มือ QMD](TA_UPDATE_BLOCK.qmd#testing) การทดสอบดังกล่าวไม่ครอบคลุมการคลิก dialog จริง, dynamic/nested block ทุกกรณี หรือการรักษาค่า dynamic property ราย reference สคริปต์ทดสอบยังอ้าง path ของ workspace เครื่องนี้ ต้องปรับก่อนใช้เครื่องอื่น

## ข้อจำกัด

- C# ใช้ `WblockCloneObjects` กับ `DuplicateRecordCloning.Replace`; dependencies ชื่อซ้ำที่ถูก clone เช่น nested block หรือ symbol record อาจได้รับผลด้วย
- มีโค้ดอัปเดต anonymous definitions ของ dynamic block แต่ยังไม่มี integration fixture ครอบคลุม dynamic/nested block จึงควรตรวจด้วยสำเนางานจริงก่อนใช้กับชุดนั้น
- ไม่รองรับ layout, Xref หรือ dependent block เป็น definition ต้นทาง
- บันทึกปลายทางด้วย `DwgVersion.Current` ของ AutoCAD ที่รัน ไม่คงรูปแบบ DWG เก่าโดยอัตโนมัติ
- การตรวจไฟล์ที่เปิดอยู่ครอบคลุม AutoCAD session เดียวกันเท่านั้น ไม่ได้ตรวจ session ของเครื่องอื่นทั้งหมด

## Render คู่มือ QMD

เมื่อติดตั้ง Quarto แล้ว:

```powershell
quarto render .\TA_UPDATE_BLOCK.qmd --to html
```

ได้ `TA_UPDATE_BLOCK.html` พร้อมสารบัญและปุ่มคัดลอกโค้ด การ render คู่มือไม่รันคำสั่ง AutoCAD หรือชุดทดสอบ
