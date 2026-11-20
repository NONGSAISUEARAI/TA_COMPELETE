# คู่มือ VBA ในโฟลเดอร์ GPT CODE VBA

คู่มือนี้อ้างอิงโค้ด `.bas` ที่อยู่ในโฟลเดอร์นี้ ณ วันที่ 20 พฤศจิกายน 2026 โดยเน้นลำดับ **argument** ที่ต้องใส่ในสูตร Excel และสิ่งที่ต้องเลือกก่อนรัน macro ชื่อในสูตรต้องใช้ **ชื่อฟังก์ชันในโค้ด** ซึ่งบางครั้งไม่ตรงกับชื่อไฟล์

## เริ่มใช้งาน

1. เปิดไฟล์ Excel ที่ต้องการใช้เป็น `.xlsm` แล้วนำเข้าไฟล์ `.bas` ที่ต้องการผ่าน VBA Editor (`Alt+F11` → File → Import File)
2. ฟังก์ชันใช้ในเซลล์โดยขึ้นต้นด้วย `=` ส่วน `Sub` macro ที่ไม่มี argument ให้รันจาก `Alt+F8` (หรือ VBA Editor)
3. สูตรที่คืนหลายเซลล์ต้องมีพื้นที่ว่างให้ผลลัพธ์แสดง มิฉะนั้นอาจขึ้น `#SPILL!` ช่วงข้อมูลที่ใช้เป็นคู่กันต้องมีจำนวนเซลล์เท่ากัน เว้นแต่ระบุไว้ต่างหาก
4. `[argument]` หมายถึงใส่หรือไม่ใส่ก็ได้ ส่วน `Range` คือการอ้างอิงเซลล์จริง เช่น `A2:A100` ไม่ใช่ข้อความ `"A2:A100"` หากเครื่องใช้ `;` เป็นตัวคั่น argument ในสูตร ให้เปลี่ยน `,` ระหว่าง argument เป็น `;`

**ไฟล์ชื่อซ้ำ:** `CSVFIELD` มีหลาย revision และทุกไฟล์ประกาศชื่อฟังก์ชันเดียวกัน ให้เลือกนำเข้าเพียง **หนึ่ง** revision; แนะนำ `A_FUNC_CSVFIELD_REV03.bas` ส่วน `A_FUNC_copyallsheet_v1.bas` กับ `EXCEL/copyallsheet.bas` ประกาศชื่อ `copyallsheet` เหมือนกัน ให้เลือกเพียงหนึ่งไฟล์

## 1. ข้อความและ CSV

### `KeepNumber` — [A_FUNC_KeepNumber.bas](A_FUNC_KeepNumber.bas)

`=KeepNumber(s)` — `s` คือข้อความหรือเซลล์ เริ่มอ่านตัวเลขชุดแรกที่พบและหยุดเมื่อเจออักขระที่ไม่ใช่ตัวเลขหลังจากนั้น; ถ้าไม่พบตัวเลข คืน `0` เช่น `=KeepNumber(D6)` (ข้อความ `2DL` คืน `2`) ผลลัพธ์เป็น `Long`; ตัวเลขชุดใหญ่เกินชนิดนี้อาจทำให้สูตรผิดพลาด

### `FORCSV` — [A_FUNC_FORCSV.bas](A_FUNC_FORCSV.bas)

`=FORCSV(SourceRange,[AdditionalRange...],[Separator],[RemoveBlank])`

| Argument | ความหมาย |
| --- | --- |
| `SourceRange` | ช่วงแรกที่ต้องการต่อข้อความ |
| `AdditionalRange...` | ช่วงเพิ่มเติมได้หลายช่วง ต่อข้อมูลตามลำดับที่ส่งเข้าไป |
| `Separator` | ข้อความคั่น; ค่าเริ่มต้น `","` |
| `RemoveBlank` | `TRUE` (ค่าเริ่มต้น) ข้ามเซลล์ว่าง; `FALSE` รักษาตำแหน่งว่างไว้ |

ตัวอย่าง `=FORCSV(A1:D1,",",FALSE)` อาจได้ `A,,C,D` ถ้า B1 ว่าง; `=FORCSV(A1:D1,F1:G1,";",TRUE)` ต่อหลายช่วงโดยคั่น `;`

### `CSVFIELD` — เลือก revision เดียว

