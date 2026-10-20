import {worldPoint,length,sub} from './geometry.js';
import {curtainSettings,curtainOrigin} from './curtain-settings.js';

// Apply links as an edit transaction, before the shared Join settings propagate.
// Joined members have one anchor: moving any locked member moves the group.
export function applyPatternOriginLinks(previous,next,primaryId){
 const oldById=new Map(previous.map(a=>[a.id,a])),leaders=new Map();
 for(const a of next){const c=curtainSettings(a),old=oldById.get(a.id);if(!c.followPatternOrigin)continue;
  const changed=!old||!curtainSettings(old).followPatternOrigin||c.reference!==curtainSettings(old).reference||length(sub(worldPoint(a,a.pattern.origin),worldPoint(old,old.pattern.origin)))>1e-7;
  if(!changed)continue;const key=c.join?.group||a.id;if(!leaders.has(key)||a.id===primaryId)leaders.set(key,a);
 }
 return next.map(a=>{const c=curtainSettings(a),source=leaders.get(c.join?.group||a.id);if(!source||!c.followPatternOrigin)return a;
  const nextCurtain={...c};if(c.reference==='world'){nextCurtain.worldOrigin=worldPoint(source,source.pattern.origin);if(c.join)nextCurtain.join={...c.join,anchorId:source.id}}
  else{nextCurtain.origin=[...a.pattern.origin];nextCurtain.angle=curtainOrigin(oldById.get(a.id)||a).angle}
  return {...a,curtain:nextCurtain};
 });
}
