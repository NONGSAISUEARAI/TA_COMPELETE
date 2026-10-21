import {defaultCurtain,curtainSettings} from './curtain-settings.js';
import {unjoinCurtainAreas} from './curtain-join.js';
import {unjoinFoldedPanels} from './panel-folds.js';

export function resetCurtainAreas(areas,ids){
 const refs=areas.filter(a=>ids.has(a.id)).flatMap(a=>Object.keys(a.curtain?.panelJoins||{}).map(key=>({areaId:a.id,key})));
 // Remove both sides of affected relationships before restoring the grid.
 const detached=unjoinFoldedPanels(unjoinCurtainAreas(areas,ids),refs);
 return detached.map(a=>ids.has(a.id)?{...a,curtain:{...defaultCurtain(),enabled:curtainSettings(a).enabled}}:a);
}
