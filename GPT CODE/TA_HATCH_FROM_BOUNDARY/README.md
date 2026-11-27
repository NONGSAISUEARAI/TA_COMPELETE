# TA Hatch From Boundary

คำสั่งสร้าง Associative Hatch จาก closed boundary โดยเลือกได้สองวิธี:

1. Preset `1–5` กำหนด Annotation Scale, Hatch, Layer และ Color ใน LISP
2. Preset `0` กำหนด Scale/Hatch/Color ใน LISP และหา Layer จาก **Current Layer Filter**

รองรับ AutoCAD 2026 / Windows x64 / .NET 8

## Build

```powershell
./build.ps1
```

ผลลัพธ์อยู่ที่ `bin/TA_HATCH_FROM_BOUNDARY_v6.dll` และ
`bin/TA_HATCH_PRESETS.json`

## โหลดและใช้งานผ่าน LISP

1. ใช้ `APPLOAD` โหลด `TA_HATCH_FROM_BOUNDARY.lsp`
2. เปิด Layer Properties Manager แล้วเลือก Layer Filter ที่ต้องการ
3. รัน `TAHB`
4. เลือก LISP preset หรือเลือก `0` เพื่อใช้ Layer จาก Current Layer Filter
5. เลือก closed Polyline, Circle, Ellipse หรือ Spline

สามารถเลือก Boundary ไว้ก่อนรัน `TAHB` ได้ โปรแกรมจะอ่าน Pickfirst/Implied
Selection เทียบเท่า `(ssget "_I")` โดยอัตโนมัติ ถ้าไม่มี closed boundary ที่ใช้ได้
จึงจะเปิดให้เลือก Boundary ตามปกติ

คำสั่ง:

- `TAHB` หรือ `TAHATCHBOUNDARY` — สร้าง Hatch
- `TAHATCHPRESETS` — แสดงรายการ preset ที่กำหนดใน LISP

LISP จะโหลด DLL จากโฟลเดอร์ `bin` อัตโนมัติ ถ้าย้ายไฟล์ สามารถกำหนด root ก่อนโหลด:

```lisp
(setq *TA-HB-ROOT* "D:/CAD/TA_HATCH_FROM_BOUNDARY")
```

หาก AutoCAD บล็อก DLL ด้วย `SECURELOAD` ให้เพิ่มเฉพาะโฟลเดอร์ `bin` นี้ใน
Options > Files > Trusted Locations (`TRUSTEDPATHS`) แล้วโหลดใหม่ โปรแกรมจะไม่ลด
ค่าความปลอดภัยหรือแก้ Trusted Locations ให้อัตโนมัติ

หาก AutoCAD เคยโหลด DLL รุ่นเก่า ตัวโหลดล่าสุดจะเลือก
`TA_HATCH_FROM_BOUNDARY_v6.dll` ซึ่งใช้ชื่อ Assembly และคำสั่งภายในคนละชื่อ
จึงไม่ชนกับรุ่นเก่า หากเครื่องยังปฏิเสธการโหลด ให้ปิด AutoCAD ทุกหน้าต่าง เปิดใหม่
แล้ว APPLOAD ไฟล์ LISP รุ่นล่าสุด

## พฤติกรรม

- อ่าน Current Filter จริงผ่าน `Database.LayerFilters.Current`
- รองรับทั้ง Group Filter และ Property Filter
- LISP preset กำหนด Annotation Scale, Pattern/Scale/Angle, Layer และ Color
- ถ้า Layer ใน preset ยังไม่มี โปรแกรมจะสร้าง Layer ให้
- Color รองรับ `BYLAYER`, `BYBLOCK`, `ACI:n` และ `RGB:r,g,b`
- Preset `0` ไม่ค้นหา Hatch ต้นแบบ; หลังเลือก Boundary จะแสดง Pattern Preset
  ซึ่งจับคู่ Pattern/Scale/Angle ไว้แล้ว
- Preset `0` เลือก Layer จาก Current Filter ตามลำดับ: Current Layer ถ้าเป็นสมาชิก
  → Layer ที่ชื่อมีคำว่า `HATCH` → Layer แรกตามชื่อ และรวมสมาชิกใน Filter ลูก
