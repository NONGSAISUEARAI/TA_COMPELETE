import fs from "node:fs";
import path from "node:path";
import { createScheduler, createWorker } from "tesseract.js";
import sharp from "sharp";


const root = path.resolve("tmp/pdfs");
const imageDir = path.join(root, "merged10_240");
const outputPath = path.join(root, "merged10_ocr.ndjson");
const scheduler = createScheduler();

for (let i = 0; i < 4; i += 1) {
  const worker = await createWorker("eng", 1, { logger: () => {} });
  await worker.setParameters({
    preserve_interword_spaces: "1",
    user_defined_dpi: "240",
  });
  scheduler.addWorker(worker);
}

const images = fs.readdirSync(imageDir)
  .filter((name) => /^page-\d+\.jpg$/.test(name))
  .sort();

const jobs = images.map(async (name) => {
  const page = Number(name.match(/\d+/)[0]);
  const input = path.join(imageDir, name);
  const image = await sharp(input)
    .rotate(90)
    .grayscale()
    .normalize()
    .sharpen()
    .jpeg({ quality: 94 })
    .toBuffer();
  const result = await scheduler.addJob(
    "recognize",
    image,
    {},
    { text: true, tsv: true },
    `page-${page}`,
  );
  process.stderr.write(`${page} `);
  return { page, text: result.data.text, tsv: result.data.tsv };
});

const results = await Promise.all(jobs);
results.sort((a, b) => a.page - b.page);
fs.writeFileSync(outputPath, results.map((item) => JSON.stringify(item)).join("\n") + "\n");
await scheduler.terminate();
console.log(`\nWrote ${results.length} pages to ${outputPath}`);
