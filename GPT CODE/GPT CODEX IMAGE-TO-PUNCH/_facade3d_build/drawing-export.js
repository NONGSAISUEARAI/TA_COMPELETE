import {worldCurtainBasis} from './curtain-world.js';
import {add,sub,mul,dot,cross,unit,length} from './geometry.js';
export function drawingView(options,area){
 const type=options.type||'elevation';let origin=[0,0,0],direction,up=[0,0,1],cut=false,depth=Infinity;
 if(type==='plan'){const level=Number(options.level);if(!Number.isFinite(level))throw Error('กรอกระดับตัดแปลน');origin=[0,0,level];direction=[0,0,-1];up=[0,1,0];cut=true}
 else if(type==='section'){const p=options.p1,q=options.p2;if(!Array.isArray(p)||!Array.isArray(q)||[...p,...q].some(n=>!Number.isFinite(n)))throw Error('ระบุจุดแนวตัด 2 จุด');const e=sub(q,p);e[2]=0;if(length(e)<.01)throw Error('แนวตัดต้องมี 2 จุดที่ต่างกันในระนาบ XY');origin=[p[0],p[1],0];direction=unit(cross(e,up));if(options.flip)direction=mul(direction,-1);cut=true}
 else if(type==='elevation'){const directions={front:[0,1,0],back:[0,-1,0],left:[1,0,0],right:[-1,0,0]};if(options.side==='area'){if(!area)throw Error('เลือก Area สำหรับรูปด้าน');const basis=worldCurtainBasis(area);direction=mul(basis.normal,-1);up=basis.y;origin=[...area.base]}else direction=directions[options.side||'front'];if(!direction)throw Error('รูปด้านไม่ถูกต้อง')}
 else throw Error('ประเภทแบบไม่ถูกต้อง');
 if(cut){depth=Number(options.depth);if(!Number.isFinite(depth)||depth<=0)throw Error('ระยะความลึกต้องมากกว่า 0 mm')}
 const x=unit(cross(direction,up)),y=unit(cross(x,direction));return {type,origin,direction,x,y,cut,depth,project:p=>{const d=sub(p,origin);return [dot(d,x),dot(d,y)]},distance:p=>dot(sub(p,origin),direction)};
}
export function clipDrawingSegment(a,b,view){
 if(!view.cut)return [a,b];const da=view.distance(a),db=view.distance(b),d=db-da;let lo=0,hi=1;
 if(Math.abs(d)<1e-10)return da>=-.00001&&da<=view.depth+.00001?[a,b]:null;
 const t0=(0-da)/d,t1=(view.depth-da)/d;lo=Math.max(lo,Math.min(t0,t1));hi=Math.min(hi,Math.max(t0,t1));if(hi<lo)return null;return [add(a,mul(sub(b,a),lo)),add(a,mul(sub(b,a),hi))];
}
export function triangleCut(points,view){const ds=points.map(view.distance);if(ds.every(d=>Math.abs(d)<1e-7))return null;const hits=[];for(let i=0;i<3;i++){const j=(i+1)%3,a=points[i],b=points[j],da=ds[i],db=ds[j];if(Math.abs(da)<1e-7)hits.push(a);if(da*db<0)hits.push(add(a,mul(sub(b,a),da/(da-db))))}const unique=hits.filter((p,i)=>!hits.slice(0,i).some(q=>length(sub(p,q))<1e-6));return unique.length===2?unique:null}
export function drawingResult(lines,view,{dimensions=true}={}){
 const seen=new Set(),segments=[];for(const l of lines){const clipped=l.cut?[l.a,l.b]:clipDrawingSegment(l.a,l.b,view);if(!clipped)continue;const [a,b]=clipped.map(view.project);if(Math.hypot(a[0]-b[0],a[1]-b[1])<.001)continue;const key=[a,b].map(p=>p.map(n=>Math.round(n*1000)).join(',')).sort().join('/')+'/'+l.layer;if(seen.has(key))continue;seen.add(key);segments.push({a,b,layer:l.layer});if(segments.length>300000)throw Error('เส้นเกิน 300,000 เส้น กรุณาเลือกส่งออกเฉพาะ Area ที่ต้องการ')}
 if(!segments.length)throw Error('ไม่พบเส้นในมุมมองหรือช่วงความลึกที่กำหนด');const bounds=[Infinity,Infinity,-Infinity,-Infinity],texts=[];for(const l of segments)for(const p of [l.a,l.b]){bounds[0]=Math.min(bounds[0],p[0]);bounds[1]=Math.min(bounds[1],p[1]);bounds[2]=Math.max(bounds[2],p[0]);bounds[3]=Math.max(bounds[3],p[1])}
 if(dimensions){const [x0,y0,x1,y1]=bounds,w=x1-x0,h=y1-y0,gap=Math.max(w,h)*.08||10,tick=gap*.12,dim=(a,b)=>segments.push({a,b,layer:'DIMENSIONS'});if(w>.001){const y=y0-gap;dim([x0,y],[x1,y]);for(const x of [x0,x1]){dim([x,y0],[x,y-tick]);dim([x-tick,y-tick],[x+tick,y+tick])}texts.push({point:[(x0+x1)/2,y-gap*.3],text:'W '+w.toFixed(2)+' mm',height:gap*.25,layer:'DIMENSIONS'})}if(h>.001){const x=x1+gap;dim([x,y0],[x,y1]);for(const y of [y0,y1]){dim([x1,y],[x+tick,y]);dim([x-tick,y-tick],[x+tick,y+tick])}texts.push({point:[x+gap*.2,(y0+y1)/2],text:'H '+h.toFixed(2)+' mm',height:gap*.25,layer:'DIMENSIONS'})}}
 return {segments,texts,bounds,type:view.type};
}
export function drawingDxf(drawing){
 const pairs=[],put=(c,v)=>pairs.push(String(c),String(typeof v==='number'?Number(v.toFixed(6)):v)),layers=[...new Set([...drawing.segments,...drawing.texts].map(l=>l.layer))];
 put(0,'SECTION');put(2,'HEADER');put(9,'$ACADVER');put(1,'AC1009');put(9,'$INSUNITS');put(70,4);put(9,'$MEASUREMENT');put(70,1);put(0,'ENDSEC');put(0,'SECTION');put(2,'TABLES');put(0,'TABLE');put(2,'LTYPE');put(70,1);put(0,'LTYPE');put(2,'CONTINUOUS');put(70,0);put(3,'Continuous');put(72,65);put(73,0);put(40,0);put(0,'ENDTAB');put(0,'TABLE');put(2,'LAYER');put(70,layers.length+1);for(const name of ['0',...layers]){put(0,'LAYER');put(2,name);put(70,0);put(62,name.startsWith('CUT')?1:name==='MULLION'?3:name==='FOLD'?4:name==='DIMENSIONS'?2:7);put(6,'CONTINUOUS')}put(0,'ENDTAB');put(0,'ENDSEC');put(0,'SECTION');put(2,'ENTITIES');
 for(const {a,b,layer}of drawing.segments){put(0,'LINE');put(8,layer);put(10,a[0]);put(20,a[1]);put(30,0);put(11,b[0]);put(21,b[1]);put(31,0)}
 for(const t of drawing.texts){put(0,'TEXT');put(8,t.layer);put(10,t.point[0]);put(20,t.point[1]);put(30,0);put(40,t.height);put(1,t.text)}put(0,'ENDSEC');put(0,'EOF');return pairs.join('\n')+'\n';
}
