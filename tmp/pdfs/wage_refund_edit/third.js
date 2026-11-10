const sharp=require('sharp');
(async()=>{
const input='tmp/pdfs/wage_refund_edit/new_source.png';
const m=await sharp(input).metadata();
const t=(x,y,s,size=19)=>`<text x="${x}" y="${y}" font-size="${size}">${s}</text>`;
const line=(x,y,x2)=>`<line x1="${x}" y1="${y}" x2="${x2}" y2="${y}" stroke="#888" stroke-width="0.8" stroke-dasharray="2 4"/>`;
const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="${m.width}" height="${m.height}" viewBox="0 0 1240 1754">
<rect x="785" y="265" width="295" height="43" fill="white"/>
<rect x="145" y="350" width="440" height="38" fill="white"/>
<rect x="145" y="499" width="930" height="45" fill="white"/>
<rect x="145" y="565" width="930" height="163" fill="white"/>
<rect x="350" y="1066" width="278" height="211" fill="white"/>
<rect x="700" y="925" width="320" height="51" fill="white"/>
<g font-family="Tahoma" fill="#181818">
${t(791,289,'วันที่ 10 พฤศจิกายน พ.ศ. 2569',17)}
${t(153,377,'เรื่อง เอกสารขอเงินคืนครั้งที่ 3')}
${t(153,525,'ของงวดค่าจ้างประจำเดือน กันยายน พ.ศ. 2569')}
${t(153,597,'เนื่องจากข้าพเจ้าบันทึกวันลาพักร้อนในระบบคลาดเคลื่อน โดยวันที่ลาพักร้อนจริงคือ')}
${t(153,634,'วันที่ 7-11 กันยายน พ.ศ. 2569 แต่บันทึกเป็นวันที่ 7-11 พฤศจิกายน พ.ศ. 2569')}
${t(153,671,'ส่งผลให้ข้าพเจ้าถูกหักค่าจ้างประจำเดือนกันยายน พ.ศ. 2569 เป็นจำนวนเงินทั้งสิ้น 5,464 บาท')}
${t(365,1251,'(........................................)',18)}
</g>
${line(791,300,1060)}${line(153,536,1060)}
${[610,647,684,721].map(y=>line(153,y,1060)).join('')}
${line(365,1186,578)}
${line(735,966,1012)}
</svg>`;
await sharp(input).composite([{input:Buffer.from(svg)}]).png().toFile('tmp/pdfs/wage_refund_edit/third.png');
})();
