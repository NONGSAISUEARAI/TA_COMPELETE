import {readFile,writeFile,mkdir,copyFile} from 'node:fs/promises';
import {createHash,webcrypto} from 'node:crypto';
import {execFileSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root='C:/TA/TA-PORTFOLIO';
const stage=path.dirname(fileURLToPath(import.meta.url));
const builder=path.join(root,'tools/build-encrypted-portfolio.mjs');
const keyPath=path.join(root,'private/access-key.json');
const expected='587d58a5d4c4e82418d17143464bb6174271d59039f49b9241e33eb0cca72f97';
if(createHash('sha256').update(await readFile(builder)).digest('hex')!==expected)throw new Error('Builder changed since inspection; preserve and review first.');
const oldFiles=new Map();
for(const file of ['tools/build-encrypted-portfolio.mjs','private/access-key.json','private/build-checks.json','publish/index.html','publish/js/encrypted-portfolio.js'])oldFiles.set(file,await readFile(path.join(root,file)));
const oldKey=JSON.parse(oldFiles.get('private/access-key.json').toString('utf8'));
// Credentials arrive through non-echoing stdin, never arguments or a script file.
if(process.stdin.isTTY)process.stdin.setRawMode(true);
process.stdout.write('Ready for password JSON on stdin (input is hidden).\n');
let line=await new Promise((resolve,reject)=>{let input='';const onData=chunk=>{input+=chunk.toString('utf8');if(input.includes('\n')||input.includes('\r')){process.stdin.removeListener('data',onData);process.stdin.pause();resolve(input.split(/[\r\n]/)[0]);input='';}};process.stdin.on('data',onData);process.stdin.once('error',reject);process.stdin.resume();});
if(process.stdin.isTTY)process.stdin.setRawMode(false);
let requested=JSON.parse(line);line='';
if(typeof requested.password!=='string'||requested.password.length<8)throw new Error('Requested password must be at least eight characters.');
if(requested.password===oldKey.password)throw new Error('Requested password already matches the existing credential.');
const encoder=new TextEncoder();
async function decrypt(payload,password){const data=JSON.parse(payload.match(/Object\.freeze\((\{[\s\S]+\})\);/)[1]);const bytes=encoder.encode(password);const material=await webcrypto.subtle.importKey('raw',bytes,'PBKDF2',false,['deriveKey']);bytes.fill(0);const key=await webcrypto.subtle.deriveKey({name:'PBKDF2',salt:Buffer.from(data.salt,'base64'),iterations:data.iterations,hash:'SHA-256'},material,{name:'AES-GCM',length:256},false,['decrypt']);return new Uint8Array(await webcrypto.subtle.decrypt({name:'AES-GCM',iv:Buffer.from(data.iv,'base64'),additionalData:encoder.encode('TA-PORTFOLIO:1'),tagLength:128},key,Buffer.from(data.ciphertext,'base64')));}
const oldPlaintext=await decrypt(oldFiles.get('publish/js/encrypted-portfolio.js').toString('utf8'),oldKey.password);
const oldDigest=createHash('sha256').update(oldPlaintext).digest('hex');oldPlaintext.fill(0);
// Back up code and ciphertext only. Do not create a second plaintext password file.
const backup=path.join(root,'backups/Before_Login_Password_20261011');
await mkdir(backup);for(const file of ['tools/build-encrypted-portfolio.mjs','publish/index.html','publish/js/encrypted-portfolio.js']){await mkdir(path.dirname(path.join(backup,file)),{recursive:true});await copyFile(path.join(root,file),path.join(backup,file));}
let committed=false;
try{
  await copyFile(path.join(stage,'build-encrypted-portfolio.mjs'),builder);
  const newKey={...oldKey,password:requested.password};
  if(requested.password.length<20)newKey.allowShortPassword=true;else delete newKey.allowShortPassword;
  await writeFile(keyPath,JSON.stringify(newKey,null,2),'utf8');
  const output=execFileSync(process.execPath,[builder],{encoding:'utf8',stdio:['ignore','pipe','pipe']});
  if(!output.includes('Round-trip, wrong-password and tamper checks passed.'))throw new Error('Build validation did not report success.');
  const payload=await readFile(path.join(root,'publish/js/encrypted-portfolio.js'),'utf8');
  const newPlaintext=await decrypt(payload,requested.password);
  const newDigest=createHash('sha256').update(newPlaintext).digest('hex');newPlaintext.fill(0);
  if(oldDigest!==newDigest)throw new Error('Portfolio content unexpectedly changed.');
  let rejected=false;try{const unexpected=await decrypt(payload,oldKey.password);unexpected.fill(0);}catch{rejected=true;}
  if(!rejected)throw new Error('Previous password still unlocks the new payload.');
  if(payload.includes(requested.password))throw new Error('Credential leaked into public payload.');
  if(JSON.parse(await readFile(keyPath,'utf8')).password!==requested.password)throw new Error('Saved credential mismatch.');
  committed=true;
  console.log('Password updated. New password decrypts successfully; previous password is rejected. Portfolio content unchanged. Round-trip, wrong-password and tamper checks passed. No credentials printed.');
}finally{
  if(!committed){for(const [file,bytes] of oldFiles)await writeFile(path.join(root,file),bytes);console.error('Update failed; previous files restored.');}
  requested.password='';oldKey.password='';for(const bytes of oldFiles.values())bytes.fill(0);oldFiles.clear();
}
