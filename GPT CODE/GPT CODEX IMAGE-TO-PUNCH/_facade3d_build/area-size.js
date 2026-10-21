export function areaSize(area){
 const xs=area.outer.map(p=>p[0]),ys=area.outer.map(p=>p[1]);
 const min=[Math.min(...xs),Math.min(...ys)],max=[Math.max(...xs),Math.max(...ys)];
 return {min,max,width:max[0]-min[0],height:max[1]-min[1]};
}

// Resize in the area's own plane, anchored at the minimum local X/Y corner.
export function resizeArea(area,width,height){
 if(![width,height].every(n=>Number.isFinite(n)&&n>=1&&n<=1e9))throw Error('กว้างและสูงต้องเป็นตัวเลข 1–1,000,000,000 mm');
 const size=areaSize(area),scale=[width/size.width,height/size.height];
 const transform=p=>p.map((v,i)=>size.min[i]+(v-size.min[i])*scale[i]);
 area.outer=area.outer.map(transform);area.holes=area.holes.map(h=>h.map(transform));
 area.pattern.origin=transform(area.pattern.origin);
 if(area.curtain?.origin)area.curtain.origin=transform(area.curtain.origin);
}