| ไฟล์ | สูตร / argument | ผลลัพธ์ |
| --- | --- | --- |
| [A_FUNC_CSVFIELD_REV03.bas](A_FUNC_CSVFIELD_REV03.bas) **แนะนำ** | `=CSVFIELD(CsvText,Field1,[Field2...],[TrimSpaces],[Separator])` | หลาย field รวมเป็น **เซลล์เดียว**; ค่าเริ่มต้น `TrimSpaces=TRUE`, `Separator=","`; argument ผิดหรือ CSV ผิดรูปแบบแสดงคำแนะนำในเซลล์ |
| [A_FUNC_CSVFIELD_REV02.bas](A_FUNC_CSVFIELD_REV02.bas) | argument เหมือน REV03 | หลาย field รวมเป็นเซลล์เดียว |
| [A_FUNC_CSVFIELD.bas](A_FUNC_CSVFIELD.bas) | `=CSVFIELD(CsvText,Field1,[Field2...],[TrimSpaces])` | หลาย field **spill ตามแนวนอน** |
| [A_FUNC_CSVFIELD_REV02.before-multifield-fix.bas](A_FUNC_CSVFIELD_REV02.before-multifield-fix.bas) | `=CSVFIELD(CsvText,FieldNumber,[TrimSpaces])` | รุ่นเก่า ดึงได้หนึ่ง field |
| [A_FUNC_CSVFIELD_REV02.before-single-cell-separator.bas](A_FUNC_CSVFIELD_REV02.before-single-cell-separator.bas) | argument เหมือนรุ่น spill | รุ่นเก่า spill ตามแนวนอน |

`CsvText` เป็นข้อความหรือเซลล์เดียว; หมายเลข field เริ่มที่ **1** และใส่ซ้ำได้; `TrimSpaces` เป็น `TRUE/FALSE` หลังหมายเลข field; `Separator` เป็นข้อความตัวท้ายสุดเฉพาะ REV02/REV03 เครื่องหมาย comma ภายใน `"..."` หรือวงเล็บจะไม่ถูกแยกเป็น field

ตัวอย่าง REV03: `=CSVFIELD(W2,4)` หรือ `=CSVFIELD(W2,3,1,3,TRUE," | ")` (ดึงลำดับ 3, 1, 3 แล้วรวมด้วย ` | `)

## 2. นับและรวมค่าตามกลุ่ม

ในตารางนี้ `C1`, `C2` ... หมายถึงช่วงเงื่อนไขที่อยู่แถวเดียวกัน; `S1`, `S2` ... คือการเรียงของช่วงนั้น (`0` คงลำดับที่พบ, `1` เรียงจากน้อยไปมาก) `Heading` เป็นหัวเรื่องที่ใส่หรือเว้นได้

| ไฟล์ | สูตร / argument | จุดใช้งาน |
| --- | --- | --- |
| [A_FUNC_CountUnique_V1.bas](A_FUNC_CountUnique_V1.bas) | `=COUNTUNIQUE(UniqueRange,[SortFlag=0])` | รายการไม่ซ้ำและจำนวน 2 คอลัมน์ |
| [A_FUNC_CountUnique_V2.bas](A_FUNC_CountUnique_V2.bas) | `=COUNTUNIQUE_V2(C1,C2,[C3],[Heading])` | C1 เป็นแถว, C2 เป็นหัวคอลัมน์, C3 เป็นหัวรอง; ไม่มี C3 แต่มีหัวเรื่องใช้ `=COUNTUNIQUE_V2(C1,C2,,Heading)` |
| [A_FUNC_CountUnique_V2B.bas](A_FUNC_CountUnique_V2B.bas) | `=COUNTUNIQUE_V2B(C1,S1,C2,S2,[C3,S3],[Heading])` | เพิ่มการเรียงแต่ละเงื่อนไข |
| [A_FUNC_CountUnique_V2C.bas](A_FUNC_CountUnique_V2C.bas) | `=COUNTUNIQUE_V2C(C1,S1,C2,S2,[C3,S3],[Heading])` | `S` รับ `0`, `1` หรือช่วง/array ของค่าที่ใช้เรียงเอง; key ที่กำหนดเองเรียงจากน้อยไปมาก |
| [A_FUNC_CountUnique_V3.bas](A_FUNC_CountUnique_V3.bas) | `=COUNTUNIQUE_V3(C1,SortFlag,C2,[C3],[Heading])` | เรียงเฉพาะ C1 |
| [A_FUNC_CountUnique_V4.bas](A_FUNC_CountUnique_V4.bas) | `=COUNTUNIQUE_V4(C1,S1,C2,S2,[C3,S3],[C4,S4],[Heading],[RemoveBlank])` | รองรับ 2–4 เงื่อนไข; C1 เป็นแถว, C2–C4 เป็นหัวคอลัมน์ |
| [A_FUNC_CountUnique_V5.bas](A_FUNC_CountUnique_V5.bas) | `=COUNTUNIQUE_V5(C1,S1,C2,S2,C3,S3,C4,S4,C5,S5,[Heading],[RemoveBlank])` | ต้องใส่ครบ **5** เงื่อนไข; C1 เป็นแถว, C2–C5 เป็นหัวคอลัมน์ |
| [A_FUNC_CountUnique_V6.bas](A_FUNC_CountUnique_V6.bas) | `=COUNTUNIQUE_V6(Heading,IncludeEmpty,Range1,Sort1,Range2,Sort2,...)` | อย่างน้อย 2 คู่ Range/Sort; เพิ่มคู่ได้เพื่อเพิ่มระดับหัวคอลัมน์ |

