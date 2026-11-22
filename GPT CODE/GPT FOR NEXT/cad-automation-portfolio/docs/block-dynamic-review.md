# Block / Dynamic Block — รายการพิจารณาสำหรับพอร์ต

> อัปเดตหลังตรวจเชิงลึก: อ่าน [รายงาน source audit](block-static-audit.md) ประกอบ รายการนี้เป็น shortlist เบื้องต้น ไม่ใช่สถานะ Ready โดยเฉพาะ Reblock/reblock2/reblock3 ควรพักก่อนแก้และทดสอบ ส่วน Match Attributes ควรเพิ่มเป็นตัวหลักที่พิจารณา

วันที่ตรวจ: 11 ตุลาคม 2026

ต้นฉบับ: `C:\TA\TA_COMPELETE\z00x_TA_standard_sun_func_and_MAIN.lsp`

ตรวจด้วยการอ่าน source ปัจจุบันเท่านั้น ไม่ได้รันหรือแก้ AutoLISP รายการต่อไปนี้เป็นข้อเสนอให้เลือกรายคำสั่ง ไม่ใช่การรับรองว่าใช้งานได้ครบหรือการอนุมัติเผยแพร่

## คำสั่งทั่วไปที่ควรพิจารณาก่อน

ชื่อด้านล่างเป็นชื่อที่ตามหลัง `c:` ใน definition จริง เช่นชื่อเต็มคือ `c:matching_dynamic_properties_madynprop` ชื่อท้ายแบบ `madynprop` หรือ `RENB3x` ยังไม่ถือว่าเป็น alias ที่เรียกได้ จนกว่าจะตรวจการประกาศ alias เพิ่มเติม

| ชื่อคำสั่งจริง | ชื่อผลงานไทย / English ที่เสนอ | หลักฐานหน้าที่ | บรรทัดเริ่มต้น | GIF ที่เหมาะ |
|---|---|---|---:|---|
| `matching_dynamic_properties_madynprop` | จับคู่คุณสมบัติ Dynamic Block / Match Dynamic Block Properties | อ่าน `LM:getdynprops` จาก block อ้างอิง และส่งค่าไปยังเป้าหมายผ่าน `LM:setdynpropvalue`; ข้าม property ชื่อ `Origin` | 18348 | ตั้งความยาว/visibility ของต้นแบบ แล้วถ่ายทอดค่าไปยังหลาย block |
| `Replace_block_object_Reblock` | แทนที่ Block หลายรายการ / Batch Block Replacement | กรอง effective name ของ block เดิม, แทรก block เป้าหมายที่ insertion point/rotation เดิม แล้วลบรายการเดิม; มีช่วงปรับ rotation ต่อ | 5221 | เปลี่ยนสัญลักษณ์เดิมหลายตัวเป็นสัญลักษณ์ใหม่ |
| `rename_block_RENBLKV2_RENB3x` | เปลี่ยนชื่อ Block จากข้อความ / Rename Block from Text | เลือก TextString ชื่อเดิม/ใหม่, หา block definition ด้วย `vla-Item`, เปลี่ยนชื่อด้วย `vla-put-Name`; จับข้อผิดพลาดตอนหาและเปลี่ยนชื่อ | 11419 | เลือกข้อความชื่อเดิมและชื่อใหม่ แล้วแสดงชื่อ block หลังเปลี่ยน |
| `select_dynamic_block_seldyn` | เลือกเฉพาะ Dynamic Block / Select Dynamic Blocks | คัด block ในชุดเลือกที่ `IsDynamicBlock` เป็น true แล้วส่งชุดผลลัพธ์ให้ `pselect` | 51869 | เลือก block แบบผสม แล้วเน้นเฉพาะ dynamic blocks |
| `select_not_dynamic_block_` | เลือกเฉพาะ Block ปกติ / Select Non-Dynamic Blocks | คัด block ในชุดเลือกที่ `IsDynamicBlock` ไม่เป็น true | 51915 | ใช้ชุดตัวอย่างเดียวกับคำสั่งเลือก dynamic เพื่อแสดงความแตกต่าง |
| `allow_explode_block_ALEX` | อนุญาตให้ Explode Block / Enable Block Exploding | อ่าน effective name และเรียก `TA:set-block-explodable` ซึ่งเขียน `Explodable` ของ block definition เป็น true | 4363 | แสดงสถานะก่อนและหลังเปิดให้ explode |
| `TA_SET_ALL_BLOCK_UNITS_MM` | ตั้งหน่วยแทรก Block เป็นมิลลิเมตร / Set Block Insertion Units to Millimeters | ตั้ง `INSUNITS` เป็น 4 และ `Units` ของ block definitions เป็น 4; ข้าม Layout/Xref และรายการที่ไม่รองรับ พร้อมสรุปจำนวน | 65145 | แสดงหน่วย block เดิมและผลการตั้งหน่วยหลาย definitions |

