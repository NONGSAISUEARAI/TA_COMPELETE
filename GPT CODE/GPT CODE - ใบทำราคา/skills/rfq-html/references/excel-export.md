# ส่งออก HTML ลง Excel template

ปุ่ม `#save-excel` สร้าง XLSX จากข้อมูลที่แก้ใน HTML ขณะกด ไม่ต้องใช้เซิร์ฟเวอร์หรือ Excel ที่ติดตั้งอยู่ ต้นแบบเดิมไม่ถูกเขียนทับ

ต้นแบบ Excel ที่ผู้ใช้ยืนยัน:
`C:/TA/TA_COMPELETE/GPT CODE/GPT CODE - ใบทำราคา/ฟอร์มกลาง/BU2-DE-26xxx_โครงการ นี่คือtemplae.xlsx`

HTML ฝังไฟล์ต้นฉบับแบบ base64 ใน `#excel-template-data` พร้อม SHA-256 ฝัง JSZip พร้อม license ใน `#excel-export-library` และกลไกใน `#rfq-excel-export` ต้องคงทั้งสามส่วนเมื่อบันทึก HTML หรือสร้างงานใหม่จาก master

ต้นฉบับมี 6 ชีต แต่ใช้ชีตแรก `1` เป็นฟอร์มแล้วทำสำเนาตามจำนวนหน้า HTML เท่านั้น ชีตอื่นในไฟล์ต้นฉบับไม่ใช่ข้อมูลของงานใหม่ ชื่อชีตเป็น `1`, `2`, ... ใช้ฐานชื่อเดียวกับ HTML/PDF และลงท้าย `.xlsx`

## ตำแหน่งข้อมูล

- ตารางหลัก: HTML 20 แถวต่อหน้า → Excel แถว 7–26; แถว 27 เว้นว่าง
- ตารางล่าง: แถว 31–41
- หัวเอกสาร: `documentNo=Z1`, `job=Z2`, `project=C2`, `customer=C3`, `dueDay=V3`, `dueMonth=W3`, `dueYear=X3`, `requester=C43`, `requestDate=C44`, `pageNumber=Z45`
- ช่องผู้อนุมัติ/ผู้ให้ราคาเดิมที่ไม่มีข้อมูลใน HTML ให้เว้นว่าง ไม่เก็บค่าตัวอย่างจากต้นแบบ

| ฟิลด์ | คอลัมน์ Excel |
| --- | --- |
| no, description | A, B |
| materialCode, material | E, G |
| thickness, special | I, J |
| width, height, length | K, L, M |
| cc, sp, pc, acp, otherCoat | N, O, P, Q, R |
| specialColor, paintType, brand | S, T, U |
| sides, qty, unit, cost, remark | V, W, X, Y, Z |

จำนวน/ขนาด/ราคาเป็น numeric cells เมื่อเป็นตัวเลข ช่องว่างต้องคงว่างและจำนวน 0 ต้องคง 0 ข้อความใช้ inline strings จึงไม่กลายเป็นสูตรจากอักขระนำหน้า

ชื่อวัสดุ G และ density F ใช้ VLOOKUP แบบ exact match พร้อม blank guard โดยอ้างตารางรหัส AE50:AG86 พร้อม cached values และตั้งคำนวณสูตรเมื่อเปิด Excel ผู้ส่งออกตรวจว่าชื่อจาก `model.materials` ตรงกับ Excel ต้นแบบก่อนสร้างไฟล์ เปลี่ยนรหัสวัสดุใน Excel แล้วชื่อจึงเปลี่ยนตามได้

## สิ่งที่ต้องรักษา

- แก้ OOXML ภายใน ZIP โดยรักษา styles, merged cells, ความกว้างคอลัมน์ ความสูงแถว โลโก้ drawing, VML, ctrlProps, validation และ printer settings; การนำเข้าแล้ว export ผ่าน artifact-tool ที่ทดสอบกับไฟล์นี้ทำให้ native form controls สูญหาย
- คง A4 แนวนอนและ print area `A1:Z45` ตาม Excel ต้นแบบ ไม่เปลี่ยนตาม Letter ของ HTML/PDF
- แถว description ที่มีข้อมูลใช้ style เดียวกับ B7 เพื่อไม่รับฟอนต์ใหญ่/wrap จากแถวว่างท้ายต้นแบบ ขนาดแถว/คอลัมน์ไม่เปลี่ยน
- Native checkbox ทั้ง 8 ช่องต่อชีตต้องอ้าง drawing/VML/ctrlProps ถูกต้อง และใช้ shape IDs แยกกันทั้ง workbook รวม label ด้วย สำเนาแต่ละชีตเพิ่ม ID block 1024 และแก้ compatExt spid/idmap ให้ตรงกัน
- ช่องที่ไม่ติ๊กให้ลบ attribute `checked` จาก ctrlProps; ใช้ `checked="Checked"` เฉพาะที่ติ๊ก การเขียน `checked="Unchecked"` ทำให้ Excel ที่ใช้ตรวจปฏิเสธไฟล์
- ถ้าเปลี่ยนต้นแบบ ให้ตรวจ mapping ใหม่และฝังต้นฉบับใหม่ อย่านำข้อมูลรายการหรือสถานะช่องติ๊กของตัวอย่างมาเป็นค่าเริ่มต้น

ตรวจทั้งจำนวนชีต ข้อมูลทุกช่อง ผลรวม สูตร และช่องติ๊กของทุกหน้า รวมกรณีเพิ่มหน้า/แก้จำนวน/เปลี่ยนรหัสวัสดุ หากแก้ package mechanics ให้เปิดตรวจด้วย Excel จริงใน instance แยกและไฟล์สำเนา พร้อมตรวจภาพหน้าพิมพ์ อย่าแตะ workbook งานอื่นที่ผู้ใช้เปิดอยู่
