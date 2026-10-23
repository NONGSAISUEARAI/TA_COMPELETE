import {panelEdgeLabels,boundaryCorners} from './dimensions.js';
const distance=(a,b)=>Math.hypot(...a.map((n,i)=>n-b[i]));
// Follow the physical perimeter across faces; internal joined edges never receive an E number.
export function foldedPanelBoundary(items){
 const remaining=items.flatMap(({a,p})=>panelEdgeLabels({...a,visible:true},p).filter(e=>!p.joinedEdges?.includes(e.edgeIndex)).map(e=>({...e,a,p,localEdgeIndex:e.edgeIndex}))),ordered=[];
 while(remaining.length){let edge=remaining.shift();ordered.push(edge);let end=edge.end;while(remaining.length){const index=remaining.findIndex(e=>distance(e.start,end)<.2||distance(e.end,end)<.2);if(index<0)break;edge=remaining.splice(index,1)[0];end=distance(edge.start,end)<.2?edge.end:edge.start;ordered.push(edge)}}
 return ordered.map((e,i)=>({...e,label:'E'+(i+1),edgeIndex:i}));
}
export function panelBendRows(items){
 const groups=new Map();for(const item of items){const group=item.p.foldGroup||JSON.stringify([item.a.id,item.p.key]);if(!groups.has(group))groups.set(group,[]);groups.get(group).push(item)}
 const lists=[...groups.values()].map(group=>group[0].p.foldGroup?foldedPanelBoundary(group).map(e=>({a:e.a,p:e.p,edgeIndex:e.localEdgeIndex,trimReversed:e.trimReversed})):panelEdgeLabels({...group[0].a,visible:true},group[0].p).map(e=>({...group[0],edgeIndex:e.edgeIndex,trimReversed:e.trimReversed})));
 return Array.from({length:Math.max(0,...lists.map(l=>l.length))},(_,index)=>({index,label:'E'+(index+1),targets:lists.map(l=>l[index]).filter(Boolean),unavailable:lists.some(l=>!l[index])}));
}

export function panelTrimKey(key,reversed){return reversed?({trimStart:'trimEnd',trimEnd:'trimStart',trimCStart:'trimCEnd',trimCEnd:'trimCStart'}[key]||key):key}