- boundary หนึ่งวัตถุสร้าง Hatch หนึ่งตัว และตั้ง `Associative = true`
- รองรับ Boundary ที่เลือกไว้ล่วงหน้าผ่าน Pickfirst/`(ssget "_I")`
- preset แบบ Annotative เพิ่มหลาย Annotation Scale ให้ Hatch เดียวได้
- ถ้า Scale ยังไม่มีใน DWG โปรแกรมจะสร้างจาก `paperUnits`/`drawingUnits`
- ถ้ามี Scale ชื่อเดียวกันแต่ ratio ต่างกัน จะใช้ค่าเดิมใน DWG และแจ้ง warning
- Gradient Hatch ยังไม่ใช้เป็นต้นแบบในรุ่นนี้

## แก้ Full Preset ใน LISP

แก้ตัวแปร `*TA-HB-PRESETS*` ที่ด้านบนของ `TA_HATCH_FROM_BOUNDARY.lsp`
ไม่ต้อง Build DLL ใหม่ แล้ว APPLOAD ไฟล์ LISP อีกครั้ง

Preset หมายเลข `0` แยกอยู่ใน `*TA-HB-CURRENT-FILTER-PRESET*` โดยแก้
`ANNOTATIVE`, `SCALES`, `PATTERN-PRESETS` และ
`COLOR` ได้ใน LISP ส่วน `(LAYER . "CURRENT-FILTER")` ให้โปรแกรมหา Layer
จาก Filter ที่กำลังเลือกโดยอัตโนมัติ

รายการย่อยของ `PATTERN-PRESETS` ใช้รูปแบบ:

```lisp
("ชื่อที่แสดง" "PatternType" "PatternName" Scale AngleDegrees)
```

ตัวอย่าง:

```lisp
(PATTERN-PRESETS
  ("ANSI35 x25" "PreDefined" "ANSI35" 25.0 0.0)
  ("ANSI31 x10" "PreDefined" "ANSI31" 10.0 0.0)
  ("C06 CUSTOM x1" "CustomDefined" "000_C06" 1.0 0.0)
)
```

ลำดับ Preset `0` คือ `เลือก 0 → เลือก Boundary → เลือก Pattern Preset` โดย LISP
ใช้ตัวแปร Global `run_no` จดจำหมายเลข Pattern Preset ล่าสุดสำหรับการกด Enter
และยังจำรายการหลังปิด–เปิด AutoCAD ผ่านค่า `TA_HB_LAST_FILTER_PATTERN`
ใน AutoCAD profile

หมายเลข Preset หลักที่เลือกจากหน้า `TAHB` ก็ถูกจำเช่นกัน กด Enter ครั้งถัดไปจะใช้
หมายเลขล่าสุด และยังจำหลังปิด–เปิด AutoCAD ผ่านค่า `TA_HB_LAST_PRESET_INDEX`

ชื่อ Pattern และ Scale เก็บคู่กันในบรรทัดเดียว เช่น
`(PATTERN "ANSI35" 25.0)` เพื่อให้แต่ละลายมี Scale ประจำของตัวเอง

ตัวอย่าง preset หลายสเกล:

```lisp
("DETAIL ANSI31 - 1:20 + 1:50"
  (ANNOTATIVE . T)
  (SCALES ("1:20" 1.0 20.0) ("1:50" 1.0 50.0))
  (PATTERN-TYPE . "PreDefined")
  (PATTERN "ANSI31" 10.0)
  (PATTERN-ANGLE . 45.0)
  (LAYER . "HATCH-DETAIL")
  (COLOR . "RGB:255,0,0")
)
```

Preset `0` เริ่มต้นใส่ Annotation Scale `1:1`, `1:2`, `1:5`, `1:10`, `1:15`,
`1:20` และ `1:25` ให้ Hatch ทุกตัวที่สร้าง

ถ้าใช้ Custom PAT ให้เพิ่มโฟลเดอร์ที่เก็บ `.pat` ใน AutoCAD Support File Search Path
เพื่อให้ AutoCAD สร้าง Hatch ใหม่จาก Pattern นั้นได้