สำหรับ V4/V5: `RemoveBlank=TRUE` (ค่าเริ่มต้น) ตัด **คอลัมน์ผลลัพธ์ที่ไม่มีจำนวนทุกแถวของ C1**; `FALSE` เก็บชุดหัวคอลัมน์ครบ แม้ไม่มีจำนวน ไม่ได้หมายถึงลบเซลล์ต้นทางที่ว่าง หากไม่ใส่ `Heading` สามารถใส่ `TRUE/FALSE` เป็น argument ท้ายแทนได้

ตัวอย่าง `=COUNTUNIQUE_V4(A2:A100,1,B2:B100,0,C2:C100,1,D2:D100,1,"สรุป",TRUE)` และ `=COUNTUNIQUE_V5(A2:A100,1,B2:B100,0,C2:C100,1,D2:D100,1,E2:E100,1,TRUE)`

**V6 ลำดับ argument เปลี่ยนจาก V5:**

| ตำแหน่ง | Argument | ความหมาย |
| --- | --- | --- |
| 1 | `Heading` | ข้อความ, เซลล์เดียว หรือ `""` เพื่อไม่แสดงหัวเรื่อง |
| 2 | `IncludeEmpty` | `1` แสดงหัวคอลัมน์ทุกชุดที่เป็นไปได้; `0` เฉพาะชุดที่พบจริงในข้อมูลที่ใช้ได้ |
| 3–4 | `Range1,Sort1` | กลุ่มแนวตั้งและวิธีเรียง (`0`/`1`) |
| 5–6 | `Range2,Sort2` | หัวคอลัมน์ระดับแรกและวิธีเรียง |
| ต่อไป | `Range3,Sort3,...` | หัวคอลัมน์ระดับถัดไป; ทุก Range ต้องมี Sort คู่กัน |

ตัวอย่าง `=COUNTUNIQUE_V6("สรุป",1,L3:L101,1,F3:F101,0,G3:G101,1)` ช่วงทุกชุดต้องมีจำนวนเซลล์เท่ากัน แถวที่ key ว่าง/เป็น error จะถูกข้าม; เลข `0` ถือเป็นข้อมูล; ช่องที่ไม่มีจำนวนแสดงว่าง

### ฟังก์ชันรวมค่า

| ไฟล์ | สูตร / argument | ผลลัพธ์ |
| --- | --- | --- |
| [A_FUNC_SumUnique.bas](A_FUNC_SumUnique.bas) | `=SUMUNIQUE(UniqueRange,[SumRange],[SortFlag=0])` | รายการไม่ซ้ำ + ผลรวม; เช่น `=SUMUNIQUE(A2:A100,B2:B100,1)` |
| [A_FUNC_SumUnique_V2.bas](A_FUNC_SumUnique_V2.bas) | `=SUMUNIQUE_V2(C1,S1,C2,S2,SumRange,[Heading])` | C1, C2, ผลรวม |
| [A_FUNC_SumUnique_V3.bas](A_FUNC_SumUnique_V3.bas) | `=SUMUNIQUE_V3(C1,S1,C2,S2,C3,S3,SumRange,[Heading])` | C1, C2, C3, ผลรวม |
| [A_FUNC_SumUnique_V6.bas](A_FUNC_SumUnique_V6.bas) | `=SUMUNIQUE_V6(Heading,IncludeEmpty,SumRange,Range1,Sort1,Range2,Sort2,...)` | ตารางผลรวมแบบ V6; เพิ่มคู่ Range/Sort ได้ |
| [UniqueIfs.bas](UniqueIfs.bas) | `=UNIQUEIFS(UniqueRange,CriteriaRange1,Criteria1,[CriteriaRange2,Criteria2],...)` | รายการไม่ซ้ำที่ผ่านเงื่อนไข; เพิ่มเงื่อนไขเป็นคู่ช่วง/ค่า |

