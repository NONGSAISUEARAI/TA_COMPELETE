const sharp=require('sharp');
(async()=>{
const input='tmp/pdfs/wage_refund_edit/clean_body.png';
const m=await sharp(input).metadata();
const sx=m.width/991,sy=m.height/1403;
const logo=await sharp(input).extract({left:Math.round(120*sx),top:Math.round(65*sy),width:Math.round(190*sx),height:Math.round(42*sy)}).rotate(-0.7,{background:'#fff'}).png().toBuffer();
const text=(x,y,s,size=16)=>`<text x="${x}" y="${y}" font-size="${size}">${s}</text>`;
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${m.width}" height="${m.height}" viewBox="0 0 991 1403"><rect x="70" y="40" width="835" height="280" fill="white"/><rect x="60" y="1210" width="870" height="160" fill="white"/><g font-family="Tahoma" fill="#181818">
${text(105,205,'ลำดับ.......................................')}
${text(638,216,'วันที่ 4 พฤศจิกายน พ.ศ. 2569',14.5)}
${text(105,260,'เรียน ฝ่ายบริหารทรัพยากรบุคคล')}
${text(105,291,'เรื่อง เอกสารขอเงินคืนครั้งที่ 2')}
${['FAMELINE PRODUCTS CO., LTD.','36/11 Kanchanaphisek Road,','Dokmai, Prawet, Bangkok','10250 Thailand','T +662 365 5899','F +662 365 5890','info@fameline.com','fameline.com'].map((s,i)=>text(565,89+i*12,s,10)).join('')}
${['COMPOSITE','CEILING','LOUVER','SUNART','SOLID','TEXTILE'].map((s,i)=>text(760,91+i*16,s,13)).join('')}
${text(90,1260,'หมายเหตุ : อ้างอิงประกาศฉบับที่ 005 / 2563 การขอคืนสิทธิ์รับค่าจ้าง หากตรวจพบว่าพนักงานมีการทำผิดซ้ำติดต่อกันตั้งแต่',13)}
${text(160,1291,'3 ครั้งขึ้นไป ขอสงวนสิทธิ์ไม่ทำจ่ายคืน',13)}
</g><line x1="638" y1="224" x2="865" y2="224" stroke="#777" stroke-width="0.65" stroke-dasharray="2 3"/></svg>`;
await sharp(input).composite([{input:Buffer.from(svg)},{input:logo,left:Math.round(120*sx),top:Math.round(65*sy)}]).png().toFile('tmp/pdfs/wage_refund_edit/straight_all.png');
})();
