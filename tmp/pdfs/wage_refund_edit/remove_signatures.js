const sharp = require('sharp');

const input = process.argv[2];
const output = process.argv[3];

(async () => {
  const meta = await sharp(input).metadata();
  const W = 991, H = 1403;
  const svg = `
  <svg xmlns="http://www.w3.org/2000/svg" width="${meta.width}" height="${meta.height}" viewBox="0 0 ${W} ${H}">
    <style>
      .txt { font-family: Tahoma, "Leelawadee UI", sans-serif; fill: #171717; font-weight: 400; }
      .guide { stroke: #555; stroke-width: 0.8; stroke-dasharray: 2.5 2.5; }
    </style>

    <!-- Remove the requester's handwritten signature while retaining the typed name. -->
    <rect x="540" y="694" width="345" height="128" fill="white"/>
    <line class="guide" x1="590" y1="780" x2="824" y2="780"/>
    <text class="txt" x="707" y="805" font-size="13.5" text-anchor="middle">(............ตะวัน ไตรรัตน์............)</text>

    <!-- Remove the crossed-out department-head block and all handwritten approvals. -->
    <rect x="70" y="830" width="850" height="305" fill="white"/>

    <!-- Center the two remaining approval blocks as a group. -->
    <line class="guide" x1="280" y1="963" x2="460" y2="963"/>
    <line class="guide" x1="530" y1="963" x2="710" y2="963"/>
    <text class="txt" x="370" y="1017" font-size="13.5" text-anchor="middle">(........................................)</text>
    <text class="txt" x="620" y="1017" font-size="13.5" text-anchor="middle">(........................................)</text>
    <text class="txt" x="370" y="1092" font-size="14" text-anchor="middle">ผู้จัดการฝ่าย</text>
    <text class="txt" x="620" y="1092" font-size="14" text-anchor="middle">เจ้าหน้าที่ฝ่ายบุคคล</text>
  </svg>`;

  await sharp(input)
    .composite([{ input: Buffer.from(svg), top: 0, left: 0 }])
    .png({ compressionLevel: 9 })
    .toFile(output);
})();