`SUMUNIQUE_V6` ใช้ `Heading` และ `IncludeEmpty` เหมือน `COUNTUNIQUE_V6` แต่ต้องวาง `SumRange` **ตำแหน่ง 3** ก่อนคู่ Range/Sort; ตัวอย่าง `=SUMUNIQUE_V6("สรุป",1,M3:M101,L3:L101,1,F3:F101,0)` จำนวนเซลล์ของ `SumRange` และ key ทุกช่วงต้องเท่ากัน ค่ารวมที่ไม่ใช่ตัวเลข/ว่าง/error ถูกข้าม; ผลรวมจริงที่เท่ากับ 0 แสดง `0`

`UNIQUEIFS` ตัวอย่าง `=UNIQUEIFS(A2:A100,B2:B100,"PP17",C2:C100,"STD-LENGTH_1500")`

## 3. ดึงข้อมูลระหว่างชีตและ heading/detail

### `copyallsheet` ทั้ง 5 ไฟล์

| ไฟล์ | สูตร / argument | พฤติกรรม |
| --- | --- | --- |
| [A_FUNC_copyallsheet_v1.bas](A_FUNC_copyallsheet_v1.bas) | `=copyallsheet(SourceRange)` | ดึงช่วงพิกัดเดียวกันจากทุกชีต ยกเว้นชีตที่ใส่สูตร |
| [EXCEL/copyallsheet.bas](EXCEL/copyallsheet.bas) | `=copyallsheet(SourceRange,[FilterEmptyRows=0])` | เหมือน v1 แต่ `1` ข้ามแถวที่ว่างทั้งช่วง |
| [A_FUNC_copyallsheet_v2.bas](A_FUNC_copyallsheet_v2.bas) | `=copyallsheet_v2(SourceRange,StartSheet,CopySheetCount)` | เริ่มที่ชีตชื่อ/ลำดับที่กำหนด แล้วดึงจำนวนชีตที่กำหนด |
| [A_FUNC_copyallsheet_v3.bas](A_FUNC_copyallsheet_v3.bas) | `=copyallsheet_v3(SourceRange,StartSheet,CopySheetCount,[FilterEmptyRows=0])` | v2 พร้อมตัวเลือกข้ามแถวว่าง (`0` เก็บ, `1` ข้าม) |
| [A_FUNC_copyallsheet_v4.bas](A_FUNC_copyallsheet_v4.bas) | `=copyallsheet_v4(SourceAddressOrRange,StartSheet,CopySheetCount,[FilterEmptyRows=0],[ShowSheetName=TRUE])` | พิกัดข้อความคงที่ ตามด้วยลำดับ/ชื่อชีตเริ่มต้น จำนวนชีตต่อเนื่อง และตัวเลือกแสดงชื่อชีต |

`SourceRange` ใช้กำหนด **ตำแหน่งและขนาด** ของช่วงที่จะอ่านจากทุกชีต; ผลลัพธ์เพิ่มชื่อชีตเป็นคอลัมน์แรก ตัวอย่าง `=copyallsheet_v3(A2:D20,"Sheet1",3,1)` `StartSheet` เป็นชื่อชีตหรือเลขตำแหน่งแท็บ; หากแทรก/ย้ายชีตในชุด ตำแหน่งที่ดึงอาจเปลี่ยนตามลำดับแท็บ และชื่อชีตที่ดูเป็นตัวเลขจะถูกตีความเป็นเลขตำแหน่ง

**วิธีใช้ v4:** `=copyallsheet_v4("A2:D20",3,5,1)` หมายถึงอ่านตำแหน่ง `A2:D20` จากชีตลำดับที่ 3 และชีตถัดไปจนครบ 5 ชีต (ข้ามชีตที่ใส่สูตร) ข้อความ `"A2:D20"` เป็นพิกัดคงที่ Excel จะไม่เปลี่ยนข้อความนี้เมื่อแทรกแถว/คอลัมน์ในชีตสูตร `StartSheet` ใส่ชื่อชีตแทนลำดับได้ เช่น `"Sheet3"` ค่า `FilterEmptyRows=1` ข้ามแถวที่ว่างทั้งช่วง; `0` หรือไม่ใส่จะเก็บทุกแถว

| ลำดับ | Argument | ค่าเริ่มต้น | ความหมาย |
| --- | --- | --- | --- |
| 1 | `SourceAddressOrRange` | ต้องใส่ | พิกัด เช่น `"A2:D20"` แบบข้อความคงที่ หรือ `A2:D20` แบบช่วงเซลล์ |
| 2 | `StartSheet` | ต้องใส่ | ลำดับแท็บชีตเริ่มต้น เช่น `3` หรือชื่อชีต เช่น `"Sheet3"` |
| 3 | `CopySheetCount` | ต้องใส่ | จำนวนชีตต่อเนื่องที่จะดึง โดยข้ามชีตที่ใส่สูตร |
| 4 | `FilterEmptyRows` | `0` | `0` เก็บทุกแถว; `1` ข้ามแถวที่ว่างทั้งช่วง |
| 5 | `ShowSheetName` | `TRUE` | `TRUE` เพิ่มชื่อชีตเป็นคอลัมน์แรก; `FALSE` แสดงเฉพาะข้อมูล |

