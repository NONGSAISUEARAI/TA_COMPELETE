import {numericExpression} from './numeric-expression.js';
export const isNumericInput=input=>input.type==='number'||input.dataset.numeric==='true';
export function enableNumericExpressions(root){
 for(const input of root.querySelectorAll('input[type="number"]')){
  input.dataset.numeric='true';input.type='text';input.inputMode='text';input.setAttribute('role','spinbutton');input.title+=(input.title?' · ':'')+'สูตร: 3000/2 · + - * / ( ) · Enter เพื่อคำนวณ';
  if(input.min!=='')input.setAttribute('aria-valuemin',input.min);if(input.max!=='')input.setAttribute('aria-valuemax',input.max);
 }
}
export function normalizeNumericInput(input){
 try{const n=numericExpression(input.value);if(input.closest('form')&&input.min!==''&&n<Number(input.min))throw Error(`ค่าต้องไม่น้อยกว่า ${input.min}`);if(input.closest('form')&&input.max!==''&&n>Number(input.max))throw Error(`ค่าต้องไม่เกิน ${input.max}`);input.setCustomValidity('');input.value=String(n);input.setAttribute('aria-valuenow',String(n));return true}
 catch(error){input.setCustomValidity(error.message);input.reportValidity();return false}
}
export function installNumericExpressions(root=document){
 enableNumericExpressions(root);
 root.addEventListener('input',e=>{if(e.target.dataset.numeric)e.target.setCustomValidity('')},true);
 root.addEventListener('change',e=>{if(e.target.dataset.numeric&&!normalizeNumericInput(e.target)){e.preventDefault();e.stopImmediatePropagation()}},true);
 root.addEventListener('keydown',e=>{
  const input=e.target;if(!input.dataset.numeric||e.key!=='Enter')return;
  if(!normalizeNumericInput(input)){e.preventDefault();e.stopImmediatePropagation();return}
  if(!input.closest('form')){e.preventDefault();e.stopImmediatePropagation();input.dispatchEvent(new Event('change',{bubbles:true}))}
 },true);
 root.addEventListener('submit',e=>{for(const input of e.target.querySelectorAll('[data-numeric]'))if(!input.disabled&&!normalizeNumericInput(input)){e.preventDefault();e.stopImmediatePropagation();break}},true);
}
