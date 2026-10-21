const eps=.001;
export const cellKey=b=>`${Number(b[0].toFixed(3))}:${Number(b[1].toFixed(3))}:0`;
const rect=(x0,y0,x1,y1,source)=>({bounds:[x0,y0,x1,y1],...(source?{source}:{})});
export function validatePanelPatches(patches){let count=0;if(!Array.isArray(patches)||patches.length>100)throw Error('ปรับขนาด Panel ได้สูงสุด 100 ครั้งก่อน Reset');const valid=b=>Array.isArray(b)&&b.length===4&&b.every(n=>Number.isFinite(n)&&Math.abs(n)<=1e9)&&b[2]>b[0]&&b[3]>b[1];for(const p of patches){if(!p||!valid(p.bounds)||!Array.isArray(p.cells)||(count+=p.cells.length)>200000||p.cells.some(c=>!c||!valid(c.bounds)||c.bounds[0]<p.bounds[0]-eps||c.bounds[1]<p.bounds[1]-eps||c.bounds[2]>p.bounds[2]+eps||c.bounds[3]>p.bounds[3]+eps||(c.override&&!['solid','glass','open'].includes(c.override))))throw Error('ข้อมูลแพทเทิร์น Panel ไม่ถูกต้อง')}}
export const scalePanelPatches=(patches,scale)=>patches.map(p=>({...p,bounds:p.bounds.map(n=>n*scale),cells:p.cells.map(c=>({...c,bounds:c.bounds.map(n=>n*scale)}))}));
function subtract(cell,b){const [x,y,X,Y]=cell.bounds,l=Math.max(x,b[0]),r=Math.min(X,b[2]),d=Math.max(y,b[1]),u=Math.min(Y,b[3]);if(r-l<=eps||u-d<=eps)return [cell];return [[x,y,l,Y],[r,y,X,Y],[l,y,r,d],[l,u,r,Y]].filter(q=>q[2]-q[0]>eps&&q[3]-q[1]>eps).map(bounds=>({...cell,bounds}))}
export function panelCells(xs,ys,patches=[],overrides={}){
 let cells=[];for(let i=0;i<xs.length-1;i++)for(let j=0;j<ys.length-1;j++){const cell=rect(xs[i],ys[j],xs[i+1],ys[j+1]);if(overrides[cellKey(cell.bounds)])cell.override=overrides[cellKey(cell.bounds)];cells.push(cell)}
 for(const patch of patches){cells=cells.flatMap(cell=>subtract(cell,patch.bounds));cells.push(...patch.cells.map(cell=>({...cell,bounds:[...cell.bounds]})));if(cells.length>100000)throw Error('Panel รวมเกิน 100,000 ช่องต่อ Area')}
 return cells;
}
export function panelGrid(cells,bounds){
 const lines=[new Map(),new Map()];
 for(const {bounds:b}of cells)for(const axis of [0,1])for(const side of [0,2]){const at=b[axis+side];if(Math.abs(at-bounds[axis])<eps||Math.abs(at-bounds[axis+2])<eps)continue;const key=Number(at.toFixed(6));if(!lines[axis].has(key))lines[axis].set(key,[]);lines[axis].get(key).push([b[1-axis],b[3-axis]])}
 const result=[];for(const axis of [0,1])for(const [at,ranges]of lines[axis]){const merged=[];for(const range of ranges.sort((a,b)=>a[0]-b[0])){const last=merged.at(-1);if(last&&range[0]<=last[1]+eps)last[1]=Math.max(last[1],range[1]);else merged.push([...range])}for(const [lo,hi]of merged)result.push(axis===0?[[at,lo],[at,hi]]:[[lo,at],[hi,at]])}return result;
}
export function resizedStrip(cells,selected,axis,low,high,extent,spacing){
 const b=selected.bounds,other=1-axis,region=[...extent];region[other]=b[other];region[other+2]=b[other+2];const list=[];
 for(const cell of cells){const q=[...cell.bounds];q[other]=Math.max(q[other],region[other]);q[other+2]=Math.min(q[other+2],region[other+2]);if(q[other+2]-q[other]<=eps)continue;
  if(q[axis]>=b[axis]-eps&&q[axis+2]<=b[axis+2]+eps)continue;
  const delta=q[axis+2]<=b[axis]+eps?low-b[axis]:high-b[axis+2];q[axis]=Math.max(extent[axis],q[axis]+delta);q[axis+2]=Math.min(extent[axis+2],q[axis+2]+delta);if(q[axis+2]-q[axis]>eps)list.push({...cell,source:cellKey(cell.bounds),bounds:q});
 }
 const edited={...selected,bounds:[...b],source:cellKey(b)};edited.bounds[axis]=low;edited.bounds[axis+2]=high;list.push(edited);
 const min=Math.min(...list.map(c=>c.bounds[axis])),max=Math.max(...list.map(c=>c.bounds[axis+2]));
 for(let end=min;end>extent[axis]+eps;){const q=[...region];q[axis]=Math.max(extent[axis],end-spacing);q[axis+2]=end;list.push({bounds:q});end=q[axis]}
 for(let start=max;start<extent[axis+2]-eps;){const q=[...region];q[axis]=start;q[axis+2]=Math.min(extent[axis+2],start+spacing);list.push({bounds:q});start=q[axis+2]}
 return {bounds:region,cells:list};
}