argument ที่ 5 `ShowSheetName`: `TRUE` (ค่าเริ่มต้น) เพิ่มชื่อชีตเป็นคอลัมน์แรก; `FALSE` แสดงเฉพาะคอลัมน์ข้อมูล ตัวอย่าง `=copyallsheet_v4("A2:D20",3,5,1,FALSE)` จะได้ 4 คอลัมน์ A:D โดยไม่มีคอลัมน์ชื่อชีต หากใช้ `SORT` หรือ `FILTER` ครอบผลลัพธ์ ให้เลือกเลขคอลัมน์ตามรูปแบบที่ตั้งไว้

v4 ยังรับ argument แรกแบบช่วงเซลล์ `A2:D20` ได้ แต่ Excel อาจปรับพิกัดนี้อัตโนมัติเมื่อแทรก/ลบเซลล์ในชีตสูตร จึงใช้ `"A2:D20"` เมื่อต้องการล็อกพิกัด

v4 อ่าน **พิกัดเซลล์เดียวกัน** จากทุกชีต หากแทรกแถวหรือคอลัมน์ของตารางในบางชีตจนข้อมูลย้ายที่ ต้องแก้ข้อความพิกัดให้ตรงกับตำแหน่งใหม่ ข้อความพิกัดไม่เลื่อนตามตารางเอง ส่วนการแทรก/ลบ/ย้ายแท็บชีตในชุดที่จะดึงจะเปลี่ยนชุดชีตตามลำดับแท็บที่มีอยู่ในขณะคำนวณ

### `HEADINGDETAILS` — [A_FUNC_HeadingDetails.bas](A_FUNC_HeadingDetails.bas)

`=HEADINGDETAILS(HeadingCell,MatchRange,[ReturnRange],[MatchMode="PREFIX"],[UniqueOnly=TRUE],[SortResult=TRUE])`

| Argument | ความหมาย |
| --- | --- |
| `HeadingCell` | เซลล์เดียวที่มีรหัสหัวข้อ เช่น `A243` |
| `MatchRange` | ช่วง 1 คอลัมน์ของรหัสข้อมูลย่อย |
| `ReturnRange` | ช่วง 1 คอลัมน์ที่ต้องการแสดง; เว้นไว้เพื่อแสดงค่า `MatchRange` |
| `MatchMode` | `"PREFIX"` เริ่มต้นด้วยรหัส heading; `"EXACT"` ตรงทั้งข้อความ |
| `UniqueOnly` | `TRUE` ตัดค่าซ้ำ; `FALSE` เก็บค่าซ้ำ |
| `SortResult` | `TRUE` เรียงผลลัพธ์; `FALSE` ตามข้อมูลต้นทาง |

ผลลัพธ์ spill **แนวนอน**; `MatchRange` และ `ReturnRange` ต้องมีจำนวนแถวเท่ากัน ตัวอย่าง `=HEADINGDETAILS($A243,'Total On Hand'!$C$2:$C$3506)`

### `HEADINGDETAILTABLE` — [A_FUNC_HeadingDetailTable.bas](A_FUNC_HeadingDetailTable.bas)

`=HEADINGDETAILTABLE(HeadingRange,DetailKeyRange,[OutputRange...],["PREFIX"|"EXACT"],["ROWS"|"COLUMNS"],["KEEPALL"|"MATCHEDONLY"])`

| Argument | ความหมาย |
| --- | --- |
| `HeadingRange` | ช่วง heading หลายแถวได้; **คอลัมน์แรกเป็น Code**; คอลัมน์ที่เหลือจะปรากฏในแถว heading ของผลลัพธ์ |
| `DetailKeyRange` | ช่วงรหัสของข้อมูลย่อย 1 คอลัมน์ที่นำมาเทียบกับ Code |
| `OutputRange...` | ช่วงข้อมูลย่อยที่ต้องการแสดง ระบุหลายช่วงได้ตามลำดับที่ต้องการ แต่ละช่วงอาจหลายคอลัมน์และต้องมีจำนวนแถวเท่ากับ `DetailKeyRange`; ถ้าไม่ระบุจะแสดง `DetailKeyRange` |
| `"PREFIX"` / `"EXACT"` | เทียบขึ้นต้นด้วย Code (ค่าเริ่มต้น) / เทียบตรงทั้งหมด |
| `"ROWS"` / `"COLUMNS"` | ค่าเริ่มต้น: แถว heading ตามด้วยแถวข้อมูลย่อย / หนึ่งแถวต่อ heading และรายละเอียดไปทางขวา |
| `"KEEPALL"` / `"MATCHEDONLY"` | แสดง heading ทุกตัว (ค่าเริ่มต้น) / ซ่อน heading ที่ไม่มีข้อมูลย่อยในโหมด `ROWS` |

