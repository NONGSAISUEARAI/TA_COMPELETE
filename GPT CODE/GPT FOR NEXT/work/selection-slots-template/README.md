# Selection Slots — UI template

เทมเพลต TH/EN สำหรับ Save / Load / Add / Remove โดยใช้พื้นหลังดาวโทนหน้าล็อกอิน ไม่ใช่หน้าที่มี password protection เอง เก็บนอก publish/ และยังไม่ได้เชื่อมกับพอร์ตที่เข้ารหัส ไม่เผยแพร่ GitHub ในรอบนี้

## ใช้งาน

เปิด index.html ผ่านเบราว์เซอร์ หรือเปิดผ่าน localhost เพื่อให้ Clipboard API ทำงาน ปุ่มเลือก GIF อ่านไฟล์เฉพาะในเครื่อง และแสดงด้วย Blob URL ไม่ส่งไฟล์ ไม่เขียนลงดิสก์ ไม่เก็บหลัง refresh

แต่ละคำสั่งมีภาพ preview ของตนเอง สลับแท็บกลับมาแล้วภาพยังอยู่จน refresh/ปิดหน้า ปุ่มขยายเปิดภาพเต็มกรอบ และปุ่มล้างยกเลิกภาพในเบราว์เซอร์ ใช้ GIF ที่มี header GIF87a/GIF89a และขนาดไม่เกิน 20 MB; validation นี้ไม่ใช่การตรวจความปลอดภัยของไฟล์ทั้งหมด

## ใส่ GIF จริงลงเว็บภายหลัง

1. เก็บภาพบันทึกจริงใน assets/gifs/ โดยแนะนำชื่อ save-selection.gif, load-selection.gif, add-selection.gif และ remove-selection.gif
2. ใน assets/template.js ตั้ง gifSrc ของคำสั่งนั้นเป็น เช่น assets/gifs/save-selection.gif ค่าเริ่มต้นว่าง จึงไม่เกิดลิงก์ภาพเสียเมื่อยังไม่มีไฟล์
3. กรอบสาธิตขนาด 16:10 ใช้ object-fit: contain ไม่ตัดภาพ หากอัตราส่วนอื่นจะมีพื้นที่ว่างรอบภาพ
4. ตรวจว่า GIF ไม่แสดงข้อมูลลูกค้า ชื่อไฟล์โครงการ หรือข้อมูลส่วนตัวก่อนเผยแพร่ หากต้องการ password protection ต้องรวม template และ media เข้ากับขั้นตอนเข้ารหัสเดิม ไม่ควรวาง GIF ที่ต้องการปกป้องเป็น URL สาธารณะโดยตรง

## ขอบเขตเนื้อหา

ชื่อสั้นบนแท็บเป็นป้าย workflow ไม่ใช่ command aliases ใช้ชื่อจริงจาก source ในกรอบ Command Overview ไม่ใส่ไฟล์ LSP, ผลทดสอบ CAD, GIF จริง หรือคำกล่าวอ้างด้านประสิทธิภาพ ไม่แก้ไขหรือรัน AutoLISP ต้นฉบับ

รายละเอียดอิงจากโค้ด 4 คำสั่งที่ผู้ใช้แนบ และ helper TA:combine_selection_set_ ในไฟล์หลัก Save/Load/Add/Remove ใช้ตัวแปร ssA–ssJ ร่วมกัน; Load เรียก helper ส่วนคำสั่งอื่นไม่พบ custom helper ภายนอก ชุดเลือกเก็บในหน่วยความจำ ไม่ใช่การบันทึก selection ลงไฟล์ ยังต้องแก้สถานะ ssG/Slot 10 ของ Save/Load และตรวจการเลือกว่างก่อนจัดเป็นรุ่นพร้อมใช้

ใช้แนวทาง Sites จัดการเล่า workflow พร้อมหลักฐาน แยก placeholder ชัดเจน และตรวจภาพหน้าเว็บในเครื่อง ไม่มี CDN, fonts ภายนอก, telemetry, network API, form submission หรือการเก็บไฟล์ที่เลือกด้วย browser storage ปุ่มหยุดดาวและ prefers-reduced-motion หยุดพื้นหลังดาว แต่ไม่สามารถหยุด animation ของ GIF ที่เลือกได้; ใช้ปุ่มล้างภาพหากต้องการหยุดดู GIF
