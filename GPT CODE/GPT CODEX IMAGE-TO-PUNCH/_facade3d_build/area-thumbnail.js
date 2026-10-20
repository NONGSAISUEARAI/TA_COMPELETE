import {dot,worldPoint,sub} from './geometry.js';
import {worldCurtainBasis} from './curtain-world.js';

// A face-on silhouette, with equal scale on both axes and actual openings.
export function createAreaThumbnail(area,index){
 const ns='http://www.w3.org/2000/svg',svg=document.createElementNS(ns,'svg'),path=document.createElementNS(ns,'path'),basis=worldCurtainBasis(area);
 const loops=[area.outer,...area.holes].map(loop=>loop.map(p=>{const w=sub(worldPoint(area,p),area.base);return [dot(w,basis.x),dot(w,basis.y)]}));
 const xs=loops[0].map(p=>p[0]),ys=loops[0].map(p=>p[1]),minX=Math.min(...xs),maxX=Math.max(...xs),minY=Math.min(...ys),maxY=Math.max(...ys),scale=38/Math.max(maxX-minX,maxY-minY,1e-9);
 const point=([x,y])=>[24+(x-(minX+maxX)/2)*scale,24-(y-(minY+maxY)/2)*scale].map(n=>Number(n.toFixed(3))).join(',');
 svg.setAttribute('viewBox','0 0 48 48');svg.setAttribute('class','area-thumbnail');svg.setAttribute('role','img');svg.setAttribute('aria-label',`Area ${index} · ${area.name} · boundary and openings`);
 path.setAttribute('d',loops.map(loop=>'M '+loop.map(point).join(' L ')+' Z').join(' '));path.setAttribute('fill-rule','evenodd');svg.append(path);
 const title=document.createElementNS(ns,'title');title.textContent=`${area.name} · ${area.outer.length} boundary vertices · ${area.holes.length} openings`;svg.prepend(title);return svg;
}