ผลลัพธ์มี **เลขลำดับหน้ารายการ heading** ในคอลัมน์แรกของแต่ละกลุ่ม ตัวอย่าง:

```excel
=HEADINGDETAILTABLE('Item Category'!$A$237:$C$250,'Total On Hand'!$C$2:$C$3506,'Total On Hand'!$C$2:$D$3506,'Total On Hand'!$F$2:$F$3506,"PREFIX","ROWS")
```

ถ้า `HeadingRange` ใช้แค่ `A237:A250` ผลลัพธ์จะแสดงแค่ Code ในแถว heading; ถ้าต้องการ Level และชื่อ ให้ใช้ `A237:C250`

## 4. การจัดชุดตัด / สรุปการใช้วัสดุ

### `PACK_MULTI` — จัดชิ้นงานลงวัสดุต้นทาง

| ไฟล์ | ชื่อสูตรและ argument |
| --- | --- |
| [EXCEL/mul_v2_5_FINAL.bas](EXCEL/mul_v2_5_FINAL.bas) | `=PACK_MULTI_v2_6(ValueRange,QtyRange,targetRange,TargetQtyRange,TargetWasteRange,[Allowance=5])` — **ชื่อสูตรเป็น v2_6** แม้ชื่อไฟล์เขียน v2_5 |
| [S_FUNC_PACK_MULTI_v2_7.bas](S_FUNC_PACK_MULTI_v2_7.bas) | `=PACK_MULTI_v2_7(ValueRange,QtyRange,targetRange,TargetQtyRange,TargetWasteRange,[Allowance=5])` |
| [S_FUNC_PACK_MULTI_v2_8.bas](S_FUNC_PACK_MULTI_v2_8.bas) | `=PACK_MULTI_v2_8(ValueRange,QtyRange,targetRange,TargetQtyRange,TargetWasteRange,[Allowance=5],[MaxSearchNodes=50000])` |
| [S_FUNC_PACK_MULTI_v3_1.bas](S_FUNC_PACK_MULTI_v3_1.bas) | `=PACK_MULTI_v3_1(ValueRange,QtyRange,targetRange,TargetQtyRange,TargetWasteRange,[MaxItemsPerStock=8],[Allowance=5],[MaxSearchNodes=50000])` — wrapper ที่เรียก `PACK_MULTI_v3_2` ซึ่ง **ไม่มีไฟล์ต้นทางในโฟลเดอร์นี้** |

| Argument | ความหมาย |
| --- | --- |
| `ValueRange` | ความยาว/ขนาดของชิ้นงาน |
| `QtyRange` | จำนวนชิ้นงานแต่ละขนาด |
| `targetRange` | ความยาว/ขนาดวัสดุต้นทางที่มีให้เลือก |
| `TargetQtyRange` | จำนวนวัสดุต้นทางแต่ละขนาด |
| `TargetWasteRange` | ค่าความสูญเสีย/เผื่อตัดที่สัมพันธ์กับวัสดุต้นทางแต่ละขนาด |
| `Allowance` | ค่าเผื่อเพิ่มเติม; ค่าเริ่มต้น `5` |
| `MaxSearchNodes` | เพดานจำนวนจุดค้นหาต่อวัสดุต้นทาง; v2_8 และ wrapper v3_1 เท่านั้น |
| `MaxItemsPerStock` | จำนวนชิ้นงานสูงสุดต่อวัสดุหนึ่งชิ้น; wrapper v3_1 เท่านั้น |

คู่ `ValueRange`/`QtyRange` และชุด `targetRange`/`TargetQtyRange`/`TargetWasteRange` ต้องเรียงแถวให้สัมพันธ์กัน; v2_8 รองรับสูงสุด 8 ชิ้นต่อวัสดุและเตรียมคอลัมน์ `Item1`–`Item40` ในผลลัพธ์ ตัวอย่าง `=PACK_MULTI_v2_8(A2:A20,B2:B20,D2:D5,E2:E5,F2:F5,5,50000)`

### `PACK_SUMMARY` — สรุปผลจาก PACK_MULTI

