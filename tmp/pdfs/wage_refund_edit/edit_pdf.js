const fs = require('fs');
const sharp = require('sharp');

const input = process.argv[2];
const output = process.argv[3];

function esc(s) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

(async () => {
  const meta = await sharp(input).metadata();
  const W = 991, H = 1403;
  const svg = `
  <svg xmlns="http://www.w3.org/2000/svg" width="${meta.width}" height="${meta.height}" viewBox="0 0 ${W} ${H}">
    <style>
      .txt { font-family: Tahoma, "Leelawadee UI", sans-serif; fill: #171717; font-weight: 400; }
      .guide { stroke: #555; stroke-width: 0.8; stroke-dasharray: 2.5 2.5; }
    </style>

    <!-- Document date -->
    <rect x="626" y="193" width="242" height="34" fill="white"/>
    <line class="guide" x1="638" y1="222" x2="858" y2="222"/>
    <text class="txt" x="638" y="216" font-size="14.5">${esc('วันที่ 4 พฤศจิกายน พ.ศ. 2569')}</text>

    <!-- Request sequence number -->
    <rect x="297" y="267" width="24" height="29" fill="white"/>
    <text class="txt" x="302" y="289" font-size="15">2</text>

    <!-- Payroll month -->
    <rect x="276" y="383" width="214" height="36" fill="white"/>
    <line class="guide" x1="276" y1="416" x2="490" y2="416"/>
    <text class="txt" x="280" y="409" font-size="14.5">${esc('กันยายน พ.ศ. 2569')}</text>

    <!-- Reason paragraph -->
    <rect x="94" y="441" width="780" height="128" fill="white"/>
    <line class="guide" x1="96" y1="477" x2="865" y2="477"/>
    <line class="guide" x1="96" y1="507" x2="865" y2="507"/>
    <line class="guide" x1="96" y1="537" x2="865" y2="537"/>
    <line class="guide" x1="96" y1="567" x2="865" y2="567"/>
    <text class="txt" x="100" y="469" font-size="14.5">${esc('เนื่องจาก ข้าพเจ้า ลืมทำการลงบันทึกเวลา ทั้งที่ตัวเครื่องสแกนลายนิ้วมือและใบหน้า รวมไปถึง')}</text>
    <text class="txt" x="100" y="499" font-size="14.5">${esc('การลงเวลาในระบบคอมพิวเตอร์ เมื่อวันที่ 28-29 กันยายน พ.ศ. 2569 จำนวนทั้งสิ้น 2 วัน')}</text>
    <text class="txt" x="100" y="529" font-size="14.5">${esc('เป็นเหตุให้ข้าพเจ้าถูกตัดเงินเป็นจำนวนทั้งสิ้น 1,561 บาท')}</text>
  </svg>`;

  await sharp(input)
    .composite([{ input: Buffer.from(svg), top: 0, left: 0 }])
    .png({ compressionLevel: 9 })
    .toFile(output);
})();