## จุดตรวจความพร้อมที่เห็นจาก source

- **Match Dynamic Properties:** ใช้ `_StartUndo`, `_EndUndo`, `doc` และ LM:/TA: helpers; เงื่อนไขให้ effective name ต้นแบบ/เป้าหมายเท่ากันถูก comment ไว้ ต้องตรวจชื่อ/ชนิด/read-only/allowed values ของ property และการยกเลิกคำสั่งก่อนทำ demo
- **Replace Block:** ตอนแทรกใช้ scale `1` และไม่พบการถ่าย attribute/dynamic values ในตัวคำสั่งนี้ จึงยังไม่ควรอธิบายว่าเก็บคุณสมบัติเดิมครบทุกอย่าง; คืน `OSMODE` เป็นค่าตายตัว `1279` แทนการคืนค่าก่อนเริ่ม
- **Rename from Text:** มี local variables และการจับข้อผิดพลาด แต่ยังต้องตรวจว่า object ที่เลือกมี `TextString` และทดสอบกรณีชื่อชนกัน/ชื่อไม่ถูกต้อง
- **Dynamic/Non-Dynamic Selection:** ตรวจกรณีไม่มีการเลือกและไม่มีผลลัพธ์; เป็น demo ที่ขอบเขตแคบกว่าการแก้ block
- **Enable Exploding:** แก้ที่ block definition ซึ่ง references ใช้ร่วมกัน; ไม่ได้สั่ง explode โดยตรง และ helper ปัจจุบันตั้ง true แม้มี argument `allow-exploding`
- **Set Units:** เปลี่ยนข้อมูลหน่วยสำหรับการแทรก ไม่ได้คูณพิกัดหรือย่อ/ขยาย geometry ที่มีอยู่ จึงไม่ควรใช้คำอธิบายว่าแปลงแบบจากเมตรเป็นมิลลิเมตร

## รายการที่ยังต้องพิจารณาแยก

| คำสั่ง / ชุดคำสั่ง | หลักฐานและเหตุผลที่ยังไม่จัดเป็นตัวหลัก |
|---|---|
| `MKblk` | สร้าง block จากวัตถุที่เลือก ตั้งชื่อจาก DWG และ suffix; มีการใช้ `doc`, helper และ branch ลบ definition เดิม ต้องตรวจการจัดการชื่อซ้ำ/สถานะเอกสารก่อนเลือก |
| `BasePoint_to_BasePoint_[B2B]` | เนื้อโค้ดย้าย references ด้วย `vla-move` ตามจุดอ้างอิง; อย่าตีความจากชื่อว่าแก้ base point ของ definition ก่อนตรวจ workflow ทั้งหมด |
| `ADD_VISIBILITY_multi-mode_ADVSM_` | สร้าง visibility parameter/states ใน Block Editor แต่ preset ผูกกับ screw, U-profile, bolt และ cutting plan; โหมด copy อ่าน property ชื่อ `view` โดยตรง |
| `dynamic_rewidth_array_1_rew1` และ variants | ตรวจชื่อ action `ARRAY_MAIN` และ property `array_width` โดยตรง ต้องมี block/action schema ที่ตรงกัน |
| `dynamic_update_U-Carrier_[UCupdate]` | อ่าน properties ของ U-carrier เช่น `total_u-profile_depth`, `u-profile_width_set` และ `Position1 Y`; เป็นงานเฉพาะชิ้นส่วน |
| `DynBlk_make_thread-bolt_mktbolt` | แทรก block ชื่อ `000 - PROTOTYPE-DYNAMIC_THREAD_BOLT` และแก้ properties เฉพาะ bolt |
| `RECTANGLE_TO_BLOCK_REC-TO-BLK` | เลือก LWPOLYLINE สี 3 และแทรก block ชื่อ `010 - C10_PANEL_PANEL_GREEN_PLATE_SET-B-BOT-VIEW`; ชื่อดูทั่วไปแต่การทำงานผูกกับ panel เฉพาะงาน |

รายการเฉพาะทางในหมวด Block ไม่ได้ถูกตัดออกโดยอัตโนมัติตามมติ PPLINE จึงคงไว้เป็นรายการให้ผู้ใช้พิจารณาเพิ่มเติม

## ลำดับการคัดเลือกที่เสนอ

หลังตรวจทางเดินเชิงลึก ให้เริ่มพิจารณา Match Dynamic Properties, Match Attributes และ Rename Block from Text แล้วใช้คู่ Dynamic/Non-Dynamic Selection เป็น demo สั้นเพิ่มเติม **Batch Block Replacement ยังไม่ใช่ตัวพร้อมทำ demo/แจกไฟล์** เพราะพบความเสี่ยงต่อข้อมูลเดิม ดูหลักฐานในรายงาน source audit สถานะการใช้จริงและสิทธิ์เผยแพร่ยังรอการตัดสินของผู้ใช้