| ไฟล์ | สูตร / argument |
| --- | --- |
| [PACK_SUMMARY_v2_7.bas](PACK_SUMMARY_v2_7.bas) | `=PACK_SUMMARY_v2_7(ResultRange,SourceLengthRange,SourceQtyRange)` |
| [S_FUNC_SUMMARY_v2_9.bas](S_FUNC_SUMMARY_v2_9.bas) | `=PACK_SUMMARY_v2_9(ResultRange,SourceLengthRange,SourceQtyRange,[ItemListRowOffset=18])` |
| [S_FUNC_SUMMARY_v2_10.bas](S_FUNC_SUMMARY_v2_10.bas) | `=PACK_SUMMARY_v2_10(ResultRange,SourceLengthRange,SourceQtyRange,[ItemListRowOffset=18])` — รองรับผล v2_8 ที่มี `Item1`–`Item40` และค้นหาคอลัมน์จากชื่อ header |
| [S_FUNC_SUMMARY_v3_1.bas](S_FUNC_SUMMARY_v3_1.bas) | `=PACK_SUMMARY_v3_1(ResultRange,SourceLengthRange,SourceQtyRange,[ItemListRowOffset=18])` — wrapper ที่เรียก `PACK_SUMMARY_v3_2` ซึ่ง **ไม่มีไฟล์ต้นทางในโฟลเดอร์นี้** |

`ResultRange` คือผลลัพธ์รวม header จาก `PACK_MULTI`; `SourceLengthRange` คือขนาดวัสดุต้นทาง; `SourceQtyRange` คือจำนวนแต่ละขนาด ทั้งสองช่วงหลังต้องมีจำนวนเซลล์เท่ากัน; `ItemListRowOffset` คือระยะห่างของส่วนรายการชิ้นงานในตารางสรุป ตัวอย่าง `=PACK_SUMMARY_v2_10(H2:BB200,D2:D5,E2:E5,18)` (ปรับช่วงผลลัพธ์จริงให้ครอบคลุม header และข้อมูลทั้งหมด)

### `PairSumProbability` — [EXCEL/PairSumProbability.bas](EXCEL/PairSumProbability.bas)

`=PairSumProbability(DataRange)` อ่านตัวเลขตัวแรกจากแต่ละเซลล์ที่ใช้ได้ จับทุกคู่แบบไม่ซ้ำตำแหน่ง แล้วคืนตาราง 3 คอลัมน์: ผลบวก, จำนวนคู่, ความน่าจะเป็น ต้องมีตัวเลขอย่างน้อย 2 ค่า ตัวอย่าง `=PairSumProbability(A2:A20)`

## 5. Macro (ไม่มี argument ในวงเล็บ)

Macro เหล่านี้ใช้ชีต/เซลล์ที่เปิดหรือเลือกอยู่ จึงควรตรวจสถานะก่อนรัน

