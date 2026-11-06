const sharp=require('sharp');
(async()=>{
const input='tmp/pdfs/wage_refund_edit/no_signatures_200.png';
const m=await sharp(input).metadata();
const lines=[
[105,351,'ข้าพเจ้า นาย ตะวัน ไตรรัตน์'],
[105,382,'รหัสพนักงาน 11350    ฝ่าย IP&EP Management    แผนก ฝ่ายบริหารโครงการ 1'],
[105,413,'ของงวดค่าจ้างประจำเดือน กันยายน พ.ศ. 2569'],
[105,475,'เนื่องจาก ข้าพเจ้าลืมทำการลงบันทึกเวลา ทั้งที่ตัวเครื่องสแกนลายนิ้วมือและใบหน้า'],
[105,506,'รวมไปถึงการลงเวลาในระบบคอมพิวเตอร์ เมื่อวันที่ 28-29 กันยายน พ.ศ. 2569'],
[105,537,'จำนวนทั้งสิ้น 2 วัน เป็นเหตุให้ข้าพเจ้าถูกตัดเงินเป็นจำนวนทั้งสิ้น 1,561 บาท'],
[105,599,'จึงเรียนมาเพื่อทราบ']
];
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${m.width}" height="${m.height}" viewBox="0 0 991 1403"><rect x="75" y="325" width="825" height="302" fill="white"/><rect x="540" y="655" width="345" height="45" fill="white"/><g font-family="Tahoma" font-size="16" fill="#181818">${lines.map(([x,y,t])=>`<text x="${x}" y="${y}">${t.replace(/&/g,'&amp;')}</text>`).join('')}<text x="707" y="680" text-anchor="middle" font-size="14">ขอแสดงความนับถือ</text></g><g stroke="#777" stroke-width="0.65" stroke-dasharray="2 3">${[359,390,421,483,514,545,576].map(y=>`<line x1="105" y1="${y}" x2="865" y2="${y}"/>`).join('')}</g></svg>`;
await sharp(input).composite([{input:Buffer.from(svg)}]).png().toFile('tmp/pdfs/wage_refund_edit/clean_body.png');
})();
