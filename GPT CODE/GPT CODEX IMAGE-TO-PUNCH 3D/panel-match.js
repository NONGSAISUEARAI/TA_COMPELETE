import {curtainSettings,validateCurtainSettings} from './curtain-settings.js';
import {buildCurtainLayout} from './curtain.js';
import {boundaryCorners} from './dimensions.js';
import {panelBendEdges,panelBendProfile} from './panel-bends.js';
export function capturePanelProperties(areas,ref){
 const a=areas.find(a=>a.id===ref.areaId),layout=a&&buildCurtainLayout(a),p=layout?.panels.find(p=>p.key===ref.key);if(!p)throw Error('เลือก Panel ที่แสดงอยู่เป็นต้นแบบ');
 const bend=layout.settings.panelBends[p.key],edgeSettings={};for(const edge of panelBendEdges(bend).filter(e=>!p.joinedEdges?.includes(e)))edgeSettings[edge]=structuredClone(panelBendProfile(bend,edge));
 return {type:p.type,edgeSettings,source:{...ref},name:p.name};
}
export function matchPanelProperties(areas,properties,refs){
 const next=structuredClone(areas);let count=0;
 for(const ref of refs){const a=next.find(a=>a.id===ref.areaId),layout=a&&buildCurtainLayout(a),p=layout?.panels.find(p=>p.key===ref.key);if(!p)throw Error('ไม่พบ Panel ปลายทาง');
 if(ref.areaId===properties.source.areaId&&ref.key===properties.source.key)continue;
 const c=curtainSettings(a),edges=boundaryCorners(p.rings[0]).length,map={};for(const [edge,profile] of Object.entries(properties.edgeSettings))if(Number(edge)<edges)map[edge]=structuredClone(profile);
 c.overrides[p.key]=properties.type;if(Object.keys(map).length)c.panelBends[p.key]={edgeSettings:map};else delete c.panelBends[p.key];validateCurtainSettings(c);a.curtain=c;buildCurtainLayout(a);count++;
 }
 return {areas:next,count};
}