| ไฟล์ | Macro | สิ่งที่ใช้หรือเปลี่ยน |
| --- | --- | --- |
| [A_PUBS_HighlightListedNumbers.bas](A_PUBS_HighlightListedNumbers.bas) | `HighlightListedNumbersInColumnA()` | เลือกเซลล์ที่มีเลขจำนวนเต็มหลายตัว (คั่น comma, semicolon, ช่องว่าง หรือขึ้นบรรทัด); ไฮไลต์แถวที่คอลัมน์ A ตรงกับเลข |
| [A_PUBS_NumberSelectedTextTopDown.bas](A_PUBS_NumberSelectedTextTopDown.bas) | `NumberSelectedTextTopDown()` | เลือกช่วง 1 คอลัมน์; แทนข้อความที่ไม่ว่างด้วยเลข 1, 2, 3... จากบนลงล่าง; เว้นค่าว่าง/ตัวเลขเดิม |
| [A_PUBS_SET_PRINT_A4_LANDSCAPE.bas](A_PUBS_SET_PRINT_A4_LANDSCAPE.bas) | `SetPrintA4Landscape_ActiveSheet()` | ตั้งค่าพิมพ์ชีตปัจจุบัน A4 แนวนอน; พื้นที่พิมพ์ `A1:V45`, พอดี 1 หน้า |
| [A_PUBS_SET_PRINT_A4_LANDSCAPE.bas](A_PUBS_SET_PRINT_A4_LANDSCAPE.bas) | `SetPrintA4Landscape_AllSheets()` | ตั้งค่าแบบเดียวกันกับทุกชีตในไฟล์ |
| [A_PUBS_ToggleFormulaPrefix.bas](A_PUBS_ToggleFormulaPrefix.bas) | `ToggleFormulaPrefix()` | สลับสูตรกับข้อความที่ขึ้นต้น `=` ที่ **AM2 ของชีตปัจจุบันเท่านั้น**; ไม่ได้ใช้เซลล์ที่เลือก |
| [EXCEL/Copy_X_AA_AllSheets_To_SUM_BK1.bas](EXCEL/Copy_X_AA_AllSheets_To_SUM_BK1.bas) | `Copy_X_AA_AllSheets_To_SUM_BK1()` | รวม X:AA จากทุกชีตลงชีต `SUM BK1`; ชื่อชีตใน A, ข้อมูลใน B:E; ล้างและ unmerge A:E เดิมก่อนลงข้อมูล |
| [Format_Blank_NonBlank.bas](Format_Blank_NonBlank.bas) | `ApplyBlankNonBlankFormatting()` | เพิ่ม Conditional Formatting เส้นล่างต่างกันสำหรับเซลล์ว่าง/ไม่ว่างทั้งชีตปัจจุบัน |
| [Format_Blank_NonBlank.bas](Format_Blank_NonBlank.bas) | `DeleteAllConditionalFormattingFromActiveSheet()` | ลบ **ทุก** กฎ Conditional Formatting ในชีตปัจจุบันหลังยืนยัน |
| [S_PUBS_EXPORT-PDF_FOR_CE-02.bas](S_PUBS_EXPORT-PDF_FOR_CE-02.bas) | `TA_T_PDFActiveSheet()` | ส่งออกชีตปัจจุบันเป็น PDF ชื่อตามไฟล์ workbook |
| [S_PUBS_EXPORT-PDF_FOR_CE-02.bas](S_PUBS_EXPORT-PDF_FOR_CE-02.bas) | `TA_T_OVL_PDFActiveSheet()` | ส่งออกชีตปัจจุบันเป็น PDF ต่อท้ายชื่อ `_OVL` |
| [S_PUBS_EXPORT-PDF_FOR_CE-02.bas](S_PUBS_EXPORT-PDF_FOR_CE-02.bas) | `TA_T_PROJECT_SAMPLE_PDFActiveSheet()` | ส่งออกชีตที่เลือกเป็น PDF; ชื่อเริ่มต้นจาก `T1_D1_C4` ของชีตปัจจุบัน และมีหน้าต่างเลือกที่บันทึก |

## 6. ไฟล์ทดสอบ

ไฟล์ต่อไปนี้ใช้ตรวจการทำงานของฟังก์ชัน ไม่ต้องนำเข้าเมื่อต้องการใช้สูตรทั่วไป ทั้งสามตัวเป็น VBA `Function` ที่คืนข้อความ PASS/FAIL ไม่ใช่ `Sub` macro ในรายการ `Alt+F8`; เรียกจาก VBA Immediate Window ได้ เช่น `? RunCountUniqueV6Tests()`

| ไฟล์ | Function ทดสอบ (ไม่มี argument) |
| --- | --- |
| [tests/countunique_v6/Test_CountUnique_V6.bas](tests/countunique_v6/Test_CountUnique_V6.bas) | `RunCountUniqueV6Tests()` |
| [tests/csvfield_rev03/Test_CSVFIELD_REV03.bas](tests/csvfield_rev03/Test_CSVFIELD_REV03.bas) | `RunCsvFieldRev03Tests()` |
| [tests/sumunique_v6/Test_SumUnique_V6.bas](tests/sumunique_v6/Test_SumUnique_V6.bas) | `RunSumUniqueV6Tests()` |

## จุดที่ควรจำ

- `COUNTUNIQUE_V6` กับ `SUMUNIQUE_V6` รับ `Heading,IncludeEmpty` เป็นสอง argument แรก; `SUMUNIQUE_V6` รับ `SumRange` เป็น argument ที่ 3
- `TRUE/FALSE` ของ `COUNTUNIQUE_V4/V5` ควบคุมการแสดง **คอลัมน์ที่ไม่มีจำนวน** ไม่ได้เปลี่ยนข้อมูลต้นฉบับ
- `HEADINGDETAILTABLE` ต้องรวมคอลัมน์ทั้งหมดที่อยากเห็นใน `HeadingRange`; คอลัมน์แรกของผลลัพธ์เป็นเลขลำดับ heading
- `copyallsheet_v4` ใช้พิกัดข้อความร่วมกับลำดับแท็บชีต; หากเปลี่ยนลำดับแท็บ ให้ตรวจชุดชีตที่สูตรดึงอีกครั้ง
- ชุด `PACK_*_v3_1` เป็นเพียงตัวเรียกต่อไปยัง v3_2; โฟลเดอร์นี้ยังไม่มี v3_2 จึงใช้งานเดี่ยว ๆ ไม่ได้
