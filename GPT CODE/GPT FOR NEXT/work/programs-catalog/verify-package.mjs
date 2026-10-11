import {readFile,writeFile} from 'node:fs/promises';
import {webcrypto,createHash} from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root='C:/TA/TA-PORTFOLIO';
const staging=path.dirname(fileURLToPath(import.meta.url));
const payload=await readFile(path.join(root,'publish/js/encrypted-portfolio.js'),'utf8');
const data=JSON.parse(payload.match(/Object\.freeze\((\{[\s\S]+\})\);/)[1]);
let password=JSON.parse(await readFile(path.join(root,'private/access-key.json'),'utf8')).password;
const encoder=new TextEncoder(),secretBytes=encoder.encode(password);
const material=await webcrypto.subtle.importKey('raw',secretBytes,'PBKDF2',false,['deriveKey']);secretBytes.fill(0);
const key=await webcrypto.subtle.deriveKey({name:'PBKDF2',salt:Buffer.from(data.salt,'base64'),iterations:data.iterations,hash:'SHA-256'},material,{name:'AES-GCM',length:256},false,['decrypt']);password='';
const plaintext=new Uint8Array(await webcrypto.subtle.decrypt({name:'AES-GCM',iv:Buffer.from(data.iv,'base64'),additionalData:encoder.encode('TA-PORTFOLIO:1'),tagLength:128},key,Buffer.from(data.ciphertext,'base64')));
const html=new TextDecoder().decode(plaintext);plaintext.fill(0);
if(!html.includes('<title>Programs — TA AutoLISP Collection</title>')||!html.includes('Data & Reporting')||html.includes('Match Dynamic<br>Properties'))throw new Error('Wrong after-login document');
const parent=await readFile(path.join(root,'publish/index.html'),'utf8');
for(const [tag,directive] of [['script','script-src'],['style','style-src']]){
  const bytes=html.match(new RegExp(`<${tag}>([\\s\\S]*?)<\\/${tag}>`))[1];
  const hash=createHash('sha256').update(bytes).digest('base64');
  if(!parent.match(new RegExp(`${directive}[^;]*`))[0].includes(`'sha256-${hash}'`))throw new Error(`${directive} CSP hash mismatch`);
}
const checks=JSON.parse(await readFile(path.join(root,'private/build-checks.json'),'utf8'));
if(checks.sourceSha256!==createHash('sha256').update(html).digest('hex')||!checks.roundTrip||!checks.wrongPasswordRejected||!checks.tamperRejected)throw new Error('Package validation mismatch');
// QA-only: render the exact decrypted document under the real parent's CSP and
// iframe sandbox. No password is stored, displayed or supplied to a browser form.
const escaped=html.replaceAll('&','&amp;').replaceAll('"','&quot;').replaceAll('<','&lt;').replaceAll('>','&gt;');
const csp=parent.match(/<meta http-equiv="Content-Security-Policy"[^>]+>/)[0];
const fixture=`<!doctype html><html lang="th"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">${csp}<title>QA — Programs after unlock</title><link rel="stylesheet" href="publish/css/login.css"></head><body><section class="portfolio-view"><header class="viewer-bar"><span>TA / PORTFOLIO — QA OF DECRYPTED DOCUMENT</span><span>LOCAL TEST ONLY</span></header><iframe id="portfolio-frame" title="Programs" sandbox="allow-scripts" referrerpolicy="no-referrer" srcdoc="${escaped}"></iframe></section></body></html>`;
await writeFile(path.join(staging,'qa-unlocked.html'),fixture,'utf8');
console.log('Verified: encrypted document is Programs; source digest, CSP hashes, round-trip, wrong-password and tamper checks pass. QA-only sandbox preview generated. No credentials printed.');
