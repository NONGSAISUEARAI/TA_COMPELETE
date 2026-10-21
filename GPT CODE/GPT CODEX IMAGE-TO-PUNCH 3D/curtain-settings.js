import {validatePanelPatches} from './panel-tiling.js';
import {worldCurtainFrame} from './curtain-world.js';
import {dot} from './geometry.js';
export const defaultCurtain=()=>({enabled:false,reference:'local',worldOrigin:[0,0,0],worldAngle:0,joinMode:'world',join:null,followPatternOrigin:false,origin:null,angle:null,spacingX:1200,spacingY:1200,gap:12,gapAtBoundary:true,panelThickness:4,panelType:'solid',panelColor:'#aeb8ae',showPanels:true,showGrid:true,showMullions:true,mullionWidth:50,mullionDepth:100,mullionOffset:-55,flipMullionSide:false,boundary:true,openings:true,customX:[],customY:[],cutOverridesX:{},cutOverridesY:{},panelJoins:{},panelSizes:{},panelPatches:[],overrides:{}});
export function curtainSettings(a){return {...defaultCurtain(),...a.curtain,panelJoins:{...a.curtain?.panelJoins},panelSizes:{...a.curtain?.panelSizes},overrides:{...a.curtain?.overrides}}}
export function curtainOrigin(a){const c=curtainSettings(a);if(c.reference==='world'){const f=worldCurtainFrame(a,c);return {origin:f.from([0,0]),angle:Math.atan2(dot(f.x,a.v),dot(f.x,a.u))*180/Math.PI}}return {origin:c.origin??a.pattern.origin,angle:c.angle??a.pattern.angle}}
export function validateCurtainSettings(c){
 if(c===undefined)return;
 if(!c||typeof c!=='object'||Array.isArray(c))throw Error('Curtain Wall settings ไม่ถูกต้อง');
 const s={...defaultCurtain(),...c};
 if(!['local','world'].includes(s.reference))throw Error('Curtain reference ต้องเป็น Local หรือ World');
 if(!Array.isArray(s.worldOrigin)||s.worldOrigin.length!==3||s.worldOrigin.some(n=>!Number.isFinite(n)||Math.abs(n)>1e9))throw Error('World Origin ต้องเป็น World X,Y,Z');
 if(!['world','unfold'].includes(s.joinMode))throw Error('Joint alignment ต้องเป็น World หรือ Unfold');
 if(!Number.isFinite(s.worldAngle))throw Error('World grid angle ไม่ถูกต้อง');
 if(s.join!==null){const j=s.join;if(!j||j.version!==1||typeof j.group!=='string'||!j.group||j.group.length>100||typeof j.rootId!=='string'||!j.rootId||j.rootId.length>100)throw Error('ข้อมูล Curtain Join ไม่ถูกต้อง');
  for(const key of ['x','y','anchorX','anchorY'])if(!Array.isArray(j[key])||j[key].length!==3||j[key].some(n=>!Number.isFinite(n))||Math.abs(Math.hypot(...j[key])-1)>1e-5)throw Error('แกน Curtain Join ไม่ถูกต้อง');
  if(j.anchorId!==undefined&&(typeof j.anchorId!=='string'||!j.anchorId||j.anchorId.length>100))throw Error('จุดอ้างอิง Curtain Join ไม่ถูกต้อง');
  if(j.anchorOffset!==undefined&&(!Array.isArray(j.anchorOffset)||j.anchorOffset.length!==2||j.anchorOffset.some(n=>!Number.isFinite(n)||Math.abs(n)>1e12)))throw Error('ระยะจุดอ้างอิง Curtain Join ไม่ถูกต้อง');
  if(Math.abs(dot(j.x,j.y))>1e-5||Math.abs(dot(j.anchorX,j.anchorY))>1e-5||!Array.isArray(j.offset)||j.offset.length!==2||j.offset.some(n=>!Number.isFinite(n)||Math.abs(n)>1e12))throw Error('ระยะ Curtain Join ไม่ถูกต้อง');
 }

 if(s.origin!==null&&(!Array.isArray(s.origin)||s.origin.length!==2||s.origin.some(n=>!Number.isFinite(n)||Math.abs(n)>1e9)))throw Error('Curtain Origin ต้องเป็น Local X,Y');
 if(s.angle!==null&&!Number.isFinite(s.angle))throw Error('Curtain axis angle ไม่ถูกต้อง');
 for(const key of ['followPatternOrigin','enabled','showPanels','showGrid','showMullions','boundary','openings','gapAtBoundary','flipMullionSide'])if(typeof s[key]!=='boolean')throw Error('Curtain Wall toggle ไม่ถูกต้อง');
 for(const [key,min,max]of [['spacingX',50,1e6],['spacingY',50,1e6],['gap',0,1000],['panelThickness',.1,300],['mullionWidth',1,1000],['mullionDepth',1,2000],['mullionOffset',-5000,5000]])if(!Number.isFinite(s[key])||s[key]<min||s[key]>max)throw Error(`${key}: ต้องอยู่ระหว่าง ${min}–${max} mm`);
 if(s.gap>=Math.min(s.spacingX,s.spacingY))throw Error('Panel gap ต้องน้อยกว่าระยะกริด');
 if(!['solid','glass','open'].includes(s.panelType)||!/^#[\da-f]{6}$/i.test(s.panelColor))throw Error('Panel type หรือสีไม่ถูกต้อง');
 for(const key of ['customX','customY'])if(!Array.isArray(s[key])||s[key].length>60||s[key].some(n=>!Number.isFinite(n)||Math.abs(n)>1e8))throw Error('Custom grid ต้องเป็นระยะตัวเลขไม่เกิน 60 แนวต่อแกน');
 for(const key of ['cutOverridesX','cutOverridesY'])if(!s[key]||typeof s[key]!=='object'||Array.isArray(s[key])||Object.entries(s[key]).length>100000||Object.entries(s[key]).some(([k,v])=>!Number.isFinite(Number(k))||!Number.isFinite(v)||Math.abs(v)>1e9))throw Error('ตำแหน่งแนวแบ่ง Panel ไม่ถูกต้อง');
 if(!s.panelJoins||typeof s.panelJoins!=='object'||Array.isArray(s.panelJoins)||Object.keys(s.panelJoins).length>100||Object.entries(s.panelJoins).some(([key,j])=>key.length>120||!j||typeof j.group!=='string'||!j.group||j.group.length>100||!Array.isArray(j.edges)||!j.edges.length||j.edges.length>4||j.edges.some(i=>!Number.isInteger(i)||i<0||i>=5000)||(j.sheet&&(['width','height'].some(k=>!Number.isFinite(j.sheet[k])||j.sheet[k]<1||j.sheet[k]>1e6)))))throw Error('ข้อมูล Folded panel ไม่ถูกต้อง หรือเกิน 100 แผ่นต่อ Area');
 validatePanelPatches(s.panelPatches);
 if(!s.panelSizes||typeof s.panelSizes!=='object'||Array.isArray(s.panelSizes)||Object.keys(s.panelSizes).length>100)throw Error('ข้อมูลขนาด Panel ไม่ถูกต้อง หรือเกิน 100 แผ่นต่อ Area');
 for(const j of [...Object.values(s.panelJoins),...Object.values(s.panelSizes)]){if(!j||typeof j!=='object')throw Error('ข้อมูลขนาด Panel ไม่ถูกต้อง');if(j.patchReset){validatePanelPatches(j.patchReset.before);validatePanelPatches(j.patchReset.after);if(typeof j.patchReset.key!=='string')throw Error('ข้อมูล Reset Panel ไม่ถูกต้อง')}if(j.sizeReset){for(const stage of ['before','after'])for(const axis of ['X','Y']){const map=j.sizeReset?.[stage]?.[axis];if(!map||typeof map!=='object'||Array.isArray(map)||Object.keys(map).length>100000||Object.entries(map).some(([key,value])=>!Number.isFinite(Number(key))||!Number.isFinite(value)||Math.abs(value)>1e9))throw Error('ข้อมูล Start สำหรับ Reset Panel ไม่ถูกต้อง')}}}
 if(!s.overrides||typeof s.overrides!=='object'||Array.isArray(s.overrides)||Object.keys(s.overrides).length>100||Object.entries(s.overrides).some(([k,v])=>k.length>120||!['solid','glass','open'].includes(v)))throw Error('เปลี่ยน Panel ได้สูงสุด 100 ช่องต่อ Area');
}
