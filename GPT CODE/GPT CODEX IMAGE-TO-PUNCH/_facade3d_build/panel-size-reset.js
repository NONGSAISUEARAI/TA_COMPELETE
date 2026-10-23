import {curtainSettings} from './curtain-settings.js';
import {curtainFrame,cutLines} from './curtain.js';
import {panelRef,parsePanelRef,foldedAssemblies} from './panel-folds.js';
import {validateFoldedSheetLimits} from './folded-panel-resize.js';
const eps=.02,rounded=n=>Number(n.toFixed(3));
function cuts(a,c,axis){const frame=curtainFrame({...a,curtain:c}),values=a.outer.map(frame.to).map(p=>p[axis]),suffix=axis?'Y':'X';return cutLines(Math.min(...values),Math.max(...values),c['spacing'+suffix],c['custom'+suffix],c['cutOverrides'+suffix])}

export function resetPanelDimensions(areas,selection){
 const refs=new Set(selection.map(r=>panelRef(r.areaId,r.key))),groups=new Set(selection.map(r=>areas.find(a=>a.id===r.areaId)?.curtain?.panelJoins?.[r.key]?.group).filter(Boolean));
 for(const a of areas)for(const [key,j]of Object.entries(a.curtain?.panelJoins||{}))if(groups.has(j.group))refs.add(panelRef(a.id,key));
 const maps=new Map(),next=areas.map(a=>{
  const selected=[...refs].map(parsePanelRef).filter(r=>r.areaId===a.id);if(!selected.length)return a;
  const c=curtainSettings(a),back=new Map(),patches=selected.map(r=>({r,saved:c.panelSizes?.[r.key]?.patchReset})).filter(p=>p.saved).sort((a,b)=>b.saved.after.length-a.saved.after.length);
  for(const {r,saved}of patches){if(JSON.stringify(c.panelPatches)!==JSON.stringify(saved.after))throw Error('แพทเทิร์นถูกแก้ต่อแล้ว · Reset แผ่นที่แก้ล่าสุดก่อน');c.panelPatches=structuredClone(saved.before);for(const [to,from]of Object.entries(saved.mapBack||{}))back.set(to,from);back.set(r.key,saved.key);delete c.panelSizes[r.key]}
  const active=selected.filter(r=>!patches.some(p=>p.r.key===r.key)),oldCuts=[0,1].map(axis=>cuts(a,c,axis)),removed=[new Map(),new Map()];
  for(const axis of [0,1]){
   const property=axis?'cutOverridesY':'cutOverridesX',edges=[];
   for(const r of active){const lower=Number(r.key.split(':')[axis]),index=oldCuts[axis].findIndex(n=>Math.abs(n-lower)<eps);if(index>=0)edges.push(oldCuts[axis][index],oldCuts[axis][index+1])}
   const snapshots=selected.map(r=>a.curtain?.panelJoins?.[r.key]?.sizeReset??a.curtain?.panelSizes?.[r.key]?.sizeReset).filter(Boolean);
   if(snapshots.length){const map={...c[property]};for(const snapshot of snapshots){const suffix=axis?'Y':'X',before=snapshot.before[suffix],after=snapshot.after[suffix];for(const key of new Set([...Object.keys(before),...Object.keys(after)])){if(before[key]===after[key])continue;if(map[key]!==after[key])throw Error('แนว Start ถูกแก้ร่วมกับแผ่นอื่นแล้ว · Reset แผ่นที่แก้ล่าสุดก่อน');if(after[key]!==undefined)removed[axis].set(after[key],Number(key));if(before[key]===undefined)delete map[key];else map[key]=before[key]}}c[property]=map}
   else c[property]=Object.fromEntries(Object.entries(c[property]).filter(([source,target])=>{if(edges.some(n=>Math.abs(n-target)<eps)){removed[axis].set(target,Number(source));return false}return true}));
  }
  const newCuts=[0,1].map(axis=>cuts(a,c,axis));
  const mapKey=key=>{if(back.has(key))return back.get(key);const parts=key.split(':');for(const axis of [0,1]){const old=Number(parts[axis]),entry=[...removed[axis]].find(([value])=>Math.abs(value-old)<eps);if(!entry)continue;const source=newCuts[axis].find(n=>Math.abs(n-entry[1])<eps);parts[axis]=String(rounded(source??newCuts[axis].filter(n=>n<=old+eps).at(-1)??newCuts[axis][0]))}return parts.join(':')};
  const remap=entries=>{const out={};for(const [key,value]of entries){const target=mapKey(key);if(target in out&&JSON.stringify(out[target])!==JSON.stringify(value))throw Error('Reset จะรวมช่องที่มีค่า Panel ต่างกัน · เลือกแผ่นที่เกี่ยวข้องเพิ่ม หรือ Unjoin ก่อน');out[target]=value}return out};
  c.panelJoins=remap(Object.entries(c.panelJoins).map(([key,j])=>{if(!groups.has(j.group))return [key,j];const clean={...j};delete clean.sheet;delete clean.sizeReset;return [key,clean]}));
  c.panelBends=remap(Object.entries(c.panelBends||{}));c.panelSizes=remap(Object.entries(c.panelSizes||{}).filter(([key])=>!selected.some(r=>r.key===key)));c.overrides=remap(Object.entries(c.overrides));maps.set(a.id,mapKey);return {...a,curtain:c};
 });
 validateFoldedSheetLimits(foldedAssemblies(next));
 return {areas:next,refs:new Set([...refs].map(parsePanelRef).map(r=>panelRef(r.areaId,maps.get(r.areaId)?.(r.key)??r.key)))};
}
