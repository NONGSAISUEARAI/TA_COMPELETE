import {worldPoint,localPoint,sub,add,mul,dot,length} from './geometry.js';
import {curtainSettings} from './curtain-settings.js';
import {curtainFrame,cutLines} from './curtain.js';
import {foldedAssemblies} from './panel-folds.js';
import {foldedPanelSize} from './folded-panel-size.js';
const eps=.02;
const rounded=n=>Number(n.toFixed(3));
const valid=n=>Number.isFinite(n)&&n>=1&&n<=1e6;

export function foldedFaceMetrics(assembly){
 if(assembly.members.length!==2||assembly.bends.length!==1)throw Error('การกรอกขนาดแผ่นพับรองรับชิ้นที่มี 2 ด้านและแนวพับเดียว');
 const bend=assembly.bends[0],delta=sub(bend.q,bend.p);let along=mul(delta,1/length(delta)),dominant=along.reduce((best,n,i)=>Math.abs(n)>Math.abs(along[best])?i:best,0);if(along[dominant]<0)along=mul(along,-1);
 const base=dot(bend.p,along)<dot(bend.q,along)?bend.p:bend.q;
 return assembly.members.map(({a,panel})=>{
  if(panel.rings.length!==1||panel.rings[0].length!==4)throw Error('กรอกขนาดได้เมื่อทั้งสองด้านเป็นแผ่นสี่เหลี่ยม');
  const frame=curtainFrame(a),points=panel.rings[0].map(frame.to),low=[0,1].map(k=>Math.min(...points.map(p=>p[k]))),high=[0,1].map(k=>Math.max(...points.map(p=>p[k])));
  if(!points.every(p=>[0,1].every(k=>Math.min(Math.abs(p[k]-low[k]),Math.abs(p[k]-high[k]))<eps)))throw Error('ปรับแนวกริดให้ขนานกับแนวพับก่อนกรอกขนาด');
  const worlds=panel.rings[0].map(p=>worldPoint(a,p)),center=mul(worlds.reduce((sum,p)=>add(sum,p),[0,0,0]),.25),radial=sub(sub(center,base),mul(along,dot(sub(center,base),along))),inward=mul(radial,1/length(radial)),width=Math.max(...worlds.map(p=>dot(sub(p,base),inward)));
  const zero=frame.to(localPoint(a,base)),step=frame.to(localPoint(a,add(base,inward))),widthAxis=Math.abs(step[0]-zero[0])>Math.abs(step[1]-zero[1])?0:1,heightAxis=1-widthAxis;
  return {a,panel,frame,base,along,inward,width,widthAxis,heightAxis,worlds};
 });
}
function cutsFor(a,c,axis){const frame=curtainFrame({...a,curtain:c}),values=a.outer.map(frame.to).map(p=>p[axis]),min=Math.min(...values),max=Math.max(...values),suffix=axis?'Y':'X';return {min,max,suffix,cuts:cutLines(min,max,c['spacing'+suffix],c['custom'+suffix],c['cutOverrides'+suffix])}}
export function movePanelEdge(a,c,axis,current,desired,outward,changes,translate=false){
 if(translate&&Math.abs(current-desired)<eps)return;
 const {min,max,suffix,cuts}=cutsFor(a,c,axis),boundaryMargin=c.gapAtBoundary?c.gap/2:0,extent=outward>0?max:min,atBoundary=Math.abs(current-(extent-outward*boundaryMargin))<eps;
 const source=atBoundary?extent:current+outward*c.gap/2,index=cuts.findIndex(n=>Math.abs(n-source)<eps);if(index<0)throw Error('ไม่พบแนวแบ่งที่ตรงกับขอบแผ่น');
 const outerFinished=extent-outward*boundaryMargin;if(outward*(desired-outerFinished)>eps)throw Error('ขนาดที่กรอกเกินขอบ Area · ลดขนาดหรือปรับพื้นที่ก่อน');
 let target=Math.abs(desired-outerFinished)<eps?extent:desired+outward*c.gap/2;
 const property='cutOverrides'+suffix,map={...c[property]},delta=target-source,spacing=c['spacing'+suffix];
 // Rebase every subsequent start, rather than stretching the adjacent cell.
 // Bounds stay fixed; the last panel is clipped to the remaining Area.
 for(const [key,value]of Object.entries(map))if(outward*(value-source)>=-eps)map[key]=rounded(value+delta);
 const sourceKeys=new Map(Object.entries(c[property]).map(([key,value])=>[rounded(value),key]));
 let ordinal=0;
 for(const value of cuts.slice(1,-1).filter(value=>outward*(value-source)>=-eps).sort((a,b)=>outward*(a-b))){const key=sourceKeys.get(rounded(value))??String(Number(value.toFixed(6))),position=translate?value+delta:Math.abs(value-source)<eps?target:target+outward*spacing*(++ordinal);map[key]=rounded(position);changes[axis].push([value,rounded(position)])}
 if(atBoundary)map[String(rounded(target))]=rounded(target);
 // A shortened corner can create room for an extra full panel at the far end.
 const targets=new Set(Object.values(map).map(rounded));let extra=0;
 const tail=translate?outward>0?Math.max(target,...Object.values(map).filter(v=>v>target&&v<max)):Math.min(target,...Object.values(map).filter(v=>v<target&&v>min)):target;
 for(let value=tail+outward*spacing;value>min+eps&&value<max-eps;value+=outward*spacing)if(!targets.has(rounded(value))){let key=String(rounded(value));while(key in map)key=String(rounded(min-1000-(++extra)));map[key]=rounded(value);targets.add(rounded(value))}
 c[property]=map;
}
export function resizeFoldedPanel(areas,group,property,value){
 if(!valid(value))throw Error('กรอกขนาดตั้งแต่ 1 ถึง 1,000,000 mm');
 const assembly=foldedAssemblies(areas).find(g=>g.group===group);if(!assembly)throw Error('เลือกแผ่นพับหนึ่งชิ้นก่อน');
 const metrics=foldedFaceMetrics(assembly),size=foldedPanelSize(assembly),first=assembly.members[0],sheet=first.a.curtain.panelJoins[first.panel.key].sheet||{width:size.width,height:size.height};
 let width=sheet.width,maxHeight=sheet.height,height=size.height,wings=metrics.map(m=>m.width);
 if(property==='width'){width=value;wings=wings.map(w=>w*width/size.width);const caps=metrics.map(m=>Math.max(...m.a.outer.map(p=>dot(sub(worldPoint(m.a,p),m.base),m.inward)))-(curtainSettings(m.a).gapAtBoundary?curtainSettings(m.a).gap/2:0));if(width>caps[0]+caps[1]+eps)throw Error('Width รวมเกินพื้นที่ที่มีอยู่ทั้งสองด้าน');if(wings[0]>caps[0])wings=[caps[0],width-caps[0]];if(wings[1]>caps[1])wings=[width-caps[1],caps[1]]}
 else if(property==='maxHeight'){maxHeight=value;height=Math.min(height,maxHeight)}
 else if(property==='height')height=value;
 else if(property==='wing0'){wings=[value,width-value]}
 else if(property==='wing1'){wings=[width-value,value]}
 else throw Error('ไม่พบคุณสมบัติขนาดแผ่น');
 if(wings.some(w=>!valid(w))||height>maxHeight+eps)throw Error('ขนาดต้องไม่เกินแผ่นมาตรฐาน และต้องเหลือความกว้างให้ทั้งสองด้านอย่างน้อย 1 mm');
 const patternWorld=worldPoint(first.a,first.a.pattern.origin),heightPivot=Math.max(0,Math.min(size.height,dot(sub(patternWorld,metrics[0].base),metrics[0].along))),heightStart=heightPivot*(1-height/size.height);
 const next=structuredClone(areas),plans=new Map();
 for(let i=0;i<metrics.length;i++){
  const m=metrics[i],a=next.find(a=>a.id===m.a.id),c=curtainSettings(a),changes=[[],[]],to=p=>m.frame.to(localPoint(m.a,p));
  c.cutOverridesX={...c.cutOverridesX};c.cutOverridesY={...c.cutOverridesY};
  const saved=m.a.curtain.panelJoins[m.panel.key].sizeReset;
  const before=saved?.before??Object.fromEntries([0,1].map(axis=>{const suffix=axis?'Y':'X',values=cutsFor(a,c,axis).cuts,index=values.findIndex(v=>Math.abs(v-Number(m.panel.key.split(':')[axis]))<eps),edges=values.slice(index,index+2);return [suffix,Object.fromEntries(Object.entries(c['cutOverrides'+suffix]).filter(([,v])=>!edges.some(edge=>Math.abs(v-edge)<eps)))]}));
  const w0=to(add(m.base,mul(m.inward,m.width)))[m.widthAxis],w1=to(add(m.base,mul(m.inward,wings[i])))[m.widthAxis],wSign=Math.sign(to(add(m.base,m.inward))[m.widthAxis]-to(m.base)[m.widthAxis]);
  movePanelEdge(a,c,m.widthAxis,w0,w1,wSign,changes);
  const h0=to(add(m.base,mul(m.along,size.height)))[m.heightAxis],h1=to(add(m.base,mul(m.along,heightStart+height)))[m.heightAxis],hSign=Math.sign(to(add(m.base,m.along))[m.heightAxis]-to(m.base)[m.heightAxis]);
  const hBase=to(m.base)[m.heightAxis],hStart=to(add(m.base,mul(m.along,heightStart)))[m.heightAxis];if(Math.abs(hBase-hStart)>eps)movePanelEdge(a,c,m.heightAxis,hBase,hStart,-hSign,changes);
  movePanelEdge(a,c,m.heightAxis,h0,h1,hSign,changes);
  const keyMap=key=>{const [x,y,k]=key.split(':'),point=[Number(x),Number(y)];for(let axis=0;axis<2;axis++){const change=changes[axis].find(([old])=>Math.abs(old-point[axis])<eps);if(change)point[axis]=change[1]}return `${rounded(point[0])}:${rounded(point[1])}:${k}`};
  c.panelJoins=Object.fromEntries(Object.entries(c.panelJoins).filter(([,j])=>j.group!==group).map(([key,j])=>[keyMap(key),j]));c.overrides=Object.fromEntries(Object.entries(c.overrides).map(([key,v])=>[keyMap(key),v]));c.panelSizes=Object.fromEntries(Object.entries(c.panelSizes||{}).map(([key,v])=>[keyMap(key),v]));a.curtain=c;
  const sample=to(add(add(m.base,mul(m.inward,wings[i]/2)),mul(m.along,heightStart+height/2))),xs=cutsFor(a,c,0).cuts,ys=cutsFor(a,c,1).cuts,lower=(cuts,value)=>cuts[Math.max(0,cuts.findIndex((n,j)=>j<cuts.length-1&&value>=n-eps&&value<=cuts[j+1]+eps))];
  const key=`${rounded(lower(xs,sample[0]))}:${rounded(lower(ys,sample[1]))}:0`;
  plans.set(a.id,{key,join:{...m.a.curtain.panelJoins[m.panel.key],sheet:{width:rounded(width),height:rounded(maxHeight)},sizeReset:{before,after:{X:{...c.cutOverridesX},Y:{...c.cutOverridesY}}}}});
 }
 for(const a of next){const plan=plans.get(a.id);if(plan)a.curtain.panelJoins[plan.key]=plan.join}
 const resulting=foldedAssemblies(next).find(g=>g.group===group),actual=foldedPanelSize(resulting),actualWings=foldedFaceMetrics(resulting);
 if(Math.abs(actual.width-width)>eps||Math.abs(actual.height-height)>eps||actualWings.some((m,i)=>Math.abs(m.width-wings[i])>eps))throw Error('ขนาดจริงไม่ตรงกับค่าที่กรอก · ตรวจขอบ Area และแนวแบ่งกริด');
 validateFoldedSheetLimits(foldedAssemblies(next));return next;
}
export function validateFoldedSheetLimits(assemblies){for(const g of assemblies){const sheet=g.members[0].a.curtain.panelJoins[g.members[0].panel.key].sheet;if(!sheet)continue;const size=foldedPanelSize(g);if(size.width>sheet.width+eps||size.height>sheet.height+eps)throw Error('ขนาดแผ่นพับเกิน Width / Height ที่กำหนดไว้')}}
