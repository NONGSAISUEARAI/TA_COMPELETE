---
name: autocad-ta-hatch-from-boundary
description: Maintain the AutoCAD 2026 TA Hatch From Boundary LISP/C# project, including current-layer-filter presets, remembered Hatch selection, Pickfirst boundaries, annotative scales, versioned DLL builds, and AutoCAD loading behavior.
---

# ดูแล TA Hatch From Boundary

ใช้กับไฟล์ในโฟลเดอร์นี้ อ่าน [TA_HATCH_FROM_BOUNDARY.lsp](TA_HATCH_FROM_BOUNDARY.lsp), [src/HatchCommands.cs](src/HatchCommands.cs) และ [README.md](README.md) ก่อนแก้พฤติกรรม ตรวจค่าจากไฟล์จริงทุกครั้ง เพราะผู้ใช้แก้ Preset ใน LISP เองได้และต้องรักษาค่าเหล่านั้นไว้

โปรเจกต์รองรับ AutoCAD 2026 / Windows x64 / .NET 8 ผู้ใช้เรียกงานผ่านคำสั่ง LISP `TAHB` หรือ `TAHATCHBOUNDARY`; ชื่อคำสั่ง `TAHATCHBOUNDARYNETn` และ LispFunction ใน DLL เป็น API ภายใน

## พฤติกรรมที่ต้องรักษา

- Preset `0` ใช้ Layer จาก Current Layer Filter ที่เลือกใน Layer Properties Manager ไม่ค้นหา Hatch ต้นแบบ
- ลำดับ Preset `0` คือ `เลือก 0 → เลือก Boundary → เลือก Hatch/Pattern Preset → สร้าง Hatch`
- Boundary ของ Preset `0` รับ Pickfirst ด้วย `(ssget "_I")` ก่อน ถ้าไม่มีจึงใช้ `ssget` ให้เลือกใหม่ จากนั้นใช้ `sssetfirst` ส่ง Selection ให้ DLL
- DLL ต้องประกาศ `CommandFlags.UsePickSet`, อ่าน `Editor.SelectImplied()` และตรวจว่า Boundary ปิดและอยู่ใน Current Space ก่อนสร้าง
- รายการ Pattern ของ Preset `0` อยู่ใน `PATTERN-PRESETS` รูปแบบ `("ชื่อแสดง" "PatternType" "PatternName" Scale AngleDegrees)` เช่น `("ANSI35 x25" "PreDefined" "ANSI35" 25.0 0.0)` ค่าตัวแรกเป็นเพียงชื่อรายการ ไม่ใช่ชื่อ Hatch จริง
- Pattern, Scale และ Angle เป็นข้อมูลชุดเดียวกัน ห้ามแยก Scale ออกจากรายการ Pattern จนทำให้เลือกสลับกันได้
- LISP แสดงหมายเลข Hatch และใช้ Global `run_no` จำหมายเลขล่าสุดใน session การกด Enter ต้องใช้ `run_no` เดิม
- `*TA-HB-LAST-FILTER-PATTERN*` จำชื่อรายการ Pattern และเก็บข้ามการเปิด AutoCAD ด้วย ENV ที่กำหนดใน `*TA-HB-PATTERN-MEMORY-ENV*`
- `*TA-HB-LAST-PRESET-INDEX*` จำหมายเลข Preset หลัก โดยยังอัปเดต `exchoice` เพื่อรองรับโค้ดเดิม และเก็บข้าม session ผ่าน `*TA-HB-PRESET-MEMORY-ENV*`
- Preset `1..N` เป็น Full Preset ใน `*TA-HB-PRESETS*` กำหนด Annotation Scale, Pattern/Scale/Angle, Layer และ Color และไม่ควรถามซ้ำเมื่อข้อมูลครบ
- สีรองรับ `BYLAYER`, `BYBLOCK`, `ACI:n` และ `RGB:r,g,b`; PatternType รองรับ `PreDefined`, `CustomDefined` และ `UserDefined`
- Layer ของ Preset `0` เลือกตามลำดับ: Current Layer ถ้าเป็นสมาชิก Filter → Layer ที่ชื่อมี `HATCH` → Layer แรกตามชื่อ รวมสมาชิกใน Filter ลูก และหลีกเลี่ยง Layer dependent เมื่อมี Layer ที่เขียนได้
- Boundary หนึ่งชิ้นสร้าง Associative Hatch หนึ่งตัว Preset แบบ Annotative เพิ่ม Annotation Scale หลายรายการให้ Hatch เดียวได้

