import path from "node:path";
import { createWorker } from "tesseract.js";
import sharp from "sharp";

const imagePath = path.resolve("tmp/pdfs/merged10_hi/page001.png");
const image = await sharp(imagePath).rotate(90).grayscale().normalize().png().toBuffer();
const worker = await createWorker("eng", 1, {
  logger: (message) => console.error(message.status, message.progress ?? ""),
});
await worker.setParameters({
  tessedit_char_whitelist: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.-+/(): ",
  preserve_interword_spaces: "1",
});
const result = await worker.recognize(image);
console.log(result.data.text);
await worker.terminate();
