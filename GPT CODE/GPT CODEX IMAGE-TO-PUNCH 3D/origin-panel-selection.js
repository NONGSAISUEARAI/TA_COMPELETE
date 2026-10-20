import {curtainFrame} from './curtain.js';
import {panelRef,parsePanelRef} from './panel-folds.js';

// Interior cells retain their grid keys when the Origin moves. A clipped cell
// at an Area boundary gets a new lower-bound key even though it stays selected.
export function originPanelSelection(previous,next,refs,active,layoutFor){
 const mapping=new Map(),all=new Set(refs);if(active)all.add(panelRef(active.areaId,active.key));
 for(const ref of all){
  const {areaId,key}=parsePanelRef(ref),before=previous.find(a=>a.id===areaId),after=next.find(a=>a.id===areaId),panels=after&&layoutFor(after)?.panels;
  if(!before||!panels)continue;
  if(panels.some(p=>p.key===key)){mapping.set(ref,ref);continue}
  const oldFrame=curtainFrame(before),newFrame=curtainFrame(after),oldPoints=before.outer.map(oldFrame.to),newPoints=after.outer.map(newFrame.to),parts=key.split(':');
  for(const axis of [0,1]){const min=Math.min(...oldPoints.map(p=>p[axis]));if(Math.abs(Number(parts[axis])-min)<.001)parts[axis]=String(Number(Math.min(...newPoints.map(p=>p[axis])).toFixed(3)))}
  const candidate=parts.join(':');if(panels.some(p=>p.key===candidate))mapping.set(ref,panelRef(areaId,candidate));
 }
 return {refs:new Set([...refs].map(ref=>mapping.get(ref)).filter(Boolean)),active:active?parseMapped(mapping.get(panelRef(active.areaId,active.key))):null};
}
const parseMapped=ref=>ref?parsePanelRef(ref):null;
