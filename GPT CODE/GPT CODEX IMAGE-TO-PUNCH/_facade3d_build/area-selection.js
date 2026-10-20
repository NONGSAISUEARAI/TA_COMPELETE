import {validateArea} from './geometry.js';
export function selectAreaIds(current,primary,id,toggle=false){
 const ids=new Set(toggle?current:[]);
 if(toggle&&ids.has(id)){ids.delete(id);if(primary===id)primary=[...ids].at(-1)||null}else{ids.add(id);primary=id}
 return {ids,primary};
}
export function selectAreaRange(order,anchor,id,current=new Set(),additive=false){
 const end=order.indexOf(id);if(end<0)return {ids:new Set(current),primary:null,anchor:null};
 let start=order.indexOf(anchor);if(start<0){start=end;anchor=id}
 return {ids:new Set([...(additive?current:[]),...order.slice(Math.min(start,end),Math.max(start,end)+1)]),primary:id,anchor};
}
export function editAreaGroup(areas,ids,mutator,validateScene){
 const next=areas.map(a=>{if(!ids.has(a.id))return a;const edited=structuredClone(a);mutator(edited);validateArea(edited);return edited});validateScene(next);return next;
}
