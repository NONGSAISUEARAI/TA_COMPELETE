const insideRect=(p,r)=>p[0]>=r[0]&&p[0]<=r[2]&&p[1]>=r[1]&&p[1]<=r[3];
const inside=(p,ring)=>{let result=false;for(let i=0,j=ring.length-1;i<ring.length;j=i++){const a=ring[i],b=ring[j];if((a[1]>p[1])!==(b[1]>p[1])&&p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0])result=!result}return result};
function segmentHit(a,b,r){let low=0,high=1;for(const axis of [0,1]){const d=b[axis]-a[axis];if(Math.abs(d)<1e-10){if(a[axis]<r[axis]||a[axis]>r[axis+2])return false}else{let x=(r[axis]-a[axis])/d,y=(r[axis+2]-a[axis])/d;if(x>y)[x,y]=[y,x];low=Math.max(low,x);high=Math.min(high,y);if(low>high)return false}}return true}
export function boxHitsPolygon(rings,rect,crossing=false){
 if(!rings[0]?.length)return false;if(!crossing)return rings[0].every(p=>insideRect(p,rect));
 for(const ring of rings)for(let i=0;i<ring.length;i++)if(insideRect(ring[i],rect)||segmentHit(ring[i],ring[(i+1)%ring.length],rect))return true;
 const p=[(rect[0]+rect[2])/2,(rect[1]+rect[3])/2];return inside(p,rings[0])&&!rings.slice(1).some(h=>inside(p,h));
}