ข้อกำหนดเหล่านี้เป็นค่าปัจจุบัน เปลี่ยนได้เมื่อผู้ใช้สั่งเปลี่ยนโดยตรง แต่ห้ามย้อน Preset หรือค่าที่ผู้ใช้แก้เองตามตัวอย่างเก่า

## จุดแก้หลัก

- Preset และตัวแปรจดจำ: ส่วนต้นของ `TA_HATCH_FROM_BOUNDARY.lsp`
- รับหมายเลข Hatch: `TA-HB:choose-pattern-preset`; ต้องคง `run_no` เป็น Global ไม่ใส่ในรายการ local ของ `defun`
- รับ Boundary: `TA-HB:select-boundaries`
- ส่ง Pattern ที่เลือกให้ DLL: `TA-HB:send-current-filter-preset`; ส่งรายการที่เลือกเพียงรายการเดียวเพื่อไม่ให้ C# ถาม Pattern ซ้ำ
- ลำดับคำสั่ง: `c:TAHATCHBOUNDARY`
- รับ Preset จาก LISP: `SetLispPreset`, `SetFilterPreset`
- ตรวจ Pickfirst/Boundary และสร้าง Hatch: `CreateHatchFromBoundary`, `ValidateBoundaries`, `CreateHatchesFromLispPreset`
- หา Layer จาก Filter: `ResolveLayerNameFromCurrentFilter`, `FilterTreeMatchesLayer`

## Version และการ Build

AutoCAD unload managed assembly ระหว่าง session ไม่ได้ เมื่อแก้ C# ให้เพิ่มหมายเลขรุ่นพร้อมกันทุกจุด เช่น V6 → V7:

- ชื่อ Assembly ใน `TA_HATCH_FROM_BOUNDARY.csproj` และ `build.ps1`
- ชื่อไฟล์ `bin/TA_HATCH_FROM_BOUNDARY_vN.dll`
- `[CommandMethod]` และ `[LispFunction]` ใน C#
- ชื่อที่ LISP เรียก, readiness check, DLL search order และข้อความ file picker
- README

เพิ่ม DLL รุ่นใหม่เป็นตัวเลือกแรก แต่เก็บ fallback รุ่นเก่าไว้เพื่อช่วยค้นหาไฟล์ อย่าแก้ C# แล้ว Build ทับชื่อ DLL ที่ AutoCAD อาจโหลดค้างอยู่ การแก้เฉพาะ Preset หรือ logic ใน LISP ไม่ต้อง Build DLL ใหม่

Build จากโฟลเดอร์นี้:

```powershell
./build.ps1
```

## ตรวจงาน

- ตรวจวงเล็บ LISP โดยลบ string/comment ก่อนนับ `(` และ `)`; การนับตัวอักษรดิบทำให้ผลคลาดเคลื่อนจากวงเล็บในข้อความ
- หลัง Build ตรวจว่า DLL รุ่นใหม่มี CommandMethod และ LispFunction ชื่อรุ่นเดียวกับ LISP
- ตรวจว่า LISP เลือก DLL รุ่นล่าสุดก่อนรุ่นเก่า และ `TA-HB:net-api-ready-p` ตรวจ API รุ่นเดียวกัน
- ตรวจ flow Preset `0`: Pickfirst และเลือกใหม่, กด Enter ที่ `run_no`, เลือกเลขอื่น, Pattern/Scale/Angle ที่ส่งเข้า DLL และไม่มีคำถาม Pattern ซ้ำจาก C#
- ตรวจ Preset `1..N` แยกจาก Preset `0` เพื่อไม่ให้การย้าย prompt ไป LISP กระทบ Full Preset
- การทดสอบ AutoCAD จริงให้ APPLOAD LISP ล่าสุด ตรวจ TRUSTEDPATHS แล้วรันในสำเนา DWG; การคอมไพล์ผ่านอย่างเดียวไม่ยืนยัน Layer Filter, annotation context หรือ custom PAT ใน AutoCAD runtime
